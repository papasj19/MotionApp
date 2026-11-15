import 'dart:async';

import 'package:camera/camera.dart';
import 'package:material_ui/material_ui.dart';

import '../hand_tracking/hand_tracking_service.dart';
import '../hand_tracking/hand_tracking_update.dart';
import '../hand_tracking/mediapipe_hand_tracking_service.dart';
import '../services/camera_service.dart';
import '../widgets/hand_skeleton_overlay.dart';

enum _CameraViewState {
  initializing,
  ready,
  noFrontCamera,
  permissionDenied,
  permissionRestricted,
  paused,
  failure,
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, this.cameraService, this.handTrackingService});

  final CameraService? cameraService;
  final HandTrackingService? handTrackingService;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  static const _orientationRestartDelay = Duration(milliseconds: 300);

  late final CameraService _cameraService;
  late final HandTrackingService _handTrackingService;
  StreamSubscription<HandTrackingUpdate>? _handTrackingSubscription;

  _CameraViewState _viewState = _CameraViewState.initializing;
  HandTrackingUpdate _handTrackingUpdate = const HandTrackingUpdate.idle();
  CameraController? _controller;
  String _statusMessage = 'Starting the front camera…';
  bool _isAppActive = true;
  bool _isInitializing = false;
  int _requestId = 0;
  Future<void>? _pauseOperation;
  Orientation? _lastOrientation;
  Timer? _orientationRestartTimer;

  @override
  void initState() {
    super.initState();
    _cameraService = widget.cameraService ?? DeviceCameraService();
    _handTrackingService =
        widget.handTrackingService ?? MediaPipeHandTrackingService();
    _handTrackingSubscription = _handTrackingService.updates.listen((update) {
      if (mounted) {
        setState(() => _handTrackingUpdate = update);
      }
    });
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeCamera());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.orientationOf(context);
    final previousOrientation = _lastOrientation;
    _lastOrientation = orientation;

    if (previousOrientation != null && previousOrientation != orientation) {
      _scheduleOrientationRestart();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_isAppActive) {
          _isAppActive = true;
          unawaited(_resumeCamera());
        }
        return;
      case AppLifecycleState.inactive:
        // Permission prompts and other temporary overlays can make the app
        // inactive without putting it in the background.
        return;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (_isAppActive) {
          _isAppActive = false;
          _orientationRestartTimer?.cancel();
          _pauseOperation = _pauseCamera();
        }
        return;
    }
  }

  Future<void> _initializeCamera({
    String startingMessage = 'Starting the front camera…',
  }) async {
    if (_isInitializing || !_isAppActive) {
      return;
    }

    _isInitializing = true;
    final requestId = ++_requestId;
    if (mounted) {
      setState(() {
        _viewState = _CameraViewState.initializing;
        _controller = null;
        _statusMessage = startingMessage;
      });
    }

    final result = await _cameraService.initialize();
    if (!mounted || requestId != _requestId || !_isAppActive) {
      return;
    }

    _isInitializing = false;
    CameraController? readyController;
    setState(() {
      _statusMessage = result.message;
      switch (result.status) {
        case CameraSetupStatus.ready:
          final controller = result.controller;
          if (controller == null || !controller.value.isInitialized) {
            _viewState = _CameraViewState.failure;
            _statusMessage = 'The camera could not start. Please try again.';
          } else {
            _viewState = _CameraViewState.ready;
            _controller = controller;
            readyController = controller;
          }
        case CameraSetupStatus.noFrontCamera:
          _viewState = _CameraViewState.noFrontCamera;
        case CameraSetupStatus.permissionDenied:
          _viewState = _CameraViewState.permissionDenied;
        case CameraSetupStatus.permissionRestricted:
          _viewState = _CameraViewState.permissionRestricted;
        case CameraSetupStatus.cancelled:
          _viewState = _CameraViewState.paused;
        case CameraSetupStatus.failure:
          _viewState = _CameraViewState.failure;
      }
    });

    final controller = readyController;
    if (controller != null &&
        mounted &&
        requestId == _requestId &&
        _isAppActive) {
      await _handTrackingService.start(controller);
    }
  }

  void _scheduleOrientationRestart() {
    _orientationRestartTimer?.cancel();
    if (!_isAppActive) {
      return;
    }

    _orientationRestartTimer = Timer(_orientationRestartDelay, () {
      _orientationRestartTimer = null;
      if (mounted && _isAppActive) {
        unawaited(_restartCameraForOrientationChange());
      }
    });
  }

  Future<void> _restartCameraForOrientationChange() async {
    final restartId = ++_requestId;
    _isInitializing = false;
    if (mounted) {
      setState(() {
        _controller = null;
        _viewState = _CameraViewState.initializing;
        _statusMessage = 'Adjusting camera orientation…';
      });
    }

    await _stopCameraAndTracking();
    if (!mounted || !_isAppActive || restartId != _requestId) {
      return;
    }

    await _initializeCamera(startingMessage: 'Adjusting camera orientation…');
  }

  Future<void> _pauseCamera() async {
    _requestId += 1;
    _isInitializing = false;
    if (mounted) {
      setState(() {
        _controller = null;
        _viewState = _CameraViewState.paused;
        _statusMessage = 'Camera paused while the app is not active.';
      });
    }
    await _stopCameraAndTracking();
  }

  Future<void> _resumeCamera() async {
    await _pauseOperation;
    _pauseOperation = null;
    if (mounted && _isAppActive) {
      await _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _orientationRestartTimer?.cancel();
    _isAppActive = false;
    _requestId += 1;
    final subscription = _handTrackingSubscription;
    _handTrackingSubscription = null;
    unawaited(subscription?.cancel());
    unawaited(_disposeCameraAndTracking());
    super.dispose();
  }

  Future<void> _stopCameraAndTracking() async {
    await _handTrackingService.stop();
    await _cameraService.dispose();
  }

  Future<void> _disposeCameraAndTracking() async {
    await _handTrackingService.dispose();
    await _cameraService.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hand tracking preview')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: _PreviewPanel(
                  viewState: _viewState,
                  controller: _controller,
                  handTrackingUpdate: _handTrackingUpdate,
                ),
              ),
              const SizedBox(height: 16),
              _StatusPanel(
                viewState: _viewState,
                message: _statusMessage,
                onRetry: _canRetry ? _initializeCamera : null,
              ),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.privacy_tip_outlined, size: 20),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Live preview only. Nothing is recorded or saved.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canRetry => switch (_viewState) {
    _CameraViewState.permissionDenied || _CameraViewState.failure => true,
    _ => false,
  };
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.viewState,
    required this.controller,
    required this.handTrackingUpdate,
  });

  final _CameraViewState viewState;
  final CameraController? controller;
  final HandTrackingUpdate handTrackingUpdate;

  @override
  Widget build(BuildContext context) {
    final activeController = controller;
    final showPreview =
        viewState == _CameraViewState.ready &&
        activeController != null &&
        activeController.value.isInitialized;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ColoredBox(
        color: Colors.black,
        child: Center(
          child: showPreview
              ? CameraPreview(
                  activeController,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (handTrackingUpdate.observation
                          case final observation?)
                        HandSkeletonOverlay(observation: observation),
                      Align(
                        alignment: Alignment.topCenter,
                        child: _HandTrackingBadge(update: handTrackingUpdate),
                      ),
                    ],
                  ),
                )
              : _PreviewPlaceholder(viewState: viewState),
        ),
      ),
    );
  }
}

class _HandTrackingBadge extends StatelessWidget {
  const _HandTrackingBadge({required this.update});

  final HandTrackingUpdate update;

  @override
  Widget build(BuildContext context) {
    final label = switch (update.status) {
      HandTrackingStatus.idle => 'Hand tracking paused',
      HandTrackingStatus.starting => 'Starting hand tracking…',
      HandTrackingStatus.searching => 'Show one hand',
      HandTrackingStatus.tracking => _trackingLabel,
      HandTrackingStatus.failure => 'Hand tracking unavailable',
    };
    final icon = update.status == HandTrackingStatus.tracking
        ? Icons.pan_tool_alt_outlined
        : update.status == HandTrackingStatus.failure
        ? Icons.warning_amber_rounded
        : Icons.center_focus_weak;
    final semanticLabel = switch (update.status) {
      HandTrackingStatus.idle => 'Hand tracking paused.',
      HandTrackingStatus.starting => 'Starting hand tracking.',
      HandTrackingStatus.searching => 'No hand detected. Show one hand.',
      HandTrackingStatus.tracking =>
        'Hand detected. One hand is being tracked.',
      HandTrackingStatus.failure =>
        'Hand tracking unavailable. ${update.message}',
    };

    return Semantics(
      container: true,
      liveRegion: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _trackingLabel {
    final fps = update.framesPerSecond.round();
    final latency = update.processingLatency?.inMilliseconds;
    if (latency == null) {
      return 'Hand detected • $fps FPS';
    }
    return 'Hand detected • $fps FPS • $latency ms';
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder({required this.viewState});

  final _CameraViewState viewState;

  @override
  Widget build(BuildContext context) {
    final isLoading = viewState == _CameraViewState.initializing;
    return Semantics(
      label: isLoading
          ? 'Camera preview loading'
          : 'Camera preview unavailable',
      child: ExcludeSemantics(
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(
                Icons.videocam_off_outlined,
                color: Colors.white,
                size: 64,
              ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.viewState,
    required this.message,
    required this.onRetry,
  });

  final _CameraViewState viewState;
  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = switch (viewState) {
      _CameraViewState.initializing => 'Starting camera',
      _CameraViewState.ready => 'Camera ready',
      _CameraViewState.noFrontCamera => 'Front camera unavailable',
      _CameraViewState.permissionDenied => 'Camera permission needed',
      _CameraViewState.permissionRestricted => 'Camera access restricted',
      _CameraViewState.paused => 'Camera paused',
      _CameraViewState.failure => 'Camera unavailable',
    };
    final icon = switch (viewState) {
      _CameraViewState.ready => Icons.check_circle_outline,
      _CameraViewState.initializing => Icons.hourglass_top,
      _CameraViewState.paused => Icons.pause_circle_outline,
      _ => Icons.info_outline,
    };

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    container: true,
                    liveRegion: true,
                    label: 'Camera status. $title. $message',
                    child: ExcludeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(message),
                        ],
                      ),
                    ),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
