import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tapni_app/models/card_template.dart';
import 'package:tapni_app/utils/branded_qr.dart';
import 'package:tapni_app/widgets/branded_qr_image.dart';
import 'package:tapni_app/widgets/verified_name.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';

class TemplateBusinessCardPreview extends StatelessWidget {
  final CardTemplate template;
  final String name;
  final String profileUrl;
  final String userInitial;
  final String? profilePhotoUrl;
  final String? coverPhotoUrl;
  final String? subtitle;
  final String? bio;
  final bool verified;
  final double width;
  final double? height;

  /// When false, hides the profile URL under the QR (matches Card mock).
  final bool showProfileUrl;

  const TemplateBusinessCardPreview({
    super.key,
    required this.template,
    required this.name,
    required this.profileUrl,
    required this.userInitial,
    this.profilePhotoUrl,
    this.coverPhotoUrl,
    this.subtitle,
    this.bio,
    this.verified = false,
    this.width = 340,
    this.height,
    this.showProfileUrl = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasBorder = template.backgroundColor == const Color(0xFFFFFFFF);
    final cover = coverPhotoUrl?.trim();
    final compact = height != null;
    final pad = compact ? 18.0 : 22.0;
    final avatarSize = compact ? 70.0 : 78.0;
    final qrSize = compact
        ? math.min(136.0, math.max(112.0, (height! - 260) * 0.55))
        : 148.0;

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cover == null || cover.isEmpty ? template.backgroundColor : null,
        borderRadius: BorderRadius.circular(24),
        border: hasBorder
            ? Border.all(color: Colors.black.withValues(alpha: 0.08), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        image: cover != null && cover.isNotEmpty
            ? DecorationImage(
                image: _imageProvider(cover),
                fit: BoxFit.cover,
              )
            : null,
      ),
      padding: EdgeInsets.all(pad),
      child: Column(
        mainAxisSize: height == null ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  BrandedQr.logoAsset,
                  width: 26,
                  height: 26,
                  fit: BoxFit.cover,
                ),
              ),
              Text(
                context.l10n.barqody,
                style: TextStyle(
                  color: template.brandingColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 18),
          _buildAvatar(avatarSize),
          SizedBox(height: compact ? 10 : 14),
          VerifiedName(
            name: name,
            verified: verified,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: template.textColor,
              fontSize: compact ? 18 : 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              height: 1.15,
            ),
            badgeColor: const Color(0xFFFFCC00),
            badgeSize: 18,
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: template.brandingColor.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
          if (bio != null && bio!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              bio!,
              textAlign: TextAlign.center,
              maxLines: compact ? 2 : 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: template.textColor.withValues(alpha: 0.85),
                fontSize: compact ? 12.5 : 14,
                fontWeight: FontWeight.w400,
                height: 1.3,
              ),
            ),
          ],
          if (height != null)
            const Spacer(flex: 1)
          else
            const SizedBox(height: 18),
          Container(
            padding: EdgeInsets.all(compact ? 10 : 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: BrandedQrImage(
              data: profileUrl,
              size: qrSize,
              padding: EdgeInsets.zero,
              backgroundColor: Colors.white,
            ),
          ),
          if (showProfileUrl) ...[
            const SizedBox(height: 8),
            Text(
              profileUrl.replaceAll('https://', ''),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: template.labelColor,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(double size) {
    final photo = profilePhotoUrl?.trim();
    if (photo != null && photo.isNotEmpty) {
      final imageProvider = _imageProvider(photo);
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: template.textColor.withValues(alpha: 0.2),
            width: 2,
          ),
          image: DecorationImage(
            image: imageProvider,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: template.isDark
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.black.withValues(alpha: 0.08),
      ),
      alignment: Alignment.center,
      child: Text(
        userInitial.toUpperCase(),
        style: TextStyle(
          color: template.textColor,
          fontSize: size * 0.33,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static ImageProvider _imageProvider(String path) {
    if (path.startsWith('data:')) {
      return MemoryImage(_decodeDataUrl(path));
    }
    if (path.startsWith('/') || path.contains(':\\')) {
      return FileImage(File(path));
    }
    return NetworkImage(path);
  }

  static Uint8List _decodeDataUrl(String dataUrl) {
    final comma = dataUrl.indexOf(',');
    final base64Data = comma >= 0 ? dataUrl.substring(comma + 1) : dataUrl;
    return base64Decode(base64Data);
  }
}
