import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/providers/locale_provider.dart';
import 'package:tapni_app/services/caller_id_service.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class CallerIdSetupScreen extends StatefulWidget {
  const CallerIdSetupScreen({super.key});

  @override
  State<CallerIdSetupScreen> createState() => _CallerIdSetupScreenState();
}

class _CallerIdSetupScreenState extends State<CallerIdSetupScreen>
    with WidgetsBindingObserver {
  static const _cardBg = Color(0xFFF5F5F5);
  static const _muted = Color(0xFF8E8E93);
  static const _toggleActive = Color(0xFF2C2C2E);

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

  bool get _needsPermissions => !_phoneOk || !_overlayOk || !_roleOk;

  @override
  Widget build(BuildContext context) {
    if (!CallerIdService.isSupported) {
      return Scaffold(
        backgroundColor: BarqodyChrome.scaffold,
        body: SafeArea(
          child: Column(
            children: [
              BarqodyTitleBar(title: context.l10n.callerIdTitle),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Center(
                    child: Text(
                      context.l10n.callerIdAndroidOnly,
                      style: WaUi.body.copyWith(color: BarqodyChrome.secondaryText),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BarqodyTitleBar(title: context.l10n.callerIdTitle),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.black,
                      ),
                    )
                  : _enabled
                      ? _buildActiveView()
                      : _buildEnableView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnableView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              BarqodyChrome.sidePad,
              28,
              BarqodyChrome.sidePad,
              16,
            ),
            child: Column(
              children: [
                const _CallerIdHero(),
                const SizedBox(height: 28),
                Text(
                  context.l10n.callerIdTitle,
                  textAlign: TextAlign.center,
                  style: WaUi.toolsTitleOf(
                    size: 28,
                    weight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Know who’s calling before you answer',
                  textAlign: TextAlign.center,
                  style: WaUi.body.copyWith(
                    fontSize: 15,
                    color: _muted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFEAEAEA)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Instant Verification',
                              style: WaUi.bodyMedium.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Secure identification for recognized personal and bussiness callers.',
                              style: WaUi.body.copyWith(
                                fontSize: 13,
                                color: _muted,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const _ShieldCheckIcon(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BarqodyChrome.sidePad,
            8,
            BarqodyChrome.sidePad,
            16,
          ),
          child: PillButton(
            label: _busy ? '…' : 'Enable Caller ID',
            enabled: !_busy,
            onPressed: () => _toggle(true),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        BarqodyChrome.sidePad,
        20,
        BarqodyChrome.sidePad,
        28,
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Caller ID',
                      style: WaUi.bodyMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Identify incoming calls with barqody',
                      style: WaUi.caption.copyWith(
                        fontSize: 13,
                        color: _muted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Switch.adaptive(
                value: _enabled,
                activeThumbColor: Colors.white,
                activeTrackColor: _toggleActive,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFD1D1D6),
                onChanged: _busy ? null : _toggle,
              ),
            ],
          ),
        ),
        if (_needsPermissions) ...[
          const SizedBox(height: 24),
          Text(
            'Permissions',
            style: WaUi.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _muted,
            ),
          ),
          const SizedBox(height: 8),
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
      ],
    );
  }
}

class _CallerIdHero extends StatelessWidget {
  const _CallerIdHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/images/png/account-icon.png',
            width: 128,
            height: 128,
            color: Colors.black,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.person_rounded,
              size: 128,
              color: Colors.black,
            ),
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/png/phone-icon.png',
                  width: 24,
                  height: 24,
                  color: Colors.white,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.phone_rounded,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShieldCheckIcon extends StatelessWidget {
  const _ShieldCheckIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.shield_rounded,
            size: 40,
            color: Colors.black.withValues(alpha: 0.92),
          ),
          Image.asset(
            'assets/images/png/check-icon-1.png',
            width: 14,
            height: 14,
            color: Colors.white,
            errorBuilder: (_, _, _) => const Icon(
              Icons.check_rounded,
              size: 16,
              color: Colors.white,
            ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: WaUi.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  if (!granted) ...[
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.callerIdPermissionNeeded,
                      style: WaUi.caption.copyWith(
                        fontSize: 12,
                        color: BarqodyChrome.secondaryText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (granted)
              const Icon(Icons.check_circle, color: Colors.black, size: 22)
            else
              TextButton(
                onPressed: onGrant,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  context.l10n.grantPermission,
                  style: WaUi.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
