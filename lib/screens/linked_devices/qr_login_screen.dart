import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/subscription_provider.dart';
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/screens/main_shell.dart';
import 'package:tapni_app/services/account_storage.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/alert.dart';

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
      deviceName: AccountStorage.defaultDeviceName(),
      platform: AccountStorage.devicePlatformLabel(),
    );

    if (!mounted) return;

    if (!res.success || res.data is! Map) {
      setState(() {
        _loading = false;
        _error = res.message ?? 'Could not create QR code';
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

    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    if (_code == null || _completing) return;

    if (_expiresAt != null && DateTime.now().isAfter(_expiresAt!)) {
      _pollTimer?.cancel();
      if (mounted) {
        setState(() => _error = 'QR code expired');
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
      setState(() => _error = 'QR code expired. Tap refresh.');
    }
  }

  Future<void> _onApproved(Map data) async {
    _completing = true;
    _pollTimer?.cancel();

    final token = data['token']?.toString() ?? '';
    final user = data['user'];
    if (token.isEmpty || user is! Map) {
      setState(() {
        _error = 'Login failed. Try again.';
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
        _error = 'Could not complete login';
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
      MaterialPageRoute(builder: (_) => const MainShell()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      appBar: AppBar(
        backgroundColor: WaUi.toolsScaffold,
        elevation: 0,
        foregroundColor: WaUi.primaryText,
        title: Text(
          widget.addAccount ? 'Add account' : 'Log in with QR',
          style: WaUi.headline,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text(
                'Use Barqody on your phone to scan this code',
                textAlign: TextAlign.center,
                style: WaUi.body.copyWith(color: WaUi.secondaryText),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: Center(
                  child: _buildQrArea(),
                ),
              ),
              if (_code != null && _error == null) ...[
                const SizedBox(height: 8),
                Text(
                  'Code: $_code',
                  style: WaUi.caption.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _code!));
                    ShowAlert.success(
                      message: 'Code copied',
                      context: context,
                    );
                  },
                  child: Text(
                    'Copy code',
                    style: WaUi.bodyMedium.copyWith(color: WaUi.accent),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              _howtoStep('1', 'Open Barqody on your other phone'),
              _howtoStep('2', 'Go to Tools → Linked devices'),
              _howtoStep('3', 'Tap Link a device and scan this QR'),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrArea() {
    if (_loading || _completing) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: WaUi.accent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _completing ? 'Logging you in…' : 'Preparing QR code…',
            style: WaUi.caption,
          ),
        ],
      );
    }

    if (_error != null || _qrPayload == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_2, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: WaUi.body,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _startPairing,
            icon: const Icon(Icons.refresh, color: WaUi.accent),
            label: Text(
              'Refresh QR',
              style: WaUi.bodyMedium.copyWith(color: WaUi.accent),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(WaUi.radiusLg),
        border: Border.all(color: WaUi.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: QrImageView(
        data: _qrPayload!,
        version: QrVersions.auto,
        size: 240,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: WaUi.primaryText,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: WaUi.primaryText,
        ),
      ),
    );
  }

  Widget _howtoStep(String n, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: WaUi.chipBg,
              shape: BoxShape.circle,
            ),
            child: Text(
              n,
              style: WaUi.label.copyWith(
                color: const Color(0xFF1FA855),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: WaUi.body)),
        ],
      ),
    );
  }
}
