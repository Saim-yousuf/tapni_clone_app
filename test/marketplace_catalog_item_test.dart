import 'package:flutter_test/flutter_test.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/marketplace_category.dart';

void main() {
  group('CatalogItem marketplace fields', () {
    test('round-trips marketplace ids and preserves business section', () {
      final item = CatalogItem(
        name: 'Earbuds',
        price: 99,
        category: 'New Arrivals',
        marketplaceCategoryId: 'cat1',
        marketplaceSubcategoryId: 'sub1',
      );
      final json = item.toJson();
      expect(json['category'], 'New Arrivals');
      expect(json['marketplaceCategoryId'], 'cat1');
      expect(json['marketplaceSubcategoryId'], 'sub1');

      final parsed = CatalogItem.fromJson(json);
      expect(parsed.category, 'New Arrivals');
      expect(parsed.marketplaceCategoryId, 'cat1');
      expect(parsed.isListedOnMarketplace, isTrue);
    });

    test('legacy products without marketplace ids still parse', () {
      final parsed = CatalogItem.fromJson({
        'name': 'Old Product',
        'price': 5,
        'category': 'Best Sellers',
      });
      expect(parsed.category, 'Best Sellers');
      expect(parsed.marketplaceCategoryId, isEmpty);
      expect(parsed.isListedOnMarketplace, isFalse);
    });
  });

  group('MarketplaceCategory tree', () {
    test('parses nested children', () {
      final root = MarketplaceCategory.fromJson({
        'id': '1',
        'name': 'Electronics',
        'children': [
          {'id': '2', 'name': 'Laptops', 'parentId': '1'},
        ],
      });
      expect(root.isTopLevel, isTrue);
      expect(root.children, hasLength(1));
      expect(root.children.first.name, 'Laptops');
    });
  });
}
