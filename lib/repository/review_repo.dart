import 'package:tapni_app/models/business_review.dart';
import 'package:tapni_app/utils/api_endpoint.dart';
import 'package:tapni_app/utils/api_handler.dart';

class ReviewRepo {
  Future<ApiResponse> upsertReview({
    required String targetType,
    required String targetId,
    required String businessId,
    required int rating,
    String text = '',
    String targetLabel = '',
  }) {
    return ApiHandler.request(
      api: Api.reviews.create,
      method: ApiMethod.post,
      authorization: true,
      jsonBody: {
        'targetType': targetType,
        'targetId': targetId,
        'businessId': businessId,
        'rating': rating,
        'text': text,
        'targetLabel': targetLabel,
      },
    );
  }

  Future<ApiResponse> listReviews({
    required String businessId,
    String targetType = 'business',
    String? targetId,
    int page = 1,
    int limit = 20,
  }) {
    return ApiHandler.request(
      api: Api.reviews.forBusiness(businessId),
      method: ApiMethod.get,
      authorization: true,
      queryParams: {
        'targetType': targetType,
        if (targetId != null && targetId.isNotEmpty) 'targetId': targetId,
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );
  }

  Future<ApiResponse> reportReview(String reviewId) {
    return ApiHandler.request(
      api: Api.reviews.report(reviewId),
      method: ApiMethod.post,
      authorization: true,
    );
  }

  List<BusinessReview> parseReviews(dynamic data) {
    final root = data is Map ? data : <String, dynamic>{};
    final payload = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : Map<String, dynamic>.from(root);
    final list = payload['reviews'] as List? ?? [];
    return list
        .whereType<Map>()
        .map((e) => BusinessReview.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<ItemReviewSummary> parseItemSummaries(dynamic data) {
    final root = data is Map ? data : <String, dynamic>{};
    final payload = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : Map<String, dynamic>.from(root);
    final list = payload['itemSummaries'] as List? ?? [];
    return list
        .whereType<Map>()
        .map((e) => ItemReviewSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
