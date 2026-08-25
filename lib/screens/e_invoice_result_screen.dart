import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/utils/zatca_qr_parser.dart';
import 'package:url_launcher/url_launcher.dart';

class EInvoiceResultScreen extends StatelessWidget {
  final ZatcaInvoice invoice;

  const EInvoiceResultScreen({super.key, required this.invoice});

  static const Color _successGreen = Color(0xFF22C55E);
  static const Color _badgeGreen = Color(0xFF86EFAC);
  static const Color _errorRed = Color(0xFFEF4444);
  static const Color _badgeRed = Color(0xFFFECACA);
  static const Color _cardBg = Color(0xFFF3F4F6);
  static const Color _labelGray = Color(0xFF9CA3AF);

  static const String _zatcaLookupAr =
      'https://zatca.gov.sa/ar/eServices/Pages/TaxpayerLookup.aspx';
  static const String _zatcaReportAr =
      'https://zatca.gov.sa/ar/eServices/Pages/SubmitaReport.aspx';

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

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _shareText(BuildContext context) {
    final l10n = context.l10n;
    final buffer = StringBuffer()
      ..writeln(l10n.saudiEInvoiceShareHeader)
      ..writeln(l10n.sellerColon(invoice.sellerName))
      ..writeln(l10n.vatColon(invoice.vatNumber))
      ..writeln(l10n.dateColon(_displayTimestamp()))
      ..writeln(l10n.totalColon(invoice.invoiceTotal))
      ..writeln(l10n.vatColon('${invoice.vatTotal} SAR'));
    return buffer.toString();
  }

  /// Show the QR wall-clock time as encoded (ZATCA ISO-8601), without
  /// converting UTC → device local. That extra +3h was turning
  /// `21:51 31/07/2026` into `00:51 01/08/2026`.
  String _displayTimestamp() {
    final raw = invoice.timestamp.trim();
    if (raw.isEmpty) return '—';

    final match = RegExp(
      r'(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})',
    ).firstMatch(raw);
    if (match != null) {
      final yyyy = match.group(1)!;
      final mm = match.group(2)!;
      final dd = match.group(3)!;
      final hh = match.group(4)!;
      final min = match.group(5)!;
      return '$hh:$min $dd/$mm/$yyyy';
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      final dd = parsed.day.toString().padLeft(2, '0');
      final mm = parsed.month.toString().padLeft(2, '0');
      final yyyy = parsed.year.toString();
      final hh = parsed.hour.toString().padLeft(2, '0');
      final min = parsed.minute.toString().padLeft(2, '0');
      return '$hh:$min $dd/$mm/$yyyy';
    }
    return raw;
  }

  /// Official KSA invoice apps always use Tajawal, even if the rest of
  /// the app is in English.
  static TextStyle _style({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = Colors.black87,
    double height = 1.4,
  }) {
    final resolved = weight == FontWeight.w600 ? FontWeight.w700 : weight;
    return GoogleFonts.tajawal(
      fontSize: size,
      fontWeight: resolved,
      color: color,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Localizations.override(
      context: context,
      locale: const Locale('ar'),
      child: Builder(
        builder: (context) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: _buildArabicScaffold(context),
          );
        },
      ),
    );
  }

  Widget _buildArabicScaffold(BuildContext context) {
    final l10n = context.l10n;
    final timestamp = _displayTimestamp();
    final isValid = invoice.isValidTaxInvoice;
    final statusColor = isValid ? _successGreen : _errorRed;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          l10n.eInvoiceVerification,
          style: _style(
            size: 16,
            weight: FontWeight.w500)),
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop()),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: statusColor, width: 5),
              ),
              child: Icon(
                isValid ? Icons.check_rounded : Icons.close_rounded,
                color: statusColor,
                size: 52,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isValid ? l10n.validTaxInvoice : l10n.invalidTaxInvoice,
            textAlign: TextAlign.center,
            style: _style(
              size: 22,
              weight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isValid
                          ? _badgeGreen.withValues(alpha: 0.55)
                          : _badgeRed,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isValid
                          ? l10n.invoiceRegistered
                          : l10n.invoiceNotRegistered,
                      style: _style(
                        size: 12,
                        weight: FontWeight.w500,
                        color: isValid
                            ? const Color(0xFF166534)
                            : const Color(0xFF991B1B),
                      ),
                    ),
                  ),
                ),
                if (invoice.sellerName.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    invoice.sellerName,
                    textAlign: TextAlign.start,
                    style: _style(
                      size: 18,
                      weight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.black.withValues(alpha: 0.08),
                ),
                const SizedBox(height: 16),
                _DetailField(
                  label: l10n.vatRegistrationNumber,
                  value: invoice.vatNumber,
                ),
                const SizedBox(height: 16),
                _DetailField(
                  label: l10n.invoiceDateTime,
                  value: timestamp,
                ),
                const SizedBox(height: 16),
                _DetailField(
                  label: l10n.invoiceTotalWithTax,
                  value: invoice.invoiceTotal,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (isValid) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: () => _copy(context, _shareText(context)),
                icon: const Icon(Icons.copy_rounded, size: 20),
                label: Text(
                  l10n.copyAllDetails,
                  style: _style(
                    size: 16,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _successGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => Share.share(_shareText(context)),
                icon: const Icon(Icons.share_outlined, size: 20),
                label: Text(
                  l10n.share,
                  style: _style(
                    size: 16,
                    weight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () => _openUrl(_zatcaLookupAr),
                child: Text(
                  l10n.verifyVatRegistration,
                  style: _style(
                    size: 15,
                    weight: FontWeight.w500,
                    color: const Color(0xFF166534),
                  ),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () => _openUrl(_zatcaReportAr),
                style: FilledButton.styleFrom(
                  backgroundColor: _successGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.submitVatReport,
                  style: _style(
                    size: 16,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => _openUrl(_zatcaLookupAr),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.verifyVatRegistration,
                  style: _style(
                    size: 15,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  final String label;
  final String value;

  const _DetailField({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: EInvoiceResultScreen._style(
            size: 13,
            weight: FontWeight.w400,
            color: EInvoiceResultScreen._labelGray,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: EInvoiceResultScreen._style(
            size: 16,
            weight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
