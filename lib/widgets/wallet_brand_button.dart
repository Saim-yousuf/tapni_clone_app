import 'package:flutter/material.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

/// Official-style Add to Apple / Google Wallet button.
class WalletBrandButton extends StatelessWidget {
  static const double height = WaUi.primaryButtonHeight;

  final String title;
  final String subtitle;
  final String iconAsset;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outlined;

  const WalletBrandButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconAsset,
    required this.onPressed,
    this.loading = false,
    this.outlined = false,
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
      outlined: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    final fg = outlined ? Colors.black : Colors.white;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Material(
        color: outlined ? Colors.white : Colors.black,
        shape: StadiumBorder(
          side: outlined
              ? const BorderSide(color: Colors.black, width: 1.2)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          customBorder: const StadiumBorder(),
          child: Opacity(
            opacity: disabled && !loading ? 0.5 : 1,
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: fg,
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
                              style: TextStyle(
                                color: fg,
                                fontSize: 11,
                                height: 1.1,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.1,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: fg,
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
