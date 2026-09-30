import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/screens/scan_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class ScanToInviteScreen extends StatelessWidget {
  const ScanToInviteScreen({super.key});

  Future<void> _goToScan(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(title: context.l10n.scan),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: BarqodyChrome.sidePad),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    Image.asset(
                      'assets/images/png/scanning-img.png',
                      width: 220,
                      height: 220,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 120,
                        color: BarqodyChrome.secondaryText.withValues(alpha: 0.35),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      context.l10n.scanToInvite,
                      textAlign: TextAlign.center,
                      style: WaUi.toolsTitleOf(
                        size: 22,
                        weight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.l10n.scanAnyUserOrBusinessQRToAddEmployee,
                      textAlign: TextAlign.center,
                      style: WaUi.body.copyWith(
                        fontSize: 15,
                        height: 1.35,
                        color: BarqodyChrome.bodyText,
                      ),
                    ),
                    const Spacer(flex: 3),
                    PillButton(
                      label: 'Go to Scan',
                      onPressed: () => _goToScan(context),
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
