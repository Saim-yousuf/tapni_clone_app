import 'package:flutter/material.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/utils/theme.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class SocialIconButton extends StatelessWidget {
  final SocialLink socialLink;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool showLabel;

  const SocialIconButton({
    Key? key,
    required this.socialLink,
    required this.onTap,
    this.onLongPress,
    this.showLabel = false,
  }) : super(key: key);

  Color getBrandColor() {
    switch (socialLink.platform) {
      case SocialPlatform.whatsApp:
        return const Color(0xFF25D366);
      case SocialPlatform.linkedIn:
        return const Color(0xFF0077B5);
      case SocialPlatform.instagram:
        return const Color(0xFFE1306C);
        // case SocialPlatform.facebook:
        //   return const Color(0xFF1877F2);
        // case SocialPlatform.youTube:
        //   return const Color(0xFFFF0000);
        // case SocialPlatform.website:
        return AppTheme.accentGold;
      default:
        return AppTheme.primaryBlack;
    }
  }

  IconData getBrandIcon() {
    switch (socialLink.platform) {
      case SocialPlatform.whatsApp:
        return Icons.phone_android; // customized representing WhatsApp/chat
      case SocialPlatform.linkedIn:
        return Icons.business; // representing LinkedIn
      case SocialPlatform.instagram:
        return Icons.camera_alt_outlined; // representing Instagram
      // case SocialPlatform.facebook:
      //   return Icons.facebook_outlined; // representing Facebook
      // case SocialPlatform.youTube:
      //   return Icons.play_circle_outline; // representing YouTube
      // case SocialPlatform.website:
      //   return Icons.language; // representing Website
      default:
        return Icons.link;
    }
  }

  Widget _buildIcon(bool isDark) {
    if (socialLink.logoUrl?.isNotEmpty == true) {
      return Padding(
        padding: EdgeInsets.all(6.0),
        child: Image.network(
          socialLink.logoUrl!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Image.asset(
            SocialLink.getAssetPath(socialLink.platform),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.link, color: Colors.white, size: 24),
          ),
        ),
      );
    }

    switch (socialLink.platform) {
      case SocialPlatform.whatsApp:
        return Icon(
          Icons.chat_bubble_outline,
          color: Colors.white,
          size: 24,
        );
      case SocialPlatform.linkedIn:
        return const Text(
          'in',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            fontFamily: 'sans-serif',
          ),
        );
      case SocialPlatform.instagram:
        return const Icon(
          Icons.camera_alt_outlined,
          color: Colors.white,
          size: 24,
        );
      // case SocialPlatform.facebook:
      //   return const Icon(Icons.facebook, color: Colors.white, size: 26);
      // case SocialPlatform.youTube:
      //   return const Icon(Icons.play_arrow, color: Colors.white, size: 26);
      // case SocialPlatform.website:
      //   return const Icon(
      //     Icons.language_outlined,
      //     color: Colors.white,
      //     size: 24,
      //   );
      default:
        return Padding(
          padding: const EdgeInsets.all(6.0),
          child: Image.asset(
            SocialLink.getAssetPath(socialLink.platform),
            fit: BoxFit.contain,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final brandColor = getBrandColor();

    Widget button = Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: socialLink.isActive
            ? brandColor.withOpacity(0.9)
            : (isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05)),
        shape: BoxShape.circle,
        border: Border.all(
          color: socialLink.isActive
              ? brandColor.withOpacity(0.5)
              : (isDark ? Colors.white10 : Colors.black12),
          width: 1,
        ),
        boxShadow: socialLink.isActive
            ? [
                BoxShadow(
                  color: brandColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Opacity(
          opacity: socialLink.isActive ? 1.0 : 0.4,
          child: _buildIcon(isDark),
        ),
      ),
    );

    if (!showLabel) {
      return GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: button,
      );
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          button,
          const SizedBox(height: 8),
          Text(
            socialLink.platformName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: socialLink.isActive
                  ? (isDark ? Colors.white : Colors.black)
                  : theme.disabledColor,
            ),
          ),
        ],
      ),
    );
  }
}
