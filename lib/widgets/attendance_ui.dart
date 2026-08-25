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
}
