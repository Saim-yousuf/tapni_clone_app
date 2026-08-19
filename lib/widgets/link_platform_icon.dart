import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/widgets/document_kind_icon.dart';

/// Same catalog brand tiles as Add Link. Falls back to bundled assets.
class LinkPlatformIcon extends StatelessWidget {
  const LinkPlatformIcon({
    super.key,
    required this.link,
    this.size = 60,
    this.fit = BoxFit.cover,
  });

  final SocialLink link;
  final double size;
  final BoxFit fit;

  String? _networkLogo(String? value) {
    final logo = value?.trim() ?? '';
    if (logo.startsWith('http://') || logo.startsWith('https://')) {
      return logo;
    }
    return null;
  }

  Widget _assetFallback() {
    return Padding(
      padding: EdgeInsets.all(size * 0.14),
      child: Image.asset(
        link.assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.link,
          size: size * 0.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (link.isDocumentLink) {
      return DocumentKindIcon(
        fileUrl: link.fullUrl,
        fileName: link.platformName,
        customLogoUrl: link.logoUrl,
        size: size,
        radius: size * 0.22,
      );
    }

    final provider = Provider.of<ProfileProvider>(context);
    final logo = _networkLogo(link.logoUrl) ??
        _networkLogo(provider.catalogLogoFor(link));

    if (logo == null) return _assetFallback();

    return Image.network(
      logo,
      width: size,
      height: size,
      fit: fit,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) => _assetFallback(),
    );
  }
}
