import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/stored_account.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/screens/linked_devices/qr_login_screen.dart';
import 'package:tapni_app/screens/phone_auth_screen.dart';
import 'package:tapni_app/screens/splash_screen.dart';
import 'package:tapni_app/services/push_notification_service.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/alert.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';

class AccountSwitcherSheet {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _AccountSwitcherBody(hostContext: context),
    );
  }
}

class _AccountSwitcherBody extends StatelessWidget {
  _AccountSwitcherBody({required this.hostContext});

  /// Context of the screen that opened the sheet (stays mounted after pop).
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final accounts = auth.accounts;
    final activeId = auth.activeAccount?.userId;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BarqodyChrome.sheetRadius),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetDragHandle(),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleBackButton(onTap: () => Navigator.pop(context)),
                  Expanded(
                    child: Text(
                      context.l10n.accounts,
                      textAlign: TextAlign.center,
                      style: WaUi.toolsTitleOf(
                        size: 18,
                        weight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ...accounts.map((account) {
                      final selected = account.userId == activeId;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AccountCard(
                          account: account,
                          selected: selected,
                          onTap: selected
                              ? () => Navigator.pop(context)
                              : () => _switch(context, account),
                        ),
                      );
                    }),
                    _AddAccountCard(onTap: () => _addAccount(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _switch(BuildContext sheetContext, StoredAccount account) async {
    Navigator.pop(sheetContext);

    final nav = PushNotificationService.navigatorKey.currentState;
    final navContext = PushNotificationService.navigatorKey.currentContext;
    final ctx = hostContext.mounted
        ? hostContext
        : (navContext != null && navContext.mounted ? navContext : null);
    if (ctx == null) return;

    final auth = Provider.of<AuthProvider>(ctx, listen: false);
    var ok = false;
    try {
      ok = await auth.switchAccount(account.userId, ctx);
    } catch (_) {
      ok = false;
    }

    if (ok) {
      (nav ?? Navigator.of(ctx)).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (_) => false,
      );
      return;
    }

    if (ctx.mounted) {
      ShowAlert.error(
        message: ctx.l10n.couldNotSwitchAccount,
        context: ctx,
      );
    }
  }

  void _addAccount(BuildContext sheetContext) {
    Navigator.pop(sheetContext);
    if (!hostContext.mounted) return;

    showModalBottomSheet(
      context: hostContext,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => _AddAccountOptionsSheet(hostContext: hostContext),
    );
  }
}

class _AddAccountOptionsSheet extends StatelessWidget {
  final BuildContext hostContext;

  const _AddAccountOptionsSheet({required this.hostContext});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BarqodyChrome.sheetRadius),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetDragHandle(),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleBackButton(onTap: () => Navigator.pop(context)),
                  Expanded(
                    child: Text(
                      hostContext.l10n.accounts,
                      textAlign: TextAlign.center,
                      style: WaUi.toolsTitleOf(
                        size: 18,
                        weight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 8),
              _SheetOptionTile(
                asset: 'assets/images/png/qr-code-icon.png',
                title: hostContext.l10n.scanQRShowQR,
                subtitle: hostContext.l10n.linkByQROnAnotherPhone,
                onTap: () {
                  Navigator.pop(context);
                  if (!hostContext.mounted) return;
                  Navigator.of(hostContext).push(
                    MaterialPageRoute(
                      builder: (_) => QrLoginScreen(addAccount: true),
                    ),
                  );
                },
              ),
              _SheetOptionTile(
                asset: 'assets/images/png/phone-icon.png',
                title: hostContext.l10n.phoneNumber2,
                onTap: () {
                  Navigator.pop(context);
                  if (!hostContext.mounted) return;
                  Navigator.of(hostContext).push(
                    MaterialPageRoute(
                      builder: (_) => const PhoneAuthScreen(addAccount: true),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final StoredAccount account;
  final bool selected;
  final VoidCallback onTap;

  const _AccountCard({
    required this.account,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = account.username != null && account.username!.isNotEmpty
        ? '@${account.username}'
        : account.email;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black, width: 1.2),
          ),
          child: Row(
            children: [
              _Avatar(account: account),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.displayName,
                      style: WaUi.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: WaUi.caption.copyWith(
                          color: BarqodyChrome.secondaryText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/png/check-icon.png',
                    width: 12,
                    height: 12,
                    color: Colors.white,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddAccountCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddAccountCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/png/plus-icon.png',
                  width: 16,
                  height: 16,
                  color: Colors.white,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.addAccount,
                      style: WaUi.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.emailLoginOrScanQR,
                      style: WaUi.caption.copyWith(
                        color: BarqodyChrome.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetOptionTile extends StatelessWidget {
  final String asset;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SheetOptionTile({
    required this.asset,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            AssetIcon(asset, size: 26, color: Colors.black),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: WaUi.body.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: WaUi.caption.copyWith(
                        color: BarqodyChrome.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: BarqodyChrome.secondaryText,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.account});
  final StoredAccount account;

  @override
  Widget build(BuildContext context) {
    final photo = account.profilePhoto;
    if (photo != null && photo.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(photo),
        backgroundColor: BarqodyChrome.circleBtn,
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: BarqodyChrome.circleBtn,
      child: Text(
        account.initials,
        style: WaUi.avatarInitial.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
