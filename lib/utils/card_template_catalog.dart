import 'package:flutter/material.dart';
import 'package:tapni_app/models/card_template.dart';

/// Shared business card templates used by profile and employee company cards.
class CardTemplateCatalog {
  static const String defaultTemplateId = 't2';

  static final List<CardTemplate> all = [
    CardTemplate(
      id: 't1',
      name: 'Violet',
      backgroundColor: const Color(0xFF7A78FF),
      textColor: Colors.white,
      labelColor: Colors.white.withValues(alpha: 0.6),
      brandingColor: Colors.white,
      isPro: true,
      isDark: true,
    ),
    CardTemplate(
      id: 't2',
      name: 'Charcoal',
      backgroundColor: const Color(0xFF1E2022),
      textColor: Colors.white,
      labelColor: Colors.white.withValues(alpha: 0.6),
      brandingColor: Colors.white,
      isPro: false,
      isDark: true,
    ),
    CardTemplate(
      id: 't3',
      name: 'Vibrant Red',
      backgroundColor: const Color(0xFFEA2C3B),
      textColor: Colors.white,
      labelColor: Colors.white.withValues(alpha: 0.6),
      brandingColor: Colors.white,
      isPro: false,
      isDark: true,
    ),
    CardTemplate(
      id: 't4',
      name: 'Pure White',
      backgroundColor: const Color(0xFFFFFFFF),
      textColor: const Color(0xFF1E2022),
      labelColor: const Color(0xFF1E2022).withValues(alpha: 0.6),
      brandingColor: const Color(0xFF1E2022),
      isPro: false,
      isDark: false,
    ),
    CardTemplate(
      id: 't5',
      name: 'Cream Beige',
      backgroundColor: const Color(0xFFF5EBE1),
      textColor: const Color(0xFF1E2022),
      labelColor: const Color(0xFF1E2022).withValues(alpha: 0.6),
      brandingColor: const Color(0xFF1E2022),
      isPro: true,
      isDark: false,
    ),
    CardTemplate(
      id: 't6',
      name: 'Olive Green',
      backgroundColor: const Color(0xFF9EBF7B),
      textColor: Colors.white,
      labelColor: Colors.white.withValues(alpha: 0.6),
      brandingColor: Colors.white,
      isPro: false,
      isDark: true,
    ),
    CardTemplate(
      id: 't7',
      name: 'Light Blue',
      backgroundColor: const Color(0xFF6BB5FF),
      textColor: Colors.white,
      labelColor: Colors.white.withValues(alpha: 0.6),
      brandingColor: Colors.white,
      isPro: false,
      isDark: true,
    ),
    CardTemplate(
      id: 't8',
      name: 'Pitch Black',
      backgroundColor: const Color(0xFF000000),
      textColor: Colors.white,
      labelColor: Colors.white.withValues(alpha: 0.6),
      brandingColor: Colors.white,
      isPro: false,
      isDark: true,
    ),
  ];

  static CardTemplate byId(String? id) {
    if (id == null || id.isEmpty) return all[1];
    return all.firstWhere(
      (template) => template.id == id,
      orElse: () => all[1],
    );
  }

  static int indexById(String? id) {
    if (id == null || id.isEmpty) return 1;
    final index = all.indexWhere((template) => template.id == id);
    return index >= 0 ? index : 1;
  }
}
