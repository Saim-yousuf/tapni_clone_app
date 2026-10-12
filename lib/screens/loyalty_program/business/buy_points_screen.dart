import 'package:flutter/material.dart';
import 'package:tapni_app/screens/loyalty_program/business/points_flow_models.dart';
import 'package:tapni_app/screens/loyalty_program/business/points_payment_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// Figma `Buy Points` — packages + sticky Continue bar.
class BuyPointsScreen extends StatefulWidget {
  const BuyPointsScreen({super.key});

  @override
  State<BuyPointsScreen> createState() => _BuyPointsScreenState();
}

class _BuyPointsScreenState extends State<BuyPointsScreen> {
  static const _cardFill = Color(0xFFF5F5F5);
  static const _cardStroke = Color(0xFFE5E7EB);
  static const _bonusBg = Color(0xFFE8F5E9);
  static const _bonusFg = Color(0xFF2E7D32);

  final _balanceStore = BusinessPointsBalance.instance;
  PointsPackage? _selected;

  @override
  void initState() {
    super.initState();
    _balanceStore.addListener(_onBalance);
    _balanceStore.refresh();
  }

  @override
  void dispose() {
    _balanceStore.removeListener(_onBalance);
    super.dispose();
  }

  void _onBalance() {
    if (mounted) setState(() {});
  }

  static double _font(AuthScale m, double pt, {double min = 11}) =>
      m.s(pt).clamp(min, pt * 1.2);

  @override
  Widget build(BuildContext context) {
    final balance = _balanceStore.balance;
    final packages = _balanceStore.packages;
    final selected = _selected;
    final m = AuthScale.of(context);
    final side = m.padH.clamp(20.0, 28.0);

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BarqodyTitleBar(title: 'Buy Points'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(side, m.v(4), side, m.v(16)),
                children: [
                  Text(
                    'Purchase points to cover customer redemptions',
                    style: WaUi.toolsTitleOf(
                      size: _font(m, 24, min: 20),
                      weight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: m.v(28).clamp(20.0, 34.0)),
                  Text(
                    formatPoints(balance),
                    style: WaUi.toolsTitleOf(
                      size: _font(m, 36, min: 28),
                      weight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.05,
                    ),
                  ),
                  SizedBox(height: m.v(6).clamp(4.0, 8.0)),
                  Text(
                    'CURRENT POINT BALANCE',
                    style: WaUi.body.copyWith(
                      fontSize: _font(m, 12, min: 10),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.6,
                      color: BarqodyChrome.secondaryText,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: m.v(16).clamp(12.0, 20.0)),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE8E8E8),
                  ),
                  SizedBox(height: m.v(20).clamp(16.0, 24.0)),
                  Text(
                    'CHOOSE A PACKAGE',
                    style: WaUi.body.copyWith(
                      fontSize: _font(m, 12, min: 10),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: Colors.black,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: m.v(14).clamp(12.0, 18.0)),
                  ...packages.map(
                    (p) => Padding(
                      padding: EdgeInsets.only(bottom: m.v(12).clamp(10.0, 14.0)),
                      child: _PackageCard(
                        package: p,
                        selected: selected?.id == p.id,
                        onTap: () => setState(() => _selected = p),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(side, 12, side, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selected == null
                              ? '—'
                              : '${formatPoints(selected.totalPoints)} Points',
                          style: WaUi.body.copyWith(
                            fontSize: _font(m, 14, min: 12),
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: m.v(4).clamp(2.0, 6.0)),
                        Text(
                          selected == null
                              ? '—'
                              : selected.priceLabel,
                          style: WaUi.toolsTitleOf(
                            size: _font(m, 22, min: 18),
                            weight: FontWeight.w700,
                            color: Colors.black,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: m.s(12)),
                  SizedBox(
                    width: m.s(160).clamp(140.0, 180.0),
                    child: PillButton(
                      label: 'Continue',
                      enabled: selected != null,
                      onPressed: () {
                        if (selected == null) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PaymentScreen(package: selected),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final PointsPackage package;
  final bool selected;
  final VoidCallback onTap;

  const _PackageCard({
    required this.package,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final pad = m.s(16).clamp(14.0, 18.0);
    final radius = m.s(16).clamp(14.0, 18.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: _BuyPointsScreenState._cardFill,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: selected ? Colors.black : _BuyPointsScreenState._cardStroke,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${formatPoints(package.points)} Points',
                          style: WaUi.body.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: m.s(16).clamp(14.0, 17.0),
                            color: Colors.black,
                            height: 1.2,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.black,
                          ),
                        ),
                      ),
                      if (package.bonusPoints > 0) ...[
                        SizedBox(width: m.s(8)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: m.s(8).clamp(6.0, 10.0),
                            vertical: m.v(4).clamp(3.0, 6.0),
                          ),
                          decoration: BoxDecoration(
                            color: _BuyPointsScreenState._bonusBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '+${formatPoints(package.bonusPoints)} Bonus Points',
                            style: WaUi.body.copyWith(
                              fontSize: m.s(11).clamp(10.0, 12.0),
                              fontWeight: FontWeight.w600,
                              color: _BuyPointsScreenState._bonusFg,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                      // room for check when selected
                      if (selected) SizedBox(width: m.s(28)),
                    ],
                  ),
                  SizedBox(height: m.v(8).clamp(6.0, 10.0)),
                  Text(
                    package.priceLabel,
                    style: WaUi.body.copyWith(
                      color: BarqodyChrome.secondaryText,
                      fontSize: m.s(14).clamp(13.0, 15.0),
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: m.v(4).clamp(2.0, 6.0)),
                  Text(
                    'One-time purchase',
                    style: WaUi.body.copyWith(
                      color: BarqodyChrome.secondaryText,
                      fontSize: m.s(13).clamp(12.0, 14.0),
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                    ),
                  ),
                  if (package.recommended) ...[
                    SizedBox(height: m.v(10).clamp(8.0, 12.0)),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: m.s(10).clamp(8.0, 12.0),
                          vertical: m.v(5).clamp(4.0, 7.0),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        child: Text(
                          'Recommend',
                          style: WaUi.body.copyWith(
                            fontSize: m.s(11).clamp(10.0, 12.0),
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (selected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: m.s(24).clamp(22.0, 26.0),
                    height: m.s(24).clamp(22.0, 26.0),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: m.s(16).clamp(14.0, 18.0),
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
