import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tapni_app/models/invitation_design.dart';
import 'package:tapni_app/widgets/branded_qr_image.dart';
import 'package:tapni_app/models/loyalty_card_design.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/widgets/invitation_design_renderer.dart';
import 'package:tapni_app/widgets/reward_stamp_slot.dart';

/// Avoid re-decoding large data-URI backgrounds on every swipe rebuild.
final Map<String, Uint8List> _loyaltyImageBytesCache = {};

Uint8List? _cachedBytesForDataUri(String src) {
  final cached = _loyaltyImageBytesCache[src];
  if (cached != null) return cached;
  try {
    final comma = src.indexOf(',');
    final raw = comma >= 0 ? src.substring(comma + 1) : src;
    final bytes = base64Decode(raw);
    // Cap cache size to avoid unbounded memory growth.
    if (_loyaltyImageBytesCache.length > 40) {
      _loyaltyImageBytesCache.remove(_loyaltyImageBytesCache.keys.first);
    }
    _loyaltyImageBytesCache[src] = bytes;
    return bytes;
  } catch (_) {
    return null;
  }
}

/// Renders a [LoyaltyCardDesign] stamp card (preview / editor / customer view).
class LoyaltyCardDesignRenderer extends StatelessWidget {
  final LoyaltyCardDesign design;
  final int filledStamps;
  final bool interactive;
  final String? selectedLayerId;
  final void Function(String layerId)? onLayerTap;
  final void Function(String layerId, Offset deltaNorm)? onLayerDrag;
  final BoxBorder? border;
  final List<BoxShadow>? shadows;
  final double borderRadius;

  const LoyaltyCardDesignRenderer({
    super.key,
    required this.design,
    this.filledStamps = 0,
    this.interactive = false,
    this.selectedLayerId,
    this.onLayerTap,
    this.onLayerDrag,
    this.border,
    this.shadows,
    this.borderRadius = 20,
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
                fallback: const Color(0xFF1B4332),
              ),
              borderRadius: BorderRadius.circular(
                interactive ? 12 : borderRadius,
              ),
              border: border,
              boxShadow: shadows ??
                  [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (design.backgroundImage.isNotEmpty)
                  Positioned.fill(
                    child: _SrcImage(
                      src: design.backgroundImage,
                      fit: BoxFit.cover,
                    ),
                  ),
                ...design.sortedLayers.where((l) => l.visible).map(
                      (layer) => _LoyaltyLayerWidget(
                        layer: layer,
                        canvasW: w,
                        canvasH: h,
                        design: design,
                        filledStamps: filledStamps,
                        selected: selectedLayerId == layer.id,
                        interactive: interactive,
                        onTap: onLayerTap,
                        onDrag: onLayerDrag,
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LoyaltyLayerWidget extends StatelessWidget {
  final DesignLayer layer;
  final double canvasW;
  final double canvasH;
  final LoyaltyCardDesign design;
  final int filledStamps;
  final bool selected;
  final bool interactive;
  final void Function(String layerId)? onTap;
  final void Function(String layerId, Offset deltaNorm)? onDrag;

  const _LoyaltyLayerWidget({
    required this.layer,
    required this.canvasW,
    required this.canvasH,
    required this.design,
    required this.filledStamps,
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
          border: Border.all(color: const Color(0xFFFF8A3D), width: 2),
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
        behavior:
            interactive ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
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
      case DesignLayerType.logo:
      case DesignLayerType.image:
        return _image(w, h);
      case DesignLayerType.shape:
      case DesignLayerType.ornament:
        return _shape(w, h);
      case DesignLayerType.stampGrid:
        return _stampGrid(w, h);
      case DesignLayerType.qr:
        return _qr(w, h);
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
          textAlign: TextAlign.center,
          textDirection: design.rtl ? TextDirection.rtl : TextDirection.ltr,
          style: designFontStyle(
            family: layer.fontFamily,
            fontSize: fontSize,
            color: layer.text.isEmpty ? color.withValues(alpha: 0.4) : color,
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
          Icon(
            designIconData(layer.iconName),
            color: color,
            size: fontSize * 1.6,
          ),
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
    final data =
        layer.qrData.isNotEmpty ? layer.qrData : 'barqody://loyalty/preview';
    final color = designColorFromHex(layer.qrColor, fallback: Colors.black);
    final size = w < h ? w : h;
    return Center(
      child: Container(
        width: size,
        height: size,
        color: Colors.white,
        padding: const EdgeInsets.all(4),
        child: BrandedQrImage(
          data: data,
          padding: EdgeInsets.zero,
          foregroundColor: color,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _image(double w, double h) {
    final src = layer.imageSrc.isNotEmpty
        ? layer.imageSrc
        : (layer.fieldKey == 'logo' ? design.logo : '');
    if (src.isEmpty) {
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: layer.shape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
          borderRadius:
              layer.shape == 'circle' ? null : BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.add_photo_alternate_outlined,
          color: Colors.white.withValues(alpha: 0.7),
          size: w * 0.35,
        ),
      );
    }
    final img = _SrcImage(src: src, fit: BoxFit.cover);
    if (layer.shape == 'circle') {
      return ClipOval(child: SizedBox(width: w, height: h, child: img));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(width: w, height: h, child: img),
    );
  }

  Widget _shape(double w, double h) {
    final color = designColorFromHex(layer.color, fallback: Colors.transparent);
    final borderColor = designColorFromHex(layer.borderColor);
    final bw = layer.borderWidth * canvasW;
    if (layer.shape == 'circle') {
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: bw > 0 ? Border.all(color: borderColor, width: bw) : null,
        ),
      );
    }
    if (layer.shape == 'line' || layer.shape == 'divider') {
      final lineH = (bw > 0 ? bw : 2.0).clamp(1.0, h).toDouble();
      return Center(
        child: Container(
          width: w,
          height: lineH,
          color: color,
        ),
      );
    }
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(layer.borderRadius * canvasW),
        border: bw > 0 ? Border.all(color: borderColor, width: bw) : null,
      ),
    );
  }

  Widget _stampGrid(double w, double h) {
    final count = int.tryParse(layer.text) ?? design.stamps;
    final stampCount = count.clamp(1, 24);
    final shape = layer.shape.isNotEmpty ? layer.shape : design.stampShape;
    final cols = stampCount <= 4
        ? 2
        : stampCount <= 9
            ? 3
            : stampCount <= 12
                ? 4
                : 5;
    final theme = RewardTheme(
      cardBackgroundColor: designColorFromHex(design.backgroundColor),
      cardTextColor: designColorFromHex(layer.color, fallback: Colors.white),
      stampColor: designColorFromHex(
        layer.color.isNotEmpty ? layer.color : design.stampColor,
        fallback: Colors.white,
      ),
      stampBorderColor: designColorFromHex(
        layer.borderColor.isNotEmpty
            ? layer.borderColor
            : design.stampBorderColor,
        fallback: Colors.white,
      ),
    );

    final stampIcon = design.stampIcon.isNotEmpty ? design.stampIcon : null;
    final unstampIcon =
        design.unstampIcon.isNotEmpty ? design.unstampIcon : null;

    String? urlOrNull(String? v) =>
        (v != null && v.isNotEmpty && !v.startsWith('data:')) ? v : null;
    String? b64OrNull(String? v) =>
        (v != null && v.startsWith('data:')) ? v : null;

    return SizedBox(
      width: w,
      height: h,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellW = constraints.maxWidth / cols;
          final rows = (stampCount / cols).ceil();
          final cellH = constraints.maxHeight / rows;
          final slotSize = (cellW < cellH ? cellW : cellH) * 0.78;

          return Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            children: List.generate(stampCount, (i) {
              return SizedBox(
                width: cellW,
                height: cellH,
                child: Center(
                  child: RewardStampSlot(
                    filled: i < filledStamps,
                    size: slotSize,
                    theme: theme,
                    shape: shape,
                    stampIconUrl: urlOrNull(stampIcon),
                    unstampIconUrl: urlOrNull(unstampIcon),
                    stampIconBase64: b64OrNull(stampIcon),
                    unstampIconBase64: b64OrNull(unstampIcon),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _SrcImage extends StatelessWidget {
  final String src;
  final BoxFit fit;

  const _SrcImage({required this.src, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (src.startsWith('data:')) {
      final bytes = _cachedBytesForDataUri(src);
      if (bytes == null) return const SizedBox.shrink();
      return Image.memory(
        bytes,
        key: ValueKey(src.hashCode),
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      );
    }
    if (src.startsWith('http')) {
      return Image.network(
        src,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    return const SizedBox.shrink();
  }
}
