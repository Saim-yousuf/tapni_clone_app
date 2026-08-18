import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/providers/locale_provider.dart';
import 'package:tapni_app/services/caller_id_service.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:provider/provider.dart';

class CallerIdSetupScreen extends StatefulWidget {
  const CallerIdSetupScreen({super.key});

  @override
  State<CallerIdSetupScreen> createState() => _CallerIdSetupScreenState();
}

class _CallerIdSetupScreenState extends State<CallerIdSetupScreen>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool _phoneOk = false;
  bool _overlayOk = false;
  bool _roleOk = false;
  bool _enabled = false;
  bool _busy = false;
  bool _pendingEnable = false;
  bool _didAutoRequest = false;

  String get _lang {
    final locale = context.read<LocaleProvider>().locale;
    return locale?.languageCode ?? 'en';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enabled = CallerIdService.isEnabled;
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    if (!CallerIdService.isSupported) {
      setState(() => _loading = false);
      return;
    }
    final phoneOk = await CallerIdService.hasPhonePermissions();
    final overlayOk = await CallerIdService.hasOverlayPermission();
    final roleOk = await CallerIdService.hasCallScreeningRole();
    if (_pendingEnable && phoneOk && overlayOk && roleOk) {
      if (!mounted) return;
      await CallerIdService.setEnabled(true, lang: _lang);
      _pendingEnable = false;
    }
    if (!mounted) return;
    setState(() {
      _phoneOk = phoneOk;
      _overlayOk = overlayOk;
      _roleOk = roleOk;
      _enabled = CallerIdService.isEnabled;
      _loading = false;
    });
    if (!_didAutoRequest &&
        CallerIdService.isEnabled &&
        (!phoneOk || !overlayOk || !roleOk)) {
      _didAutoRequest = true;
      _toggle(true);
    }
  }

  Future<void> _toggle(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (!value) {
        _pendingEnable = false;
        await CallerIdService.setEnabled(false, lang: _lang);
        await _refresh();
        return;
      }
      _pendingEnable = true;
      if (!_phoneOk) {
        await CallerIdService.requestPhonePermissions();
        await Future<void>.delayed(const Duration(milliseconds: 400));
        await _refresh();
        if (!_phoneOk) return;
      }
      if (!_overlayOk) {
        await CallerIdService.requestOverlayPermission();
        return;
      }
      if (!_roleOk) {
        await CallerIdService.requestCallScreeningRole();
        return;
      }
      await CallerIdService.setEnabled(true, lang: _lang);
      _pendingEnable = false;
      await _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!CallerIdService.isSupported) {
      return Scaffold(
        backgroundColor: WaUi.toolsScaffold,
        appBar: AppBar(
          backgroundColor: WaUi.toolsScaffold,
          elevation: 0,
          foregroundColor: WaUi.primaryText,
        ),
        body: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            context.l10n.callerIdAndroidOnly,
            style: WaUi.body.copyWith(color: WaUi.secondaryText),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      appBar: AppBar(
        backgroundColor: WaUi.toolsScaffold,
        elevation: 0,
        foregroundColor: WaUi.primaryText,
        title: Text(context.l10n.callerIdTitle, style: WaUi.title),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Text(
                  context.l10n.callerIdDisclosure,
                  style: WaUi.body.copyWith(color: WaUi.secondaryText),
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.callerIdMajorityHint,
                  style: WaUi.body.copyWith(color: WaUi.secondaryText),
                ),
                const SizedBox(height: 20),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.callerIdEnable, style: WaUi.listTitle),
                  subtitle: Text(
                    _enabled
                        ? context.l10n.callerIdEnabled
                        : context.l10n.callerIdDisabled,
                    style: WaUi.caption,
                  ),
                  value: _enabled,
                  activeColor: WaUi.accent,
                  onChanged: _busy ? null : _toggle,
                ),
                const Divider(height: 32),
                _PermissionRow(
                  label: context.l10n.callerIdPhonePermission,
                  granted: _phoneOk,
                  onGrant: () => _toggle(true),
                ),
                _PermissionRow(
                  label: context.l10n.callerIdOverlayPermission,
                  granted: _overlayOk,
                  onGrant: () => CallerIdService.requestOverlayPermission(),
                ),
                _PermissionRow(
                  label: context.l10n.callerIdScreeningRole,
                  granted: _roleOk,
                  onGrant: () => CallerIdService.requestCallScreeningRole(),
                ),
              ],
            ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.label,
    required this.granted,
    required this.onGrant,
  });

  final String label;
  final bool granted;
  final VoidCallback onGrant;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: WaUi.body),
      trailing: granted
          ? Icon(Icons.check_circle, color: WaUi.accent)
          : TextButton(
              onPressed: onGrant,
              child: Text(context.l10n.grantPermission),
            ),
      subtitle: granted
          ? null
          : Text(
              context.l10n.callerIdPermissionNeeded,
              style: WaUi.caption,
            ),
    );
  }
}
