import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/utils/app_motion.dart';

/// Logout confirmation modal matching Tools redesign.
class LogoutConfirmDialog extends StatefulWidget {
  final bool hasOtherAccounts;
  final Future<void> Function() onLogoutThis;
  final Future<void> Function()? onLogoutAll;

  const LogoutConfirmDialog({
    super.key,
    required this.hasOtherAccounts,
    required this.onLogoutThis,
    this.onLogoutAll,
  });

  static Future<void> show(
    BuildContext context, {
    required bool hasOtherAccounts,
    required Future<void> Function() onLogoutThis,
    Future<void> Function()? onLogoutAll,
  }) {
    return showAppDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => LogoutConfirmDialog(
        hasOtherAccounts: hasOtherAccounts,
        onLogoutThis: onLogoutThis,
        onLogoutAll: onLogoutAll,
      ),
    );
  }

  @override
  State<LogoutConfirmDialog> createState() => _LogoutConfirmDialogState();
}

class _LogoutConfirmDialogState extends State<LogoutConfirmDialog> {
  bool _busy = false;
  _LogoutAction? _active;

  Future<void> _run(_LogoutAction action, Future<void> Function() work) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _active = action;
    });
    try {
      await work();
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _active = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Dialog(
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
                child: IgnorePointer(
                  ignoring: _busy,
                  child: Opacity(
                    opacity: _busy ? 0.35 : 1,
                    child: CircleCloseButton(
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
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
                widget.hasOtherAccounts
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
                enabled: !_busy,
                onPressed: () => Navigator.of(context).pop(),
              ),
              if (widget.hasOtherAccounts && widget.onLogoutAll != null) ...[
                const SizedBox(height: 14),
                PillButton(
                  label: context.l10n.logOutAll,
                  filled: false,
                  enabled: !_busy,
                  loading: _active == _LogoutAction.all,
                  onPressed: () => _run(
                    _LogoutAction.all,
                    widget.onLogoutAll!,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              PillButton(
                label: widget.hasOtherAccounts
                    ? context.l10n.thisAccount
                    : context.l10n.logOut2,
                enabled: !_busy,
                loading: _active == _LogoutAction.thisAccount,
                onPressed: () => _run(
                  _LogoutAction.thisAccount,
                  widget.onLogoutThis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _LogoutAction { thisAccount, all }
