import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Shared branding for in-app QR widgets and downloaded PNGs.
///
/// Sparse Starbucks-style mark: small circular data dots (not a solid mosaic),
/// circular finder eyes, and a circular white center plate with the Barqody
/// logo. High ECC recovers the covered center.
abstract final class BrandedQr {
  static const logoAsset = 'assets/images/png/app_icon.png';
  static const errorCorrectionLevel = QrErrorCorrectLevel.H;

  /// Circular white plate diameter relative to the QR side.
  static const plateFraction = 0.28;

  /// Padding between plate edge and logo (relative to plate side).
  /// Near-zero so the logo fills the white circle.
  static const logoInsetFraction = 0.02;

  /// Data-dot diameter as a fraction of each module cell.
  /// Lower = visibly "kam dots" / more white space between modules.
  static const moduleFill = 0.55;

  /// Kept for call-site compatibility; sparse painter always spaces modules.
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
  // Bump when decode/paint rules change so hot-reload drops a stretched cache.
  static const _logoCacheEpoch = 2;
  static int _logoLoadedEpoch = 0;

  static Future<ui.Image> loadLogoImage() {
    if (_logoImage != null && _logoLoadedEpoch == _logoCacheEpoch) {
      return Future.value(_logoImage!);
    }
    _logoImage?.dispose();
    _logoImage = null;
    _logoFuture = null;
    _logoLoadedEpoch = _logoCacheEpoch;
    return _logoFuture ??= _decodeLogo();
  }

  static Future<ui.Image> _decodeLogo() async {
    final data = await rootBundle.load(logoAsset);
    // Decode at native aspect — forcing both targetWidth/Height stretches.
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: 512,
    );
    final frame = await codec.getNextFrame();
    _logoImage = frame.image;
    return frame.image;
  }

  static Size plateSizeFor(double qrSide) =>
      Size.square(qrSide * plateFraction);

  /// Full-circle plate (Starbucks-style logo buffer).
  static double plateRadiusFor(double plateSide) => plateSide / 2;

  /// BoxFit.cover-style destination for [src] inside a square [box].
  static Rect _coverRect(Size src, Rect box) {
    final scale = (box.width / src.width > box.height / src.height)
        ? box.width / src.width
        : box.height / src.height;
    final w = src.width * scale;
    final h = src.height * scale;
    return Rect.fromCenter(center: box.center, width: w, height: h);
  }

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
    final clip = Rect.fromCenter(
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
    final dst = _coverRect(Size(logo.width.toDouble(), logo.height.toDouble()), clip);
    canvas.save();
    canvas.clipPath(Path()..addOval(clip));
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
    final painter = BrandedQrPainter(
      data: data,
      foreground: foreground,
      background: background,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final qrSize = Size(size.toDouble(), size.toDouble());
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

/// Sparse circular QR painter used by on-screen widgets and PNG export.
class BrandedQrPainter extends CustomPainter {
  BrandedQrPainter({
    required this.data,
    this.foreground = Colors.black,
    this.background = Colors.transparent,
    this.moduleFill = BrandedQr.moduleFill,
    this.errorCorrectionLevel = BrandedQr.errorCorrectionLevel,
  }) : _qrImage = _buildImage(data, errorCorrectionLevel);

  final String data;
  final Color foreground;
  final Color background;
  final double moduleFill;
  final int errorCorrectionLevel;
  final QrImage? _qrImage;

  static const int _finderLimit = 7;

  static QrImage? _buildImage(String data, int ecc) {
    try {
      final code = QrCode.fromData(data: data, errorCorrectLevel: ecc);
      return QrImage(code);
    } catch (_) {
      return null;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    if (side <= 0) return;

    if (background.a > 0) {
      canvas.drawRect(
        Offset.zero & Size(side, side),
        Paint()..color = background,
      );
    }

    final image = _qrImage;
    if (image == null) return;

    final count = image.moduleCount;
    final cell = side / count;
    final dotRadius = (cell * moduleFill) / 2;
    final paint = Paint()
      ..color = foreground
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    _paintFinder(canvas, cell, 0, 0, paint);
    _paintFinder(canvas, cell, count - _finderLimit, 0, paint);
    _paintFinder(canvas, cell, 0, count - _finderLimit, paint);

    for (var row = 0; row < count; row++) {
      for (var col = 0; col < count; col++) {
        if (_inFinder(row, col, count)) continue;
        if (!image.isDark(row, col)) continue;
        final cx = (col + 0.5) * cell;
        final cy = (row + 0.5) * cell;
        canvas.drawCircle(Offset(cx, cy), dotRadius, paint);
      }
    }
  }

  bool _inFinder(int row, int col, int count) {
    final inTop = row < _finderLimit;
    final inBottom = row >= count - _finderLimit;
    final inLeft = col < _finderLimit;
    final inRight = col >= count - _finderLimit;
    return (inTop && inLeft) || (inTop && inRight) || (inBottom && inLeft);
  }

  void _paintFinder(
    Canvas canvas,
    double cell,
    int originCol,
    int originRow,
    Paint fill,
  ) {
    final cx = (originCol + _finderLimit / 2) * cell;
    final cy = (originRow + _finderLimit / 2) * cell;
    final center = Offset(cx, cy);

    // Outer ring (~7 modules), kept solid enough for scanners.
    final outerR = (_finderLimit / 2) * cell * 0.92;
    final ring = Paint()
      ..color = fill.color
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.95;
    canvas.drawCircle(center, outerR - ring.strokeWidth / 2, ring);

    // Center pupil (~3 modules), slightly sparse.
    canvas.drawCircle(center, cell * 1.35, fill);
  }

  @override
  bool shouldRepaint(covariant BrandedQrPainter oldDelegate) {
    return data != oldDelegate.data ||
        foreground != oldDelegate.foreground ||
        background != oldDelegate.background ||
        moduleFill != oldDelegate.moduleFill ||
        errorCorrectionLevel != oldDelegate.errorCorrectionLevel;
  }
}
