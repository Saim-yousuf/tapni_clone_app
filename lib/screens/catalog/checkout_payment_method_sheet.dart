import 'package:flutter/material.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

/// Cash vs online selection before placing a catalog order.
enum CheckoutPaymentMethod { cashOnDelivery, online }

Future<CheckoutPaymentMethod?> showCheckoutPaymentMethodSheet(
  BuildContext context, {
  required double totalAmount,
  required String currency,
  String title = 'How will you pay?',
}) {
  return showModalBottomSheet<CheckoutPaymentMethod>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CheckoutPaymentMethodSheet(
      totalAmount: totalAmount,
      currency: currency,
      title: title,
    ),
  );
}

class _CheckoutPaymentMethodSheet extends StatefulWidget {
  final double totalAmount;
  final String currency;
  final String title;

  const _CheckoutPaymentMethodSheet({
    required this.totalAmount,
    required this.currency,
    required this.title,
  });

  @override
  State<_CheckoutPaymentMethodSheet> createState() =>
      _CheckoutPaymentMethodSheetState();
}

class _CheckoutPaymentMethodSheetState
    extends State<_CheckoutPaymentMethodSheet> {
  CheckoutPaymentMethod _selected = CheckoutPaymentMethod.cashOnDelivery;

  void _select(CheckoutPaymentMethod method) {
    if (_selected == method) return;
    setState(() => _selected = method);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.totalAmount;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5E5),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: WaUi.toolsTitleOf(
                    size: 20,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
              CircleCloseButton(onTap: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Total due: ${widget.currency} ${total.toStringAsFixed(total == total.roundToDouble() ? 0 : 2)}',
            style: WaUi.body.copyWith(
              color: BarqodyChrome.secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _PayOption(
            selected: _selected == CheckoutPaymentMethod.cashOnDelivery,
            title: 'Cash',
            subtitle: 'Cash on delivery / pay at venue',
            onTap: () => _select(CheckoutPaymentMethod.cashOnDelivery),
          ),
          const SizedBox(height: 10),
          _PayOption(
            selected: _selected == CheckoutPaymentMethod.online,
            title: 'Online payment',
            subtitle: 'Card · simulated demo checkout (not real)',
            onTap: () => _select(CheckoutPaymentMethod.online),
          ),
          const SizedBox(height: 10),
          Text(
            'Online checkout is a Stripe-style demo. No real card charges. Card details are never stored.',
            style: WaUi.body.copyWith(
              fontSize: 12,
              color: BarqodyChrome.secondaryText,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          PillButton(
            label: 'Continue',
            onPressed: () => Navigator.pop(context, _selected),
          ),
        ],
      ),
    );
  }
}

class _PayOption extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PayOption({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFF0F0F0)
                : const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? Colors.black : const Color(0xFFE8E8E8),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: Colors.black,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: WaUi.body.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: WaUi.body.copyWith(
                        fontSize: 12,
                        color: BarqodyChrome.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
