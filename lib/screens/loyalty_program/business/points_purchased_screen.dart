import 'package:flutter/material.dart';
import 'package:tapni_app/screens/loyalty_program/business/points_flow_models.dart';
import 'package:tapni_app/screens/loyalty_program/business/points_rewards_screen.dart';
import 'package:tapni_app/utils/app_fonts.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// Figma `Success Payment` / Purchased — confirmation after points purchase.
class PointsPurchasedScreen extends StatelessWidget {
  static const _divider = Color(0xFFE8E8E8);
  static const _muted = Color(0xFF8E8E93);

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

  String get _txnDisplay {
    final t = transactionId.trim();
    if (t.isEmpty) return '—';
    return t.startsWith('#') ? t : '#$t';
  }

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final side = m.padH.clamp(20.0, 28.0);
    final checkSize = m.s(112).clamp(96.0, 128.0);
    final checkIcon = m.s(48).clamp(40.0, 56.0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _done(context);
      },
      child: Scaffold(
        backgroundColor: BarqodyChrome.scaffold,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BarqodyTitleBar(
                title: 'Purchased',
                onBack: () => _done(context),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(side, m.v(12), side, m.v(16)),
                  children: [
                    Center(
                      child: Container(
                        width: checkSize,
                        height: checkSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/png/check-img.png',
                          width: checkSize,
                          height: checkSize,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Container(
                            width: checkSize,
                            height: checkSize,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: checkIcon + 8,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: m.v(28).clamp(22.0, 34.0)),
                    Text(
                      'Points Purchased',
                      textAlign: TextAlign.center,
                      style: AppFonts.textStyle(
                        fontSize: m.s(28).clamp(24.0, 30.0),
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.15,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: m.v(10).clamp(8.0, 14.0)),
                    Text(
                      '${formatPoints(package.totalPoints)} Points have been added to your business balance.',
                      textAlign: TextAlign.center,
                      style: WaUi.body.copyWith(
                        fontSize: m.s(15).clamp(13.0, 16.0),
                        fontWeight: FontWeight.w400,
                        color: _muted,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: m.v(40).clamp(28.0, 48.0)),
                    const Divider(height: 1, thickness: 1, color: _divider),
                    _DetailRow(
                      label: 'Transaction ID',
                      value: _txnDisplay,
                      labelUpper: false,
                      boldValue: true,
                    ),
                    _DetailRow(
                      label: 'PREVIOUS BALANCE',
                      value: '${formatPoints(balanceBefore)} Points',
                    ),
                    _DetailRow(
                      label: 'PURCHASED',
                      value: '+${formatPoints(package.totalPoints)} Points',
                    ),
                    _DetailRow(
                      label: 'NEW BALANCE',
                      value: '${formatPoints(balanceAfter)} Points',
                    ),
                    const Divider(height: 1, thickness: 1, color: _divider),
                    _DetailRow(
                      label: 'PURCHASE AMOUNT',
                      value: package.priceLabel,
                      emphasizeValue: true,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(side, 8, side, 16),
                child: PillButton(
                  label: 'Done',
                  onPressed: () => _done(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool labelUpper;
  final bool boldValue;
  final bool emphasizeValue;

  const _DetailRow({
    required this.label,
    required this.value,
    this.labelUpper = true,
    this.boldValue = false,
    this.emphasizeValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: m.v(16).clamp(14.0, 18.0)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: WaUi.body.copyWith(
                fontSize: m.s(12).clamp(11.0, 13.0),
                fontWeight: FontWeight.w600,
                letterSpacing: labelUpper ? 0.4 : 0,
                color: PointsPurchasedScreen._muted,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.right,
            style: emphasizeValue
                ? AppFonts.textStyle(
                    fontSize: m.s(16).clamp(15.0, 18.0),
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  )
                : WaUi.body.copyWith(
                    fontSize: m.s(14).clamp(13.0, 15.0),
                    fontWeight: boldValue ? FontWeight.w700 : FontWeight.w500,
                    color: Colors.black,
                    height: 1.25,
                  ),
          ),
        ],
      ),
    );
  }
}
