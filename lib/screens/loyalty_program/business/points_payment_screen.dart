import 'package:flutter/material.dart';
import 'package:tapni_app/repository/loyalty_points_repo.dart';
import 'package:tapni_app/screens/loyalty_program/business/points_flow_models.dart';
import 'package:tapni_app/screens/loyalty_program/business/points_purchased_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// Figma `Payment` — order summary + payment methods + Pay CTA.
class PaymentScreen extends StatefulWidget {
  final PointsPackage package;

  const PaymentScreen({super.key, required this.package});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const _cardFill = Color(0xFFF5F5F5);
  static const _cardStroke = Color(0xFFE5E7EB);
  static const _bonusFg = Color(0xFF2E7D32);

  int _selectedMethod = 0;
  bool _paying = false;

  Future<void> _pay() async {
    if (_paying) return;
    setState(() => _paying = true);

    final res = await LoyaltyPointsRepo().purchaseBusinessPoints(
      widget.package.id,
    );
    if (!mounted) return;
    setState(() => _paying = false);

    if (!res.success || res.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            res.message ?? 'Purchase failed',
            style: WaUi.body.copyWith(color: Colors.white),
          ),
          backgroundColor: Colors.black,
        ),
      );
      return;
    }

    final raw = res.data is Map ? res.data['data'] ?? res.data : res.data;
    final map = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    final balanceBefore =
        (map['balanceBefore'] as num?)?.toInt() ??
            BusinessPointsBalance.instance.balance;
    final balanceAfter =
        (map['balanceAfter'] as num?)?.toInt() ??
            balanceBefore + widget.package.totalPoints;
    final txn =
        map['transactionId']?.toString() ??
        'TXN-${DateTime.now().millisecondsSinceEpoch}';

    BusinessPointsBalance.instance.balance = balanceAfter;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PointsPurchasedScreen(
          package: widget.package,
          balanceBefore: balanceBefore,
          balanceAfter: balanceAfter,
          transactionId: txn,
        ),
      ),
    );
  }

  static double _font(AuthScale m, double pt, {double min = 11}) =>
      m.s(pt).clamp(min, pt * 1.2);

  @override
  Widget build(BuildContext context) {
    final pkg = widget.package;
    final m = AuthScale.of(context);
    final side = m.padH.clamp(20.0, 28.0);
    final radius = m.s(16).clamp(14.0, 18.0);
    final pad = m.s(16).clamp(14.0, 18.0);

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BarqodyTitleBar(title: 'Payment'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(side, m.v(4), side, m.v(24)),
                children: [
                  // Summary — left points/bonus, right Total SAR
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(pad),
                    decoration: BoxDecoration(
                      color: _cardFill,
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(color: _cardStroke),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${formatPoints(pkg.points)} Points',
                                style: WaUi.body.copyWith(
                                  fontSize: _font(m, 15, min: 13),
                                  fontWeight: FontWeight.w500,
                                  color: BarqodyChrome.secondaryText,
                                  height: 1.25,
                                ),
                              ),
                              if (pkg.bonusPoints > 0) ...[
                                SizedBox(height: m.v(6).clamp(4.0, 8.0)),
                                Text(
                                  '+${formatPoints(pkg.bonusPoints)} Points',
                                  style: WaUi.body.copyWith(
                                    fontSize: _font(m, 15, min: 13),
                                    fontWeight: FontWeight.w600,
                                    color: _bonusFg,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          'Total ${pkg.priceLabel}',
                          style: WaUi.body.copyWith(
                            fontSize: _font(m, 16, min: 14),
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            height: 1.2,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: m.v(28).clamp(22.0, 34.0)),
                  Text(
                    'PAYMENT METHOD',
                    style: WaUi.body.copyWith(
                      fontSize: _font(m, 12, min: 11),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: Colors.black,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: m.v(14).clamp(12.0, 18.0)),
                  _PaymentMethodCard(
                    label: 'Visa',
                    subtitle: '•••• 4242',
                    selected: _selectedMethod == 0,
                    onTap: () => setState(() => _selectedMethod = 0),
                  ),
                  SizedBox(height: m.v(12).clamp(10.0, 14.0)),
                  _PaymentMethodCard(
                    label: 'Mastercard',
                    subtitle: '•••• 4242',
                    selected: _selectedMethod == 1,
                    onTap: () => setState(() => _selectedMethod = 1),
                  ),
                  SizedBox(height: m.v(16).clamp(12.0, 20.0)),
                  GestureDetector(
                    onTap: () {},
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: m.v(4).clamp(2.0, 6.0),
                      ),
                      child: Text(
                        '+ Add Payment Method',
                        style: WaUi.body.copyWith(
                          fontSize: _font(m, 15, min: 13),
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(side, 0, side, 16),
              child: PillButton(
                label: _paying ? 'Processing…' : 'Pay ${pkg.priceLabel}',
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
    final m = AuthScale.of(context);
    final radius = m.s(16).clamp(14.0, 18.0);
    final pad = m.s(16).clamp(14.0, 18.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: _PaymentScreenState._cardFill,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: selected
                  ? Colors.black
                  : _PaymentScreenState._cardStroke,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: WaUi.body.copyWith(
                  fontSize: m.s(16).clamp(14.0, 17.0),
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.2,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.black,
                ),
              ),
              SizedBox(height: m.v(6).clamp(4.0, 8.0)),
              Text(
                subtitle,
                style: WaUi.body.copyWith(
                  fontSize: m.s(14).clamp(13.0, 15.0),
                  fontWeight: FontWeight.w400,
                  color: BarqodyChrome.secondaryText,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
