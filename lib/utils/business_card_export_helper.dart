import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tapni_app/utils/print_export_sizes.dart';

class BusinessCardExportHelper {
  static Future<Uint8List?> capturePngBytes(
    GlobalKey key, {
    double pixelRatio = 3.0,
  }) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      log('capturePngBytes: $e');
      return null;
    }
  }

  static Future<bool> _ensureGalleryAccess() async {
    var hasAccess = await Gal.hasAccess();
    if (!hasAccess) {
      hasAccess = await Gal.requestAccess();
    }
    return hasAccess;
  }

  static Future<bool> savePngBytes(
    Uint8List bytes, {
    String? fileName,
  }) async {
    if (!await _ensureGalleryAccess()) return false;

    final tempDir = await getTemporaryDirectory();
    final safeName = (fileName ?? 'business_card')
        .replaceAll(RegExp(r'[^\w\-]+'), '_')
        .toLowerCase();
    final file = File(
      '${tempDir.path}/${safeName}_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes);
    await Gal.putImage(file.path);
    return true;
  }

  static Future<bool> savePng(GlobalKey key, {String? fileName}) async {
    final bytes = await capturePngBytes(key);
    if (bytes == null) return false;
    return savePngBytes(bytes, fileName: fileName);
  }

  /// Renders a QR PNG at [size] px and saves it to the gallery (no size picker).
  static Future<bool> saveQrPng(
    String data, {
    String? fileName,
    int size = 1024,
    Color foreground = Colors.black,
    Color background = Colors.white,
  }) async {
    try {
      final painter = QrPainter(
        data: data,
        version: QrVersions.auto,
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
      final byteData = await painter.toImageData(size.toDouble());
      if (byteData == null) return false;

      var bytes = byteData.buffer.asUint8List();
      if (background != Colors.transparent) {
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          final canvas = img.Image(width: size, height: size);
          img.fill(
            canvas,
            color: img.ColorRgba8(
              (background.r * 255.0).round().clamp(0, 255),
              (background.g * 255.0).round().clamp(0, 255),
              (background.b * 255.0).round().clamp(0, 255),
              (background.a * 255.0).round().clamp(0, 255),
            ),
          );
          img.compositeImage(canvas, decoded);
          bytes = Uint8List.fromList(img.encodePng(canvas));
        }
      }
      return savePngBytes(bytes, fileName: fileName ?? 'qr');
    } catch (e) {
      log('saveQrPng: $e');
      return false;
    }
  }

  static Future<bool> saveJpg(GlobalKey key, {String? fileName}) async {
    final bytes = await capturePngBytes(key);
    if (bytes == null) return false;

    final decoded = img.decodeImage(bytes);
    if (decoded == null) return false;

    final jpgBytes = img.encodeJpg(decoded, quality: 92);
    if (!await _ensureGalleryAccess()) return false;

    final tempDir = await getTemporaryDirectory();
    final safeName = (fileName ?? 'business_card')
        .replaceAll(RegExp(r'[^\w\-]+'), '_')
        .toLowerCase();
    final file = File(
      '${tempDir.path}/${safeName}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(jpgBytes);
    await Gal.putImage(file.path);
    return true;
  }

  /// Resize / letterbox captured PNG bytes to [size] and save to gallery.
  static Future<bool> saveSizedPng(
    Uint8List sourcePng, {
    required PrintExportSize size,
    String? fileName,
    /// Source content aspect (width/height). Used for A4 letterbox & square fit.
    double? contentAspectRatio,
  }) async {
    try {
      final out = fitToPrintSize(
        sourcePng,
        size: size,
        contentAspectRatio: contentAspectRatio,
      );
      if (out == null) return false;
      return savePngBytes(
        out,
        fileName: '${fileName ?? 'export'}_${size.preset.name}',
      );
    } catch (e) {
      log('saveSizedPng: $e');
      return false;
    }
  }

  /// Capture widget then resize to [size].
  static Future<bool> captureAndSaveSized(
    GlobalKey key, {
    required PrintExportSize size,
    String? fileName,
    double? contentAspectRatio,
    double pixelRatio = 4.0,
  }) async {
    final bytes = await capturePngBytes(key, pixelRatio: pixelRatio);
    if (bytes == null) return false;
    return saveSizedPng(
      bytes,
      size: size,
      fileName: fileName,
      contentAspectRatio: contentAspectRatio,
    );
  }

  /// Transform PNG into target print size.
  /// - A4: place card centered on white page with ~8% margin
  /// - Other: cover-fit into target (centered crop) or contain for QR
  static Uint8List? fitToPrintSize(
    Uint8List sourcePng, {
    required PrintExportSize size,
    double? contentAspectRatio,
  }) {
    final decoded = img.decodeImage(sourcePng);
    if (decoded == null) return null;

    final targetW = size.width;
    final targetH = size.height;

    if (size.letterboxOnA4) {
      return _letterboxOnCanvas(
        decoded,
        canvasW: targetW,
        canvasH: targetH,
        marginFraction: 0.08,
        background: img.ColorRgba8(255, 255, 255, 255),
        contentAspectRatio: contentAspectRatio,
      );
    }

    // QR and square: contain with white padding
    if (size.kind == PrintExportKind.qrOnly ||
        size.preset == PrintExportPreset.square) {
      return _letterboxOnCanvas(
        decoded,
        canvasW: targetW,
        canvasH: targetH,
        marginFraction: size.kind == PrintExportKind.qrOnly ? 0.06 : 0.04,
        background: img.ColorRgba8(255, 255, 255, 255),
        contentAspectRatio: contentAspectRatio,
      );
    }

          // Standard / Stand: scale to cover target (portrait), center crop if needed
    if (decoded.width / decoded.height >
        targetW / targetH) {
      // source wider — fit height, crop sides
      final newH = targetH;
      final newW = (decoded.width * targetH / decoded.height).round();
      final resized = img.copyResize(
        decoded,
        width: newW,
        height: newH,
        interpolation: img.Interpolation.cubic,
      );
      final ox = ((newW - targetW) / 2).round().clamp(0, newW);
      final cropped = img.copyCrop(
        resized,
        x: ox,
        y: 0,
        width: targetW,
        height: targetH,
      );
      return Uint8List.fromList(img.encodePng(cropped));
    }

    final newW = targetW;
    final newH = (decoded.height * targetW / decoded.width).round();
    final resized = img.copyResize(
      decoded,
      width: newW,
      height: newH,
      interpolation: img.Interpolation.cubic,
    );
    final oy = ((newH - targetH) / 2).round().clamp(0, newH);
    final cropped = img.copyCrop(
      resized,
      x: 0,
      y: oy,
      width: targetW,
      height: targetH,
    );
    return Uint8List.fromList(img.encodePng(cropped));
  }

  static Uint8List? _letterboxOnCanvas(
    img.Image source, {
    required int canvasW,
    required int canvasH,
    required double marginFraction,
    required img.ColorRgba8 background,
    double? contentAspectRatio,
  }) {
    final canvas = img.Image(width: canvasW, height: canvasH);
    img.fill(canvas, color: background);

    final marginX = (canvasW * marginFraction).round();
    final marginY = (canvasH * marginFraction).round();
    final maxW = canvasW - marginX * 2;
    final maxH = canvasH - marginY * 2;
    if (maxW <= 0 || maxH <= 0) return null;

    final srcAspect = contentAspectRatio ?? (source.width / source.height);
    late int drawW;
    late int drawH;
    if (srcAspect >= maxW / maxH) {
      drawW = maxW;
      drawH = (maxW / srcAspect).round().clamp(1, maxH);
    } else {
      drawH = maxH;
      drawW = (maxH * srcAspect).round().clamp(1, maxW);
    }

    final resized = img.copyResize(
      source,
      width: drawW,
      height: drawH,
      interpolation: img.Interpolation.cubic,
    );

    final ox = ((canvasW - drawW) / 2).round();
    final oy = ((canvasH - drawH) / 2).round();
    img.compositeImage(canvas, resized, dstX: ox, dstY: oy);

    return Uint8List.fromList(img.encodePng(canvas));
  }
}
