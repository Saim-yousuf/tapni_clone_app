import 'package:flutter/material.dart';
import 'package:tapni_app/screens/loyalty_program/business/loyalty_program_list_screen.dart';
import 'package:tapni_app/screens/loyalty_program/business/points_rewards_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// Entry hub for business loyalty: stamp cards and points rewards.
class LoyaltyHubScreen extends StatelessWidget {
  const LoyaltyHubScreen({super.key});

  static const Color _cardBg = Color(0xFFF5F5F5);
  static const Color _cardBorder = Color(0xFFE5E7EB);

  static double _font(AuthScale m, double pt, {double min = 11}) =>
      m.s(pt).clamp(min, pt * 1.25);

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BarqodyTitleBar(title: 'Loyalty'),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  m.padH,
                  m.v(16),
                  m.padH,
                  m.v(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reward your customers and keep them coming back.',
                      style: WaUi.toolsTitleOf(
                        size: _font(m, 20, min: 17),
                        weight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: m.v(20)),
                    _HubOptionCard(
                      color: _cardBg,
                      borderColor: _cardBorder,
                      iconAsset: 'assets/images/png/stamp-icon-1.png',
                      iconSize: m.s(48).clamp(40.0, 56.0),
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
                    SizedBox(height: m.v(12)),
                    _HubOptionCard(
                      color: _cardBg,
                      borderColor: _cardBorder,
                      iconAsset: 'assets/images/png/money-icon.png',
                      iconSize: m.s(44).clamp(38.0, 52.0),
                      title: 'Points Rewards',
                      subtitle:
                          'Let customers earn points and use them toward future orders.',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            settings:
                                const RouteSettings(name: '/points_rewards'),
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
  final Color borderColor;
  final String iconAsset;
  final double iconSize;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HubOptionCard({
    required this.color,
    required this.borderColor,
    required this.iconAsset,
    required this.iconSize,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  static double _font(AuthScale m, double pt, {double min = 11}) =>
      m.s(pt).clamp(min, pt * 1.25);

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(m.s(16).clamp(14.0, 18.0)),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(m.s(16).clamp(14.0, 18.0)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              m.s(16),
              m.v(16),
              m.s(12),
              m.v(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: WaUi.toolsTitleOf(
                              size: _font(m, 15, min: 13),
                              weight: FontWeight.w700,
                              color: Colors.black,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: m.v(8)),
                          Text(
                            subtitle,
                            style: WaUi.body.copyWith(
                              fontSize: _font(m, 14, min: 12),
                              color: const Color(0xFF6B7280),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: m.s(10)),
                    Image.asset(
                      iconAsset,
                      width: iconSize,
                      height: iconSize,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.card_giftcard_outlined,
                        size: iconSize * 0.75,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: m.v(8)),
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black,
                    size: m.s(24).clamp(20.0, 26.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
