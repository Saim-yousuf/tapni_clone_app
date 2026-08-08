import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/utils/zatca_qr_parser.dart';

class EInvoiceResultScreen extends StatelessWidget {
  final ZatcaInvoice invoice;

  const EInvoiceResultScreen({super.key, required this.invoice});

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

  String _shareText(BuildContext context) {
    final l10n = context.l10n;
    final buffer = StringBuffer()
      ..writeln(l10n.saudiEInvoiceShareHeader)
      ..writeln(l10n.sellerColon(invoice.sellerName))
      ..writeln(l10n.vatColon(invoice.vatNumber))
      ..writeln(l10n.dateColon(invoice.timestamp))
      ..writeln(l10n.totalColon('${invoice.invoiceTotal} SAR'))
      ..writeln(l10n.vatColon('${invoice.vatTotal} SAR'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.eInvoiceDetails),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B5E3C), Color(0xFF1A8A5A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.saudiEInvoice,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        invoice.isPhase2
                            ? l10n.zatcaPhase2Supported
                            : l10n.zatcaPhase1Invoice,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _FieldCard(
            label: l10n.sellerName,
            value: invoice.sellerName,
            onCopy: () => _copy(context, invoice.sellerName),
          ),
          _FieldCard(
            label: l10n.vatRegistrationNumber,
            value: invoice.vatNumber,
            onCopy: () => _copy(context, invoice.vatNumber),
          ),
          _FieldCard(
            label: l10n.invoiceDateTime,
            value: invoice.timestamp.isEmpty ? '—' : invoice.timestamp,
            onCopy: invoice.timestamp.isEmpty
                ? null
                : () => _copy(context, invoice.timestamp),
          ),
          Row(
            children: [
              Expanded(
                child: _FieldCard(
                  label: l10n.invoiceTotal,
                  value: '${invoice.invoiceTotal} SAR',
                  highlight: true,
                  onCopy: () => _copy(context, invoice.invoiceTotal),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FieldCard(
                  label: l10n.vatAmount,
                  value: invoice.vatTotal.isEmpty
                      ? '—'
                      : '${invoice.vatTotal} SAR',
                  onCopy: invoice.vatTotal.isEmpty
                      ? null
                      : () => _copy(context, invoice.vatTotal),
                ),
              ),
            ],
          ),
          if (invoice.invoiceHash != null &&
              invoice.invoiceHash!.isNotEmpty) ...[
            const SizedBox(height: 4),
            _FieldCard(
              label: l10n.invoiceHash,
              value: invoice.invoiceHash!,
              compact: true,
              onCopy: () => _copy(context, invoice.invoiceHash!),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () => _copy(context, _shareText(context)),
              icon: const Icon(Icons.copy_rounded, size: 20),
              label: Text(l10n.copyAllDetails),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0B5E3C),
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
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => Share.share(_shareText(context)),
              icon: const Icon(Icons.share_outlined, size: 20),
              label: Text(l10n.share),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: BorderSide(color: Colors.black.withValues(alpha: 0.15)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onCopy;
  final bool highlight;
  final bool compact;

  const _FieldCard({
    required this.label,
    required this.value,
    this.onCopy,
    this.highlight = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.fromLTRB(14, 12, onCopy != null ? 4 : 14, 12),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFF0B5E3C).withValues(alpha: 0.08)
            : const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(14),
        border: highlight
            ? Border.all(
                color: const Color(0xFF0B5E3C).withValues(alpha: 0.25),
              )
            : null,
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
                  maxLines: compact ? 3 : null,
                  style: TextStyle(
                    fontSize: highlight ? 17 : 15,
                    fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                    color: highlight
                        ? const Color(0xFF0B5E3C)
                        : Colors.black87,
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
            ),
        ],
      ),
    );
  }
}
