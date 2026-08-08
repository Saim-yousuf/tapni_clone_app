import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tapni_app/models/reward.dart';

class RewardStampSlot extends StatelessWidget {
  final bool filled;
  final double size;
  final RewardTheme theme;
  final String? stampIconUrl;
  final String? unstampIconUrl;
  final String? stampIconBase64;
  final String? unstampIconBase64;
  final bool animated;
  /// circle (default) or square
  final String shape;

  const RewardStampSlot({
    super.key,
    required this.filled,
    required this.theme,
    this.size = 36,
    this.stampIconUrl,
    this.unstampIconUrl,
    this.stampIconBase64,
    this.unstampIconBase64,
    this.animated = false,
    this.shape = 'circle',
  });

  bool get _isSquare => shape == 'square';

  BoxDecoration _decoration({required bool hasCustomImage}) {
    return BoxDecoration(
      color: filled && !hasCustomImage ? theme.stampColor : Colors.transparent,
      shape: _isSquare ? BoxShape.rectangle : BoxShape.circle,
      borderRadius: _isSquare ? BorderRadius.circular(size * 0.12) : null,
      border: Border.all(color: theme.stampBorderColor, width: 2.5),
    );
  }

  Widget _clip(Widget child) {
    if (_isSquare) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.12),
        child: child,
      );
    }
    return ClipOval(child: child);
  }

  @override
  Widget build(BuildContext context) {
    final customUrl = filled ? stampIconUrl : unstampIconUrl;
    final customBase64 = filled ? stampIconBase64 : unstampIconBase64;
    final hasCustomImage =
        (customUrl != null && customUrl.isNotEmpty) ||
        (customBase64 != null && customBase64.isNotEmpty);

    final content = _clip(_buildContent(hasCustomImage, customUrl, customBase64));

    if (!animated) {
      return Container(
        width: size,
        height: size,
        decoration: _decoration(hasCustomImage: hasCustomImage),
        child: content,
      );
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: _decoration(hasCustomImage: hasCustomImage),
      child: content,
    );
  }

  Widget _buildContent(
    bool hasCustomImage,
    String? customUrl,
    String? customBase64,
  ) {
    if (hasCustomImage) {
      if (customBase64 != null && customBase64.isNotEmpty) {
        return Image.memory(
          base64Decode(customBase64.split(',').last),
          fit: BoxFit.cover,
          width: size,
          height: size,
        );
      }
      return Image.network(
        customUrl!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => _defaultIcon(),
      );
    }
    return _defaultIcon();
  }

  Widget _defaultIcon() {
    return Center(
      child: Icon(
        filled ? Icons.check_rounded : Icons.circle_outlined,
        size: size * 0.5,
        color: filled ? theme.cardTextColor : theme.stampBorderColor,
      ),
    );
  }
}
