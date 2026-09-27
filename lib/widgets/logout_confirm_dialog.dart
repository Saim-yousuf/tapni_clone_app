import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// Logout confirmation modal matching Tools redesign.
class LogoutConfirmDialog extends StatelessWidget {
  final bool hasOtherAccounts;
  final VoidCallback onLogoutThis;
  final VoidCallback? onLogoutAll;

  const LogoutConfirmDialog({
    super.key,
    required this.hasOtherAccounts,
    required this.onLogoutThis,
    this.onLogoutAll,
  });

  static Future<void> show(
    BuildContext context, {
    required bool hasOtherAccounts,
    required VoidCallback onLogoutThis,
    VoidCallback? onLogoutAll,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => LogoutConfirmDialog(
        hasOtherAccounts: hasOtherAccounts,
        onLogoutThis: onLogoutThis,
        onLogoutAll: onLogoutAll,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(BarqodyChrome.modalRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: CircleCloseButton(
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(height: 8),
            AssetIcon(
              'assets/images/png/logout-icon.png',
              size: 88,
              color: Colors.black,
            ),
            const SizedBox(height: 24),
            Text(
              hasOtherAccounts
                  ? context
                      .l10n
                      .logOutOfThisAccountOnlyOtherAccountsWillStayOnThisPhone
                  : 'Are you sure you want to LogOut?',
              textAlign: TextAlign.center,
              style: WaUi.toolsTitleOf(
                size: 20,
                weight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 32),
            PillButton(
              label: context.l10n.cancel,
              filled: false,
              onPressed: () => Navigator.of(context).pop(),
            ),
            if (hasOtherAccounts && onLogoutAll != null) ...[
              const SizedBox(height: 14),
              PillButton(
                label: context.l10n.logOutAll,
                filled: false,
                onPressed: () {
                  Navigator.of(context).pop();
                  onLogoutAll!();
                },
              ),
            ],
            const SizedBox(height: 14),
            PillButton(
              label: hasOtherAccounts
                  ? context.l10n.thisAccount
                  : context.l10n.logOut2,
              onPressed: () {
                Navigator.of(context).pop();
                onLogoutThis();
              },
            ),
          ],
        ),
      ),
    );
  }
}
