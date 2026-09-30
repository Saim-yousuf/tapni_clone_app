import 'package:flutter/material.dart';
import 'package:tapni_app/screens/loyalty_program/business/buy_points_screen.dart';
import 'package:tapni_app/screens/loyalty_program/business/points_activity_screen.dart';
import 'package:tapni_app/screens/loyalty_program/business/points_flow_models.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class PointsRewardsScreen extends StatefulWidget {
  const PointsRewardsScreen({super.key});

  @override
  State<PointsRewardsScreen> createState() => _PointsRewardsScreenState();
}

class _PointsRewardsScreenState extends State<PointsRewardsScreen> {
  final _balanceStore = BusinessPointsBalance.instance;

  @override
  void initState() {
    super.initState();
    _balanceStore.addListener(_onBalance);
  }

  @override
  void dispose() {
    _balanceStore.removeListener(_onBalance);
    super.dispose();
  }

  void _onBalance() {
    if (mounted) setState(() {});
  }

  Future<void> _openBuyPoints() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BuyPointsScreen()),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final balance = _balanceStore.balance;

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BarqodyTitleBar(title: 'Points Rewards'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  BarqodyChrome.sidePad,
                  8,
                  BarqodyChrome.sidePad,
                  24,
                ),
                children: [
                  Text(
                    'Manage your points program and customer redemptions',
                    style: WaUi.body.copyWith(
                      fontSize: 15,
                      color: BarqodyChrome.bodyText,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    formatPoints(balance),
                    textAlign: TextAlign.center,
                    style: WaUi.toolsTitleOf(
                      size: 44,
                      weight: FontWeight.w700,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'POINTS BALANCE',
                    textAlign: TextAlign.center,
                    style: WaUi.caption.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: BarqodyChrome.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Material(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        onTap: _openBuyPoints,
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/png/money-icon.png',
                                width: 18,
                                height: 18,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.payments_outlined,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Buy Points',
                                style: WaUi.promoButton.copyWith(fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _InfoCard(
                    title: 'Points Rewards',
                    body:
                        'Use your balance to fund customer point redemptions across your loyalty programs.',
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: 'HOW IT WORKS',
                    body:
                        'Purchase points packages, assign rewards that cost points, and track activity as customers redeem.',
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
                label: 'View Activity',
                filled: false,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PointsActivityScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String body;

  const _InfoCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            title,
            style: WaUi.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: WaUi.body.copyWith(
              fontSize: 14,
              color: BarqodyChrome.bodyText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
