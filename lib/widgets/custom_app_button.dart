import 'package:flutter/material.dart';

class CustomAppButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color textColor;
  final Color? iconColor;
  final double fontSize;
  final FontWeight fontWeight;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double iconSpacing;
  final double iconSize;
  final double? width;
  final BoxBorder? border;
  final bool isLoading;
  final bool isDisabled;
  final String? fontFamily;
  final IconPosition iconPosition;

  const CustomAppButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
    this.backgroundColor = Colors.black,
    this.textColor = Colors.white,
    this.iconColor,
    this.fontSize = 20,
    this.fontWeight = FontWeight.w700,
    this.borderRadius = 25,
    this.padding = const EdgeInsets.all(16),
    this.iconSpacing = 8,
    this.iconSize = 24,
    this.width,
    this.border,
    this.isLoading = false,
    this.isDisabled = false,
    this.fontFamily,
    this.iconPosition = IconPosition.end,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = isDisabled || isLoading;

    final List<Widget> children = [
      if (isLoading)
        SizedBox(
          height: fontSize,
          width: fontSize,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(textColor),
          ),
        )
      else
        Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontFamily: fontFamily,
            letterSpacing: 0.5,
          ),
        ),
      if (icon != null && !isLoading) ...[
        SizedBox(width: iconSpacing),
        Icon(icon, color: iconColor ?? textColor, size: iconSize),
      ],
    ];

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.5 : 1.0,
        child: Container(
          width: width,
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
            children: iconPosition == IconPosition.start
                ? children.reversed.toList()
                : children,
          ),
        ),
      ),
    );
  }
}

enum IconPosition { start, end }
