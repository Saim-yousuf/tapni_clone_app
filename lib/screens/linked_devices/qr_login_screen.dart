import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/subscription_provider.dart';
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/screens/main_shell.dart';
import 'package:tapni_app/services/account_storage.dart';
import 'package:tapni_app/utils/app_fonts.dart';
import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:tapni_app/widgets/alert.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/branded_qr_image.dart';
import 'package:tapni_app/widgets/profile_screen_shimmer.dart';

/// WhatsApp Web style: this device shows a QR, another logged-in phone scans it.
class QrLoginScreen extends StatefulWidget {
  const QrLoginScreen({super.key, this.addAccount = false});

  final bool addAccount;

  @override
  State<QrLoginScreen> createState() => _QrLoginScreenState();
}

class _QrLoginScreenState extends State<QrLoginScreen> {
  final AuthRepo _repo = AuthRepo();
  Timer? _pollTimer;
  String? _code;
  String? _qrPayload;
  DateTime? _expiresAt;
  bool _loading = true;
  String? _error;
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    _startPairing();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _startPairing() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    _pollTimer?.cancel();

    final res = await _repo.createDevicePairing(
      deviceName: await AccountStorage.defaultDeviceName(),
      platform: AccountStorage.devicePlatformLabel(),
      deviceKey: await AccountStorage.deviceKey(),
    );

    if (!mounted) return;

    if (!res.success || res.data is! Map) {
      setState(() {
        _loading = false;
        _error = res.message ?? context.l10n.couldNotCreateQRCode;
      });
      return;
    }

    final data = res.data as Map;
    setState(() {
      _loading = false;
      _code = data['code']?.toString();
      _qrPayload = data['qrPayload']?.toString() ??
          (data['code'] != null
              ? 'barqody://link-device?code=${data['code']}'
              : null);
      final exp = data['expiresAt']?.toString();
      _expiresAt = exp != null ? DateTime.tryParse(exp)?.toLocal() : null;
    });

    _pollTimer = Timer.periodic(Duration(seconds: 2), (_) {
      _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    if (_code == null || _completing) return;

    if (_expiresAt != null && DateTime.now().isAfter(_expiresAt!)) {
      _pollTimer?.cancel();
      if (mounted) {
        setState(() => _error = context.l10n.qrCodeExpired);
      }
      return;
    }

    final res = await _repo.getDevicePairingStatus(code: _code!);
    if (!mounted || !res.success || res.data is! Map) return;

    final data = res.data as Map;
    final status = data['status']?.toString();
    if (status == 'approved' && data['token'] != null) {
      await _onApproved(data);
    } else if (status == 'expired' || status == 'cancelled') {
      _pollTimer?.cancel();
      setState(() => _error = context.l10n.qrCodeExpiredTapRefresh);
    }
  }

  Future<void> _onApproved(Map data) async {
    _completing = true;
    _pollTimer?.cancel();

    final token = data['token']?.toString() ?? '';
    final user = data['user'];
    if (token.isEmpty || user is! Map) {
      setState(() {
        _error = context.l10n.loginFailedTryAgain;
        _completing = false;
      });
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await auth.loginWithLinkedDevice(
      token: token,
      user: Map<String, dynamic>.from(user),
      deviceSessionId: data['deviceSessionId']?.toString(),
      context: context,
    );

    if (!mounted) return;
    if (!ok) {
      setState(() {
        _error = context.l10n.couldNotCompleteLogin;
        _completing = false;
      });
      return;
    }

    final subProvider = Provider.of<SubscriptionProvider>(
      context,
      listen: false,
    );
    await subProvider.checkSubscriptionStatus();
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    await profileProvider.fetchProfile();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      AppPageRoute(builder: (_) => MainShell()),
      (_) => false,
    );
  }

  TextStyle _text(
    AuthScale m, {
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = AuthUi.textPrimary,
    double height = 1.2,
    double letterSpacing = 0,
  }) {
    return AppFonts.textStyle(
      fontSize: m.s(size),
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final title = widget.addAccount
        ? context.l10n.addAccount.toUpperCase()
        : 'LOGIN WITH QR';

    return Scaffold(
      backgroundColor: AuthUi.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Shared auth app bar (Login / OTP / QR) — bold ALL-CAPS title.
            AuthAppBarTitle(
              title,
              showBack: true,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  m.padH,
                  m.v(8),
                  m.padH,
                  m.v(24),
                ),
                child: Column(
                  children: [
                    Text(
                      context.l10n.useBarqodyOnYourPhoneToScanThisCode,
                      textAlign: TextAlign.center,
                      style: _text(
                        m,
                        size: AuthUi.bodySize,
                        color: AuthUi.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    SizedBox(height: m.v(40)),
                    _buildQrArea(m),
                    SizedBox(height: m.v(20)),
                    _buildCodeRow(m),
                    SizedBox(height: m.v(36)),
                    _howtoStep(m, '1', context.l10n.openBarqodyOnYourOtherPhone),
                    SizedBox(height: m.v(14)),
                    _howtoStep(m, '2', context.l10n.goToToolsLinkedDevices),
                    SizedBox(height: m.v(14)),
                    _howtoStep(
                      m,
                      '3',
                      context.l10n.tapLinkADeviceAndScanThisQR,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fixed footprint: loading / live / expired all share the same card size
  /// so expiry never collapses the layout.
  Widget _buildQrArea(AuthScale m) {
    final qrSize = m.s(240);
    final cardPad = m.s(18);
    final cardRadius = m.s(16);
    final cardSide = qrSize + cardPad * 2;
    final expired = _error != null;

    if (_loading || _completing) {
      return AppShimmer(
        child: ShimmerBox(
          width: cardSide,
          height: cardSide,
          borderRadius: cardRadius,
        ),
      );
    }

    return SizedBox(
      width: cardSide,
      height: cardSide,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AuthUi.bg,
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(color: AuthUi.border, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cardRadius),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_qrPayload != null)
                Padding(
                  padding: EdgeInsets.all(cardPad),
                  child: Opacity(
                    opacity: expired ? 0.18 : 1,
                    child: BrandedQrImage(
                      data: _qrPayload!,
                      size: qrSize,
                      backgroundColor: AuthUi.bg,
                      foregroundColor: AuthUi.textPrimary,
                    ),
                  ),
                ),
              if (expired)
                Positioned.fill(
                  child: ColoredBox(
                    color: AuthUi.bg.withValues(alpha: 0.72),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: m.s(20)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_2,
                            size: m.s(36),
                            color: AuthUi.textMuted,
                          ),
                          SizedBox(height: m.v(12)),
                          Text(
                            _error ?? context.l10n.somethingWentWrong,
                            textAlign: TextAlign.center,
                            style: _text(
                              m,
                              size: 14,
                              color: AuthUi.textSecondary,
                              height: 1.35,
                            ),
                          ),
                          SizedBox(height: m.v(14)),
                          GestureDetector(
                            onTap: _startPairing,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: m.s(8),
                                vertical: m.s(6),
                              ),
                              child: Text(
                                context.l10n.refreshQR,
                                style: _text(
                                  m,
                                  size: 15,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Same vertical space for code + action whether live, loading, or expired.
  Widget _buildCodeRow(AuthScale m) {
    if (_loading || _completing) {
      return AppShimmer(
        child: Column(
          children: [
            ShimmerBox(
              width: m.s(148),
              height: m.s(14),
              borderRadius: 6,
            ),
            SizedBox(height: m.v(10)),
            ShimmerBox(
              width: m.s(100),
              height: m.s(16),
              borderRadius: 6,
            ),
          ],
        ),
      );
    }

    if (_code == null) {
      return SizedBox(height: m.v(14) + m.s(16) + m.v(10) + m.s(28));
    }

    final expired = _error != null;
    return Column(
      children: [
        Text(
          context.l10n.codeWithValue(_code!),
          textAlign: TextAlign.center,
          style: _text(
            m,
            size: 14,
            color: AuthUi.textSecondary.withValues(alpha: expired ? 0.55 : 1),
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: m.v(8)),
        if (expired)
          GestureDetector(
            onTap: _startPairing,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: m.s(12),
                vertical: m.s(6),
              ),
              child: Text(
                context.l10n.refreshQR,
                textAlign: TextAlign.center,
                style: _text(
                  m,
                  size: 16,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          )
        else
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _code!));
              ShowAlert.success(
                message: context.l10n.codeCopied,
                context: context,
              );
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: m.s(12),
                vertical: m.s(6),
              ),
              child: Text(
                context.l10n.copyCode,
                textAlign: TextAlign.center,
                style: _text(
                  m,
                  size: 16,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _howtoStep(AuthScale m, String n, String text) {
    final circle = m.s(24);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: circle,
          height: circle,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AuthUi.textPrimary,
            shape: BoxShape.circle,
          ),
          child: Text(
            n,
            style: _text(
              m,
              size: 12,
              weight: FontWeight.w700,
              color: Colors.white,
              height: 1,
            ),
          ),
        ),
        SizedBox(width: m.s(12)),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: m.s(2)),
            child: Text(
              text,
              style: _text(
                m,
                size: AuthUi.bodySize,
                color: AuthUi.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
