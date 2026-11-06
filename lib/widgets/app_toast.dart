import 'package:flutter/material.dart';
import 'package:tapni_app/utils/app_fonts.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// Toast tone — keeps success/error/warning/info visually consistent app-wide.
enum AppToastKind { success, error, warning, info }

/// Professional floating toast card (BarQody: white surface, soft shadow, status mark).
class AppToastCard extends StatelessWidget {
  const AppToastCard({
    super.key,
    required this.message,
    this.kind = AppToastKind.info,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final AppToastKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final style = _AppToastStyle.of(kind);
    final hasAction =
        actionLabel != null && actionLabel!.trim().isNotEmpty && onAction != null;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AuthUi.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: style.iconBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(style.icon, size: 20, color: style.iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppFonts.textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AuthUi.textPrimary,
                  height: 1.35,
                ),
              ),
            ),
            if (hasAction) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: AuthUi.textPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  actionLabel!,
                  style: AppFonts.textStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AuthUi.textPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AppToastStyle {
  const _AppToastStyle({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  static _AppToastStyle of(AppToastKind kind) {
    switch (kind) {
      case AppToastKind.success:
        return const _AppToastStyle(
          icon: Icons.check_rounded,
          iconColor: Colors.white,
          iconBg: Colors.black,
        );
      case AppToastKind.error:
        return const _AppToastStyle(
          icon: Icons.close_rounded,
          iconColor: AuthUi.error,
          iconBg: Color(0xFFFEE2E2),
        );
      case AppToastKind.warning:
        return const _AppToastStyle(
          icon: Icons.priority_high_rounded,
          iconColor: Color(0xFFB45309),
          iconBg: Color(0xFFFFF7ED),
        );
      case AppToastKind.info:
        return const _AppToastStyle(
          icon: Icons.info_outline_rounded,
          iconColor: AuthUi.textSecondary,
          iconBg: BarqodyChrome.circleBtn,
        );
    }
  }
}

/// Builds a transparent floating [SnackBar] that hosts [AppToastCard].
SnackBar appToastSnackBar(
  String message, {
  AppToastKind kind = AppToastKind.info,
  Duration duration = const Duration(seconds: 3),
  EdgeInsetsGeometry? margin,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.transparent,
    elevation: 0,
    padding: EdgeInsets.zero,
    duration: duration,
    margin: margin ?? const EdgeInsets.fromLTRB(16, 0, 16, 24),
    content: AppToastCard(
      message: message,
      kind: kind,
      actionLabel: actionLabel,
      onAction: onAction,
    ),
  );
}

/// Infer toast kind from legacy flags / colors used across the app.
AppToastKind appToastKindFrom({
  bool isError = false,
  bool isSuccess = false,
  bool isWarning = false,
  Color? color,
}) {
  if (isError) return AppToastKind.error;
  if (isSuccess) return AppToastKind.success;
  if (isWarning) return AppToastKind.warning;
  if (color == null) return AppToastKind.info;

  bool matches(Color a, Color b) => a.toARGB32() == b.toARGB32();

  if (matches(color, Colors.green) ||
      matches(color, Colors.green.shade700) ||
      matches(color, Colors.greenAccent) ||
      matches(color, WaUi.accent) ||
      matches(color, const Color(0xFF2E7D32)) ||
      matches(color, const Color(0xFF43A047))) {
    return AppToastKind.success;
  }
  if (matches(color, Colors.red) ||
      matches(color, Colors.redAccent) ||
      matches(color, AuthUi.error) ||
      matches(color, const Color(0xFFC62828)) ||
      matches(color, const Color(0xFFB00020))) {
    return AppToastKind.error;
  }
  if (matches(color, Colors.orange) ||
      matches(color, Colors.orangeAccent) ||
      matches(color, Colors.amber) ||
      matches(color, const Color(0xFFF59E0B))) {
    return AppToastKind.warning;
  }
  return AppToastKind.info;
}

/// Show the canonical app toast. Clears any existing snackbar first.
void showAppToast(
  BuildContext context,
  String message, {
  AppToastKind kind = AppToastKind.info,
  Duration duration = const Duration(seconds: 3),
  EdgeInsetsGeometry? margin,
  bool clearExisting = true,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  showAppToastMessenger(
    ScaffoldMessenger.of(context),
    message,
    kind: kind,
    duration: duration,
    margin: margin,
    clearExisting: clearExisting,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}

/// Same as [showAppToast] but safe after `await` when [BuildContext] may be unmounted.
void showAppToastMessenger(
  ScaffoldMessengerState messenger,
  String message, {
  AppToastKind kind = AppToastKind.info,
  Duration duration = const Duration(seconds: 3),
  EdgeInsetsGeometry? margin,
  bool clearExisting = true,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  if (clearExisting) messenger.clearSnackBars();
  messenger.showSnackBar(
    appToastSnackBar(
      message,
      kind: kind,
      duration: duration,
      margin: margin,
      actionLabel: actionLabel,
      onAction: onAction,
    ),
  );
}

/// Convenience wrappers.
void showSuccessToast(BuildContext context, String message, {Duration? duration}) =>
    showAppToast(
      context,
      message,
      kind: AppToastKind.success,
      duration: duration ?? const Duration(seconds: 3),
    );

void showErrorToast(BuildContext context, String message, {Duration? duration}) =>
    showAppToast(
      context,
      message,
      kind: AppToastKind.error,
      duration: duration ?? const Duration(seconds: 3),
    );

void showWarningToast(BuildContext context, String message, {Duration? duration}) =>
    showAppToast(
      context,
      message,
      kind: AppToastKind.warning,
      duration: duration ?? const Duration(seconds: 3),
    );

void showInfoToast(BuildContext context, String message, {Duration? duration}) =>
    showAppToast(
      context,
      message,
      kind: AppToastKind.info,
      duration: duration ?? const Duration(seconds: 3),
    );
