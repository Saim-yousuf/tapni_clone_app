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
  static const bool publicWebsites = false;
  static const bool businessOwner = false;
  static const bool businessPro = false;
  static const bool commercePayments = false;

  static bool get canShowBusinessSuite => businessOwner;
  static bool get canOpenExplore => explore;
  static bool get canUseShopping => shopping;
  static bool get canUseWorkplace => workplace;
  static bool get canOpenPublicWebsite => publicWebsites;
  static bool get canUseBusinessPro => businessPro;
  static bool get canUseCommercePayments => commercePayments;

  /// Catalog inventory and published-site tiles stay in DB but are hidden.
  static bool isPersonalLinkVisible(SocialLink link) {
    if (!personalLinks) return false;
    if (link.isBusinessWebsiteLink || link.isCatalogLink) {
      return publicWebsites || businessOwner || shopping;
    }
    return true;
  }

  static bool get canManageCatalogOrWebsiteLinks =>
      businessOwner || publicWebsites || shopping;
}
