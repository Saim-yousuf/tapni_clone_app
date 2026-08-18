import 'package:flutter/material.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/wa_primary_button.dart';

/// Attendance screens — WhatsApp Business–style surfaces and typography.
class AttendanceUi {
  static String get fontFamily => WaUi.fontFamily;

  static const double buttonHeight = WaUi.primaryButtonHeight;
  static const double borderWidth = 1;
  static const double radius = WaUi.radiusLg;

  static Color get scaffoldBg => WaUi.toolsScaffold;
  static Color get primaryText => WaUi.primaryText;
  static Color get secondaryText => WaUi.secondaryText;
  static Color get divider => WaUi.divider;
  static Color get surface => WaUi.surface;
  static Color get buttonDark => WaUi.buttonDark;

  static TextStyle get pageTitle => WaUi.headline;

  static TextStyle get sectionTitle => WaUi.sectionHeader;

  static TextStyle get cardTitle => WaUi.chatName;

  static TextStyle get body => WaUi.body;

  static TextStyle get bodyMuted => WaUi.listSubtitle;

  static TextStyle get statNumber => WaUi.toolsTitle.copyWith(
        fontSize: 28,
        color: primaryText,
      );

  static TextStyle get statLabel => WaUi.label.copyWith(color: primaryText);

  static TextStyle get buttonLabel => WaUi.button.copyWith(color: Colors.white);

  static BoxDecoration get thickCard => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: divider, width: borderWidth),
      );

  static BoxDecoration thickCardFilled({Color fill = WaUi.buttonDark}) =>
      BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: fill, width: borderWidth),
      );

  static AppBar appBar(String title, {List<Widget>? actions}) {
    return AppBar(
      backgroundColor: scaffoldBg,
      surfaceTintColor: scaffoldBg,
      elevation: 0,
      iconTheme: const IconThemeData(color: WaUi.primaryText, size: 24),
      title: Text(title, style: pageTitle),
      actions: actions,
    );
  }

  static Widget sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: sectionTitle),
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
              Text(
                value,
                style: WaUi.headline.copyWith(fontSize: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
