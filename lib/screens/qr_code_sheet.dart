import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Call this anywhere to show the Sharing Profile bottom sheet:
///   SharingProfileSheet.show(context, profileUrl: 'https://tapni.com/tltqfl43');
class SharingProfileSheet {
  static void show(
    BuildContext context, {
    required String profileUrl,
    String? userInitial, // e.g. 'S'
    Color? initialBgColor, // e.g. Colors.purple
    List<Widget>? socialIcons, // pass your own social icon widgets
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SharingProfileSheet(
        profileUrl: profileUrl,
        userInitial: userInitial ?? 'S',
        initialBgColor: initialBgColor ?? const Color(0xFF9C27B0),
        socialIcons: socialIcons,
      ),
    );
  }
}

class _SharingProfileSheet extends StatelessWidget {
  final String profileUrl;
  final String userInitial;
  final Color initialBgColor;
  final List<Widget>? socialIcons;

  const _SharingProfileSheet({
    required this.profileUrl,
    required this.userInitial,
    required this.initialBgColor,
    this.socialIcons,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                // ── Handle bar ──
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Title ──
                const Text(
                  'Sharing Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),

                // ── QR Code ──
                Stack(
                  alignment: Alignment.center,
                  children: [
                    QrImageView(
                      data: profileUrl,
                      version: QrVersions.auto,
                      size: 240,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                    ),
                    // Center logo / initial
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: initialBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        userInitial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Social Icons ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:
                      socialIcons ??
                      [
                        _defaultSocialIcon(
                          icon: "assets/images/png/instagram-logo.png",
                        ),
                        const SizedBox(width: 12),
                        _defaultSocialIcon(
                          icon: "assets/images/png/linkedin-logo.png",
                        ),
                        const SizedBox(width: 12),
                        _defaultSocialIcon(
                          icon: "assets/images/png/whatsapp-logo.png",
                        ),
                      ],
                ),
                const SizedBox(height: 32),

                // ── Download & Copy Link Buttons ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Download QR
                    _circleIconBtn(
                      icon: Icons.download_rounded,
                      onTap: () {
                        // TODO: save QR image to gallery
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('QR saved to gallery!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),

                    // Copy link
                    _circleIconBtn(
                      icon: Icons.link_rounded,
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: profileUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Link copied!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── URL bar with copy icon ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: profileUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copied!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              profileUrl,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.copy_rounded,
                            size: 18,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Add to Google Wallet button ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () {
                      // TODO: integrate Google Wallet pass
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google Wallet coloured dot icon
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
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _defaultSocialIcon({required String icon}) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
      child: Image.asset(icon, height: 25, width: 25),
    );
  }

  Widget _circleIconBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _googleWalletIcon() {
    // Simple coloured squares mimicking Google Wallet icon
    return SizedBox(
      width: 28,
      height: 28,
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF4285F4),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEA4335),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF34A853),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFBBC05),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}
