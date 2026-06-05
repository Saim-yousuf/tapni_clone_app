import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Tapni-style "Sharing Profile" bottom sheet.
/// ```dart
/// SharingProfileSheet.show(
///   context,
///   profileUrl: 'https://tapni.com/tltqfl43',
///   userInitial: 'S',
///   profilePhotoUrl: profile.profilePhotoUrl,
/// );
/// ```
class SharingProfileSheet {
  static void show(
    BuildContext context, {
    required String profileUrl,
    String? userInitial,
    Color? initialBgColor,
    String? profilePhotoUrl,
    List<Widget>? socialIcons,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SharingProfileSheet(
        profileUrl: profileUrl,
        userInitial: userInitial ?? 'S',
        initialBgColor: initialBgColor ?? const Color(0xFF7B1FA2),
        profilePhotoUrl: profilePhotoUrl,
        socialIcons: socialIcons,
      ),
    );
  }
}

class _SharingProfileSheet extends StatelessWidget {
  final String profileUrl;
  final String userInitial;
  final Color initialBgColor;
  final String? profilePhotoUrl;
  final List<Widget>? socialIcons;

  const _SharingProfileSheet({
    required this.profileUrl,
    required this.userInitial,
    required this.initialBgColor,
    this.profilePhotoUrl,
    this.socialIcons,
  });

  static const _qrEyeStyle = QrEyeStyle(
    eyeShape: QrEyeShape.square,
    color: Colors.black,
  );

  static const _qrDataStyle = QrDataModuleStyle(
    dataModuleShape: QrDataModuleShape.circle,
    color: Colors.black,
  );

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
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
                SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      QrImageView(
                        data: profileUrl,
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
                          color: initialBgColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          userInitial.toUpperCase(),
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
                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: socialIcons ?? _defaultSocialRow(),
                ),
                const SizedBox(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _circleIconBtn(
                      icon: Icons.download_rounded,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('QR saved to gallery!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 14),
                    _circleIconBtn(
                      icon: Icons.link_rounded,
                      onTap: () => _copyLink(context),
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
                              profileUrl,
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
      },
    );
  }

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: profileUrl));
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
    final photo = profilePhotoUrl?.trim();
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
        userInitial.toUpperCase(),
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
