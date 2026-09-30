import 'package:flutter/material.dart';
import 'package:tapni_app/screens/loyalty_program/business/points_flow_models.dart';
import 'package:tapni_app/screens/loyalty_program/business/points_purchased_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class PaymentScreen extends StatefulWidget {
  final PointsPackage package;

  const PaymentScreen({super.key, required this.package});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedMethod = 0;
  bool _paying = false;

  Future<void> _pay() async {
    setState(() => _paying = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _paying = false);

    final balanceBefore = BusinessPointsBalance.instance.balance;
    final added = widget.package.totalPoints;
    BusinessPointsBalance.instance.addPoints(added);
    final balanceAfter = BusinessPointsBalance.instance.balance;

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PointsPurchasedScreen(
          package: widget.package,
          balanceBefore: balanceBefore,
          balanceAfter: balanceAfter,
          transactionId: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pkg = widget.package;

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BarqodyTitleBar(title: 'Payment'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  BarqodyChrome.sidePad,
                  8,
                  BarqodyChrome.sidePad,
                  24,
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: BarqodyChrome.fieldFill,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order summary',
                          style: WaUi.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SummaryRow(
                          label: 'Points',
                          value: formatPoints(pkg.points),
                        ),
                        if (pkg.bonusPoints > 0) ...[
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: 'Bonus',
                            value: '+${formatPoints(pkg.bonusPoints)}',
                          ),
                        ],
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: BarqodyChrome.divider),
                        ),
                        _SummaryRow(
                          label: 'Total',
                          value: 'SAR ${pkg.priceSar}',
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'PAYMENT METHOD',
                    style: WaUi.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: BarqodyChrome.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PaymentMethodCard(
                    label: 'Visa',
                    subtitle: '•••• 4242',
                    selected: _selectedMethod == 0,
                    onTap: () => setState(() => _selectedMethod = 0),
                  ),
                  const SizedBox(height: 10),
                  _PaymentMethodCard(
                    label: 'Mastercard',
                    subtitle: '•••• 8888',
                    selected: _selectedMethod == 1,
                    onTap: () => setState(() => _selectedMethod = 1),
                  ),
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(
                      'Add Payment Method',
                      style: WaUi.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BarqodyChrome.sidePad,
                0,
                BarqodyChrome.sidePad,
                16,
              ),
              child: PillButton(
                label: _paying ? 'Processing…' : 'Pay SAR ${pkg.priceSar}',
                enabled: !_paying,
                onPressed: _pay,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? WaUi.bodyMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 16)
        : WaUi.body.copyWith(fontSize: 15, color: BarqodyChrome.bodyText);
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? Colors.black : BarqodyChrome.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: BarqodyChrome.fieldFill,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label == 'Visa' ? 'VISA' : 'MC',
                  style: WaUi.caption.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: WaUi.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: WaUi.caption.copyWith(
                        color: BarqodyChrome.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Image.asset(
                  'assets/images/png/check-icon.png',
                  width: 20,
                  height: 20,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.check_circle,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
