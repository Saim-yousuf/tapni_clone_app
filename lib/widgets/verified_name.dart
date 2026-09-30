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
    this.badgeSize = 20,
  });

  static const Color defaultBadgeColor = Color(0xFFFFCC00);

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: name),
          if (verified) ...[
            const WidgetSpan(child: SizedBox(width: 6)),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Image.asset(
                'assets/images/png/verified-badge.png',
                width: badgeSize,
                height: badgeSize,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.verified,
                  size: badgeSize,
                  color: badgeColor ?? defaultBadgeColor,
                ),
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
