import 'dart:developer';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/utils/constant.dart';
import 'package:tapni_app/utils/theme.dart';

class SharingProfileSheet {
  static void show(
    BuildContext context,
    // required String profileUrl,
    // String? userInitial,
    // Color? initialBgColor,
    // String? profilePhotoUrl,
    // List<Widget>? socialIcons,
  ) {
    final profile = Provider.of<ProfileProvider>(
      context,
      listen: false,
    ).profile;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SharingProfileSheet(
        profileUrl: "${Constants.appDomain}/${profile.username}",
        userInitial: profile.name?.substring(0, 1).toUpperCase() ?? '?',
        initialBgColor: AppTheme.primaryBlack,
        profilePhotoUrl:
            profile.profilePhotoUrl ??
            "${Constants.appDomain}/${profile.username}",
        socialIcons: profile.socialLinks,
      ),
    );
  }
}

class _SharingProfileSheet extends StatefulWidget {
  final String profileUrl;
  final String userInitial;
  final Color initialBgColor;
  final String? profilePhotoUrl;
  final List<SocialLink>? socialIcons;

  const _SharingProfileSheet({
    required this.profileUrl,
    required this.userInitial,
    required this.initialBgColor,
    this.profilePhotoUrl,
    this.socialIcons,
  });

  @override
  State<_SharingProfileSheet> createState() => _SharingProfileSheetState();
}

class _SharingProfileSheetState extends State<_SharingProfileSheet> {
  static const _qrEyeStyle = QrEyeStyle(
    eyeShape: QrEyeShape.circle,
    color: Colors.black,
  );

  static const _qrDataStyle = QrDataModuleStyle(
    dataModuleShape: QrDataModuleShape.circle,
    color: Colors.black,
  );

  final GlobalKey _globalKey = GlobalKey();

  // Store messenger ref BEFORE async gap to show snackbar even if sheet is closed
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
        final file = await File(
          '${tempDir.path}/Tapni_QR_${DateTime.now().millisecondsSinceEpoch}.png',
        ).create();
        await file.writeAsBytes(pngBytes);

        bool hasAccess = await Gal.hasAccess();
        if (!hasAccess) {
          hasAccess = await Gal.requestAccess();
        }

        if (hasAccess) {
          await Gal.putImage(file.path);
          _showSnackBar('QR Code saved to gallery!');
        } else {
          _showSnackBar(
            'Gallery permission required. Please enable it in Settings.',
            color: Colors.red,
          );
        }
      }
    } catch (e) {
      log("$e");
      _showSnackBar('Failed to save QR Code.', color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Sharing Profile',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 22),

            // QR with rounded modules + center initial
            RepaintBoundary(
              key: _globalKey,
              child: Container(
                color: Colors.white,
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      QrImageView(
                        data: widget.profileUrl,
                        version: QrVersions.auto,
                        size: 260,
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                        eyeStyle: _qrEyeStyle,
                        dataModuleStyle: _qrDataStyle,
                        gapless: true,
                      ),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: widget.initialBgColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          widget.userInitial.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            if (widget.socialIcons != null &&
                widget.socialIcons!.where((l) => l.isActive).isNotEmpty)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: widget.socialIcons!
                    .where((l) => l.isActive)
                    .map(
                      (link) => Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade100,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            link.assetPath,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, _, __) => const Icon(
                              Icons.link,
                              size: 20,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            if (widget.socialIcons != null &&
                widget.socialIcons!.where((l) => l.isActive).isNotEmpty)
              const SizedBox(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _circleIconBtn(
                  icon: Icons.download_rounded,
                  onTap: _downloadQr,
                ),
                const SizedBox(width: 14),
                _circleIconBtn(
                  icon: Icons.share_rounded,
                  onTap: () {
                    Share.share(
                      'Check out my Tapni profile: ${widget.profileUrl}',
                      subject: 'My Tapni Profile',
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: GestureDetector(
                onTap: () => _copyLink(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.profileUrl,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF333333),
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Google Wallet integration coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _googleWalletIcon(),
                      const SizedBox(width: 10),
                      const Text(
                        'Add to Google Wallet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.profileUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Widget> _defaultSocialRow() {
    return [
      _profileAvatar(),
      const SizedBox(width: 10),
      _socialCircle('assets/images/png/whatsapp-logo.png'),
      const SizedBox(width: 10),
      _socialCircle('assets/images/png/instagram-logo.png'),
    ];
  }

  Widget _profileAvatar() {
    final photo = widget.profilePhotoUrl?.trim();
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        color: Colors.grey.shade200,
      ),
      clipBehavior: Clip.antiAlias,
      child: photo != null && photo.isNotEmpty
          ? Image.network(
              photo,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initialAvatar(),
            )
          : _initialAvatar(),
    );
  }

  Widget _initialAvatar() {
    return Container(
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: Text(
        widget.userInitial.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _socialCircle(String assetPath) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // border: Border.all(color: Colors.grey.shade200, width: 1),
        // color: Colors.white,
      ),
      // padding: const EdgeInsets.all(8),
      child: Image.asset(assetPath, fit: BoxFit.contain),
    );
  }

  Widget _circleIconBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _googleWalletIcon() {
    return SizedBox(
      width: 26,
      height: 26,
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _walletTile(const Color(0xFF4285F4)),
          _walletTile(const Color(0xFFEA4335)),
          _walletTile(const Color(0xFF34A853)),
          _walletTile(const Color(0xFFFBBC05)),
        ],
      ),
    );
  }

  Widget _walletTile(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
