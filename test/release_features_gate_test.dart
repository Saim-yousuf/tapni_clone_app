import 'package:flutter_test/flutter_test.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/utils/release_features.dart';

void main() {
  group('ReleaseFeatures initial personal release', () {
    test('business surfaces are off', () {
      expect(ReleaseFeatures.explore, isFalse);
      expect(ReleaseFeatures.shopping, isFalse);
      expect(ReleaseFeatures.workplace, isFalse);
      expect(ReleaseFeatures.publicWebsites, isFalse);
      expect(ReleaseFeatures.businessOwner, isFalse);
      expect(ReleaseFeatures.businessPro, isFalse);
      expect(ReleaseFeatures.commercePayments, isFalse);
    });

    test('personal surfaces are on', () {
      expect(ReleaseFeatures.personalDigitalCard, isTrue);
      expect(ReleaseFeatures.personalLinks, isTrue);
      expect(ReleaseFeatures.contactsLeads, isTrue);
      expect(ReleaseFeatures.analytics, isTrue);
      expect(ReleaseFeatures.personalInvitations, isTrue);
      expect(ReleaseFeatures.personalQrScan, isTrue);
    });

    test('hides catalog and business website links', () {
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
      expect(ReleaseFeatures.isPersonalLinkVisible(catalog), isFalse);
      expect(ReleaseFeatures.isPersonalLinkVisible(website), isFalse);
      expect(ReleaseFeatures.isPersonalLinkVisible(social), isTrue);
    });

    test('push routing gate matrix matches release switches', () {
      bool routeCatalogOrder() =>
          ReleaseFeatures.canUseShopping ||
          ReleaseFeatures.canShowBusinessSuite;
      bool routeSubscription() => ReleaseFeatures.canUseBusinessPro;
      bool routeLoyalty() => ReleaseFeatures.canUseShopping;
      bool routeEmployee() => ReleaseFeatures.canUseWorkplace;

      expect(routeCatalogOrder(), isFalse);
      expect(routeSubscription(), isFalse);
      expect(routeLoyalty(), isFalse);
      expect(routeEmployee(), isFalse);
    });
  });
}
