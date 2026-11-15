import 'dart:typed_data';

enum CameraFrameFormat { bgra8888, yuv420 }

class CameraFramePlane {
  const CameraFramePlane({
    required this.bytes,
    required this.bytesPerRow,
    required this.bytesPerPixel,
  });

  final Uint8List bytes;
  final int bytesPerRow;
  final int bytesPerPixel;
}

class CameraFrameData {
  const CameraFrameData({
    required this.width,
    required this.height,
    required this.format,
    required this.planes,
  });

  final int width;
  final int height;
  final CameraFrameFormat format;
  final List<CameraFramePlane> planes;
}

class ConvertedCameraFrame {
  const ConvertedCameraFrame({
    required this.pixels,
    required this.width,
    required this.height,
    required this.isBgra,
    required this.bytesPerRow,
  });

  final Uint8List pixels;
  final int width;
  final int height;
  final bool isBgra;
  final int bytesPerRow;
}

ConvertedCameraFrame convertCameraFrame(CameraFrameData frame) {
  return switch (frame.format) {
    CameraFrameFormat.bgra8888 => _copyBgraFrame(frame),
    CameraFrameFormat.yuv420 => _convertYuv420Frame(frame),
  };
}

ConvertedCameraFrame _copyBgraFrame(CameraFrameData frame) {
  if (frame.planes.length != 1) {
    throw const FormatException('A BGRA camera frame must have one plane.');
  }
  final plane = frame.planes.single;
  final expectedLength = plane.bytesPerRow * frame.height;
  if (plane.bytes.length < expectedLength) {
    throw const FormatException('The BGRA camera plane is incomplete.');
  }

  return ConvertedCameraFrame(
    pixels: Uint8List.fromList(plane.bytes.sublist(0, expectedLength)),
    width: frame.width,
    height: frame.height,
    isBgra: true,
    bytesPerRow: plane.bytesPerRow,
  );
}

ConvertedCameraFrame _convertYuv420Frame(CameraFrameData frame) {
  if (frame.planes.length != 3) {
    throw const FormatException(
      'A YUV420 camera frame must have three planes.',
    );
  }
  final yPlane = frame.planes[0];
  final uPlane = frame.planes[1];
  final vPlane = frame.planes[2];
  final rgba = Uint8List(frame.width * frame.height * 4);

  var outputIndex = 0;
  for (var y = 0; y < frame.height; y++) {
    final yRow = y * yPlane.bytesPerRow;
    final uvRow = (y >> 1) * uPlane.bytesPerRow;
    final vRow = (y >> 1) * vPlane.bytesPerRow;
    for (var x = 0; x < frame.width; x++) {
      final yIndex = yRow + x * yPlane.bytesPerPixel;
      final uvColumn = x >> 1;
      final uIndex = uvRow + uvColumn * uPlane.bytesPerPixel;
      final vIndex = vRow + uvColumn * vPlane.bytesPerPixel;
      if (yIndex >= yPlane.bytes.length ||
          uIndex >= uPlane.bytes.length ||
          vIndex >= vPlane.bytes.length) {
        throw const FormatException('The YUV420 camera planes are incomplete.');
      }

      final yValue = yPlane.bytes[yIndex];
      final uValue = uPlane.bytes[uIndex] - 128;
      final vValue = vPlane.bytes[vIndex] - 128;
      final adjustedY = yValue < 16 ? 0 : yValue - 16;
      final scaledY = 1192 * adjustedY;

      rgba[outputIndex++] = _clampByte((scaledY + 1634 * vValue) >> 10);
      rgba[outputIndex++] = _clampByte(
        (scaledY - 833 * vValue - 400 * uValue) >> 10,
      );
      rgba[outputIndex++] = _clampByte((scaledY + 2066 * uValue) >> 10);
      rgba[outputIndex++] = 255;
    }
  }

  return ConvertedCameraFrame(
    pixels: rgba,
    width: frame.width,
    height: frame.height,
    isBgra: false,
    bytesPerRow: frame.width * 4,
  );
}

int _clampByte(int value) => value.clamp(0, 255);
