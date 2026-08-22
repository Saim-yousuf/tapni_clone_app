import 'package:flutter/material.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/wa_primary_button.dart';

class CustomAppButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color textColor;
  final double? width;
  final bool isLoading;
  final bool isDisabled;

  const CustomAppButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
    this.backgroundColor = WaUi.buttonDark,
    this.textColor = Colors.white,
    this.width,
    this.isLoading = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return WaPrimaryButton(
      label: text,
      onPressed: isDisabled ? null : onTap,
      loading: isLoading,
      icon: icon,
      expand: width == null || width == double.infinity,
      backgroundColor: backgroundColor,
      foregroundColor: textColor,
    );
  }
}
