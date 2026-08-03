import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tapni_app/models/invitation_design.dart';

Color designColorFromHex(String hex, {Color fallback = Colors.white}) {
  var value = hex.trim().replaceAll('#', '');
  if (value.length == 6) value = 'FF$value';
  if (value.length != 8) return fallback;
  return Color(int.parse(value, radix: 16));
}

TextStyle designFontStyle({
  required String family,
  required double fontSize,
  required Color color,
  bool bold = false,
  bool italic = false,
}) {
  final weight = bold ? FontWeight.w700 : FontWeight.w400;
  final style = italic ? FontStyle.italic : FontStyle.normal;
  switch (family) {
    case 'playfair':
      return GoogleFonts.playfairDisplay(
        fontSize: fontSize,
        color: color,
        fontWeight: weight,
        fontStyle: style,
        height: 1.2,
      );
    case 'cormorant':
      return GoogleFonts.cormorantGaramond(
        fontSize: fontSize,
        color: color,
        fontWeight: weight,
        fontStyle: style,
        height: 1.25,
      );
    case 'amiri':
      return GoogleFonts.amiri(
        fontSize: fontSize,
        color: color,
        fontWeight: weight,
        fontStyle: style,
        height: 1.3,
      );
    case 'noto_naskh':
      return GoogleFonts.notoNaskhArabic(
        fontSize: fontSize,
        color: color,
        fontWeight: weight,
        fontStyle: style,
        height: 1.3,
      );
    case 'roboto':
      return GoogleFonts.roboto(
        fontSize: fontSize,
        color: color,
        fontWeight: weight,
        fontStyle: style,
        height: 1.25,
      );
    case 'cairo':
    default:
      return GoogleFonts.cairo(
        fontSize: fontSize,
        color: color,
        fontWeight: weight,
        fontStyle: style,
        height: 1.3,
      );
  }
}

IconData designIconData(String name) {
  switch (name) {
    case 'clock':
      return Icons.access_time_rounded;
    case 'location':
      return Icons.location_on_outlined;
    case 'calendar':
      return Icons.calendar_today_outlined;
    case 'person':
      return Icons.person_outline;
    case 'phone':
      return Icons.phone_outlined;
    case 'email':
      return Icons.email_outlined;
    case 'link':
      return Icons.link;
    default:
      return Icons.star_outline;
  }
}

/// Renders an [InvitationDesign] to a fixed-aspect card (preview / export).
class InvitationDesignRenderer extends StatelessWidget {
  final InvitationDesign design;
  final String? invitationId;
  final bool interactive;
  final String? selectedLayerId;
  final void Function(String layerId)? onLayerTap;
  final void Function(String layerId, Offset deltaNorm)? onLayerDrag;
  final BoxBorder? border;
  final List<BoxShadow>? shadows;

  const InvitationDesignRenderer({
    super.key,
    required this.design,
    this.invitationId,
    this.interactive = false,
    this.selectedLayerId,
    this.onLayerTap,
    this.onLayerDrag,
    this.border,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: design.aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Container(
            decoration: BoxDecoration(
              color: designColorFromHex(
                design.backgroundColor,
                fallback: Colors.black,
              ),
              borderRadius: BorderRadius.circular(interactive ? 12 : 16),
              border: border,
              boxShadow: shadows ??
                  [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                if (design.backgroundImage.isNotEmpty)
                  Positioned.fill(
                    child: _ImageSrc(
                      src: design.backgroundImage,
                      fit: BoxFit.cover,
                    ),
                  ),
                ...design.sortedLayers
                    .where((l) => l.visible)
                    .map((layer) => _LayerWidget(
                          layer: layer,
                          canvasW: w,
                          canvasH: h,
                          design: design,
                          invitationId: invitationId,
                          selected: selectedLayerId == layer.id,
                          interactive: interactive,
                          onTap: onLayerTap,
                          onDrag: onLayerDrag,
                        )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LayerWidget extends StatelessWidget {
  final DesignLayer layer;
  final double canvasW;
  final double canvasH;
  final InvitationDesign design;
  final String? invitationId;
  final bool selected;
  final bool interactive;
  final void Function(String layerId)? onTap;
  final void Function(String layerId, Offset deltaNorm)? onDrag;

  const _LayerWidget({
    required this.layer,
    required this.canvasW,
    required this.canvasH,
    required this.design,
    this.invitationId,
    this.selected = false,
    this.interactive = false,
    this.onTap,
    this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    final left = layer.x * canvasW;
    final top = layer.y * canvasH;
    final width = layer.width * canvasW;
    final height = layer.height * canvasH;

    Widget child = _buildContent(width, height);

    if (layer.rotation != 0) {
      child = Transform.rotate(
        angle: layer.rotation * 3.1415926535 / 180,
        child: child,
      );
    }

    child = Opacity(opacity: layer.opacity.clamp(0.0, 1.0), child: child);

    if (selected && interactive) {
      child = Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF25D366), width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: child,
      );
    }

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        behavior: interactive ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
        onTap: interactive && onTap != null ? () => onTap!(layer.id) : null,
        onPanUpdate: interactive && !layer.locked && onDrag != null
            ? (d) => onDrag!(
                  layer.id,
                  Offset(d.delta.dx / canvasW, d.delta.dy / canvasH),
                )
            : null,
        child: child,
      ),
    );
  }

  Widget _buildContent(double w, double h) {
    switch (layer.type) {
      case DesignLayerType.text:
        return _textBox(w, h);
      case DesignLayerType.iconField:
        return _iconField(w, h);
      case DesignLayerType.qr:
        return _qr(w, h);
      case DesignLayerType.logo:
        return _logo(w, h);
      case DesignLayerType.image:
        return _image(w, h);
      case DesignLayerType.shape:
      case DesignLayerType.ornament:
        return _shape(w, h);
    }
  }

  TextAlign get _align {
    switch (layer.align) {
      case DesignTextAlign.left:
        return design.rtl ? TextAlign.right : TextAlign.left;
      case DesignTextAlign.right:
        return design.rtl ? TextAlign.left : TextAlign.right;
      case DesignTextAlign.center:
        return TextAlign.center;
    }
  }

  Widget _textBox(double w, double h) {
    final color = designColorFromHex(layer.color);
    final fontSize = layer.fontSize * canvasW;
    return SizedBox(
      width: w,
      height: h,
      child: Center(
        child: Text(
          layer.text.isEmpty ? 'Tap to edit' : layer.text,
          textAlign: _align,
          textDirection: design.rtl ? TextDirection.rtl : TextDirection.ltr,
          style: designFontStyle(
            family: layer.fontFamily,
            fontSize: fontSize,
            color: layer.text.isEmpty
                ? color.withValues(alpha: 0.4)
                : color,
            bold: layer.bold,
            italic: layer.italic,
          ),
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _iconField(double w, double h) {
    final color = designColorFromHex(layer.color);
    final fontSize = layer.fontSize * canvasW;
    return SizedBox(
      width: w,
      height: h,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(designIconData(layer.iconName), color: color, size: fontSize * 1.6),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              layer.text.isEmpty ? '—' : layer.text,
              textAlign: TextAlign.center,
              textDirection: design.rtl ? TextDirection.rtl : TextDirection.ltr,
              style: designFontStyle(
                family: layer.fontFamily,
                fontSize: fontSize,
                color: color,
                bold: layer.bold,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _qr(double w, double h) {
    final data = layer.qrData.isNotEmpty
        ? layer.qrData
        : (invitationId != null && invitationId!.isNotEmpty
            ? 'barqody://invitation/$invitationId'
            : 'barqody://invitation/preview');
    final color = designColorFromHex(layer.qrColor, fallback: Colors.black);
    final size = w < h ? w : h;
    return Center(
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.06),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: QrImageView(
          data: data,
          version: QrVersions.auto,
          eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: color),
          dataModuleStyle: QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _logo(double w, double h) {
    final color = designColorFromHex(layer.color, fallback: Colors.amber);
    if (layer.imageSrc.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _ImageSrc(src: layer.imageSrc, fit: BoxFit.contain),
      );
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, color: color, size: w * 0.35),
            if (w > 40)
              Text(
                'Logo',
                style: TextStyle(color: color, fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }

  Widget _image(double w, double h) {
    if (layer.imageSrc.isEmpty) {
      return Container(
        color: Colors.black26,
        child: const Center(
          child: Icon(Icons.image_outlined, color: Colors.white54),
        ),
      );
    }
    final fit = switch (layer.boxFit) {
      'contain' => BoxFit.contain,
      'fill' => BoxFit.fill,
      _ => BoxFit.cover,
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(layer.borderRadius),
      child: _ImageSrc(src: layer.imageSrc, fit: fit),
    );
  }

  Widget _shape(double w, double h) {
    final color = designColorFromHex(layer.color);
    final borderColor = designColorFromHex(layer.borderColor);
    switch (layer.shape) {
      case 'circle':
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: layer.opacity <= 0 && layer.borderWidth > 0
                ? Colors.transparent
                : color.withValues(alpha: layer.opacity),
            border: layer.borderWidth > 0
                ? Border.all(color: borderColor, width: layer.borderWidth)
                : null,
          ),
        );
      case 'line':
        return Center(
          child: Container(
            width: w,
            height: (layer.borderWidth > 0 ? layer.borderWidth : 1.5),
            color: color,
          ),
        );
      case 'divider':
        return Row(
          children: [
            Expanded(child: Container(height: 1, color: color)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.diamond_outlined, size: 10, color: color),
            ),
            Expanded(child: Container(height: 1, color: color)),
          ],
        );
      case 'diamond':
        return Center(
          child: Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: w * 0.5,
              height: w * 0.5,
              color: color,
            ),
          ),
        );
      case 'rect':
      default:
        return Container(
          decoration: BoxDecoration(
            color: layer.opacity <= 0 && layer.borderWidth > 0
                ? Colors.transparent
                : color.withValues(alpha: layer.opacity.clamp(0.0, 1.0)),
            borderRadius: BorderRadius.circular(layer.borderRadius),
            border: layer.borderWidth > 0
                ? Border.all(color: borderColor, width: layer.borderWidth)
                : null,
          ),
        );
    }
  }
}

class _ImageSrc extends StatelessWidget {
  final String src;
  final BoxFit fit;

  const _ImageSrc({required this.src, required this.fit});

  @override
  Widget build(BuildContext context) {
    if (src.startsWith('data:')) {
      try {
        final b64 = src.split(',').last;
        final bytes = base64Decode(b64);
        return Image.memory(Uint8List.fromList(bytes), fit: fit);
      } catch (_) {
        return const SizedBox.shrink();
      }
    }
    if (src.startsWith('http://') || src.startsWith('https://')) {
      return Image.network(
        src,
        fit: fit,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    if (src.startsWith('/') || src.contains(r'\')) {
      final file = File(src);
      if (file.existsSync()) {
        return Image.file(file, fit: fit);
      }
    }
    // raw base64 without data: prefix
    if (src.length > 100 && !src.contains('/')) {
      try {
        final bytes = base64Decode(src);
        return Image.memory(Uint8List.fromList(bytes), fit: fit);
      } catch (_) {}
    }
    return const SizedBox.shrink();
  }
}
