import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/utils/general_qr_parser.dart';
import 'package:url_launcher/url_launcher.dart';

class GeneralQrResultScreen extends StatelessWidget {
  final String rawValue;

  const GeneralQrResultScreen({super.key, required this.rawValue});

  GeneralQrResult get _result => GeneralQrParser.parse(rawValue);

  Future<void> _copy(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.copiedToClipboard),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _launchResult(BuildContext context, GeneralQrResult result) async {
    final uri = result.launchUri;
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.couldNotOpenLink),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  IconData _iconFor(GeneralQrType type) {
    switch (type) {
      case GeneralQrType.url:
        return Icons.link_rounded;
      case GeneralQrType.wifi:
        return Icons.wifi_rounded;
      case GeneralQrType.email:
        return Icons.email_outlined;
      case GeneralQrType.phone:
        return Icons.phone_outlined;
      case GeneralQrType.sms:
        return Icons.sms_outlined;
      case GeneralQrType.text:
        return Icons.qr_code_2_rounded;
    }
  }

  String _typeLabel(BuildContext context, GeneralQrType type) {
    final l10n = context.l10n;
    switch (type) {
      case GeneralQrType.url:
        return l10n.qrTypeWebsite;
      case GeneralQrType.wifi:
        return l10n.qrTypeWifi;
      case GeneralQrType.email:
        return l10n.qrTypeEmail;
      case GeneralQrType.phone:
        return l10n.qrTypePhone;
      case GeneralQrType.sms:
        return l10n.qrTypeSms;
      case GeneralQrType.text:
        return l10n.qrTypeText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final wifi = result.wifi;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(context.l10n.scannedQr),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF2F80ED).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconFor(result.type),
                size: 36,
                color: const Color(0xFF2F80ED),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _typeLabel(context, result.type),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.qrScanResultSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 24),
          if (wifi != null) ...[
            _InfoTile(
              label: context.l10n.wifiNetwork,
              value: wifi.ssid,
              onCopy: () => _copy(context, wifi.ssid),
            ),
            _InfoTile(
              label: context.l10n.wifiPassword,
              value: wifi.password.isEmpty ? '—' : wifi.password,
              onCopy: wifi.password.isEmpty
                  ? null
                  : () => _copy(context, wifi.password),
            ),
            _InfoTile(
              label: context.l10n.wifiSecurity,
              value: wifi.security,
            ),
            const SizedBox(height: 8),
          ],
          _InfoTile(
            label: context.l10n.scannedContent,
            value: result.rawValue,
            onCopy: () => _copy(context, result.rawValue),
          ),
          const SizedBox(height: 28),
          if (result.type == GeneralQrType.url)
            _ActionButton(
              icon: Icons.open_in_browser_rounded,
              label: context.l10n.openLink,
              onTap: () => _launchResult(context, result),
            ),
          if (result.type == GeneralQrType.email)
            _ActionButton(
              icon: Icons.email_outlined,
              label: context.l10n.openEmail,
              onTap: () => _launchResult(context, result),
            ),
          if (result.type == GeneralQrType.phone)
            _ActionButton(
              icon: Icons.phone_outlined,
              label: context.l10n.callNumber,
              onTap: () => _launchResult(context, result),
            ),
          if (result.type == GeneralQrType.sms)
            _ActionButton(
              icon: Icons.sms_outlined,
              label: context.l10n.sendSms,
              onTap: () => _launchResult(context, result),
            ),
          _ActionButton(
            icon: Icons.copy_rounded,
            label: context.l10n.copyContent,
            outlined: true,
            onTap: () => _copy(context, result.rawValue),
          ),
          _ActionButton(
            icon: Icons.share_outlined,
            label: context.l10n.share,
            outlined: true,
            onTap: () => Share.share(result.rawValue),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onCopy;

  const _InfoTile({
    required this.label,
    required this.value,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              onPressed: onCopy,
              icon: const Icon(Icons.copy_rounded, size: 18),
              color: Colors.black54,
              tooltip: context.l10n.copyContent,
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool outlined;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: outlined
            ? OutlinedButton.icon(
                onPressed: onTap,
                icon: Icon(icon, size: 20),
                label: Text(label),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.black.withValues(alpha: 0.15)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            : FilledButton.icon(
                onPressed: onTap,
                icon: Icon(icon, size: 20),
                label: Text(label),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2F80ED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
      ),
    );
  }
}
