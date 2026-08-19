import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tapni_app/utils/document_file.dart';

class DocumentKindIcon extends StatelessWidget {
  final String fileUrl;
  final String? fileName;
  final String? customLogoUrl;
  final String? localImagePath;
  final double size;
  final double radius;

  const DocumentKindIcon({
    super.key,
    required this.fileUrl,
    this.fileName,
    this.customLogoUrl,
    this.localImagePath,
    this.size = 44,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final local = localImagePath?.trim() ?? '';
    if (local.isNotEmpty) {
      return _clip(
        Image.file(File(local), width: size, height: size, fit: BoxFit.cover),
      );
    }

    final custom = customLogoUrl?.trim() ?? '';
    if (custom.startsWith('http://') || custom.startsWith('https://')) {
      return _clip(
        Image.network(
          custom,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _kindTile(),
        ),
      );
    }

    return _kindTile();
  }

  Widget _clip(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: size, height: size, child: child),
    );
  }

  Widget _kindTile() {
    final kind = DocumentFileHelper.kindFrom(fileUrl, fileName);
    late Color bg;
    late Color fg;
    switch (kind) {
      case DocumentKind.pdf:
        bg = const Color(0xFFE74C3C);
        fg = Colors.white;
        break;
      case DocumentKind.word:
        bg = const Color(0xFF2B579A);
        fg = Colors.white;
        break;
      case DocumentKind.image:
        bg = const Color(0xFF1B7A4E);
        fg = Colors.white;
        break;
      case DocumentKind.file:
        bg = const Color(0xFF1B4F72);
        fg = Colors.white;
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Text(
        DocumentFileHelper.labelFor(kind),
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.22,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
