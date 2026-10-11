import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/screens/scan_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class ScanToInviteScreen extends StatelessWidget {
  const ScanToInviteScreen({super.key});

  Future<void> _goToScan(BuildContext context) async {
    final invited = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const ScanScreen(inviteEmployee: true),
      ),
    );
    // Add-member success pops past this route via popUntil; only close
    // Scan-to-invite when Scan still returned a result normally.
    if (context.mounted && invited != null) {
      Navigator.pop(context, invited);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(title: context.l10n.scan),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: BarqodyChrome.sidePad),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/png/scanning-img.png',
                      width: m.s(220),
                      height: m.s(220),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.qr_code_scanner_rounded,
                        size: m.s(120),
                        color: BarqodyChrome.secondaryText.withValues(alpha: 0.35),
                      ),
                    ),
                    SizedBox(height: m.v(28)),
                    Text(
                      'Scan to invite',
                      textAlign: TextAlign.center,
                      style: WaUi.toolsTitleOf(
                        size: 22,
                        weight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: m.v(10)),
                    Text(
                      "Scan a team member's QR code to send them an invitation.",
                      textAlign: TextAlign.center,
                      style: WaUi.body.copyWith(
                        fontSize: m.s(15),
                        height: 1.35,
                        color: BarqodyChrome.bodyText,
                      ),
                    ),
                    const Spacer(),
                    PillButton(
                      label: 'Go to Scan',
                      onPressed: () => _goToScan(context),
                    ),
                    SizedBox(height: m.v(16)),
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
