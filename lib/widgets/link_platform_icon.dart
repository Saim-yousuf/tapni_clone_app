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

  /// Brand tiles (e.g. TikTok) often ship with padded + pre-rounded corners.
  /// Scale slightly so BoxFit.cover tiles fill edge-to-edge under ClipRRect.
  Widget _edgeFill(Widget image) {
    if (fit != BoxFit.cover) return image;
    return SizedBox(
      width: size,
      height: size,
      child: ClipRect(
        child: Transform.scale(
          scale: 1.16,
          child: image,
        ),
      ),
    );
  }

  Widget _assetFallback() {
    // BoxFit.cover: fill the tile so radius/size match network logos.
    if (fit == BoxFit.cover) {
      return _edgeFill(
        Image.asset(
          link.assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (_, __, ___) => ColoredBox(
            color: const Color(0xFFF5F5F5),
            child: Icon(Icons.link, size: size * 0.4),
          ),
        ),
      );
    }
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
    if (link.isGalleryLink) {
      final provider = Provider.of<ProfileProvider>(context);
      final logo = _networkLogo(link.logoUrl) ??
          _networkLogo(provider.catalogLogoFor(link));
      if (logo != null) {
        return _edgeFill(
          Image.network(
            logo,
            width: size,
            height: size,
            fit: fit,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) => _galleryFallback(),
          ),
        );
      }
      return _galleryFallback();
    }

    if (link.isDocumentLink) {
      return DocumentKindIcon(
        fileUrl: link.fullUrl,
        fileName: link.fileExt,
        fileExt: link.fileExt,
        customLogoUrl: link.logoUrl,
        size: size,
        radius: size * 0.22,
      );
    }

    final provider = Provider.of<ProfileProvider>(context);
    final logo = _networkLogo(link.logoUrl) ??
        _networkLogo(provider.catalogLogoFor(link));

    if (logo == null) return _assetFallback();

    return _edgeFill(
      Image.network(
        logo,
        width: size,
        height: size,
        fit: fit,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => _assetFallback(),
      ),
    );
  }

  Widget _galleryFallback() {
    return ColoredBox(
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: Icon(
          Icons.photo_library_rounded,
          size: size * 0.42,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }
}
