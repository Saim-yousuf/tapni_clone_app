import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class BankDetailDialog extends StatelessWidget {
  final Map<String, dynamic> bankDetails;
  final String? title;

  const BankDetailDialog({
    super.key,
    required this.bankDetails,
    this.title,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> bankDetails,
    String? title,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => BankDetailDialog(
        bankDetails: bankDetails,
        title: title,
      ),
    );
  }

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
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: WaUi.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: BarqodyChrome.secondaryText,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value.isEmpty ? '-' : value,
                  style: WaUi.body.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _copy(context, value),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                'assets/images/png/copy-icon.png',
                width: 18,
                height: 18,
                color: Colors.black,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _divider = Divider(
    height: 1,
    thickness: 1,
    color: Color(0xFFE8E8E8),
  );

  @override
  Widget build(BuildContext context) {
    final sheetTitle = title?.trim().isNotEmpty == true
        ? title!.trim()
        : context.l10n.bankDetails;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(BarqodyChrome.sheetRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPad > 0 ? 0 : 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const SheetDragHandle(),
              const SizedBox(height: 14),
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
              _divider,
              _buildRow(
                context,
                'Account Holder Name',
                bankDetails['accountHolderName']?.toString() ?? '',
              ),
              _divider,
              _buildRow(
                context,
                'Account Iban',
                bankDetails['iban']?.toString() ?? '',
              ),
              _divider,
              _buildRow(
                context,
                'Account Number',
                bankDetails['accountNumber']?.toString() ?? '',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
                child: PillButton(
                  label: context.l10n.copyAllDetails,
                  onPressed: () => _copyAll(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
