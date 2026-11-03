import 'package:flutter_test/flutter_test.dart';
import 'package:tapni_app/utils/business_features.dart';

void main() {
  group('websiteTypeForBusinessType', () {
    test('products and stay share products websiteType', () {
      expect(websiteTypeForBusinessType('products'), 'products');
      expect(websiteTypeForBusinessType('stay'), 'products');
    });

    test('restaurant / services / portfolio map distinctly', () {
      expect(websiteTypeForBusinessType('restaurant'), 'menu');
      expect(websiteTypeForBusinessType('services'), 'service');
      expect(websiteTypeForBusinessType('portfolio'), 'portfolio');
    });
  });

  group('websiteCategoryMatchesBusinessType', () {
    test('products matches Retail only', () {
      expect(
        websiteCategoryMatchesBusinessType('Retail', 'products'),
        isTrue,
      );
      expect(
        websiteCategoryMatchesBusinessType('Hospitality', 'products'),
        isFalse,
      );
    });

    test('stay matches Hospitality only', () {
      expect(
        websiteCategoryMatchesBusinessType('Hospitality', 'stay'),
        isTrue,
      );
      expect(
        websiteCategoryMatchesBusinessType('Retail', 'stay'),
        isFalse,
      );
    });
  });

  group('resolveBusinessTypeForRouting', () {
    test('explicit businessType wins over category', () {
      expect(
        resolveBusinessTypeForRouting(
          businessType: 'products',
          businessCategory: 'Hospitality',
        ),
        'products',
      );
    });

    test('empty businessType stays empty (no silent invent for skip)', () {
      expect(normalizeBusinessType(null), isEmpty);
      expect(normalizeBusinessType(''), isEmpty);
      expect(normalizeBusinessType('garbage'), isEmpty);
    });
  });
}
