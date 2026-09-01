import 'package:flutter/material.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

/// Official-style Add to Apple / Google Wallet button (black pill, two-line label).
class WalletBrandButton extends StatelessWidget {
  static const double height = WaUi.primaryButtonHeight;

  final String title;
  final String subtitle;
  final String iconAsset;
  final VoidCallback? onPressed;
  final bool loading;

  const WalletBrandButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconAsset,
    required this.onPressed,
    this.loading = false,
  });

  factory WalletBrandButton.apple({
    Key? key,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return WalletBrandButton(
      key: key,
      title: 'Add to',
      subtitle: 'Apple Wallet',
      iconAsset: 'assets/images/png/apple-wallet-icon.png',
      onPressed: onPressed,
      loading: loading,
    );
  }

  factory WalletBrandButton.google({
    Key? key,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return WalletBrandButton(
      key: key,
      title: 'Add to',
      subtitle: 'Google Wallet',
      iconAsset: 'assets/images/png/google-wallet-icon.png',
      onPressed: onPressed,
      loading: loading,
    );
  }

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Material(
        color: Colors.black,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          customBorder: const StadiumBorder(),
          child: Opacity(
            opacity: disabled && !loading ? 0.5 : 1,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          iconAsset,
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                height: 1.1,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.1,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
