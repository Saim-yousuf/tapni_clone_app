import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/theme_provider.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/widgets/glass_card.dart';
import 'package:tapni_app/widgets/custom_button.dart';

class QrCodeScreen extends StatelessWidget {
  const QrCodeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final profileProvider = Provider.of<ProfileProvider>(context);
    final profile = profileProvider.profile;

    final profileLink =
        'https://tapni.com/${profile.name.replaceAll(' ', '').toLowerCase()}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Subtitle instruction
              Text(
                'Scan QR Code',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Let others point their phone camera to this QR code to instantly view your networking profile.',
                style: TextStyle(
                  color: isDark
                      ? AppTheme.textGreyDark
                      : AppTheme.textGreyLight,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // The QR Box (Glassmorphic Outer Container)
              GlassCard(
                blur: 25,
                borderOpacity: 0.15,
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    // Brand / Profile initial label
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppTheme.goldGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.contactless,
                                color: AppTheme.secondaryWhite,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                profile.name,
                                style: const TextStyle(
                                  color: AppTheme.secondaryWhite,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // QR Code rendering
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentGold.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          QrImageView(
                            data: profileLink,
                            version: QrVersions.auto,
                            size: 200.0,
                            gapless: false,
                            foregroundColor: Colors.black,
                           
                          ),
                          // Custom Gold Accent Center Icon overlay
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              gradient: AppTheme.goldGradient,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.contactless,
                                size: 18,
                                color: AppTheme.secondaryWhite,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Card link label
                    Text(
                      profileLink,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppTheme.accentGold
                            : AppTheme.accentGoldDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Action Utilities (Share & Download UI only)
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Share Link',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Sharing profile link: $profileLink'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      isGold: true,
                      icon: Icons.share_rounded,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: 'Download',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'QR Code image downloaded to gallery!',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      isSecondary: true,
                      icon: Icons.download_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
