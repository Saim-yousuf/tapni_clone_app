import 'package:flutter/material.dart';

/// Name plus a verified check for BarQody Business (pro) accounts.
class VerifiedName extends StatelessWidget {
  final String name;
  final bool verified;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Color? badgeColor;
  final double badgeSize;

  const VerifiedName({
    super.key,
    required this.name,
    required this.verified,
    this.style,
    this.textAlign = TextAlign.center,
    this.maxLines,
    this.overflow,
    this.badgeColor,
    this.badgeSize = 22,
  });

  static const Color defaultBadgeColor = Color(0xFF1D9BF0);

  @override
  Widget build(BuildContext context) {
    final iconColor = badgeColor ?? defaultBadgeColor;
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: name),
          if (verified) ...[
            const WidgetSpan(child: SizedBox(width: 6)),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(
                Icons.verified,
                size: badgeSize,
                color: iconColor,
              ),
            ),
          ],
        ],
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
    );
  }
}
