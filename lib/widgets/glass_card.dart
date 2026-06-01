import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/theme_provider.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double borderOpacity;
  final EdgeInsetsGeometry padding;
  final Color? customBgColor;
  final double? width;
  final double? height;

  const GlassCard({
    Key? key,
    required this.child,
    this.borderRadius = 20.0,
    this.blur = 15.0,
    this.borderOpacity = 0.08,
    this.padding = const EdgeInsets.all(16.0),
    this.customBgColor,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final defaultBg = isDark
        ? Colors.white.withOpacity(0.04)
        : Colors.black.withOpacity(0.015);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: customBgColor ?? defaultBg,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(borderOpacity)
                  : Colors.black.withOpacity(borderOpacity),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
