import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/screens/quick_add_links_screen.dart';
import 'package:tapni_app/utils/app_fonts.dart';
import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class SubscriptionPurchasedScreen extends StatelessWidget {
  const SubscriptionPurchasedScreen({
    super.key,
    required this.planName,
    required this.planLabel,
    required this.amount,
    required this.currency,
    this.transactionId = '',
    this.startDate,
    this.endDate,
    this.fromRegistration = false,
  });

  final String planName;
  final String planLabel;
  final double amount;
  final String currency;
  final String transactionId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool fromRegistration;

  static const _muted = Color(0xFF8E8E93);
  static const _line = Color(0xFFE8E8E8);

  String _money(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  String _date(DateTime? value) {
    if (value == null) return '--';
    return '${value.day}/${value.month}/${value.year}';
  }

  String get _txnDisplay {
    final raw = transactionId.trim();
    if (raw.isEmpty) return '--';
    if (raw.startsWith('#')) return raw;
    if (raw.length <= 12) return '#$raw';
    return '#${raw.substring(raw.length - 10).toUpperCase()}';
  }

  Future<void> _onDone(BuildContext context) async {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    profileProvider.upgradeToPro();
    await profileProvider.fetchProfile();
    if (!context.mounted) return;

    if (fromRegistration) {
      Navigator.of(context).pushAndRemoveUntil(
        AppPageRoute(builder: (_) => const QuickAddLinksScreen()),
        (_) => false,
      );
      return;
    }

    // Clear subscription checkout from stack so home/settings see Pro state.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onDone(context);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BarqodyTitleBar(
                title: 'Purchased',
                onBack: () => _onDone(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    BarqodyChrome.sidePad,
                    36,
                    BarqodyChrome.sidePad,
                    24,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/images/png/check-icon-1.png',
                          width: 36,
                          height: 36,
                          color: Colors.white,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.check_rounded,
                            size: 44,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Business Activated',
                        textAlign: TextAlign.center,
                        style: AppFonts.textStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          height: 1.15,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$planLabel plan is now active on your account.',
                        textAlign: TextAlign.center,
                        style: AppFonts.textStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: _muted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _DetailRow(label: 'Transaction ID', value: _txnDisplay),
                      const Divider(height: 1, thickness: 1, color: _line),
                      _DetailRow(label: 'Plan', value: planName),
                      const Divider(height: 1, thickness: 1, color: _line),
                      _DetailRow(label: 'Billing', value: planLabel),
                      const Divider(height: 1, thickness: 1, color: _line),
                      _DetailRow(
                        label: 'Valid until',
                        value: _date(endDate),
                      ),
                      const Divider(height: 1, thickness: 1, color: _line),
                      _DetailRow(
                        label: 'Purchase amount',
                        value: '$currency ${_money(amount)}',
                        emphasizeValue: true,
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
                  label: 'Done',
                  onPressed: () => _onDone(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.emphasizeValue = false,
  });

  final String label;
  final String value;
  final bool emphasizeValue;

  static const _muted = Color(0xFF8E8E93);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: WaUi.caption.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _muted,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: emphasizeValue
                  ? AppFonts.textStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    )
                  : WaUi.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
