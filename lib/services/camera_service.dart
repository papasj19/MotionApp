import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

enum CameraSetupStatus {
  ready,
  noFrontCamera,
  permissionDenied,
  permissionRestricted,
  cancelled,
  failure,
}

class CameraSetupResult {
  const CameraSetupResult({
    required this.status,
    required this.message,
    this.controller,
  });

  final CameraSetupStatus status;
  final String message;
  final CameraController? controller;
}

abstract interface class CameraService {
  Future<CameraSetupResult> initialize();

  Future<void> dispose();
}

typedef CameraListLoader = Future<List<CameraDescription>> Function();

CameraDescription? selectFrontCamera(List<CameraDescription> cameras) {
  for (final camera in cameras) {
    if (camera.lensDirection == CameraLensDirection.front) {
      return camera;
    }
  }

  return null;
}

ImageFormatGroup cameraImageFormatForPlatform(TargetPlatform platform) {
  return platform == TargetPlatform.iOS
      ? ImageFormatGroup.bgra8888
      : ImageFormatGroup.yuv420;
}

class DeviceCameraService implements CameraService {
  DeviceCameraService({this.cameraListLoader = availableCameras});

  final CameraListLoader cameraListLoader;

  CameraController? _activeController;
  CameraController? _pendingController;
  Future<CameraSetupResult>? _initialization;
  int _operationId = 0;

  @override
  Future<CameraSetupResult> initialize() {
    final currentInitialization = _initialization;
    if (currentInitialization != null) {
      return currentInitialization;
    }

    final currentController = _activeController;
    if (currentController?.value.isInitialized ?? false) {
      return Future.value(
        CameraSetupResult(
          status: CameraSetupStatus.ready,
          message: 'The front camera preview is ready.',
          controller: currentController,
        ),
      );
    }

    final initialization = _initialize();
    _initialization = initialization;
    initialization.then<void>((_) {
      if (identical(_initialization, initialization)) {
        _initialization = null;
      }
    });
    return initialization;
  }

  Future<CameraSetupResult> _initialize() async {
    final operationId = ++_operationId;
    CameraController? initializingController;

    try {
      final cameras = await cameraListLoader();
      if (operationId != _operationId) {
        return _cancelledResult;
      }

      final frontCamera = selectFrontCamera(cameras);
      if (frontCamera == null) {
        return const CameraSetupResult(
          status: CameraSetupStatus.noFrontCamera,
          message: 'No front-facing camera was found on this device.',
        );
      }

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: cameraImageFormatForPlatform(defaultTargetPlatform),
      );
      initializingController = controller;
      _pendingController = controller;
      await controller.initialize();

      if (operationId != _operationId) {
        await controller.dispose();
        return _cancelledResult;
      }

      _pendingController = null;
      _activeController = controller;
      return CameraSetupResult(
        status: CameraSetupStatus.ready,
        message: 'The front camera preview is ready.',
        controller: controller,
      );
    } on CameraException catch (error) {
      await _disposeIfPending(initializingController);
      return _resultForCameraException(error);
    } catch (_) {
      await _disposeIfPending(initializingController);
      return const CameraSetupResult(
        status: CameraSetupStatus.failure,
        message: 'The camera could not start. Please try again.',
      );
    }
  }

  CameraSetupResult _resultForCameraException(CameraException error) {
    switch (error.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
        return const CameraSetupResult(
          status: CameraSetupStatus.permissionDenied,
          message:
              'Camera access was denied. Allow camera access in device '
              'settings, then try again.',
        );
      case 'CameraAccessRestricted':
        return const CameraSetupResult(
          status: CameraSetupStatus.permissionRestricted,
          message: 'Camera access is restricted on this device.',
        );
      default:
        return const CameraSetupResult(
          status: CameraSetupStatus.failure,
          message: 'The camera could not start. Please try again.',
        );
    }
  }

  @override
  Future<void> dispose() async {
    _operationId += 1;
    _initialization = null;

    final pendingController = _pendingController;
    final activeController = _activeController;
    _pendingController = null;
    _activeController = null;

    if (pendingController != null) {
      await pendingController.dispose();
    }
    if (activeController != null &&
        !identical(activeController, pendingController)) {
      await activeController.dispose();
    }
  }

  Future<void> _disposeIfPending(CameraController? controller) async {
    if (controller != null && identical(_pendingController, controller)) {
      _pendingController = null;
      await controller.dispose();
    }
  }

  static const _cancelledResult = CameraSetupResult(
    status: CameraSetupStatus.cancelled,
    message: 'Camera startup was cancelled.',
  );
}
