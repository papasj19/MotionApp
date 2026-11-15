import 'dart:async';

import 'package:camera/camera.dart';
import 'package:material_ui/material_ui.dart';

import '../calibration/calibration_profile.dart';
import '../hand_tracking/hand_tracking_service.dart';
import '../hand_tracking/mediapipe_hand_tracking_service.dart';
import '../movement/movement_measurement.dart';
import '../movement_tracking/hand_movement_tracking_adapter.dart';
import '../movement_tracking/mediapipe_body_movement_tracking_service.dart';
import '../movement_tracking/movement_tracking_service.dart';
import '../services/camera_service.dart';
import '../widgets/calibration_panel.dart';
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
  const CameraScreen({
    super.key,
    this.cameraService,
    this.handTrackingService,
    this.trackingServiceFactory,
    this.initialMovementType,
  });

  final CameraService? cameraService;
  final HandTrackingService? handTrackingService;
  final MovementTrackingService Function(CalibrationMovementType type)?
  trackingServiceFactory;
  final CalibrationMovementType? initialMovementType;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  static const _orientationRestartDelay = Duration(milliseconds: 300);

  late final CameraService _cameraService;
  MovementTrackingService? _trackingService;
  StreamSubscription<MovementTrackingUpdate>? _trackingSubscription;
  CalibrationMovementType? _selectedMovementType;

  _CameraViewState _viewState = _CameraViewState.initializing;
  MovementTrackingUpdate? _trackingUpdate;
  MovementMeasurement? _movementReading;
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
    _selectedMovementType = widget.initialMovementType;
    if (_selectedMovementType case final movementType?) {
      _configureTracking(movementType);
    }
    WidgetsBinding.instance.addObserver(this);
    if (_selectedMovementType != null) {
      unawaited(_initializeCamera());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.orientationOf(context);
    final previousOrientation = _lastOrientation;
    _lastOrientation = orientation;

    if (previousOrientation != null &&
        previousOrientation != orientation &&
        _selectedMovementType != null) {
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
      await _trackingService?.start(controller);
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
    if (mounted && _isAppActive && _selectedMovementType != null) {
      await _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _orientationRestartTimer?.cancel();
    _isAppActive = false;
    _requestId += 1;
    final subscription = _trackingSubscription;
    _trackingSubscription = null;
    unawaited(subscription?.cancel());
    unawaited(_disposeCameraAndTracking());
    super.dispose();
  }

  Future<void> _stopCameraAndTracking() async {
    await _trackingService?.stop();
    await _cameraService.dispose();
  }

  Future<void> _disposeCameraAndTracking() async {
    final trackingDispose = _trackingService?.dispose();
    final disposals = <Future<void>>[_cameraService.dispose()];
    if (trackingDispose != null) {
      disposals.add(trackingDispose);
    }
    await Future.wait(disposals);
  }

  @override
  Widget build(BuildContext context) {
    final movementType = _selectedMovementType;
    if (movementType == null) {
      return _MovementSelectionScreen(onSelected: _selectMovement);
    }
    final orientation = MediaQuery.orientationOf(context);
    final setupContext = CalibrationSetupContext(
      orientation: orientation == Orientation.portrait
          ? CalibrationDeviceOrientation.portrait
          : CalibrationDeviceOrientation.landscape,
    );
    final previewHeight = _viewState == _CameraViewState.ready
        ? orientation == Orientation.portrait
              ? 340.0
              : 220.0
        : 180.0;
    final trackingUpdate = _trackingUpdate;
    final movementReading = _movementReading;
    return Scaffold(
      appBar: AppBar(
        title: Text('${movementType.shortLabel} calibration'),
        actions: [
          TextButton(
            onPressed: _returnToMovementSelection,
            child: const Text('Change'),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: previewHeight,
                      child: _PreviewPanel(
                        viewState: _viewState,
                        controller: _controller,
                        trackingUpdate: trackingUpdate,
                        movementType: movementType,
                      ),
                    ),
                    if (_viewState != _CameraViewState.ready) ...[
                      const SizedBox(height: 12),
                      _StatusPanel(
                        viewState: _viewState,
                        message: _statusMessage,
                        onRetry: _canRetry ? _initializeCamera : null,
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (movementReading != null)
                      CalibrationPanel(
                        reading: movementReading,
                        movementType: movementType,
                        setupContext: setupContext,
                      )
                    else
                      _TrackingPreparationPanel(movementType: movementType),
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
            );
          },
        ),
      ),
    );
  }

  bool get _canRetry => switch (_viewState) {
    _CameraViewState.permissionDenied || _CameraViewState.failure => true,
    _ => false,
  };

  void _configureTracking(CalibrationMovementType movementType) {
    final service =
        widget.trackingServiceFactory?.call(movementType) ??
        switch (movementType) {
          CalibrationMovementType.indexFingerBend =>
            HandMovementTrackingAdapter(
              widget.handTrackingService ?? MediaPipeHandTrackingService(),
            ),
          CalibrationMovementType.wristBend ||
          CalibrationMovementType.headTilt =>
            MediaPipeBodyMovementTrackingService(movementType: movementType),
        };
    _trackingService = service;
    _trackingSubscription = service.updates.listen((update) {
      if (mounted) {
        setState(() {
          _trackingUpdate = update;
          _movementReading = update.reading;
        });
      }
    });
  }

  void _selectMovement(CalibrationMovementType movementType) {
    setState(() {
      _selectedMovementType = movementType;
      _viewState = _CameraViewState.initializing;
      _statusMessage = 'Starting the front camera…';
    });
    _configureTracking(movementType);
    unawaited(_initializeCamera());
  }

  Future<void> _returnToMovementSelection() async {
    _orientationRestartTimer?.cancel();
    _requestId += 1;
    _isInitializing = false;
    final subscription = _trackingSubscription;
    final service = _trackingService;
    _trackingSubscription = null;
    _trackingService = null;
    await subscription?.cancel();
    await service?.dispose();
    await _cameraService.dispose();
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedMovementType = null;
      _trackingUpdate = null;
      _movementReading = null;
      _controller = null;
      _viewState = _CameraViewState.initializing;
    });
  }
}

class _MovementSelectionScreen extends StatelessWidget {
  const _MovementSelectionScreen({required this.onSelected});

  final ValueChanged<CalibrationMovementType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a movement')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'What comfortable movement will control the game?',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'A caregiver can choose the clearest option. Calibration measures '
              'the child’s current comfortable movement and never asks for a '
              'maximum range.',
            ),
            const SizedBox(height: 16),
            for (final type in CalibrationMovementType.values) ...[
              _MovementChoiceCard(
                movementType: type,
                onTap: () => onSelected(type),
              ),
              const SizedBox(height: 12),
            ],
            const Text(
              'Head control uses left/right tilt only. It does not use blinking '
              'or facial expressions.',
            ),
          ],
        ),
      ),
    );
  }
}

class _MovementChoiceCard extends StatelessWidget {
  const _MovementChoiceCard({required this.movementType, required this.onTap});

  final CalibrationMovementType movementType;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (movementType) {
      CalibrationMovementType.indexFingerBend => Icons.touch_app_outlined,
      CalibrationMovementType.wristBend => Icons.pan_tool_alt_outlined,
      CalibrationMovementType.headTilt => Icons.face_outlined,
    };
    return Semantics(
      button: true,
      label: '${movementType.shortLabel}. ${movementType.selectionDescription}',
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Icon(icon, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movementType.shortLabel,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(movementType.selectionDescription),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackingPreparationPanel extends StatelessWidget {
  const _TrackingPreparationPanel({required this.movementType});

  final CalibrationMovementType movementType;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.center_focus_weak),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preparing movement tracking',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(movementType.positioningHint),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.viewState,
    required this.controller,
    required this.trackingUpdate,
    required this.movementType,
  });

  final _CameraViewState viewState;
  final CameraController? controller;
  final MovementTrackingUpdate? trackingUpdate;
  final CalibrationMovementType movementType;

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
                      if (trackingUpdate?.handObservation
                          case final observation?)
                        HandSkeletonOverlay(observation: observation),
                      Align(
                        alignment: Alignment.topCenter,
                        child: _MovementTrackingBadge(
                          update: trackingUpdate,
                          movementType: movementType,
                        ),
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

class _MovementTrackingBadge extends StatelessWidget {
  const _MovementTrackingBadge({
    required this.update,
    required this.movementType,
  });

  final MovementTrackingUpdate? update;
  final CalibrationMovementType movementType;

  @override
  Widget build(BuildContext context) {
    final status = update?.status ?? MovementTrackingStatus.starting;
    final label = switch (status) {
      MovementTrackingStatus.idle => 'Tracking paused',
      MovementTrackingStatus.starting => 'Starting tracking…',
      MovementTrackingStatus.searching => movementType.positioningHint,
      MovementTrackingStatus.tracking => _trackingLabel,
      MovementTrackingStatus.failure => 'Tracking unavailable',
    };
    final icon = status == MovementTrackingStatus.tracking
        ? Icons.pan_tool_alt_outlined
        : status == MovementTrackingStatus.failure
        ? Icons.warning_amber_rounded
        : Icons.center_focus_weak;
    final semanticLabel = switch (status) {
      MovementTrackingStatus.idle => 'Movement tracking paused.',
      MovementTrackingStatus.starting => 'Starting movement tracking.',
      MovementTrackingStatus.searching => movementType.positioningHint,
      MovementTrackingStatus.tracking =>
        '${movementType.shortLabel} movement is being tracked.',
      MovementTrackingStatus.failure =>
        'Movement tracking unavailable. ${update?.message ?? ''}',
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
    final fps = update?.framesPerSecond.round() ?? 0;
    final latency = update?.processingLatency?.inMilliseconds;
    if (latency == null) {
      return '${movementType.shortLabel} detected • $fps FPS';
    }
    return '${movementType.shortLabel} detected • $fps FPS • $latency ms';
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
