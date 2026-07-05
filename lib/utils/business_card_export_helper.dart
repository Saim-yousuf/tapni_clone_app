import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class BusinessCardExportHelper {
  static Future<Uint8List?> capturePngBytes(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
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

  static Future<bool> savePng(GlobalKey key, {String? fileName}) async {
    final bytes = await capturePngBytes(key);
    if (bytes == null) return false;

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
}
