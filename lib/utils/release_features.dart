import 'package:tapni_app/models/social_link.dart';

/// Manual release gates for the BarQody initial release.
///
/// Independent of per-user [UserProfile.enabledFeatures] /
/// [BusinessFeatureAccess]. Flip these constants manually when reactivating
/// surfaces — never derive from build flavor or environment.
class ReleaseFeatures {
  ReleaseFeatures._();

  // ---- Enabled for initial release (Personal Digital Card) ----
  static const bool personalDigitalCard = true;
  static const bool personalProfiles = true;
  static const bool personalLinks = true;
  static const bool contactsLeads = true;
  static const bool analytics = true;
  static const bool devicesAccounts = true;
  static const bool personalInvitations = true;
  static const bool personalQrScan = true;
  static const bool followDiscovery = true;

  // ---- Disabled for initial release ----
  static const bool explore = false;
  static const bool shopping = false;
  static const bool workplace = false;
  static const bool businessOwner = true;
  static const bool businessPro = true;
  /// Stripe config + PaymentSheet (Business Pro checkout).
  static const bool commercePayments = true;

  // ---- Public website types (enable one-by-one) ----
  static const bool publicWebsiteMenu = true;
  static const bool publicWebsiteServices = false;
  static const bool publicWebsiteProducts = false;
  static const bool publicWebsitePortfolio = false;

  /// True when any public website type is live.
  static bool get publicWebsites =>
      publicWebsiteMenu ||
      publicWebsiteServices ||
      publicWebsiteProducts ||
      publicWebsitePortfolio;

  static bool get canShowBusinessSuite => businessOwner;
  static bool get canOpenExplore => explore;
  static bool get canUseShopping => shopping;
  static bool get canUseWorkplace => workplace;
  static bool get canOpenPublicWebsite => publicWebsites;
  static bool get canUseBusinessPro => businessPro;
  static bool get canUseCommercePayments => commercePayments;

  /// [websiteOrCatalogType]: `menu` | `service` | `services` | `products` |
  /// `portfolio` | `catalog` (menu family).
  static bool canOpenPublicWebsiteType(String? websiteOrCatalogType) {
    final t = (websiteOrCatalogType ?? 'menu').trim().toLowerCase();
    switch (t) {
      case 'services':
      case 'service':
        return publicWebsiteServices;
      case 'products':
      case 'product':
        return publicWebsiteProducts;
      case 'portfolio':
        return publicWebsitePortfolio;
      case 'menu':
      case 'catalog':
      case '':
        return publicWebsiteMenu;
      default:
        return false;
    }
  }

  /// Catalog inventory / website tiles allowed in Add Links this release.
  static bool isCatalogOrWebsiteTypeEnabled(String? catalogOrWebsiteType) =>
      canOpenPublicWebsiteType(catalogOrWebsiteType);

  /// Catalog inventory and published-site tiles stay in DB but are hidden.
  static bool isPersonalLinkVisible(SocialLink link) {
    if (!personalLinks) return false;
    if (link.isBusinessWebsiteLink || link.isCatalogLink) {
      if (!(publicWebsites || businessOwner || shopping)) return false;
      // Owners still manage all tiles; public viewers only see enabled types.
      if (businessOwner || shopping) return true;
      return isCatalogOrWebsiteTypeEnabled(link.catalogType ?? 'menu');
    }
    return true;
  }

  static bool get canManageCatalogOrWebsiteLinks =>
      businessOwner || publicWebsites || shopping;
}
