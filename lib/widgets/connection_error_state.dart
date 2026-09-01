import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/utils/api_error_messages.dart';
import 'package:tapni_app/utils/app_fonts.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

/// Soft full-area state for load failures — especially offline / network issues.
class ConnectionErrorState extends StatelessWidget {
  const ConnectionErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.padding = const EdgeInsets.symmetric(horizontal: 28),
  });

  final String message;
  final VoidCallback? onRetry;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNetwork = ApiErrorMessages.isNetworkIssue(message: message);

    final title = ApiErrorMessages.sanitize(message);
    final subtitle = isNetwork ? ApiErrorMessages.networkSubtitle() : null;

    final iconBg = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF4F6F8);
    final iconColor = isDark
        ? const Color(0xFFFFB4AB)
        : const Color(0xFF64748B);

    return Padding(
      padding: padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isNetwork ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
              size: 32,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppFonts.titleStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : WaUi.primaryText,
              height: 1.25,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppFonts.titleStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.65)
                    : WaUi.secondaryText,
                height: 1.35,
              ),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                backgroundColor: WaUi.buttonDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(WaUi.radiusPill),
                ),
              ),
              child: Text(
                l10n.tryAgain,
                style: AppFonts.titleStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
