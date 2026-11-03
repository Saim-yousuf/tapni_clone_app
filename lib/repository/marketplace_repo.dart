import 'package:tapni_app/models/marketplace_category.dart';
import 'package:tapni_app/utils/api_endpoint.dart';
import 'package:tapni_app/utils/api_handler.dart';

class MarketplaceRepo {
  Future<ApiResponse> getCategories() {
    return ApiHandler.request(
      api: Api.marketplace.categories,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> searchProducts({
    String? category,
    String? subcategory,
    String? q,
    double? minPrice,
    double? maxPrice,
    String? brand,
    String? businessId,
    String? location,
    String sort = 'newest',
    int limit = 40,
    int offset = 0,
  }) {
    return ApiHandler.request(
      api: Api.marketplace.products,
      method: ApiMethod.get,
      authorization: true,
      queryParams: {
        if (category != null && category.isNotEmpty) 'category': category,
        if (subcategory != null && subcategory.isNotEmpty)
          'subcategory': subcategory,
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (minPrice != null) 'minPrice': minPrice.toString(),
        if (maxPrice != null) 'maxPrice': maxPrice.toString(),
        if (brand != null && brand.isNotEmpty) 'brand': brand,
        if (businessId != null && businessId.isNotEmpty)
          'businessId': businessId,
        if (location != null && location.isNotEmpty) 'location': location,
        'sort': sort,
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );
  }

  List<MarketplaceCategory> parseTree(dynamic data) {
    final root = _unwrap(data);
    final tree = root['tree'];
    if (tree is! List) return const [];
    return tree
        .whereType<Map>()
        .map((e) => MarketplaceCategory.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<MarketplaceCategory> parseFlat(dynamic data) {
    final root = _unwrap(data);
    final list = root['categories'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => MarketplaceCategory.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }
}
