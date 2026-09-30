import 'package:flutter/material.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class LoyaltyProgramSuccessScreen extends StatelessWidget {
  const LoyaltyProgramSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            const BarqodyTitleBar(title: 'Success'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    Image.asset(
                      'assets/images/png/congrats.png',
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.celebration_outlined,
                        size: 80,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Reward Program Created',
                      textAlign: TextAlign.center,
                      style: WaUi.toolsTitleOf(
                        size: 22,
                        weight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your stamp reward program is saved. Publish your design when you are ready for customers to enroll.',
                      textAlign: TextAlign.center,
                      style: WaUi.body.copyWith(
                        fontSize: 15,
                        color: BarqodyChrome.bodyText,
                        height: 1.45,
                      ),
                    ),
                    const Spacer(flex: 3),
                    PillButton(
                      label: 'Publish Your Design',
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                    const SizedBox(height: 12),
                    PillButton(
                      label: 'Back',
                      filled: false,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                    const SizedBox(height: 16),
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
