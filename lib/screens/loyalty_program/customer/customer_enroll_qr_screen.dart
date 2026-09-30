import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/explore_business.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/utils/constant.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/branded_qr_image.dart';

/// Customer-facing enroll screen: show profile QR for the business to scan.
class CustomerEnrollQrScreen extends StatelessWidget {
  final ExploreOffer offer;

  const CustomerEnrollQrScreen({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final username = (profile.username ?? '').trim();
    final qrData = username.isNotEmpty
        ? '${Constants.appDomain}/$username'
        : (profile.id != null && profile.id!.isNotEmpty
            ? '${Constants.appDomain}/u/${profile.id}'
            : Constants.appDomain);
    final business = offer.businessName.trim().isNotEmpty
        ? offer.businessName.trim()
        : 'this business';

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            const BarqodyTitleBar(title: 'Enroll'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Ask $business to scan your QR code and enroll you in the program.',
                      style: WaUi.body.copyWith(
                        fontSize: 16,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFE0E0E0),
                            width: 1,
                          ),
                        ),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: BrandedQrImage(
                            data: qrData,
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: PillButton(
                label: 'Back',
                filled: false,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Text(
                'If $business has scanned your QR code and enrolled you, tap the Back button to return to the Offers screen.',
                style: WaUi.body.copyWith(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
