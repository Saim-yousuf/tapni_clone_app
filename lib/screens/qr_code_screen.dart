import 'dart:developer';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/theme_provider.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/widgets/glass_card.dart';
import 'package:tapni_app/widgets/custom_button.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class QrCodeScreen extends StatefulWidget {
  const QrCodeScreen({Key? key}) : super(key: key);

  @override
  State<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends State<QrCodeScreen> {
  final GlobalKey _globalKey = GlobalKey();

  ScaffoldMessengerState? _messengerRef;

  void _showSnackBar(String message, {Color color = Colors.green}) {
    _messengerRef?.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
      ),
    );
  }

  Future<void> _downloadQr() async {
    // Capture BEFORE any await — context may be gone after async
    _messengerRef = ScaffoldMessenger.of(context);
    try {
      RenderRepaintBoundary boundary =
          _globalKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();

        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/Tapni_QR_${DateTime.now().millisecondsSinceEpoch}.png').create();
        await file.writeAsBytes(pngBytes);

        bool hasAccess = await Gal.hasAccess();
        if (!hasAccess) {
          hasAccess = await Gal.requestAccess();
        }

        if (hasAccess) {
          await Gal.putImage(file.path);
          _showSnackBar(context.l10n.qrCodeSavedToGallery);
        } else {
          _showSnackBar(
            context.l10n.galleryPermissionRequiredPleaseEnableItInSettings,
            color: Colors.red,
          );
        }
      }
    } catch (e) {
      log("$e");
      _showSnackBar(context.l10n.failedToSaveQRCode, color: Colors.red);
    }

  }

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
        title: Text(context.l10n.shareProfile),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            children: [
              SizedBox(height: 10),
              // Subtitle instruction
              Text(
                context.l10n.scanQRCode,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 8),
              Text(
                context.l10n.letOthersPointTheirPhoneCameraToThisQRCodeToInstantlyViewYourNetworkingProfile,
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
              RepaintBoundary(
                key: _globalKey,
                child: GlassCard(
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
                                  style: TextStyle(
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
                            // Custom Gold Accent Center overlay with initial letter
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                gradient: AppTheme.goldGradient,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  profile.name.isNotEmpty
                                      ? profile.name[0].toUpperCase()
                                      : 'S',
                                  style: TextStyle(
                                    color: AppTheme.secondaryWhite,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),

                      // Card link label
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
                          SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: profileLink),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.l10n.linkCopiedToClipboard),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Icon(
                              Icons.copy_rounded,
                              size: 16,
                              color: isDark
                                  ? AppTheme.accentGold
                                  : AppTheme.accentGoldDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // User social icons below QR
                      if (profile.socialLinks
                          .where((l) => l.isActive)
                          .isNotEmpty)
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: profile.socialLinks
                              .where((l) => l.isActive)
                              .map((link) {
                                return Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark
                                        ? Colors.white12
                                        : Colors.grey.shade100,
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      link.assetPath,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, _, __) => Icon(
                                        Icons.link,
                                        size: 18,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black54,
                                      ),
                                    ),
                                  ),
                                );
                              })
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 48),

              // Action Utilities (Share & Download UI only)
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: context.l10n.shareLink,
                      onTap: () {
                        Share.share(
                          context.l10n.checkOutThisProfile(profileLink),
                          subject: context.l10n.myTapniProfile,
                        );
                      },
                      isGold: true,
                      icon: Icons.share_rounded,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: context.l10n.download,
                      onTap: _downloadQr,
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
