import 'package:flutter/material.dart';
import 'package:tapni_app/screens/loyalty_program/business/buy_points_screen.dart';
import 'package:tapni_app/screens/loyalty_program/business/points_activity_screen.dart';
import 'package:tapni_app/screens/loyalty_program/business/points_flow_models.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// Figma `Points Rewards` — balance + info lists + View Activity.
class PointsRewardsScreen extends StatefulWidget {
  const PointsRewardsScreen({super.key});

  @override
  State<PointsRewardsScreen> createState() => _PointsRewardsScreenState();
}

class _PointsRewardsScreenState extends State<PointsRewardsScreen> {
  static const _cardFill = Color(0xFFF5F5F5);
  static const _divider = Color(0xFFE8E8E8);

  final _balanceStore = BusinessPointsBalance.instance;

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

  Future<void> _openBuyPoints() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/buy_points'),
        builder: (_) => const BuyPointsScreen(),
      ),
    );
    await _balanceStore.refresh();
    if (mounted) setState(() {});
  }

  static double _font(AuthScale m, double pt, {double min = 11}) =>
      m.s(pt).clamp(min, pt * 1.2);

  @override
  Widget build(BuildContext context) {
    final balance = _balanceStore.balance;
    final m = AuthScale.of(context);
    final side = m.padH.clamp(20.0, 28.0);

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BarqodyTitleBar(title: 'Points Rewards'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(side, m.v(4), side, m.v(16)),
                children: [
                  Text(
                    'Manage your points program and customer redemptions',
                    style: WaUi.toolsTitleOf(
                      size: _font(m, 24, min: 20),
                      weight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: m.v(28).clamp(20.0, 34.0)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                              'Points BALANCE',
                              style: WaUi.body.copyWith(
                                fontSize: _font(m, 12, min: 10),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.6,
                                color: BarqodyChrome.secondaryText,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: m.v(10).clamp(8.0, 12.0)),
                            Container(
                              width: m.s(140).clamp(110.0, 160.0),
                              height: 1,
                              color: _divider,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: m.s(12)),
                      _BuyPointsChip(onTap: _openBuyPoints),
                    ],
                  ),
                  SizedBox(height: m.v(28).clamp(20.0, 34.0)),
                  _ListCard(
                    title: 'Points Rewards',
                    titleAllCaps: false,
                    rows: const [
                      'Customers earn points automatically on eligible purchases.',
                      'Customers can redeem their points during checkout.',
                    ],
                  ),
                  SizedBox(height: m.v(14).clamp(12.0, 18.0)),
                  _ListCard(
                    title: 'HOW IT WORKS',
                    titleAllCaps: true,
                    rows: const [
                      'Customers earn',
                      'Points are added',
                      'Customers redeem',
                      'Points are consumed',
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(side, 0, side, 16),
              child: PillButton(
                label: 'View Activity',
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

class _BuyPointsChip extends StatelessWidget {
  final VoidCallback onTap;

  const _BuyPointsChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final h = m.s(40).clamp(36.0, 44.0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(h / 2),
        boxShadow: AuthUi.primaryButtonShadow(m),
      ),
      child: Material(
        color: Colors.black,
        borderRadius: BorderRadius.circular(h / 2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(h / 2),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: m.s(18).clamp(14.0, 22.0),
              vertical: m.v(10).clamp(8.0, 12.0),
            ),
            child: Text(
              'Buy Points',
              style: WaUi.body.copyWith(
                fontSize: m.s(14).clamp(13.0, 15.0),
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  final String title;
  final bool titleAllCaps;
  final List<String> rows;

  const _ListCard({
    required this.title,
    required this.rows,
    this.titleAllCaps = false,
  });

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final pad = m.s(16).clamp(14.0, 18.0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _PointsRewardsScreenState._cardFill,
        borderRadius: BorderRadius.circular(m.s(18).clamp(16.0, 20.0)),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(pad, pad, pad, m.v(12).clamp(10.0, 14.0)),
            child: Text(
              title,
              style: WaUi.body.copyWith(
                fontSize: m.s(titleAllCaps ? 13 : 15).clamp(12.0, 16.0),
                fontWeight: FontWeight.w700,
                color: Colors.black,
                letterSpacing: titleAllCaps ? 0.4 : 0,
                height: 1.2,
              ),
            ),
          ),
          for (var i = 0; i < rows.length; i++) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.black.withValues(alpha: 0.06),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: pad,
                vertical: m.v(14).clamp(12.0, 16.0),
              ),
              child: Text(
                rows[i],
                style: WaUi.body.copyWith(
                  fontSize: m.s(14).clamp(13.0, 15.0),
                  fontWeight: FontWeight.w400,
                  color: BarqodyChrome.bodyText,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
