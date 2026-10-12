import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/branded_qr_image.dart';

/// Figma `Enroll` — show the customer's profile QR so the business can scan
/// and enroll them in the loyalty program.
class CustomerEnrollQrScreen extends StatelessWidget {
  final String businessName;

  const CustomerEnrollQrScreen({
    super.key,
    required this.businessName,
  });

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final side = m.padH.clamp(20.0, 28.0);
    final name = businessName.trim().isNotEmpty ? businessName.trim() : 'the business';
    final profileUrl =
        context.watch<ProfileProvider>().activeCardDisplay.profileUrl;

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BarqodyTitleBar(title: 'Enroll'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(side, m.v(8), side, m.v(16)),
                children: [
                  Text(
                    'Ask $name to scan your QR code and enroll you in the program.',
                    style: WaUi.toolsTitleOf(
                      size: m.s(22).clamp(18.0, 24.0),
                      weight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: m.v(28).clamp(20.0, 36.0)),
                  Center(
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        maxWidth: m.s(320).clamp(260.0, 340.0),
                      ),
                      padding: EdgeInsets.all(m.s(18).clamp(14.0, 22.0)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          m.s(20).clamp(16.0, 22.0),
                        ),
                        border: Border.all(color: const Color(0xFFE8E8E8)),
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: profileUrl.trim().isEmpty
                            ? const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.black,
                                ),
                              )
                            : BrandedQrImage(
                                data: profileUrl,
                                backgroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(side, 8, side, 8),
              child: PillButton(
                label: 'Back',
                filled: false,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(side, 0, side, 16),
              child: Text(
                'If $name has scanned your QR code and enrolled you, tap the Back button to return to the Offers screen.',
                textAlign: TextAlign.center,
                style: WaUi.body.copyWith(
                  fontSize: m.s(13).clamp(12.0, 14.0),
                  color: BarqodyChrome.secondaryText,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
