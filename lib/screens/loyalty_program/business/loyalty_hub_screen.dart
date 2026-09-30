import 'package:flutter/material.dart';
import 'package:tapni_app/screens/loyalty_program/business/loyalty_program_list_screen.dart';
import 'package:tapni_app/screens/loyalty_program/business/points_rewards_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// Entry hub for business loyalty: stamp cards and points rewards.
class LoyaltyHubScreen extends StatelessWidget {
  const LoyaltyHubScreen({super.key});

  static const Color _cardBg = Color(0xFFF5F6F7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BarqodyTitleBar(title: 'Loyalty'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  BarqodyChrome.sidePad,
                  20,
                  BarqodyChrome.sidePad,
                  32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reward your customers and keep them coming back',
                      style: WaUi.toolsTitleOf(
                        size: 22,
                        weight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _HubOptionCard(
                      color: _cardBg,
                      iconAsset: 'assets/images/png/stamp-icon-1.png',
                      title: 'Stamp Rewards',
                      subtitle:
                          'Reward customers with stamps on eligible purchases.',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LoyaltyProgramListScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _HubOptionCard(
                      color: _cardBg,
                      iconAsset: 'assets/images/png/money-icon.png',
                      title: 'Points Rewards',
                      subtitle:
                          'Let customers earn points and use them toward future orders.',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PointsRewardsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubOptionCard extends StatelessWidget {
  final Color color;
  final String iconAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HubOptionCard({
    required this.color,
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: WaUi.toolsTitleOf(
                        size: 17,
                        weight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                  ),
                  Image.asset(
                    iconAsset,
                    width: 36,
                    height: 36,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.card_giftcard_outlined,
                      size: 32,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: WaUi.body.copyWith(
                  fontSize: 14,
                  color: BarqodyChrome.secondaryText,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.chevron_right_rounded,
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
