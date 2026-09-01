import 'package:flutter/material.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/wa_primary_button.dart';

/// Attendance screens — pure white + app fonts (WaUi / AppFonts).
class AttendanceUi {
  static String get fontFamily => WaUi.fontFamily;

  static const double buttonHeight = WaUi.primaryButtonHeight;
  static const double borderWidth = 1;
  static const double radius = 14;
  static const Color tileBg = Color(0xFFF5F5F5);

  static Color get scaffoldBg => Colors.white;
  static Color get primaryText => WaUi.primaryText;
  static Color get secondaryText => WaUi.secondaryText;
  static Color get divider => WaUi.divider;
  static Color get surface => Colors.white;
  static Color get buttonDark => WaUi.buttonDark;

  static TextStyle get pageTitle =>
      WaUi.toolsTitleOf(weight: FontWeight.w500, size: 22);

  static TextStyle get sectionTitle => WaUi.sectionHeader;

  static TextStyle get cardTitle => WaUi.listTitle;

  static TextStyle get body => WaUi.body;

  static TextStyle get bodyMedium => WaUi.bodyMedium;

  static TextStyle get bodyMuted => WaUi.listSubtitle;

  static TextStyle get statNumber => WaUi.toolsTitleOf(
        size: 28,
        height: 1.15,
        weight: FontWeight.w700,
      );

  static TextStyle get statLabel => WaUi.label.copyWith(
        color: secondaryText,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      );

  static TextStyle get buttonLabel => WaUi.promoButton;

  static BoxDecoration get thickCard => BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(radius),
      );

  static BoxDecoration get outlinedCard => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: divider),
      );

  static BoxDecoration thickCardFilled({Color fill = WaUi.buttonDark}) =>
      BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
      );

  static AppBar appBar(String title, {List<Widget>? actions}) {
    return AppBar(
      title: Text(title),
      actions: actions,
    );
  }

  static Widget sectionHeader(String text, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(text, style: sectionTitle)),
          if (trailing != null)
            Text(trailing, style: WaUi.caption),
        ],
      ),
    );
  }

  static Widget primaryButton({
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    bool loading = false,
    double? height,
  }) {
    return WaPrimaryButton(
      label: label,
      onPressed: onPressed,
      loading: loading,
      icon: icon,
    );
  }

  static Widget secondaryButton({
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    bool loading = false,
    double? height,
  }) {
    return WaPrimaryButton(
      label: label,
      onPressed: onPressed,
      loading: loading,
      icon: icon,
      outlined: true,
    );
  }

  static InputDecoration inputDecoration(String label) {
    return WaUi.fieldDecoration(labelText: label);
  }

  static Widget timeChip({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: thickCard,
          child: Column(
            children: [
              Text(label, style: WaUi.label),
              const SizedBox(height: 8),
              Text(value, style: WaUi.headline.copyWith(fontSize: 22)),
            ],
          ),
        ),
      ),
    );
  }

  static Widget statusText({
    required String label,
    required Color color,
  }) {
    return Text(
      label,
      style: WaUi.label.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );
  }

  /// Soft elevated card — white on grey scaffold, no harsh borders.
  static BoxDecoration get softCard => BoxDecoration(
        color: WaUi.surface,
        borderRadius: BorderRadius.circular(WaUi.radiusLg),
        boxShadow: [
          BoxShadow(
            color: WaUi.primaryText.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      );

  /// Gentle tinted surface for stat tiles.
  static BoxDecoration softTintBox(Color tint) => BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(WaUi.radiusMd),
      );

  /// Rounded status chip with soft background tint.
  static Widget statusPill({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(WaUi.radiusPill),
      ),
      child: Text(
        label,
        style: WaUi.label.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  /// Compact stat tile for report grids.
  static Widget softStatTile({
    required String label,
    required String value,
    required Color tint,
    IconData? icon,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: softTintBox(tint),
        child: Column(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: tint),
              const SizedBox(height: 6),
            ],
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WaUi.toolsTitleOf(
                size: 20,
                weight: FontWeight.w600,
                color: tint,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: statLabel.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  /// Icon in soft rounded square (tools / promo style).
  static Widget softIconBox({
    required IconData icon,
    Color? bg,
    Color? fg,
    double size = 44,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg ?? WaUi.promoIconBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: fg ?? WaUi.promoIconFg,
        size: size * 0.52,
      ),
    );
  }
}
