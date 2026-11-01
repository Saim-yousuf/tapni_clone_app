import 'package:flutter/material.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// Shared chrome for Business Presence setup + settings (Figma light theme).
class BwUi {
  static const Color pageBg = Color(0xFFF7F7F8);
  static const Color cardBorder = Color(0xFFE8E8ED);
  static const Color selectedBorder = Color(0xFF000000);
  static const Color iconTileBg = Color(0xFFF2F2F7);

  static IconData categoryIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('food') || n.contains('beverage') || n.contains('cafe') ||
        n.contains('restaurant') || n.contains('ice')) {
      return Icons.restaurant_outlined;
    }
    if (n.contains('retail') || n.contains('shop') || n.contains('store') ||
        n.contains('grocery') || n.contains('clothing') || n.contains('perfume')) {
      return Icons.storefront_outlined;
    }
    if (n.contains('beauty') || n.contains('salon')) {
      return Icons.brush_outlined;
    }
    if (n.contains('health') || n.contains('doctor') || n.contains('clinic') ||
        n.contains('medical')) {
      return Icons.medical_services_outlined;
    }
    if (n.contains('hotel') || n.contains('hospitality') || n.contains('stay') ||
        n.contains('resort')) {
      return Icons.hotel_outlined;
    }
    if (n.contains('design') || n.contains('creative') || n.contains('graphic')) {
      return Icons.desktop_windows_outlined;
    }
    if (n.contains('develop') || n.contains('code')) {
      return Icons.code;
    }
    if (n.contains('photo')) return Icons.photo_camera_outlined;
    if (n.contains('freelance')) return Icons.laptop_mac_outlined;
    if (n.contains('consult') || n.contains('agency') || n.contains('professional')) {
      return Icons.verified_user_outlined;
    }
    if (n.contains('other')) return Icons.apps_outlined;
    return Icons.business_outlined;
  }

  static IconData contentIcon(String type) {
    switch (type) {
      case 'product':
        return Icons.inventory_2_outlined;
      case 'service':
        return Icons.assignment_outlined;
      case 'package':
        return Icons.card_giftcard_outlined;
      case 'portfolio':
        return Icons.photo_library_outlined;
      case 'category':
        return Icons.category_outlined;
      default:
        return Icons.folder_outlined;
    }
  }
}

class BwProgressBar extends StatelessWidget {
  final int step; // 0-based
  final int total;

  const BwProgressBar({super.key, required this.step, this.total = 4});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: List.generate(total, (i) {
          final filled = i <= step;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
              decoration: BoxDecoration(
                color: filled ? Colors.black : const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class BwSelectCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String? subtitle;

  const BwSelectCard({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? BwUi.selectedBorder : BwUi.cardBorder,
              width: selected ? 2.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected ? Colors.black : BwUi.iconTileBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: selected ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AuthUi.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class BwFieldLabel extends StatelessWidget {
  final String text;
  const BwFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }
}

class BwFilledField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const BwFilledField({
    super.key,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15, color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 15),
        filled: true,
        fillColor: AuthUi.fieldFill,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 14 : 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black, width: 1.5),
        ),
      ),
    );
  }
}

class BwBottomCta extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const BwBottomCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: AuthPrimaryPillButton(
          label: label,
          onPressed: loading ? null : onPressed,
          loading: loading,
        ),
      ),
    );
  }
}

class BwPresenceScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? bottom;
  final Widget? belowTitle;
  final VoidCallback? onBack;

  const BwPresenceScaffold({
    super.key,
    required this.title,
    required this.body,
    this.bottom,
    this.belowTitle,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(
              title: title,
              onBack: onBack ?? () => Navigator.of(context).pop(),
            ),
            if (belowTitle != null) belowTitle!,
            Expanded(child: body),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    );
  }
}

class BwSegmentedOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final TextStyle? textStyle;

  const BwSegmentedOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: selected ? Colors.black : BwUi.cardBorder,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: (textStyle ?? const TextStyle(fontSize: 15)).copyWith(
              color: selected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
