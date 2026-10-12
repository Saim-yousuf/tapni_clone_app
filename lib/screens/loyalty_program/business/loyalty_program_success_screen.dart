import 'package:flutter/material.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// Figma Program Success — after Go Live.
/// Pops `true` for Publish Your Design (community); `false`/null for Back.
class LoyaltyProgramSuccessScreen extends StatelessWidget {
  const LoyaltyProgramSuccessScreen({super.key});

  static double _font(AuthScale m, double pt, {double min = 11}) =>
      m.s(pt).clamp(min, pt * 1.2);

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final side = m.padH.clamp(24.0, 32.0);
    final imageH = m.s(140).clamp(112.0, 160.0);
    final titleSize = _font(m, 24, min: 20);
    final bodySize = _font(m, 14, min: 12);
    final gapAfterImage = m.v(28).clamp(20.0, 32.0);
    final gapAfterTitle = m.v(12).clamp(8.0, 14.0);
    final gapBetweenButtons = m.v(12).clamp(10.0, 14.0);
    final bottomPad = m.v(16).clamp(12.0, 20.0);

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            const BarqodyTitleBar(title: 'Success'),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: side),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    Image.asset(
                      'assets/images/png/congrats.png',
                      height: imageH,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.celebration_outlined,
                        size: imageH * 0.65,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: gapAfterImage),
                    Text(
                      'Reward Program Created',
                      textAlign: TextAlign.center,
                      style: WaUi.toolsTitleOf(
                        size: titleSize,
                        weight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: gapAfterTitle),
                    Text(
                      'Your customers can now earn stamps with eligible purchases and unlock their reward.',
                      textAlign: TextAlign.center,
                      style: WaUi.body.copyWith(
                        fontSize: bodySize,
                        color: BarqodyChrome.secondaryText,
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(flex: 3),
                    PillButton(
                      label: 'Publish Your Design',
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                    SizedBox(height: gapBetweenButtons),
                    PillButton(
                      label: 'Back',
                      filled: false,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    SizedBox(height: bottomPad),
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
