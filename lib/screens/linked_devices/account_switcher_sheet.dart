import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/stored_account.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/screens/linked_devices/qr_login_screen.dart';
import 'package:tapni_app/screens/login_screen.dart';
import 'package:tapni_app/screens/main_shell.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/alert.dart';

class AccountSwitcherSheet {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: WaUi.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _AccountSwitcherBody(hostContext: context),
    );
  }
}

class _AccountSwitcherBody extends StatelessWidget {
  const _AccountSwitcherBody({required this.hostContext});

  /// Context of the screen that opened the sheet (stays mounted after pop).
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final accounts = auth.accounts;
    final activeId = auth.activeAccount?.userId;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: WaUi.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Accounts', style: WaUi.headline),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ...accounts.map((account) {
                    final selected = account.userId == activeId;
                    return ListTile(
                      leading: _Avatar(account: account),
                      title: Text(account.displayName, style: WaUi.listTitle),
                      subtitle: Text(
                        account.username != null && account.username!.isNotEmpty
                            ? '@${account.username}'
                            : account.email,
                        style: WaUi.listSubtitle,
                      ),
                      trailing: selected
                          ? const Icon(Icons.check_circle, color: WaUi.accent)
                          : null,
                      onTap: selected
                          ? () => Navigator.pop(context)
                          : () => _switch(context, account),
                    );
                  }),
                  const Divider(),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: WaUi.navPill,
                      child: const Icon(Icons.add, color: WaUi.promoIconFg),
                    ),
                    title: Text('Add account', style: WaUi.listTitle),
                    subtitle: Text(
                      'Email login or scan QR',
                      style: WaUi.listSubtitle,
                    ),
                    onTap: () => _addAccount(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _switch(BuildContext sheetContext, StoredAccount account) async {
    Navigator.pop(sheetContext);
    if (!hostContext.mounted) return;

    final auth = Provider.of<AuthProvider>(hostContext, listen: false);
    final ok = await auth.switchAccount(account.userId, hostContext);
    if (!hostContext.mounted) return;

    if (ok) {
      ShowAlert.success(
        message: 'Switched to ${account.displayName}',
        context: hostContext,
      );
      Navigator.of(hostContext).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    } else {
      ShowAlert.error(
        message: 'Could not switch account',
        context: hostContext,
      );
    }
  }

  void _addAccount(BuildContext sheetContext) {
    Navigator.pop(sheetContext);
    if (!hostContext.mounted) return;

    showModalBottomSheet(
      context: hostContext,
      backgroundColor: WaUi.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.qr_code_2, color: WaUi.promoIconFg),
              title: Text('Scan QR / show QR', style: WaUi.listTitle),
              subtitle: Text(
                'Link by QR on another phone',
                style: WaUi.listSubtitle,
              ),
              onTap: () {
                Navigator.pop(ctx);
                if (!hostContext.mounted) return;
                Navigator.of(hostContext).push(
                  MaterialPageRoute(
                    builder: (_) => const QrLoginScreen(addAccount: true),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.email_outlined, color: WaUi.promoIconFg),
              title: Text('Email & password', style: WaUi.listTitle),
              onTap: () {
                Navigator.pop(ctx);
                if (!hostContext.mounted) return;
                Navigator.of(hostContext).push(
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(addAccount: true),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
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
        backgroundImage: NetworkImage(photo),
        backgroundColor: WaUi.navPill,
      );
    }
    return CircleAvatar(
      backgroundColor: WaUi.navPill,
      child: Text(account.initials, style: WaUi.avatarInitial),
    );
  }
}
