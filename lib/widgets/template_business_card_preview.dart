import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tapni_app/models/card_template.dart';

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
  final double width;

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
    this.width = 340,
  });

  @override
  Widget build(BuildContext context) {
    final hasBorder = template.backgroundColor == const Color(0xFFFFFFFF);
    final cover = coverPhotoUrl?.trim();

    return Container(
      width: width,
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
            offset: Offset(0, 8),
          ),
        ],
        image: cover != null && cover.isNotEmpty
            ? DecorationImage(
                image: _imageProvider(cover),
                fit: BoxFit.cover,
              )
            : null,
      ),
      padding: EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.contactless,
                color: template.brandingColor.withValues(alpha: 0.85),
                size: 26,
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
          const SizedBox(height: 18),
          _buildAvatar(),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: template.textColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              height: 1.2,
            ),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: template.brandingColor.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
          if (bio != null && bio!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              bio!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: template.textColor.withValues(alpha: 0.85),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: profileUrl,
              size: 148,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            profileUrl.replaceAll('https://', ''),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: template.labelColor,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final photo = profilePhotoUrl?.trim();
    if (photo != null && photo.isNotEmpty) {
      ImageProvider imageProvider = _imageProvider(photo);
      return Container(
        width: 78,
        height: 78,
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
      width: 78,
      height: 78,
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
          fontSize: 26,
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
