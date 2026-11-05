import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Default face when a profile has no photo — used app-wide.
class BarqodyProfilePhoto {
  BarqodyProfilePhoto._();

  static const assetPath = 'assets/images/png/barqody_avatar.png';

  static ImageProvider get provider => const AssetImage(assetPath);

  /// Fills parent (use inside [ClipOval] / sized box).
  static Widget placeholder({BoxFit fit = BoxFit.cover}) {
    return Image.asset(
      assetPath,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: Color(0xFFEEF2F5),
        child: Icon(Icons.person_rounded, color: Color(0xFF6B7280)),
      ),
    );
  }

  /// Network photo when [photoUrl] is set; otherwise [placeholder].
  static Widget networkOrPlaceholder({
    required String? photoUrl,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    final url = photoUrl?.trim();
    if (url == null || url.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: placeholder(fit: fit),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      useOldImageOnUrlChange: true,
      // Soft tile while loading — not the default avatar (avoids face flash).
      errorWidget: (_, __, ___) => placeholder(fit: fit),
      placeholder: (_, __) => const ColoredBox(color: Color(0xFFEEF2F5)),
    );
  }
}
