import 'dart:async';

import 'package:camera/camera.dart';
import 'package:material_ui/material_ui.dart';

import '../services/camera_service.dart';

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
  const CameraScreen({super.key, this.cameraService});

  final CameraService? cameraService;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  late final CameraService _cameraService;

  _CameraViewState _viewState = _CameraViewState.initializing;
  CameraController? _controller;
  String _statusMessage = 'Starting the front camera…';
  bool _isAppActive = true;
  bool _isInitializing = false;
  int _requestId = 0;
  Future<void>? _pauseOperation;

  @override
  void initState() {
    super.initState();
    _cameraService = widget.cameraService ?? DeviceCameraService();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeCamera());
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
          _pauseOperation = _pauseCamera();
        }
        return;
    }
  }

  Future<void> _initializeCamera() async {
    if (_isInitializing || !_isAppActive) {
      return;
    }

    _isInitializing = true;
    final requestId = ++_requestId;
    if (mounted) {
      setState(() {
        _viewState = _CameraViewState.initializing;
        _controller = null;
        _statusMessage = 'Starting the front camera…';
      });
    }

    final result = await _cameraService.initialize();
    if (!mounted || requestId != _requestId || !_isAppActive) {
      return;
    }

    _isInitializing = false;
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
    await _cameraService.dispose();
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
    _isAppActive = false;
    _requestId += 1;
    unawaited(_cameraService.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Front camera preview')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: _PreviewPanel(
                  viewState: _viewState,
                  controller: _controller,
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
  const _PreviewPanel({required this.viewState, required this.controller});

  final _CameraViewState viewState;
  final CameraController? controller;

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
              ? CameraPreview(activeController)
              : _PreviewPlaceholder(viewState: viewState),
        ),
      ),
    );
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
