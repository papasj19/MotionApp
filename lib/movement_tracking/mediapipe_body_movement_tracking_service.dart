import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:mediapipe_vision/mediapipe_vision.dart';

import '../hand_tracking/camera_frame_converter.dart';
import '../hand_tracking/mediapipe_hand_tracking_service.dart'
    show cameraImageRotationDegrees;
import '../movement/body_movement_analyzer.dart';
import '../movement/movement_measurement.dart';
import 'movement_tracking_service.dart';

class MediaPipeBodyMovementTrackingService implements MovementTrackingService {
  MediaPipeBodyMovementTrackingService({required this.movementType})
    : assert(
        movementType != CalibrationMovementType.indexFingerBend,
        'Use HandMovementTrackingAdapter for finger tracking.',
      );

  @override
  final CalibrationMovementType movementType;

  final StreamController<MovementTrackingUpdate> _updates =
      StreamController<MovementTrackingUpdate>.broadcast();
  final Queue<Duration> _recentResults = Queue<Duration>();
  final Map<int, _SubmittedBodyFrame> _submittedFrames = {};
  final HeadTiltMovementAnalyzer _headAnalyzer = HeadTiltMovementAnalyzer();
  final WristBendMovementAnalyzer _wristAnalyzer = WristBendMovementAnalyzer();

  _BodyLandmarkerTask? _task;
  StreamSubscription<_BodyTaskResult>? _resultSubscription;
  Timer? _staleTimer;
  Stopwatch? _clock;
  CameraController? _cameraController;
  Duration? _lastObservationAt;
  int _lastTimestampMilliseconds = -1;
  int _operationId = 0;
  bool _disposed = false;
  bool _hasObservation = false;

  @override
  Stream<MovementTrackingUpdate> get updates => _updates.stream;

  @override
  Future<void> start(CameraController controller) async {
    if (_disposed) {
      throw StateError('The movement tracking service has been disposed.');
    }

    final operationId = ++_operationId;
    await _releaseSession();
    if (operationId != _operationId || _disposed) {
      return;
    }

    _emit(_statusUpdate(MovementTrackingStatus.starting, 'Starting tracking…'));
    try {
      final task = await _createTask();
      if (operationId != _operationId || _disposed) {
        await task.dispose();
        return;
      }

      _task = task;
      _cameraController = controller;
      _clock = Stopwatch()..start();
      _lastTimestampMilliseconds = -1;
      _lastObservationAt = null;
      _hasObservation = false;
      _recentResults.clear();
      _submittedFrames.clear();
      _resetAnalyzer();

      _resultSubscription = task.results.listen(
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
        _statusUpdate(
          MovementTrackingStatus.searching,
          movementType.positioningHint,
        ),
      );
    } catch (_) {
      if (operationId == _operationId && !_disposed) {
        await _releaseSession();
        _emitFailure();
      }
    }
  }

  Future<_BodyLandmarkerTask> _createTask() => switch (movementType) {
    CalibrationMovementType.headTilt => _FaceBodyLandmarkerTask.create(),
    CalibrationMovementType.wristBend => _HolisticBodyLandmarkerTask.create(),
    CalibrationMovementType.indexFingerBend => throw StateError(
      'Finger tracking uses the hand landmarker.',
    ),
  };

  void _submitFrame(CameraImage image, int operationId) {
    final task = _task;
    final controller = _cameraController;
    final clock = _clock;
    if (operationId != _operationId ||
        task == null ||
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
    _submittedFrames[timestamp] = _SubmittedBodyFrame(
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
      task.detectAsync(
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

  void _handleResult(_BodyTaskResult result, int operationId) {
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

    final submitted = _submittedFrames.remove(result.timestampMilliseconds);
    final metadata = submitted ?? const _SubmittedBodyFrame.fallback();
    final latency = submitted == null
        ? Duration.zero
        : receivedAt - submitted.submittedAt;
    final frame = MovementFrameGeometry(
      imageWidth: result.imageWidth,
      imageHeight: result.imageHeight,
      rotationDegrees: metadata.rotationDegrees,
      isMirrored: metadata.isMirrored,
    );
    final timestamp = Duration(milliseconds: result.timestampMilliseconds);
    final reading = _analyzeResult(result, timestamp, frame);
    _hasObservation = reading.isValid;
    _lastObservationAt = receivedAt;

    _emit(
      MovementTrackingUpdate(
        status: reading.isValid
            ? MovementTrackingStatus.tracking
            : MovementTrackingStatus.searching,
        message: reading.isValid
            ? '${movementType.shortLabel} movement detected.'
            : movementType.positioningHint,
        reading: reading,
        framesPerSecond: _recentResults.length.toDouble(),
        processingLatency: latency,
        droppedFrames: _task?.droppedFrames ?? 0,
      ),
    );
  }

  MovementMeasurement _analyzeResult(
    _BodyTaskResult result,
    Duration timestamp,
    MovementFrameGeometry frame,
  ) {
    if (movementType == CalibrationMovementType.headTilt) {
      final head = result.head;
      if (head == null) {
        return _headAnalyzer.markMissing(
          timestamp: timestamp,
          movementType: movementType,
          note: movementType.positioningHint,
        );
      }
      return _headAnalyzer.analyze(
        HeadTiltObservation(
          timestamp: timestamp,
          firstEyeCorner: head.firstEyeCorner,
          secondEyeCorner: head.secondEyeCorner,
          frame: frame,
        ),
      );
    }

    final wrist = result.wrist;
    if (wrist == null) {
      return _wristAnalyzer.markMissing(
        timestamp: timestamp,
        movementType: movementType,
        note: movementType.positioningHint,
      );
    }
    return _wristAnalyzer.analyze(
      WristBendObservation(
        timestamp: timestamp,
        elbow: wrist.elbow,
        poseWrist: wrist.poseWrist,
        handWrist: wrist.handWrist,
        middleFingerBase: wrist.middleFingerBase,
        frame: frame,
      ),
    );
  }

  void _checkForStaleObservation(int operationId) {
    final clock = _clock;
    final lastObservationAt = _lastObservationAt;
    if (operationId != _operationId ||
        clock == null ||
        !_hasObservation ||
        lastObservationAt == null ||
        clock.elapsed - lastObservationAt < const Duration(milliseconds: 750)) {
      return;
    }
    _hasObservation = false;
    final timestamp = Duration(
      milliseconds: math.max(
        clock.elapsedMilliseconds,
        _lastTimestampMilliseconds + 1,
      ),
    );
    _emit(_searchingUpdate(timestamp));
  }

  MovementTrackingUpdate _searchingUpdate(Duration timestamp) {
    final reading = movementType == CalibrationMovementType.headTilt
        ? _headAnalyzer.markMissing(
            timestamp: timestamp,
            movementType: movementType,
            note: movementType.positioningHint,
          )
        : _wristAnalyzer.markMissing(
            timestamp: timestamp,
            movementType: movementType,
            note: movementType.positioningHint,
          );
    return MovementTrackingUpdate(
      status: MovementTrackingStatus.searching,
      message: movementType.positioningHint,
      reading: reading,
      framesPerSecond: _recentResults.length.toDouble(),
      droppedFrames: _task?.droppedFrames ?? 0,
    );
  }

  MovementTrackingUpdate _statusUpdate(
    MovementTrackingStatus status,
    String message,
  ) {
    return MovementTrackingUpdate(
      status: status,
      message: message,
      reading: BodyMovementReading.unavailable(
        timestamp: Duration.zero,
        movementType: movementType,
        validity: BodyMovementValidity.trackingUnavailable,
        note: message,
      ),
    );
  }

  Future<void> _failAndStop() async {
    ++_operationId;
    await _releaseSession();
    _emitFailure();
  }

  void _emitFailure() {
    _emit(
      _statusUpdate(
        MovementTrackingStatus.failure,
        '${movementType.shortLabel} tracking could not start. '
        'Please leave this screen and try again.',
      ),
    );
  }

  void _emit(MovementTrackingUpdate update) {
    if (!_disposed && !_updates.isClosed) {
      _updates.add(update);
    }
  }

  void _resetAnalyzer() {
    _headAnalyzer.reset();
    _wristAnalyzer.reset();
  }

  @override
  Future<void> stop() async {
    if (_disposed) {
      return;
    }
    ++_operationId;
    await _releaseSession();
    _emit(_statusUpdate(MovementTrackingStatus.idle, 'Tracking is paused.'));
  }

  Future<void> _releaseSession() async {
    _staleTimer?.cancel();
    _staleTimer = null;
    final controller = _cameraController;
    final subscription = _resultSubscription;
    final task = _task;
    _cameraController = null;
    _resultSubscription = null;
    _task = null;
    _clock = null;
    _lastObservationAt = null;
    _hasObservation = false;
    _recentResults.clear();
    _submittedFrames.clear();
    _resetAnalyzer();

    if (controller?.value.isStreamingImages ?? false) {
      try {
        await controller!.stopImageStream();
      } catch (_) {
        // The camera can already be closing during lifecycle changes.
      }
    }
    if (task != null) {
      await task.dispose();
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

abstract interface class _BodyLandmarkerTask {
  Stream<_BodyTaskResult> get results;
  int get droppedFrames;

  void detectAsync(
    VisionImage image, {
    required int timestampMilliseconds,
    required int rotationDegrees,
  });

  Future<void> dispose();
}

class _FaceBodyLandmarkerTask implements _BodyLandmarkerTask {
  _FaceBodyLandmarkerTask._(this._landmarker);

  final FaceLandmarker _landmarker;

  static Future<_FaceBodyLandmarkerTask> create() async {
    return _FaceBodyLandmarkerTask._(
      await FaceLandmarker.create(
        FaceLandmarkerOptions(
          model: VisionModels.faceLandmarker,
          runningMode: RunningMode.liveStream,
          numFaces: 1,
        ),
      ),
    );
  }

  @override
  Stream<_BodyTaskResult> get results => _landmarker.results.map((result) {
    _RawHeadGeometry? head;
    if (result.faceLandmarks.isNotEmpty &&
        result.faceLandmarks.first.length > 263) {
      final landmarks = result.faceLandmarks.first;
      head = _RawHeadGeometry(
        firstEyeCorner: _point(landmarks[33]),
        secondEyeCorner: _point(landmarks[263]),
      );
    }
    return _BodyTaskResult(
      timestampMilliseconds: result.timestampMilliseconds ?? 0,
      imageWidth: result.imageWidth,
      imageHeight: result.imageHeight,
      head: head,
    );
  });

  @override
  int get droppedFrames => _landmarker.droppedFrames;

  @override
  void detectAsync(
    VisionImage image, {
    required int timestampMilliseconds,
    required int rotationDegrees,
  }) {
    _landmarker.detectAsync(
      image,
      timestampMilliseconds: timestampMilliseconds,
      rotationDegrees: rotationDegrees,
    );
  }

  @override
  Future<void> dispose() => _landmarker.dispose();
}

class _HolisticBodyLandmarkerTask implements _BodyLandmarkerTask {
  _HolisticBodyLandmarkerTask._(this._landmarker);

  final HolisticLandmarker _landmarker;

  static Future<_HolisticBodyLandmarkerTask> create() async {
    return _HolisticBodyLandmarkerTask._(
      await HolisticLandmarker.create(
        HolisticLandmarkerOptions(
          model: VisionModels.holisticLandmarker,
          runningMode: RunningMode.liveStream,
        ),
      ),
    );
  }

  @override
  Stream<_BodyTaskResult> get results => _landmarker.results.map((result) {
    return _BodyTaskResult(
      timestampMilliseconds: result.timestampMilliseconds ?? 0,
      imageWidth: result.imageWidth,
      imageHeight: result.imageHeight,
      wrist: _selectWrist(result),
    );
  });

  @override
  int get droppedFrames => _landmarker.droppedFrames;

  @override
  void detectAsync(
    VisionImage image, {
    required int timestampMilliseconds,
    required int rotationDegrees,
  }) {
    _landmarker.detectAsync(
      image,
      timestampMilliseconds: timestampMilliseconds,
      rotationDegrees: rotationDegrees,
    );
  }

  @override
  Future<void> dispose() => _landmarker.dispose();
}

_RawWristGeometry? _selectWrist(HolisticLandmarkerResult result) {
  if (result.poseLandmarks.length != 33) {
    return null;
  }
  final candidates = <_WristCandidate>[];
  if (result.leftHandLandmarks.length == 21) {
    candidates.add(
      _WristCandidate(
        elbow: result.poseLandmarks[13],
        poseWrist: result.poseLandmarks[15],
        handWrist: result.leftHandLandmarks[0],
        middleFingerBase: result.leftHandLandmarks[9],
      ),
    );
  }
  if (result.rightHandLandmarks.length == 21) {
    candidates.add(
      _WristCandidate(
        elbow: result.poseLandmarks[14],
        poseWrist: result.poseLandmarks[16],
        handWrist: result.rightHandLandmarks[0],
        middleFingerBase: result.rightHandLandmarks[9],
      ),
    );
  }
  if (candidates.isEmpty) {
    return null;
  }
  candidates.sort((a, b) => b.quality.compareTo(a.quality));
  final selected = candidates.first;
  return _RawWristGeometry(
    elbow: _point(selected.elbow),
    poseWrist: _point(selected.poseWrist),
    handWrist: _point(selected.handWrist),
    middleFingerBase: _point(selected.middleFingerBase),
  );
}

class _WristCandidate {
  const _WristCandidate({
    required this.elbow,
    required this.poseWrist,
    required this.handWrist,
    required this.middleFingerBase,
  });

  final NormalizedLandmark elbow;
  final NormalizedLandmark poseWrist;
  final NormalizedLandmark handWrist;
  final NormalizedLandmark middleFingerBase;

  double get quality {
    final scores = [
      elbow.visibility,
      elbow.presence,
      poseWrist.visibility,
      poseWrist.presence,
    ].whereType<double>().where((score) => score.isFinite).toList();
    if (scores.isEmpty) {
      return 1;
    }
    return scores.reduce(math.min);
  }
}

MovementPoint _point(NormalizedLandmark landmark) => MovementPoint(
  x: landmark.x,
  y: landmark.y,
  visibility: landmark.visibility,
  presence: landmark.presence,
);

class _BodyTaskResult {
  const _BodyTaskResult({
    required this.timestampMilliseconds,
    required this.imageWidth,
    required this.imageHeight,
    this.head,
    this.wrist,
  });

  final int timestampMilliseconds;
  final int imageWidth;
  final int imageHeight;
  final _RawHeadGeometry? head;
  final _RawWristGeometry? wrist;
}

class _RawHeadGeometry {
  const _RawHeadGeometry({
    required this.firstEyeCorner,
    required this.secondEyeCorner,
  });

  final MovementPoint firstEyeCorner;
  final MovementPoint secondEyeCorner;
}

class _RawWristGeometry {
  const _RawWristGeometry({
    required this.elbow,
    required this.poseWrist,
    required this.handWrist,
    required this.middleFingerBase,
  });

  final MovementPoint elbow;
  final MovementPoint poseWrist;
  final MovementPoint handWrist;
  final MovementPoint middleFingerBase;
}

class _SubmittedBodyFrame {
  const _SubmittedBodyFrame({
    required this.submittedAt,
    required this.rotationDegrees,
    required this.isMirrored,
  });

  const _SubmittedBodyFrame.fallback()
    : submittedAt = Duration.zero,
      rotationDegrees = 0,
      isMirrored = false;

  final Duration submittedAt;
  final int rotationDegrees;
  final bool isMirrored;
}
