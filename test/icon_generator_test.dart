import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Generate properly scaled, un-stretched launcher icons with trimmed padding', () async {
    final file = File('assets/images/app_icon.png');
    expect(file.existsSync(), isTrue);

    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final srcImage = frame.image;

    final srcWidth = srcImage.width;
    final srcHeight = srcImage.height;

    // Find tight bounding box of non-transparent pixels to remove excess transparent padding
    final byteData = await srcImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    final buffer = byteData!.buffer.asUint8List();

    int minX = srcWidth, minY = srcHeight, maxX = 0, maxY = 0;
    for (int y = 0; y < srcHeight; y++) {
      for (int x = 0; x < srcWidth; x++) {
        final offset = (y * srcWidth + x) * 4;
        final alpha = buffer[offset + 3];
        if (alpha > 10) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (minX > maxX || minY > maxY) {
      minX = 0;
      minY = 0;
      maxX = srcWidth;
      maxY = srcHeight;
    }

    final cropX = minX.toDouble();
    final cropY = minY.toDouble();
    final cropWidth = (maxX - minX + 1).toDouble();
    final cropHeight = (maxY - minY + 1).toDouble();
    final cropAspect = cropWidth / cropHeight;

    debugPrint('Source Logo: ${srcWidth}x$srcHeight | Cropped Bounding Box: $cropWidth x $cropHeight (aspect: $cropAspect)');

    const canvasSize = 1024.0;

    // 1. Generate adaptive foreground PNG (transparent background)
    // Safe zone diameter for adaptive icon is ~66% (676px on 1024px canvas).
    const fgTargetWidth = canvasSize * 0.68; // 696 px
    final fgTargetHeight = fgTargetWidth / cropAspect;

    final fgLeft = (canvasSize - fgTargetWidth) / 2;
    final fgTop = (canvasSize - fgTargetHeight) / 2;

    final fgRecorder = ui.PictureRecorder();
    final fgCanvas = Canvas(fgRecorder);

    fgCanvas.drawRect(
      const Rect.fromLTWH(0, 0, canvasSize, canvasSize),
      Paint()..color = const Color(0x00000000),
    );

    fgCanvas.drawImageRect(
      srcImage,
      Rect.fromLTWH(cropX, cropY, cropWidth, cropHeight),
      Rect.fromLTWH(fgLeft, fgTop, fgTargetWidth, fgTargetHeight),
      Paint()..filterQuality = FilterQuality.high,
    );

    final fgPicture = fgRecorder.endRecording();
    final fgImage = await fgPicture.toImage(canvasSize.toInt(), canvasSize.toInt());
    final fgByteData = await fgImage.toByteData(format: ui.ImageByteFormat.png);
    await File('assets/images/app_icon_padded.png').writeAsBytes(fgByteData!.buffer.asUint8List());
    debugPrint('Generated assets/images/app_icon_padded.png (Adaptive Foreground)');

    // 2. Generate standard/iOS app icon PNG (white background)
    const bgTargetWidth = canvasSize * 0.88; // 901 px (fills icon nicely without clipping)
    final bgTargetHeight = bgTargetWidth / cropAspect;

    final bgLeft = (canvasSize - bgTargetWidth) / 2;
    final bgTop = (canvasSize - bgTargetHeight) / 2;

    final bgRecorder = ui.PictureRecorder();
    final bgCanvas = Canvas(bgRecorder);

    bgCanvas.drawRect(
      const Rect.fromLTWH(0, 0, canvasSize, canvasSize),
      Paint()..color = const Color(0xFFFFFFFF),
    );

    bgCanvas.drawImageRect(
      srcImage,
      Rect.fromLTWH(cropX, cropY, cropWidth, cropHeight),
      Rect.fromLTWH(bgLeft, bgTop, bgTargetWidth, bgTargetHeight),
      Paint()..filterQuality = FilterQuality.high,
    );

    final bgPicture = bgRecorder.endRecording();
    final bgImage = await bgPicture.toImage(canvasSize.toInt(), canvasSize.toInt());
    final bgByteData = await bgImage.toByteData(format: ui.ImageByteFormat.png);
    await File('assets/images/app_icon_squared.png').writeAsBytes(bgByteData!.buffer.asUint8List());
    debugPrint('Generated assets/images/app_icon_squared.png (Standard/iOS Icon)');
  });
}
