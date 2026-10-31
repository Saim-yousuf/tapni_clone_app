import 'package:tapni_app/models/business_offer.dart';
import 'package:tapni_app/utils/api_endpoint.dart';
import 'package:tapni_app/utils/api_handler.dart';

class OfferRepo {
  List<BusinessOffer> _parseList(dynamic data) {
    final raw = data is Map ? (data['data'] ?? data) : data;
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => BusinessOffer.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ApiResponse> listBusinessOffers() {
    return ApiHandler.request(
      api: Api.offers.business,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<List<BusinessOffer>> fetchBusinessOffers() async {
    final res = await listBusinessOffers();
    if (!res.success) return [];
    return _parseList(res.data);
  }

  Future<ApiResponse> createOffer(Map<String, dynamic> body) {
    return ApiHandler.request(
      api: Api.offers.business,
      method: ApiMethod.post,
      authorization: true,
      jsonBody: body,
    );
  }

  Future<ApiResponse> updateOffer(String id, Map<String, dynamic> body) {
    return ApiHandler.request(
      api: Api.offers.businessOffer(id),
      method: ApiMethod.put,
      authorization: true,
      jsonBody: body,
    );
  }

  Future<ApiResponse> deleteOffer(String id) {
    return ApiHandler.request(
      api: Api.offers.businessOffer(id),
      method: ApiMethod.delete,
      authorization: true,
    );
  }

  Future<ApiResponse> listPublicOffers({
    required String businessId,
    String? catalogType,
  }) {
    final q = <String>['businessId=${Uri.encodeQueryComponent(businessId)}'];
    if (catalogType != null && catalogType.isNotEmpty) {
      q.add('catalogType=${Uri.encodeQueryComponent(catalogType)}');
    }
    return ApiHandler.request(
      api: '${Api.offers.publicList}?${q.join('&')}',
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> quoteCoupon({
    required String businessId,
    required double subtotalAmount,
    required List<Map<String, dynamic>> items,
    String? couponCode,
    String? offerId,
    String? catalogType,
    int pointsToRedeem = 0,
  }) {
    return ApiHandler.request(
      api: Api.offers.publicQuote,
      method: ApiMethod.post,
      authorization: true,
      jsonBody: {
        'businessId': businessId,
        'subtotalAmount': subtotalAmount,
        'items': items,
        if (couponCode != null && couponCode.isNotEmpty)
          'couponCode': couponCode,
        if (offerId != null && offerId.isNotEmpty) 'offerId': offerId,
        if (catalogType != null && catalogType.isNotEmpty)
          'catalogType': catalogType,
        if (pointsToRedeem > 0) 'pointsToRedeem': pointsToRedeem,
      },
    );
  }
}
