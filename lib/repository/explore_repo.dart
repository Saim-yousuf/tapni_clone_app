import 'package:tapni_app/models/explore_business.dart';
import 'package:tapni_app/utils/api_endpoint.dart';
import 'package:tapni_app/utils/api_handler.dart';

class ExploreRepo {
  Future<ApiResponse> getNearby({
    double? lat,
    double? lng,
    double radiusKm = 10,
    String? industry,
    String? city,
    String? q,
    String? type,
    int page = 1,
    int limit = 20,
  }) {
    final query = <String, String?>{
      if (lat != null) 'lat': lat.toString(),
      if (lng != null) 'lng': lng.toString(),
      'radiusKm': radiusKm.toString(),
      if (industry != null && industry.isNotEmpty) 'industry': industry,
      if (city != null && city.isNotEmpty) 'city': city,
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      if (type != null && type.isNotEmpty) 'type': type,
      'page': page.toString(),
      'limit': limit.toString(),
    };

    return ApiHandler.request(
      api: Api.explore.nearby,
      method: ApiMethod.get,
      authorization: true,
      queryParams: query,
    );
  }

  Future<ApiResponse> getBanners() {
    return ApiHandler.request(
      api: Api.explore.banners,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> getCategories() {
    return ApiHandler.request(
      api: Api.explore.categories,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  ExploreNearbyResult parseNearby(dynamic data) {
    final root = data is Map ? data : <String, dynamic>{};
    final payload = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : Map<String, dynamic>.from(root);

    final businesses = (payload['businesses'] as List? ?? [])
        .whereType<Map>()
        .map((e) => ExploreBusiness.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final offers = (payload['offers'] as List? ?? [])
        .whereType<Map>()
        .map((e) => ExploreOffer.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final items = (payload['items'] as List? ?? [])
        .whereType<Map>()
        .map((e) => ExploreItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return ExploreNearbyResult(
      businesses: businesses,
      offers: offers,
      items: items,
      page: (payload['page'] as num?)?.toInt() ?? 1,
      total: (payload['total'] as num?)?.toInt() ?? businesses.length,
      hasMore: payload['hasMore'] as bool? ?? false,
    );
  }

  List<ExploreBanner> parseBanners(dynamic data) {
    final root = data is Map ? data : <String, dynamic>{};
    final list = root['banners'] as List? ??
        (root['data'] is Map ? (root['data'] as Map)['banners'] as List? : null) ??
        const [];
    return list
        .whereType<Map>()
        .map((e) => ExploreBanner.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<ExploreCategoryItem> parseCategories(dynamic data) {
    final root = data is Map ? data : <String, dynamic>{};
    final list = root['categories'] as List? ??
        (root['data'] is Map
            ? (root['data'] as Map)['categories'] as List?
            : null) ??
        const [];
    return list
        .whereType<Map>()
        .map((e) => ExploreCategoryItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
