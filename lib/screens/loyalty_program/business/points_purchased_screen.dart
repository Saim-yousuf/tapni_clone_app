import 'package:flutter/material.dart';
import 'package:tapni_app/screens/loyalty_program/business/points_flow_models.dart';
import 'package:tapni_app/screens/loyalty_program/business/points_rewards_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class PointsPurchasedScreen extends StatelessWidget {
  final PointsPackage package;
  final int balanceBefore;
  final int balanceAfter;
  final String transactionId;

  const PointsPurchasedScreen({
    super.key,
    required this.package,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.transactionId,
  });

  void _done(BuildContext context) {
    final nav = Navigator.of(context);
    var foundRewards = false;
    nav.popUntil((route) {
      if (route.settings.name == '/points_rewards') {
        foundRewards = true;
        return true;
      }
      return route.isFirst;
    });
    if (!foundRewards) {
      nav.pushReplacement(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/points_rewards'),
          builder: (_) => const PointsRewardsScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BarqodyTitleBar(title: 'Purchased'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  BarqodyChrome.sidePad,
                  24,
                  BarqodyChrome.sidePad,
                  24,
                ),
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/png/check-img.png',
                          width: 32,
                          height: 32,
                          color: Colors.white,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Points Purchased',
                    textAlign: TextAlign.center,
                    style: WaUi.toolsTitleOf(
                      size: 22,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _DetailRow(label: 'Transaction ID', value: transactionId),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'Points added',
                    value: '+${formatPoints(package.totalPoints)}',
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'Previous balance',
                    value: formatPoints(balanceBefore),
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'New balance',
                    value: formatPoints(balanceAfter),
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'Amount paid',
                    value: 'SAR ${package.priceSar}',
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
                label: 'Done',
                onPressed: () => _done(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: WaUi.body.copyWith(
                color: BarqodyChrome.secondaryText,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: WaUi.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
