import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tapni_app/utils/document_file.dart';

class DocumentKindIcon extends StatefulWidget {
  final String fileUrl;
  final String? fileName;
  final String? fileExt;
  final String? customLogoUrl;
  final String? localImagePath;
  final double size;
  final double radius;

  const DocumentKindIcon({
    super.key,
    required this.fileUrl,
    this.fileName,
    this.fileExt,
    this.customLogoUrl,
    this.localImagePath,
    this.size = 44,
    this.radius = 10,
  });

  @override
  State<DocumentKindIcon> createState() => _DocumentKindIconState();
}

class _DocumentKindIconState extends State<DocumentKindIcon> {
  DocumentKind? _resolvedKind;

  @override
  void initState() {
    super.initState();
    _resolveKind();
  }

  @override
  void didUpdateWidget(covariant DocumentKindIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileUrl != widget.fileUrl ||
        oldWidget.fileName != widget.fileName ||
        oldWidget.fileExt != widget.fileExt) {
      _resolvedKind = null;
      _resolveKind();
    }
  }

  Future<void> _resolveKind() async {
    final kind = await DocumentFileHelper.resolveKind(
      url: widget.fileUrl,
      fileName: widget.fileName,
      fileExt: widget.fileExt,
    );
    if (!mounted) return;
    setState(() => _resolvedKind = kind);
  }

  @override
  Widget build(BuildContext context) {
    final local = widget.localImagePath?.trim() ?? '';
    if (local.isNotEmpty) {
      return _clip(
        Image.file(File(local), width: widget.size, height: widget.size, fit: BoxFit.cover),
      );
    }

    final custom = widget.customLogoUrl?.trim() ?? '';
    if (custom.startsWith('http://') || custom.startsWith('https://')) {
      return _clip(
        Image.network(
          custom,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _kindTile(),
        ),
      );
    }

    return _kindTile();
  }

  Widget _clip(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox(width: widget.size, height: widget.size, child: child),
    );
  }

  Widget _kindTile() {
    final kind = _resolvedKind ??
        DocumentFileHelper.kindFrom(
          widget.fileUrl,
          widget.fileName,
          widget.fileExt,
        );

    if (kind == DocumentKind.image) {
      if (widget.fileUrl.startsWith('http://') ||
          widget.fileUrl.startsWith('https://')) {
        return _clip(
          Image.network(
            widget.fileUrl,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _brandIcon(kind),
          ),
        );
      }
      if (widget.fileUrl.isNotEmpty &&
          !widget.fileUrl.startsWith('data:') &&
          !widget.fileUrl.startsWith('catalog:')) {
        final file = File(widget.fileUrl);
        if (file.existsSync()) {
          return _clip(
            Image.file(
              file,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _brandIcon(kind),
            ),
          );
        }
      }
    }

    return _brandIcon(kind);
  }

  Widget _brandIcon(DocumentKind kind) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(painter: _FileBrandPainter(kind)),
      ),
    );
  }
}

class _FileBrandPainter extends CustomPainter {
  final DocumentKind kind;

  _FileBrandPainter(this.kind);

  @override
  void paint(Canvas canvas, Size size) {
    switch (kind) {
      case DocumentKind.pdf:
        _paintPdf(canvas, size);
        break;
      case DocumentKind.word:
        _paintWord(canvas, size);
        break;
      case DocumentKind.image:
        _paintImage(canvas, size);
        break;
      case DocumentKind.file:
        _paintFile(canvas, size);
        break;
    }
  }

  void _paintPdf(Canvas canvas, Size size) {
    final r = Radius.circular(size.width * 0.18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, r),
      Paint()..color = const Color(0xFFD32F2F),
    );

    final page = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.22,
        size.height * 0.14,
        size.width * 0.56,
        size.height * 0.72,
      ),
      Radius.circular(size.width * 0.04),
    );
    canvas.drawRRect(page, Paint()..color = Colors.white);

    final fold = Path()
      ..moveTo(size.width * 0.56, size.height * 0.14)
      ..lineTo(size.width * 0.78, size.height * 0.14)
      ..lineTo(size.width * 0.78, size.height * 0.36)
      ..close();
    canvas.drawPath(fold, Paint()..color = const Color(0xFFFFCDD2));
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.56, size.height * 0.14)
        ..lineTo(size.width * 0.56, size.height * 0.36)
        ..lineTo(size.width * 0.78, size.height * 0.36)
        ..close(),
      Paint()..color = const Color(0xFFEF9A9A),
    );

    final badge = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.16,
        size.height * 0.52,
        size.width * 0.68,
        size.height * 0.28,
      ),
      Radius.circular(size.width * 0.06),
    );
    canvas.drawRRect(badge, Paint()..color = const Color(0xFFB71C1C));
    _drawCenteredText(
      canvas,
      'PDF',
      Offset(size.width / 2, size.height * 0.66),
      size.width * 0.22,
      FontWeight.w800,
    );
  }

  void _paintWord(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(size.width * 0.18),
      ),
      Paint()..color = const Color(0xFF185ABD),
    );

    final page = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.28,
        size.height * 0.16,
        size.width * 0.5,
        size.height * 0.68,
      ),
      Radius.circular(size.width * 0.04),
    );
    canvas.drawRRect(page, Paint()..color = Colors.white);

    for (var i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.36,
            size.height * 0.32 + i * size.height * 0.12,
            size.width * 0.34,
            size.height * 0.035,
          ),
          Radius.circular(2),
        ),
        Paint()..color = const Color(0xFFBBDEFB),
      );
    }

    final wBox = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.12,
        size.height * 0.34,
        size.width * 0.42,
        size.height * 0.38,
      ),
      Radius.circular(size.width * 0.06),
    );
    canvas.drawRRect(wBox, Paint()..color = const Color(0xFF0D47A1));
    _drawCenteredText(
      canvas,
      'W',
      Offset(size.width * 0.33, size.height * 0.54),
      size.width * 0.32,
      FontWeight.w900,
    );
  }

  void _paintImage(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(size.width * 0.18),
      ),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF81D4FA), Color(0xFF4FC3F7), Color(0xFF43A047)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.28),
      size.width * 0.12,
      Paint()..color = const Color(0xFFFFF176),
    );

    final mountains = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.62)
      ..lineTo(size.width * 0.32, size.height * 0.38)
      ..lineTo(size.width * 0.52, size.height * 0.55)
      ..lineTo(size.width * 0.78, size.height * 0.32)
      ..lineTo(size.width, size.height * 0.5)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(mountains, Paint()..color = const Color(0xFF2E7D32));

    final inner = Path()
      ..moveTo(size.width * 0.38, size.height)
      ..lineTo(size.width * 0.52, size.height * 0.58)
      ..lineTo(size.width * 0.78, size.height * 0.36)
      ..lineTo(size.width, size.height * 0.52)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(inner, Paint()..color = const Color(0xFF1B5E20));
  }

  void _paintFile(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(size.width * 0.18),
      ),
      Paint()..color = const Color(0xFF546E7A),
    );

    final page = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.22,
        size.height * 0.14,
        size.width * 0.56,
        size.height * 0.72,
      ),
      Radius.circular(size.width * 0.04),
    );
    canvas.drawRRect(page, Paint()..color = Colors.white);

    final fold = Path()
      ..moveTo(size.width * 0.56, size.height * 0.14)
      ..lineTo(size.width * 0.78, size.height * 0.14)
      ..lineTo(size.width * 0.78, size.height * 0.36)
      ..close();
    canvas.drawPath(fold, Paint()..color = const Color(0xFFCFD8DC));

    for (var i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.32,
            size.height * 0.44 + i * size.height * 0.1,
            size.width * 0.36,
            size.height * 0.035,
          ),
          Radius.circular(2),
        ),
        Paint()..color = const Color(0xFFB0BEC5),
      );
    }
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center,
    double fontSize,
    FontWeight weight,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: weight,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _FileBrandPainter oldDelegate) {
    return oldDelegate.kind != kind;
  }
}
