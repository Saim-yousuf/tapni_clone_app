import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Shared branding for in-app QR widgets and downloaded PNGs.
abstract final class BrandedQr {
  static const logoAsset = 'assets/images/png/app_icon.png';
  static const errorCorrectionLevel = QrErrorCorrectLevel.H;

  /// White plate size relative to the QR side.
  static const plateFraction = 0.30;
  static const plateCornerFraction = 0.2;
  static const logoInsetFraction = 0.08;
  static const logoCornerFraction = 0.16;

  static ui.Image? _logoImage;
  static Future<ui.Image>? _logoFuture;

  static Future<ui.Image> loadLogoImage() {
    final existing = _logoImage;
    if (existing != null) return Future.value(existing);
    return _logoFuture ??= _decodeLogo();
  }

  static Future<ui.Image> _decodeLogo() async {
    final data = await rootBundle.load(logoAsset);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: 256,
      targetHeight: 256,
    );
    final frame = await codec.getNextFrame();
    _logoImage = frame.image;
    return frame.image;
  }

  static Size plateSizeFor(double qrSide) =>
      Size.square(qrSide * plateFraction);

  static double plateRadiusFor(double plateSide) =>
      plateSide * plateCornerFraction;

  static void paintLogoBadge(
    Canvas canvas,
    double qrSide, {
    required ui.Image logo,
  }) {
    final plateSide = qrSide * plateFraction;
    final center = Offset(qrSide / 2, qrSide / 2);
    final plateRect = Rect.fromCenter(
      center: center,
      width: plateSide,
      height: plateSide,
    );
    final plate = RRect.fromRectAndRadius(
      plateRect,
      Radius.circular(plateRadiusFor(plateSide)),
    );
    canvas.drawRRect(plate, Paint()..color = const Color(0xFFFFFFFF));

    final inset = plateSide * logoInsetFraction;
    final logoRect = plateRect.deflate(inset);
    final logoRRect = RRect.fromRectAndRadius(
      logoRect,
      Radius.circular(logoRect.width * logoCornerFraction),
    );
    canvas.save();
    canvas.clipRRect(logoRRect);
    canvas.drawImageRect(
      logo,
      Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble()),
      logoRect,
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();
  }

  /// High-res QR PNG with the app logo baked into the pixels.
  static Future<Uint8List?> encodePng({
    required String data,
    int size = 1024,
    Color foreground = Colors.black,
    Color background = Colors.white,
  }) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: errorCorrectionLevel,
      gapless: true,
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: foreground,
      ),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: foreground,
      ),
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final qrSize = Size(size.toDouble(), size.toDouble());
    canvas.drawRect(Offset.zero & qrSize, Paint()..color = background);
    painter.paint(canvas, qrSize);

    try {
      final logo = await loadLogoImage();
      paintLogoBadge(canvas, size.toDouble(), logo: logo);
    } catch (_) {
      // Save a still-scannable QR if the asset fails to decode.
    }

    final image = await recorder.endRecording().toImage(size, size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes?.buffer.asUint8List();
  }
}
