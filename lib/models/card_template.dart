import 'package:flutter/material.dart';

class CardTemplate {
  final String id;
  final String name;
  final Color backgroundColor;
  final Color textColor;
  final Color labelColor;
  final Color brandingColor;
  final bool isPro;
  final bool isDark;

  CardTemplate({
    required this.id,
    required this.name,
    required this.backgroundColor,
    required this.textColor,
    required this.labelColor,
    required this.brandingColor,
    this.isPro = false,
    this.isDark = true,
  });
}
