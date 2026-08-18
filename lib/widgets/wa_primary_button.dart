import 'package:flutter/material.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

/// Full-width stadium primary CTA used across the app (phone Next, etc.).
class WaPrimaryButton extends StatelessWidget {
  static const double height = WaUi.primaryButtonHeight;

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expand;
  final bool outlined;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const WaPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.expand = true,
    this.outlined = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  static const StrutStyle _strut = StrutStyle(
    fontSize: 16,
    height: 1.0,
    leading: 0,
    forceStrutHeight: true,
  );

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? (outlined ? Colors.transparent : WaUi.buttonDark);
    final fg = foregroundColor ?? (outlined ? WaUi.primaryText : Colors.white);
    final disabled = onPressed == null || loading;

    final labelStyle = WaUi.button.copyWith(
      color: fg,
      height: 1.0,
      leadingDistribution: TextLeadingDistribution.even,
    );

    final child = loading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: fg,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  strutStyle: _strut,
                  style: labelStyle,
                ),
              ),
            ],
          );

    final style = outlined
        ? OutlinedButton.styleFrom(
            foregroundColor: fg,
            side: const BorderSide(color: WaUi.divider),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            minimumSize: Size(expand ? double.infinity : 64, height),
            maximumSize: Size(double.infinity, height),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: const StadiumBorder(),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            disabledBackgroundColor: bg.withValues(alpha: 0.5),
            disabledForegroundColor: fg.withValues(alpha: 0.8),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            minimumSize: Size(expand ? double.infinity : 64, height),
            maximumSize: Size(double.infinity, height),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: const StadiumBorder(),
          );

    final button = outlined
        ? OutlinedButton(
            onPressed: disabled ? null : onPressed,
            style: style,
            child: child,
          )
        : ElevatedButton(
            onPressed: disabled ? null : onPressed,
            style: style,
            child: child,
          );

    if (!expand) return SizedBox(height: height, child: button);
    return SizedBox(width: double.infinity, height: height, child: button);
  }
}
