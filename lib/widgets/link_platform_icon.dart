import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/widgets/cached_app_image.dart';
import 'package:tapni_app/widgets/document_kind_icon.dart';

/// Same catalog brand tiles as Add Link. Falls back to bundled assets.
///
/// Loading uses shimmer — never another brand/entry photo — so
/// Profile / Edit / Scanned / Add Link don't flash "wrong icon → real icon".
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

  /// Add Link catalog tiles use size `130` / radius `24` — keep that ratio
  /// on Profile / Scanned / Edit so icons match.
  static const double catalogTileSize = 130;
  static const double catalogTileRadius = 24;

  static double cornerRadius(double size) =>
      size * (catalogTileRadius / catalogTileSize);

  String? _networkLogo(String? value) {
    final logo = value?.trim() ?? '';
    if (logo.startsWith('http://') || logo.startsWith('https://')) {
      return logo;
    }
    return null;
  }

  /// Add Link shows the catalog image with [BoxFit.cover] and no extra scale.
  /// Keep the same framing on profile / scanned / edit tiles.
  Widget _edgeFill(Widget image) => image;

  Widget _softTile() {
    return ColoredBox(
      color: const Color(0xFFF5F5F5),
      child: SizedBox(width: size, height: size),
    );
  }

  Widget _loadingTile() {
    return ImageShimmerPlaceholder(
      width: size,
      height: size,
    );
  }

  Widget _cachedNet(
    String logo, {
    required Widget Function() onError,
  }) {
    return CachedNetworkImage(
      imageUrl: logo,
      width: size,
      height: size,
      fit: fit,
      alignment: Alignment.center,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      useOldImageOnUrlChange: true,
      errorWidget: (_, __, ___) => onError(),
      // Soft tile only — image is disk-cached; shimmer here flashes on every
      // rebuild even when the file is already local.
      placeholder: (_, __) => _softTile(),
    );
  }

  Widget _assetFallback() {
    if (fit == BoxFit.cover) {
      return _edgeFill(
        Image.asset(
          link.assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _softTile(),
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
        gaplessPlayback: true,
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
          _cachedNet(logo, onError: _galleryFallback),
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
    final explicitLogo = _networkLogo(link.logoUrl);
    final catalogLogo = _networkLogo(provider.catalogLogoFor(link));
    final hasAsset = link.assetPath.trim().isNotEmpty;

    // Link-level custom logo (Custom Link / catalog / website) — show on profile.
    final allowLinkLogo = link.isCustom ||
        link.isCatalogLink ||
        link.isBusinessWebsiteLink;
    if (allowLinkLogo && explicitLogo != null) {
      return _edgeFill(
        _cachedNet(
          explicitLogo,
          onError: () {
            if (catalogLogo != null) {
              return _cachedNet(
                catalogLogo,
                onError: () => hasAsset ? _assetFallback() : _softTile(),
              );
            }
            return hasAsset ? _assetFallback() : _softTile();
          },
        ),
      );
    }

    // Admin / catalog brand icon only — never link.logoUrl here.
    // logoUrl is often a polluted entry photo and caused a flash
    // (number-1 image → WhatsApp) while the catalog was still loading.
    if (catalogLogo != null) {
      return _edgeFill(
        _cachedNet(
          catalogLogo,
          onError: () => hasAsset ? _assetFallback() : _softTile(),
        ),
      );
    }

    // Shimmer only on first catalog fetch (no logos in memory yet).
    // Refetch keeps existing catalogLogo above — image stays cached.
    if (provider.isLinkCatalogLoading && provider.linkCatalog.isEmpty) {
      return _loadingTile();
    }

    if (hasAsset) return _assetFallback();

    return _softTile();
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
