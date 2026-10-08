import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Shared branding for in-app QR widgets and downloaded PNGs.
///
/// Starbucks-style mark: circular data dots, circular finder eyes, and a
/// circular white center plate with the Barqody logo. High ECC recovers the
/// covered center (standard logo-in-QR approach).
abstract final class BrandedQr {
  static const logoAsset = 'assets/images/png/app_icon.png';
  static const errorCorrectionLevel = QrErrorCorrectLevel.H;

  /// Circular white plate diameter relative to the QR side.
  static const plateFraction = 0.28;

  /// Padding between plate edge and logo (relative to plate side).
  /// Near-zero so the logo fills the white circle.
  static const logoInsetFraction = 0.02;

  /// Spaced circular modules (not a solid square mosaic).
  static const gapless = false;

  static QrEyeStyle eyeStyleFor(Color color) => QrEyeStyle(
        eyeShape: QrEyeShape.circle,
        color: color,
      );

  static QrDataModuleStyle moduleStyleFor(Color color) => QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.circle,
        color: color,
      );

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

  /// Full-circle plate (Starbucks-style logo buffer).
  static double plateRadiusFor(double plateSide) => plateSide / 2;

  /// Circular white plate + Barqody logo in the QR center.
  static void paintLogoBadge(
    Canvas canvas,
    double qrSide, {
    ui.Image? logo,
  }) {
    final plateSide = qrSide * plateFraction;
    final center = Offset(qrSide / 2, qrSide / 2);
    canvas.drawCircle(
      center,
      plateSide / 2,
      Paint()..color = const Color(0xFFFFFFFF),
    );

    if (logo == null) return;

    final inset = plateSide * logoInsetFraction;
    final logoSide = plateSide - inset * 2;
    final dst = Rect.fromCenter(
      center: center,
      width: logoSide,
      height: logoSide,
    );
    final src = Rect.fromLTWH(
      0,
      0,
      logo.width.toDouble(),
      logo.height.toDouble(),
    );
    canvas.save();
    canvas.clipPath(Path()..addOval(dst));
    canvas.drawImageRect(
      logo,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();
  }

  /// High-res QR PNG with the Barqody logo **baked into the pixels** (for
  /// download / share / print). Always use this (or
  /// [BusinessCardExportHelper.saveQrPng]) for saved files — do not rely on
  /// screen-capture alone for QR-only exports.
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
      gapless: gapless,
      eyeStyle: eyeStyleFor(foreground),
      dataModuleStyle: moduleStyleFor(foreground),
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
      // Save a still-scannable QR if badge paint fails.
    }

    final image = await recorder.endRecording().toImage(size, size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes?.buffer.asUint8List();
  }
}
