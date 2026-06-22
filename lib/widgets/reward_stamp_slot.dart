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
  });

  @override
  Widget build(BuildContext context) {
    final customUrl = filled ? stampIconUrl : unstampIconUrl;
    final customBase64 = filled ? stampIconBase64 : unstampIconBase64;
    final hasCustomImage =
        (customUrl != null && customUrl.isNotEmpty) ||
        (customBase64 != null && customBase64.isNotEmpty);

    final container = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled && !hasCustomImage ? theme.stampColor : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: theme.stampBorderColor, width: 2.5),
      ),
      child: ClipOval(child: _buildContent(hasCustomImage, customUrl, customBase64)),
    );

    if (!animated) return container;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled && !hasCustomImage ? theme.stampColor : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: theme.stampBorderColor, width: 2.5),
      ),
      child: ClipOval(child: _buildContent(hasCustomImage, customUrl, customBase64)),
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
