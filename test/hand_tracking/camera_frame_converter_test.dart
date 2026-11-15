import 'dart:typed_data';

import 'package:adaptive_motion_arcade/hand_tracking/camera_frame_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('copies BGRA rows including platform row padding', () {
    final bytes = Uint8List.fromList([
      1,
      2,
      3,
      4,
      9,
      9,
      9,
      9,
      5,
      6,
      7,
      8,
      9,
      9,
      9,
      9,
    ]);

    final converted = convertCameraFrame(
      CameraFrameData(
        width: 1,
        height: 2,
        format: CameraFrameFormat.bgra8888,
        planes: [
          CameraFramePlane(bytes: bytes, bytesPerRow: 8, bytesPerPixel: 4),
        ],
      ),
    );

    expect(converted.isBgra, isTrue);
    expect(converted.bytesPerRow, 8);
    expect(converted.pixels, bytes);
    expect(identical(converted.pixels, bytes), isFalse);
  });

  test('converts neutral YUV420 samples to opaque RGBA', () {
    final converted = convertCameraFrame(
      CameraFrameData(
        width: 2,
        height: 2,
        format: CameraFrameFormat.yuv420,
        planes: [
          CameraFramePlane(
            bytes: Uint8List.fromList([16, 235, 81, 145]),
            bytesPerRow: 2,
            bytesPerPixel: 1,
          ),
          CameraFramePlane(
            bytes: Uint8List.fromList([128]),
            bytesPerRow: 1,
            bytesPerPixel: 1,
          ),
          CameraFramePlane(
            bytes: Uint8List.fromList([128]),
            bytesPerRow: 1,
            bytesPerPixel: 1,
          ),
        ],
      ),
    );

    expect(converted.isBgra, isFalse);
    expect(converted.bytesPerRow, 8);
    expect(converted.pixels.length, 16);
    expect(converted.pixels.sublist(0, 4), [0, 0, 0, 255]);
    expect(converted.pixels[4], inInclusiveRange(254, 255));
    expect(converted.pixels[5], inInclusiveRange(254, 255));
    expect(converted.pixels[6], inInclusiveRange(254, 255));
    expect(converted.pixels[7], 255);
    expect([converted.pixels[11], converted.pixels[15]], everyElement(255));
  });

  test('rejects incomplete YUV planes', () {
    expect(
      () => convertCameraFrame(
        CameraFrameData(
          width: 2,
          height: 2,
          format: CameraFrameFormat.yuv420,
          planes: [
            CameraFramePlane(
              bytes: Uint8List(1),
              bytesPerRow: 2,
              bytesPerPixel: 1,
            ),
            CameraFramePlane(
              bytes: Uint8List(1),
              bytesPerRow: 1,
              bytesPerPixel: 1,
            ),
            CameraFramePlane(
              bytes: Uint8List(1),
              bytesPerRow: 1,
              bytesPerPixel: 1,
            ),
          ],
        ),
      ),
      throwsFormatException,
    );
  });
}
