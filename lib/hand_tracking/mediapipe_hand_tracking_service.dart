import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:mediapipe_vision/mediapipe_vision.dart';

import 'camera_frame_converter.dart';
import 'hand_observation.dart';
import 'hand_tracking_service.dart';
import 'hand_tracking_update.dart';

int cameraImageRotationDegrees({
  required int sensorOrientation,
  required DeviceOrientation deviceOrientation,
  required CameraLensDirection lensDirection,
}) {
  final deviceRotation = switch (deviceOrientation) {
    DeviceOrientation.portraitUp => 0,
    DeviceOrientation.landscapeLeft => 90,
    DeviceOrientation.portraitDown => 180,
    DeviceOrientation.landscapeRight => 270,
  };

  if (lensDirection == CameraLensDirection.front) {
    return (sensorOrientation + deviceRotation) % 360;
  }
  return (sensorOrientation - deviceRotation + 360) % 360;
}

class MediaPipeHandTrackingService implements HandTrackingService {
  final StreamController<HandTrackingUpdate> _updates =
      StreamController<HandTrackingUpdate>.broadcast();
  final HandPresenceMonitor _presenceMonitor = HandPresenceMonitor();
  final Queue<Duration> _recentResults = Queue<Duration>();
  final Map<int, _SubmittedFrame> _submittedFrames = {};

  HandLandmarker? _landmarker;
  StreamSubscription<HandLandmarkerResult>? _resultSubscription;
  Timer? _staleTimer;
  Stopwatch? _clock;
  CameraController? _cameraController;
  int _lastTimestampMilliseconds = -1;
  int _operationId = 0;
  bool _disposed = false;

  @override
  Stream<HandTrackingUpdate> get updates => _updates.stream;

  @override
  Future<void> start(CameraController controller) async {
    if (_disposed) {
      throw StateError('The hand tracking service has been disposed.');
    }

    final operationId = ++_operationId;
    await _releaseSession();
    if (operationId != _operationId || _disposed) {
      return;
    }

    _emit(const HandTrackingUpdate.starting());
    try {
      final landmarker = await HandLandmarker.create(
        HandLandmarkerOptions(
          model: VisionModels.handLandmarker,
          runningMode: RunningMode.liveStream,
          numHands: 1,
        ),
      );
      if (operationId != _operationId || _disposed) {
        await landmarker.dispose();
        return;
      }

      _landmarker = landmarker;
      _cameraController = controller;
      _clock = Stopwatch()..start();
      _lastTimestampMilliseconds = -1;
      _presenceMonitor.reset();
      _recentResults.clear();
      _submittedFrames.clear();

      _resultSubscription = landmarker.results.listen(
        (result) => _handleResult(result, operationId),
        onError: (Object _, StackTrace _) {
          if (operationId == _operationId) {
            unawaited(_failAndStop());
          }
        },
      );
      _staleTimer = Timer.periodic(
        const Duration(milliseconds: 250),
        (_) => _checkForStaleObservation(operationId),
      );

      await controller.startImageStream(
        (image) => _submitFrame(image, operationId),
      );
      if (operationId != _operationId || _disposed) {
        await _releaseSession();
        return;
      }

      _emit(
        const HandTrackingUpdate(
          status: HandTrackingStatus.searching,
          message: 'Show one hand to begin tracking.',
        ),
      );
    } catch (_) {
      if (operationId == _operationId && !_disposed) {
        await _releaseSession();
        _emitFailure();
      }
    }
  }

  void _submitFrame(CameraImage image, int operationId) {
    final landmarker = _landmarker;
    final controller = _cameraController;
    final clock = _clock;
    if (operationId != _operationId ||
        landmarker == null ||
        controller == null ||
        clock == null) {
      return;
    }

    final now = clock.elapsedMilliseconds;
    final timestamp = now > _lastTimestampMilliseconds
        ? now
        : _lastTimestampMilliseconds + 1;
    _lastTimestampMilliseconds = timestamp;

    final rotationDegrees = cameraImageRotationDegrees(
      sensorOrientation: controller.description.sensorOrientation,
      deviceOrientation: controller.value.deviceOrientation,
      lensDirection: controller.description.lensDirection,
    );
    _submittedFrames[timestamp] = _SubmittedFrame(
      submittedAt: clock.elapsed,
      rotationDegrees: rotationDegrees,
      isMirrored:
          controller.description.lensDirection == CameraLensDirection.front,
    );
    while (_submittedFrames.length > 64) {
      _submittedFrames.remove(_submittedFrames.keys.first);
    }

    try {
      final frame = _copyCameraFrame(image);
      landmarker.detectAsync(
        VisionImage.deferred(() async {
          final converted = await Isolate.run(() => convertCameraFrame(frame));
          return VisionImage.fromPixels(
            pixels: converted.pixels,
            width: converted.width,
            height: converted.height,
            format: converted.isBgra
                ? VisionPixelFormat.bgra
                : VisionPixelFormat.rgba,
            bytesPerRow: converted.bytesPerRow,
          );
        }),
        timestampMilliseconds: timestamp,
        rotationDegrees: rotationDegrees,
      );
    } catch (_) {
      if (operationId == _operationId) {
        unawaited(_failAndStop());
      }
    }
  }

  CameraFrameData _copyCameraFrame(CameraImage image) {
    final format = switch (image.format.group) {
      ImageFormatGroup.bgra8888 => CameraFrameFormat.bgra8888,
      ImageFormatGroup.yuv420 => CameraFrameFormat.yuv420,
      _ => throw const FormatException('Unsupported camera image format.'),
    };

    return CameraFrameData(
      width: image.width,
      height: image.height,
      format: format,
      planes: image.planes
          .map(
            (plane) => CameraFramePlane(
              bytes: plane.bytes,
              bytesPerRow: plane.bytesPerRow,
              bytesPerPixel: plane.bytesPerPixel ?? 4,
            ),
          )
          .toList(growable: false),
    );
  }

  void _handleResult(HandLandmarkerResult result, int operationId) {
    final clock = _clock;
    if (operationId != _operationId || clock == null) {
      return;
    }

    final receivedAt = clock.elapsed;
    _recentResults.addLast(receivedAt);
    while (_recentResults.isNotEmpty &&
        receivedAt - _recentResults.first > const Duration(seconds: 1)) {
      _recentResults.removeFirst();
    }

    final timestamp = result.timestampMilliseconds;
    final submitted = timestamp == null
        ? null
        : _submittedFrames.remove(timestamp);
    final latency = submitted == null
        ? Duration.zero
        : receivedAt - submitted.submittedAt;
    final metadata = submitted ?? const _SubmittedFrame.fallback();

    HandObservation? observation;
    if (result.handLandmarks.isNotEmpty &&
        result.handLandmarks.first.length == 21) {
      final handedness = result.handedness.isEmpty
          ? null
          : result.handedness.first.firstOrNull;
      observation = HandObservation(
        timestamp: Duration(milliseconds: timestamp ?? 0),
        landmarks: result.handLandmarks.first
            .map(
              (landmark) => HandLandmark(
                x: landmark.x,
                y: landmark.y,
                z: landmark.z,
                visibility: landmark.visibility,
                presence: landmark.presence,
              ),
            )
            .toList(growable: false),
        imageWidth: result.imageWidth,
        imageHeight: result.imageHeight,
        rotationDegrees: metadata.rotationDegrees,
        isMirrored: metadata.isMirrored,
        handedness: _handednessFromLabel(handedness?.categoryName),
        handednessConfidence: handedness?.score,
      );
    }

    _emit(
      _presenceMonitor.acceptResult(
        observation: observation,
        receivedAt: receivedAt,
        sampleTimestamp: Duration(milliseconds: timestamp ?? 0),
        framesPerSecond: _framesPerSecond,
        processingLatency: latency,
        droppedFrames: _landmarker?.droppedFrames ?? 0,
      ),
    );
  }

  Handedness _handednessFromLabel(String? label) {
    return switch (label?.toLowerCase()) {
      'left' => Handedness.left,
      'right' => Handedness.right,
      _ => Handedness.unknown,
    };
  }

  double get _framesPerSecond => _recentResults.length.toDouble();

  void _checkForStaleObservation(int operationId) {
    final clock = _clock;
    if (operationId != _operationId || clock == null) {
      return;
    }
    final update = _presenceMonitor.markStale(
      now: clock.elapsed,
      framesPerSecond: _framesPerSecond,
      droppedFrames: _landmarker?.droppedFrames ?? 0,
    );
    if (update != null) {
      _emit(update);
    }
  }

  Future<void> _failAndStop() async {
    ++_operationId;
    await _releaseSession();
    _emitFailure();
  }

  void _emitFailure() {
    _emit(
      const HandTrackingUpdate.failure(
        'Hand tracking could not start. Please leave this screen and try again.',
      ),
    );
  }

  void _emit(HandTrackingUpdate update) {
    if (!_disposed && !_updates.isClosed) {
      _updates.add(update);
    }
  }

  @override
  Future<void> stop() async {
    if (_disposed) {
      return;
    }
    ++_operationId;
    await _releaseSession();
    _emit(const HandTrackingUpdate.idle());
  }

  Future<void> _releaseSession() async {
    _staleTimer?.cancel();
    _staleTimer = null;

    final controller = _cameraController;
    final subscription = _resultSubscription;
    final landmarker = _landmarker;
    _cameraController = null;
    _resultSubscription = null;
    _landmarker = null;
    _clock = null;
    _presenceMonitor.reset();
    _recentResults.clear();
    _submittedFrames.clear();

    if (controller?.value.isStreamingImages ?? false) {
      try {
        await controller!.stopImageStream();
      } catch (_) {
        // The camera can already be closing during lifecycle changes.
      }
    }
    if (landmarker != null) {
      await landmarker.dispose();
    }
    await subscription?.cancel();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    ++_operationId;
    await _releaseSession();
    _disposed = true;
    await _updates.close();
  }
}

class _SubmittedFrame {
  const _SubmittedFrame({
    required this.submittedAt,
    required this.rotationDegrees,
    required this.isMirrored,
  });

  const _SubmittedFrame.fallback()
    : submittedAt = Duration.zero,
      rotationDegrees = 0,
      isMirrored = false;

  final Duration submittedAt;
  final int rotationDegrees;
  final bool isMirrored;
}
