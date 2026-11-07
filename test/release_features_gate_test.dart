import 'package:flutter_test/flutter_test.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/utils/release_features.dart';

void main() {
  group('ReleaseFeatures become-a-business phase', () {
    test('business signup + suite are on; other business surfaces stay off', () {
      expect(ReleaseFeatures.explore, isFalse);
      expect(ReleaseFeatures.shopping, isFalse);
      expect(ReleaseFeatures.workplace, isFalse);
      expect(ReleaseFeatures.businessOwner, isTrue);
      expect(ReleaseFeatures.businessPro, isTrue);
      expect(ReleaseFeatures.commercePayments, isTrue);
    });

    test('only menu public website type is enabled', () {
      expect(ReleaseFeatures.publicWebsiteMenu, isTrue);
      expect(ReleaseFeatures.publicWebsiteServices, isFalse);
      expect(ReleaseFeatures.publicWebsiteProducts, isFalse);
      expect(ReleaseFeatures.publicWebsitePortfolio, isFalse);
      expect(ReleaseFeatures.publicWebsites, isTrue);
      expect(ReleaseFeatures.canOpenPublicWebsite, isTrue);
      expect(ReleaseFeatures.canOpenPublicWebsiteType('menu'), isTrue);
      expect(ReleaseFeatures.canOpenPublicWebsiteType('catalog'), isTrue);
      expect(ReleaseFeatures.canOpenPublicWebsiteType('service'), isFalse);
      expect(ReleaseFeatures.canOpenPublicWebsiteType('services'), isFalse);
      expect(ReleaseFeatures.canOpenPublicWebsiteType('products'), isFalse);
      expect(ReleaseFeatures.canOpenPublicWebsiteType('portfolio'), isFalse);
    });

    test('personal surfaces are on', () {
      expect(ReleaseFeatures.personalDigitalCard, isTrue);
      expect(ReleaseFeatures.personalLinks, isTrue);
      expect(ReleaseFeatures.contactsLeads, isTrue);
      expect(ReleaseFeatures.analytics, isTrue);
      expect(ReleaseFeatures.personalInvitations, isTrue);
      expect(ReleaseFeatures.personalQrScan, isTrue);
    });

    test('business owner can see catalog and business website links', () {
      final catalog = SocialLink(
        id: '1',
        platform: SocialPlatform.instagram,
        value: 'catalog:1',
        url: 'catalog:1',
        actionType: 'menu_catalog',
        fieldType: 'menu_catalog',
        catalogItems: const [],
      );
      final website = SocialLink(
        id: '2',
        platform: SocialPlatform.instagram,
        value: 'https://example.com',
        url: 'https://example.com',
        actionType: 'business_website',
        fieldType: 'business_website',
      );
      final social = SocialLink(
        id: '3',
        platform: SocialPlatform.instagram,
        value: 'barqody',
        url: 'https://instagram.com/x',
      );

      expect(catalog.isCatalogLink, isTrue);
      expect(website.isBusinessWebsiteLink, isTrue);
      expect(ReleaseFeatures.isPersonalLinkVisible(catalog), isTrue);
      expect(ReleaseFeatures.isPersonalLinkVisible(website), isTrue);
      expect(ReleaseFeatures.isPersonalLinkVisible(social), isTrue);
    });

    test('push routing gate matrix matches release switches', () {
      bool routeCatalogOrder() =>
          ReleaseFeatures.canUseShopping ||
          ReleaseFeatures.canShowBusinessSuite;
      bool routeSubscription() => ReleaseFeatures.canUseBusinessPro;
      bool routeLoyalty() => ReleaseFeatures.canUseShopping;
      bool routeEmployee() => ReleaseFeatures.canUseWorkplace;

      expect(routeCatalogOrder(), isTrue);
      expect(routeSubscription(), isTrue);
      expect(routeLoyalty(), isFalse);
      expect(routeEmployee(), isFalse);
    });
  });
}
