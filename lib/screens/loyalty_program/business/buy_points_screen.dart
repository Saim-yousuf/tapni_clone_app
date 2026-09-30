import 'package:flutter/material.dart';
import 'package:tapni_app/screens/loyalty_program/business/points_flow_models.dart';
import 'package:tapni_app/screens/loyalty_program/business/points_payment_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class BuyPointsScreen extends StatefulWidget {
  const BuyPointsScreen({super.key});

  @override
  State<BuyPointsScreen> createState() => _BuyPointsScreenState();
}

class _BuyPointsScreenState extends State<BuyPointsScreen> {
  final _balanceStore = BusinessPointsBalance.instance;
  PointsPackage? _selected;

  @override
  Widget build(BuildContext context) {
    final balance = _balanceStore.balance;
    final selected = _selected;
    final totalSar = selected?.priceSar ?? 0;

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BarqodyTitleBar(title: 'Buy Points'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  BarqodyChrome.sidePad,
                  8,
                  BarqodyChrome.sidePad,
                  16,
                ),
                children: [
                  Text(
                    'Top up your business points balance to cover customer redemptions',
                    style: WaUi.body.copyWith(
                      fontSize: 15,
                      color: BarqodyChrome.bodyText,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'CURRENT POINT BALANCE',
                    style: WaUi.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: BarqodyChrome.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatPoints(balance),
                    style: WaUi.toolsTitleOf(
                      size: 32,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'CHOOSE A PACKAGE',
                    style: WaUi.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: BarqodyChrome.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...kDefaultPointsPackages.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
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
              padding: const EdgeInsets.fromLTRB(
                BarqodyChrome.sidePad,
                12,
                BarqodyChrome.sidePad,
                16,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: BarqodyChrome.divider),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total',
                          style: WaUi.caption.copyWith(
                            color: BarqodyChrome.secondaryText,
                          ),
                        ),
                        Text(
                          selected == null ? '—' : 'SAR $totalSar',
                          style: WaUi.toolsTitleOf(
                            size: 22,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 160,
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? Colors.black : BarqodyChrome.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${formatPoints(package.points)} pts',
                          style: WaUi.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        if (package.recommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: BarqodyChrome.fieldFill,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Recommend',
                              style: WaUi.caption.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SAR ${package.priceSar}',
                      style: WaUi.body.copyWith(
                        color: BarqodyChrome.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                    if (package.bonusPoints > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '+${formatPoints(package.bonusPoints)} bonus pts',
                        style: WaUi.caption.copyWith(
                          fontSize: 12,
                          color: const Color(0xFF1B8A4A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                Image.asset(
                  'assets/images/png/check-icon.png',
                  width: 22,
                  height: 22,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.check_circle,
                    color: Colors.black,
                    size: 22,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
