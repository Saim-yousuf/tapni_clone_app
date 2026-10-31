import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/helper/link_entries_cache.dart';
import 'package:tapni_app/helper/log_helper.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/gallery_item.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/repository/business_website_repo.dart';
import 'package:tapni_app/screens/business_website/business_website_setup_screen.dart'
    show catalogTypeFromWebsiteType, websiteTypeFromCatalogType;
import 'package:tapni_app/screens/business_website/business_website_webview_screen.dart';
import 'package:tapni_app/screens/gallery_link_screen.dart';
import 'package:tapni_app/utils/api_endpoint.dart';
import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:tapni_app/utils/catalog_helper.dart' show catalogTypesMatch;
import 'package:tapni_app/widgets/bank_widgets.dart';
import 'package:tapni_app/widgets/document_viewer.dart';
import 'package:tapni_app/widgets/link_entries_sheet.dart';
import 'package:tapni_app/widgets/menu_catalog_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

export 'package:tapni_app/utils/catalog_helper.dart' show catalogTypesMatch;

/// Infer catalog family from a business_website tile (catalogType, fieldLabel, or URL).
String? catalogTypeFromWebsiteLink(SocialLink link) {
  final ct = (link.catalogType ?? '').trim();
  if (ct.isNotEmpty) return ct;
  final field = (link.fieldLabel ?? '').trim().toLowerCase();
  if (field.isNotEmpty) {
    return catalogTypeFromWebsiteType(websiteTypeFromCatalogType(field));
  }
  final url = link.fullUrl.toLowerCase();
  if (url.contains('/products')) return 'products';
  if (url.contains('/service')) return 'services';
  if (url.contains('/portfolio')) return 'portfolio';
  if (url.contains('/menu')) return 'menu';
  return null;
}

/// Profile website link that owns this catalog inventory (same catalogType).
SocialLink? businessWebsiteForCatalogLink(
  BuildContext context,
  SocialLink catalogLink, {
  List<SocialLink>? links,
}) {
  try {
    final all = links ??
        Provider.of<ProfileProvider>(context, listen: false).profile.socialLinks;
    final type = (catalogLink.catalogType ?? '').trim();
    final wanted = type.isEmpty ? 'menu' : type;
    for (final link in all) {
      if (!link.isBusinessWebsiteLink || !link.isActive) continue;
      if (link.fullUrl.isEmpty) continue;
      final linkType = catalogTypeFromWebsiteLink(link);
      if (catalogTypesMatch(linkType, wanted) ||
          catalogTypesMatch(link.catalogType, wanted)) {
        return link;
      }
    }
    // Fallback: any active website with a public URL (single-site profiles).
    final websites = all
        .where(
          (link) =>
              link.isBusinessWebsiteLink &&
              link.isActive &&
              link.fullUrl.isNotEmpty,
        )
        .toList();
    if (websites.length == 1) return websites.first;
  } catch (_) {}
  return null;
}

/// Hide catalog inventory tiles when a typed website already represents them.
bool isCatalogInventoryHiddenByWebsite(SocialLink link, List<SocialLink> all) {
  if (!link.isCatalogLink) return false;
  final type = (link.catalogType ?? '').trim();
  final wanted = type.isEmpty ? 'menu' : type;
  for (final other in all) {
    if (!other.isActive || !other.isBusinessWebsiteLink) continue;
    // Presence of the website tile is enough — draft/empty URL still owns inventory.
    if (catalogTypesMatch(catalogTypeFromWebsiteLink(other), wanted) ||
        catalogTypesMatch(other.catalogType, wanted)) {
      return true;
    }
  }
  return false;
}

/// Keep only the first active business_website tile per catalog type family.
bool isDuplicateBusinessWebsiteLink(SocialLink link, List<SocialLink> all) {
  if (!link.isBusinessWebsiteLink) return false;
  final type = (link.catalogType ?? '').trim();
  for (final other in all) {
    if (other.id == link.id) return false;
    if (!other.isActive || !other.isBusinessWebsiteLink) continue;
    if (catalogTypesMatch(other.catalogType, type.isEmpty ? 'menu' : type)) {
      return true;
    }
  }
  return false;
}

/// Keep only the first catalog inventory tile per catalog type family.
bool isDuplicateCatalogInventoryLink(SocialLink link, List<SocialLink> all) {
  if (!link.isCatalogLink) return false;
  final type = (link.catalogType ?? '').trim();
  for (final other in all) {
    if (other.id == link.id) return false;
    if (!other.isActive || !other.isCatalogLink) continue;
    if (catalogTypesMatch(other.catalogType, type.isEmpty ? 'menu' : type)) {
      return true;
    }
  }
  return false;
}

Future<bool> openPublishedWebsiteForCatalog(
  BuildContext context,
  SocialLink catalogLink, {
  /// Links of the profile being viewed (scanned / public). Prefer over
  /// [ProfileProvider], which is the signed-in viewer on scan screens.
  List<SocialLink>? peerLinks,
  /// Vanity fallback: `/{username}/menu` when no website tile URL is paired.
  String? ownerUsername,
  /// Own-profile only: call `/mine` when peer links are not supplied.
  bool allowOwnerMineFallback = true,
}) async {
  final websiteType = websiteTypeFromCatalogType(
    catalogLink.catalogType?.isNotEmpty == true
        ? catalogLink.catalogType
        : 'menu',
  );

  Future<bool> openUrl(
    String url,
    String title, {
    bool previewMode = false,
  }) async {
    if (url.trim().isEmpty) return false;
    if (!context.mounted) return false;
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => BusinessWebsiteWebViewScreen(
          url: url,
          title: title,
          previewMode: previewMode,
        ),
      ),
    );
    return true;
  }

  bool viewingOwnProfile = peerLinks == null;
  try {
    final me =
        Provider.of<ProfileProvider>(context, listen: false).profile;
    final mineUser =
        (me.username ?? '').trim().replaceFirst(RegExp(r'^@'), '');
    final viewed = (ownerUsername ?? '').trim().replaceFirst(RegExp(r'^@'), '');
    if (viewed.isNotEmpty && mineUser.isNotEmpty && viewed == mineUser) {
      viewingOwnProfile = true;
    }
  } catch (_) {}

  final titleFallback = catalogLink.platformName;

  // Owner: resolve publish state via /mine so draft/unpublished use preview.
  if (viewingOwnProfile) {
    try {
      final repo = BusinessWebsiteRepo();
      final res = await repo.getMine(websiteType: websiteType);
      if (!context.mounted) return false;
      final website = res.success ? repo.parseWebsite(res.data) : null;
      final url = website?.resolvedPublicUrl.trim() ?? '';
      if (url.isNotEmpty) {
        return openUrl(
          url,
          website?.name.isNotEmpty == true ? website!.name : titleFallback,
          previewMode: website?.isPublished != true,
        );
      }
      // No website for this type — fall through to native catalog.
      if (!allowOwnerMineFallback) return false;
    } catch (_) {}
  }

  // 1) Pair against the viewed profile's links when provided (scan / public).
  if (peerLinks != null) {
    final paired = businessWebsiteForCatalogLink(
      context,
      catalogLink,
      links: peerLinks,
    );
    if (paired != null && paired.fullUrl.isNotEmpty) {
      return openUrl(
        paired.fullUrl,
        paired.platformName.isNotEmpty ? paired.platformName : titleFallback,
      );
    }
  } else {
    final paired = businessWebsiteForCatalogLink(context, catalogLink);
    if (paired != null && paired.fullUrl.isNotEmpty) {
      return openUrl(
        paired.fullUrl,
        paired.platformName.isNotEmpty ? paired.platformName : titleFallback,
      );
    }
  }

  // 2) Vanity public URL only when this profile has a matching website tile.
  // Never invent /username/products (etc.) — that 404s when no site exists.
  final username = (ownerUsername ?? '').trim().replaceFirst(RegExp(r'^@'), '');
  if (username.isNotEmpty && peerLinks != null) {
    final wanted = catalogTypeFromWebsiteType(websiteType);
    final hasWebsiteTile = peerLinks.any((l) {
      if (!l.isActive || !l.isBusinessWebsiteLink) return false;
      return catalogTypesMatch(catalogTypeFromWebsiteLink(l), wanted) ||
          catalogTypesMatch(l.catalogType, wanted);
    });
    if (hasWebsiteTile) {
      final vanity = Api.businessWebsite.vanitySite(username, websiteType);
      return openUrl(vanity, titleFallback);
    }
  }

  // 3) Owner fallback already attempted above when viewingOwnProfile.
  return false;
}

class Launcher {
  static SocialLink _freshFromProvider(BuildContext context, SocialLink model) {
    try {
      final links =
          Provider.of<ProfileProvider>(context, listen: false).profile.socialLinks;
      for (final link in links) {
        if (link.id == model.id) return link;
      }
      for (final link in links) {
        if (model.templateId != null &&
            model.templateId!.isNotEmpty &&
            link.templateId == model.templateId) {
          return link;
        }
      }
      for (final link in links) {
        if (link.platformName.toLowerCase() == model.platformName.toLowerCase()) {
          return link;
        }
      }
    } catch (_) {}
    return model;
  }

  static Future<void> openLink(
    SocialLink model,
    context, {
    String? businessId,
    String? businessName,
    String? businessCategory,
    String? currency,
    List<GalleryItem>? galleryItems,
    bool isGalleryOwner = false,
    /// When set (e.g. custom card scan), only these multi-entry values appear.
    Set<String>? allowedEntryIds,
    /// Social links of the profile being viewed (required on scan/public).
    List<SocialLink>? peerLinks,
    /// Username of the profile being viewed — vanity website fallback.
    String? ownerUsername,
  }) async {
    PrintLog.logMessage("model.fieldType: ${model.fieldType}");
    if (model.isGalleryLink) {
      final items = galleryItems ??
          (isGalleryOwner
              ? Provider.of<ProfileProvider>(context, listen: false)
                    .profile
                    .gallery
              : const <GalleryItem>[]);
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GalleryLinkScreen(
            items: items,
            isOwner: isGalleryOwner,
          ),
        ),
      );
      return;
    }
    if (model.isBusinessWebsiteLink) {
      final websiteType = websiteTypeFromCatalogType(
        model.catalogType?.isNotEmpty == true ? model.catalogType : 'menu',
      );
      var url = model.fullUrl;
      var previewMode = false;

      bool viewingOwn = peerLinks == null;
      try {
        final me =
            Provider.of<ProfileProvider>(context, listen: false).profile;
        final mineUser =
            (me.username ?? '').trim().replaceFirst(RegExp(r'^@'), '');
        final viewed =
            (ownerUsername ?? '').trim().replaceFirst(RegExp(r'^@'), '');
        if (viewed.isNotEmpty && mineUser.isNotEmpty && viewed == mineUser) {
          viewingOwn = true;
        }
        if (businessId != null &&
            businessId.isNotEmpty &&
            businessId == me.id) {
          viewingOwn = true;
        }
      } catch (_) {}

      if (viewingOwn) {
        try {
          final repo = BusinessWebsiteRepo();
          final res = await repo.getMine(websiteType: websiteType);
          if (!context.mounted) return;
          final website = res.success ? repo.parseWebsite(res.data) : null;
          if (website != null) {
            final resolved = website.resolvedPublicUrl.trim();
            if (resolved.isNotEmpty) url = resolved;
            previewMode = !website.isPublished;
          }
        } catch (_) {}
      } else if (url.isEmpty &&
          peerLinks != null &&
          (ownerUsername ?? '').trim().isNotEmpty) {
        url = Api.businessWebsite.vanitySite(
          ownerUsername!.trim(),
          websiteType,
        );
      }
      if (url.isEmpty) return;
      await Navigator.of(context).push(
        AppPageRoute(
          builder: (_) => BusinessWebsiteWebViewScreen(
            url: url,
            title: model.platformName.isNotEmpty
                ? model.platformName
                : 'Website',
            previewMode: previewMode,
          ),
        ),
      );
      return;
    }
    if (model.isDocumentLink) {
      await openCatalogDocument(
        context,
        CatalogItem(
          name: model.platformName,
          imageUrl: model.fullUrl,
        ),
        fileExt: model.fileExt,
      );
      return;
    }
    if (model.isCatalogLink) {
      // Prefer published website template when paired; else native catalog sheet.
      final opened = await openPublishedWebsiteForCatalog(
        context,
        model,
        peerLinks: peerLinks,
        ownerUsername: ownerUsername,
        allowOwnerMineFallback: peerLinks == null,
      );
      if (opened) return;
      openCatalogLink(
        context: context,
        link: model,
        businessId: businessId,
        businessName: businessName,
        businessCategory: businessCategory,
        currency: currency,
        businessUsername: ownerUsername,
      );
      return;
    }
    if (model.fieldType == "bank") {
      final details = model.bankDetails ?? const <String, String>{};
      await BankDetailDialog.show(
        context,
        title: model.platformName,
        bankDetails: {
          'accountHolderName':
              details['accountHolderName'] ?? details['holder'] ?? '',
          'iban': details['iban'] ?? '',
          'accountNumber':
              details['accountNumber'] ?? details['account'] ?? '',
        },
      );
      return;
    }

    // Always re-resolve entries from provider + local cache before deciding.
    var link = _freshFromProvider(context, model);
    try {
      final userId =
          Provider.of<ProfileProvider>(context, listen: false).profile.id ?? '';
      link = await LinkEntriesCache.resolve(link, userId: userId);
    } catch (_) {}

    if (allowedEntryIds != null &&
        allowedEntryIds.isNotEmpty &&
        link.effectiveEntries.isNotEmpty) {
      final filtered = link.effectiveEntries
          .where((e) => allowedEntryIds.contains(e.id))
          .toList();
      if (filtered.isEmpty) return;
      link = link.copyWith(
        entries: filtered,
        value: filtered.first.value,
      );
    }

    PrintLog.logMessage(
      "link.entries=${link.entries?.length ?? 0} multi=${link.hasMultipleEntries}",
    );

    final publicEntries = link.publicEntries;
    if (publicEntries.length > 1) {
      await showLinkEntriesSheet(
        context: context,
        link: link.copyWith(
          entries: publicEntries,
          value: publicEntries.first.value,
        ),
      );
      return;
    }
    if (publicEntries.length == 1) {
      link = link.copyWith(
        entries: publicEntries,
        value: publicEntries.first.value,
      );
    }

    final launchTarget = link.fullUrl;
    if (launchTarget.isEmpty) return;
    await launchUrl(
      Uri.parse(launchTarget),
      mode: LaunchMode.externalApplication,
    );
  }
}
