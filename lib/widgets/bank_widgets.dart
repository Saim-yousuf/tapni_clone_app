import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class BankDetailDialog extends StatelessWidget {
  final Map<String, dynamic> bankDetails;
  final String? title;

  BankDetailDialog({super.key, required this.bankDetails, this.title});

  void _copy(BuildContext context, String value) {
    if (value.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.copied)),
    );
  }

  void _copyAll(BuildContext context) {
    final holder = bankDetails['accountHolderName']?.toString() ?? '';
    final iban = bankDetails['iban']?.toString() ?? '';
    final account = bankDetails['accountNumber']?.toString() ?? '';
    final buffer = StringBuffer();
    if (holder.isNotEmpty) buffer.writeln('Account Holder Name: $holder');
    if (iban.isNotEmpty) buffer.writeln('Account Iban: $iban');
    if (account.isNotEmpty) buffer.writeln('Account Number: $account');
    final text = buffer.toString().trim();
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.copied)),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: WaUi.label.copyWith(
                    fontSize: 12,
                    color: BarqodyChrome.secondaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value.isEmpty ? '-' : value,
                  style: WaUi.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _copy(context, value),
            child: Image.asset(
              'assets/images/png/copy-icon.png',
              width: 20,
              height: 20,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.copy_rounded,
                size: 20,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sheetTitle = title?.trim().isNotEmpty == true
        ? title!.trim()
        : context.l10n.bankDetails;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(BarqodyChrome.modalRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            const SheetDragHandle(),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    CircleBackButton(
                      onTap: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        sheetTitle,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
              ),
            ),
            const SizedBox(height: 8),
            _buildRow(
              context,
              'Account Holder Name',
              bankDetails['accountHolderName']?.toString() ?? '',
            ),
            const Divider(height: 1, color: BarqodyChrome.divider),
            _buildRow(
              context,
              'Account Iban',
              bankDetails['iban']?.toString() ?? '',
            ),
            const Divider(height: 1, color: BarqodyChrome.divider),
            _buildRow(
              context,
              'Account Number',
              bankDetails['accountNumber']?.toString() ?? '',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: PillButton(
                label: context.l10n.copyAllDetails,
                onPressed: () => _copyAll(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
