import 'package:tapni_app/models/catalog_order.dart';
import 'package:tapni_app/models/service_schedule.dart';
import 'package:tapni_app/utils/api_handler.dart';
import 'package:tapni_app/utils/api_endpoint.dart';

class CatalogRepo {
  List<CatalogOrder> _parseOrders(dynamic data) {
    if (data == null) return [];
    final list = data is List ? data : (data['data'] as List? ?? []);
    return list
        .map((e) => CatalogOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ApiResponse> placeOrder({
    required String businessId,
    required String businessLinkId,
    required String catalogType,
    required List<Map<String, dynamic>> items,
    String? bookingDate,
    String? bookingTime,
    String? resourceId,
    String? bookingKind,
    String? checkInDate,
    String? checkOutDate,
    /// takeaway (pickup) | delivery — dine_in rejected by backend.
    String? orderType,
    String? fulfillmentAddress,
    String? fulfillmentNotes,
    String? deliveryArea,
    String? scheduledFor,
    double? tipAmount,
    double? fulfillmentLat,
    double? fulfillmentLng,
    int? prepTimeMinutes,
    String? guestPhone,
    @Deprecated('Dine-in removed; token ignored by backend') String? tableToken,
    String? paymentMethod,
    String? idempotencyKey,
    int? pointsToRedeem,
    String? couponCode,
    String? offerId,
  }) async {
    final tip = tipAmount ?? 0;
    final fulfillment = <String, dynamic>{
      if (fulfillmentAddress != null && fulfillmentAddress.isNotEmpty)
        'address': fulfillmentAddress,
      if (fulfillmentNotes != null && fulfillmentNotes.isNotEmpty)
        'notes': fulfillmentNotes,
      if (deliveryArea != null && deliveryArea.isNotEmpty)
        'deliveryArea': deliveryArea,
      if (scheduledFor != null && scheduledFor.isNotEmpty)
        'scheduledFor': scheduledFor,
      if (fulfillmentLat != null) 'lat': fulfillmentLat,
      if (fulfillmentLng != null) 'lng': fulfillmentLng,
      if (prepTimeMinutes != null && prepTimeMinutes > 0)
        'prepTimeMinutes': prepTimeMinutes,
      if (tip > 0) 'tipAmount': tip,
    };
    return ApiHandler.request(
      api: Api.catalog.orders,
      method: ApiMethod.post,
      authorization: true,
      jsonBody: {
        'businessId': businessId,
        'businessLinkId': businessLinkId,
        'catalogType': catalogType,
        'items': items,
        if (orderType != null && orderType.isNotEmpty) 'orderType': orderType,
        if (bookingDate != null && bookingDate.isNotEmpty)
          'bookingDate': bookingDate,
        if (bookingTime != null && bookingTime.isNotEmpty)
          'bookingTime': bookingTime,
        if (resourceId != null && resourceId.isNotEmpty)
          'resourceId': resourceId,
        if (bookingKind != null && bookingKind.isNotEmpty)
          'bookingKind': bookingKind,
        if (checkInDate != null && checkInDate.isNotEmpty)
          'checkInDate': checkInDate,
        if (checkOutDate != null && checkOutDate.isNotEmpty)
          'checkOutDate': checkOutDate,
        if (fulfillment.isNotEmpty) 'fulfillment': fulfillment,
        if (guestPhone != null && guestPhone.isNotEmpty)
          'guestPhone': guestPhone,
        if (paymentMethod != null && paymentMethod.isNotEmpty)
          'paymentMethod': paymentMethod,
        if (idempotencyKey != null && idempotencyKey.isNotEmpty)
          'idempotencyKey': idempotencyKey,
        if (pointsToRedeem != null && pointsToRedeem > 0)
          'pointsToRedeem': pointsToRedeem,
        if (couponCode != null && couponCode.isNotEmpty)
          'couponCode': couponCode,
        if (offerId != null && offerId.isNotEmpty) 'offerId': offerId,
      },
    );
  }

  /// Guest / optional-auth place order via public website API.
  /// Server resolves business from [websiteSlug] and revalidates catalog prices.
  Future<ApiResponse> placePublicOrder({
    required String websiteSlug,
    required List<Map<String, dynamic>> items,
    required String guestName,
    required String guestPhone,
    String? guestAddress,
    String? notes,
    String? bookingDate,
    String? bookingTime,
    String? resourceId,
    String? bookingKind,
    String? checkInDate,
    String? checkOutDate,
    String? orderType,
    String? deliveryArea,
    String? scheduledFor,
    double? tipAmount,
    double? fulfillmentLat,
    double? fulfillmentLng,
    int? prepTimeMinutes,
    String? paymentMethod,
    String? idempotencyKey,
    String? couponCode,
    String? offerId,
    /// When the shopper is signed in, send Bearer via [authorization].
    bool authorization = false,
  }) async {
    final tip = tipAmount ?? 0;
    return ApiHandler.request(
      api: Api.catalog.publicOrders,
      method: ApiMethod.post,
      authorization: authorization,
      jsonBody: {
        'websiteSlug': websiteSlug,
        'items': items,
        if (orderType != null && orderType.isNotEmpty) 'orderType': orderType,
        'guest': {
          'name': guestName,
          'phone': guestPhone,
          if (guestAddress != null && guestAddress.isNotEmpty)
            'address': guestAddress,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
        'fulfillment': {
          if (guestAddress != null && guestAddress.isNotEmpty)
            'address': guestAddress,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (deliveryArea != null && deliveryArea.isNotEmpty)
            'deliveryArea': deliveryArea,
          if (scheduledFor != null && scheduledFor.isNotEmpty)
            'scheduledFor': scheduledFor,
          if (fulfillmentLat != null) 'lat': fulfillmentLat,
          if (fulfillmentLng != null) 'lng': fulfillmentLng,
          if (prepTimeMinutes != null && prepTimeMinutes > 0)
            'prepTimeMinutes': prepTimeMinutes,
          if (tip > 0) 'tipAmount': tip,
        },
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (bookingDate != null && bookingDate.isNotEmpty)
          'bookingDate': bookingDate,
        if (bookingTime != null && bookingTime.isNotEmpty)
          'bookingTime': bookingTime,
        if (resourceId != null && resourceId.isNotEmpty)
          'resourceId': resourceId,
        if (bookingKind != null && bookingKind.isNotEmpty)
          'bookingKind': bookingKind,
        if (checkInDate != null && checkInDate.isNotEmpty)
          'checkInDate': checkInDate,
        if (checkOutDate != null && checkOutDate.isNotEmpty)
          'checkOutDate': checkOutDate,
        if (paymentMethod != null && paymentMethod.isNotEmpty)
          'paymentMethod': paymentMethod,
        if (idempotencyKey != null && idempotencyKey.isNotEmpty)
          'idempotencyKey': idempotencyKey,
        if (couponCode != null && couponCode.isNotEmpty)
          'couponCode': couponCode,
        if (offerId != null && offerId.isNotEmpty) 'offerId': offerId,
      },
    );
  }

  /// Link a guest website order to the signed-in account (tracking code + phone match).
  Future<ApiResponse> claimGuestOrder({required String trackingCode}) async {
    return ApiHandler.request(
      api: Api.catalog.claimGuestOrder,
      method: ApiMethod.post,
      authorization: true,
      jsonBody: {'trackingCode': trackingCode},
    );
  }

  /// Menu open/paused flags for Flutter cart Place Order CTA.
  Future<ApiResponse> getPublicStorefrontStatus({required String websiteSlug}) {
    return ApiHandler.request(
      api: Api.catalog.publicStorefrontStatus(websiteSlug),
      method: ApiMethod.get,
      authorization: false,
    );
  }

  /// Demo/mock online payment — never a real gateway charge.
  Future<ApiResponse> processMockPayment({
    required String orderId,
    required String demoOutcome,
    String? paymentAttemptKey,
    String? guestPhone,
    String? paymentSessionToken,
    bool publicGuest = false,
  }) async {
    return ApiHandler.request(
      api: publicGuest
          ? Api.catalog.publicMockPayment(orderId)
          : Api.catalog.mockPayment(orderId),
      method: ApiMethod.post,
      authorization: !publicGuest,
      jsonBody: {
        'demoOutcome': demoOutcome,
        if (paymentAttemptKey != null && paymentAttemptKey.isNotEmpty)
          'paymentAttemptKey': paymentAttemptKey,
        if (guestPhone != null && guestPhone.isNotEmpty)
          'guestPhone': guestPhone,
        if (paymentSessionToken != null && paymentSessionToken.isNotEmpty)
          'paymentSessionToken': paymentSessionToken,
      },
    );
  }

  Future<List<TimeSlot>> getAvailability({
    required String businessId,
    required String businessLinkId,
    required String date,
    String? resourceId,
    int? durationMinutes,
  }) async {
    final res = await ApiHandler.request(
      api: Api.catalog.availability,
      method: ApiMethod.get,
      authorization: true,
      queryParams: {
        'businessId': businessId,
        'businessLinkId': businessLinkId,
        'date': date,
        if (resourceId != null && resourceId.isNotEmpty)
          'resourceId': resourceId,
        if (durationMinutes != null && durationMinutes > 0)
          'durationMinutes': '$durationMinutes',
      },
    );
    if (!res.success || res.data == null) return [];
    final payload = res.data is Map && res.data['data'] != null
        ? res.data['data'] as Map<String, dynamic>
        : res.data as Map<String, dynamic>;
    final slots = payload['slots'] as List<dynamic>? ?? [];
    return slots
        .map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>?> getStayAvailability({
    required String businessId,
    required String resourceId,
    required String checkInDate,
    required String checkOutDate,
  }) async {
    final res = await ApiHandler.request(
      api: Api.catalog.stayAvailability,
      method: ApiMethod.get,
      authorization: true,
      queryParams: {
        'businessId': businessId,
        'resourceId': resourceId,
        'checkInDate': checkInDate,
        'checkOutDate': checkOutDate,
      },
    );
    if (!res.success || res.data == null) return null;
    final payload = res.data is Map && res.data['data'] != null
        ? res.data['data'] as Map<String, dynamic>
        : res.data as Map<String, dynamic>;
    return payload;
  }

  /// Returns null when the request fails (distinct from an empty list).
  Future<List<CatalogOrder>?> getBusinessOrders({
    String? status,
    String? bookingKind,
    String? catalogType,
    String? paymentStatus,
    String? q,
    String? from,
    String? to,
    String? sort,
  }) async {
    final params = _orderListParams(
      status: status,
      bookingKind: bookingKind,
      catalogType: catalogType,
      paymentStatus: paymentStatus,
      q: q,
      from: from,
      to: to,
      sort: sort,
    );
    final res = await ApiHandler.request(
      api: Api.catalog.incomingOrders,
      method: ApiMethod.get,
      authorization: true,
      queryParams: params.isEmpty ? null : params,
    );
    if (!res.success) return null;
    return _parseOrders(res.data);
  }

  /// Returns null when the request fails (distinct from an empty list).
  Future<List<CatalogOrder>?> getCustomerOrders({
    String? status,
    String? bookingKind,
    String? catalogType,
    String? paymentStatus,
    String? q,
    String? from,
    String? to,
    String? sort,
  }) async {
    final params = _orderListParams(
      status: status,
      bookingKind: bookingKind,
      catalogType: catalogType,
      paymentStatus: paymentStatus,
      q: q,
      from: from,
      to: to,
      sort: sort,
    );
    final res = await ApiHandler.request(
      api: Api.catalog.myOrders,
      method: ApiMethod.get,
      authorization: true,
      queryParams: params.isEmpty ? null : params,
    );
    if (!res.success) return null;
    return _parseOrders(res.data);
  }

  Map<String, String> _orderListParams({
    String? status,
    String? bookingKind,
    String? catalogType,
    String? paymentStatus,
    String? q,
    String? from,
    String? to,
    String? sort,
  }) {
    final params = <String, String>{};
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (bookingKind != null && bookingKind.isNotEmpty) {
      params['bookingKind'] = bookingKind;
    }
    if (catalogType != null && catalogType.isNotEmpty) {
      params['catalogType'] = catalogType;
    }
    if (paymentStatus != null && paymentStatus.isNotEmpty) {
      params['paymentStatus'] = paymentStatus;
    }
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (from != null && from.isNotEmpty) params['from'] = from;
    if (to != null && to.isNotEmpty) params['to'] = to;
    if (sort != null && sort.isNotEmpty) params['sort'] = sort;
    return params;
  }

  /// [failed] is true on network/server errors; false when the order is
  /// missing or inaccessible (404/403) so UI can show not-found vs retry.
  ///
  /// [accessToken] overrides the saved session token (WebView shopper JWT).
  Future<({CatalogOrder? order, bool failed})> getOrderById(
    String id, {
    String? accessToken,
  }) async {
    final token = accessToken?.trim();
    final res = await ApiHandler.request(
      api: Api.catalog.order(id),
      method: ApiMethod.get,
      authorization: true,
      headers: (token != null && token.isNotEmpty)
          ? {'Authorization': 'Bearer $token'}
          : null,
    );
    if (!res.success) {
      final missing = res.statusCode == 404 || res.statusCode == 403;
      return (order: null, failed: !missing);
    }
    if (res.data == null) return (order: null, failed: false);
    final payload = res.data is Map && res.data['data'] != null
        ? res.data['data'] as Map<String, dynamic>
        : res.data as Map<String, dynamic>;
    return (order: CatalogOrder.fromJson(payload), failed: false);
  }

  Future<ApiResponse> updateOrderStatus(String orderId, String status) async {
    return ApiHandler.request(
      api: Api.catalog.updateStatus(orderId),
      method: ApiMethod.put,
      authorization: true,
      jsonBody: {'status': status},
    );
  }

  /// Customer cancels their own order (held / pending / confirmed).
  Future<ApiResponse> cancelOrderAsCustomer(String orderId) async {
    return ApiHandler.request(
      api: Api.catalog.cancelOrder(orderId),
      method: ApiMethod.post,
      authorization: true,
      jsonBody: {},
    );
  }

  Future<ApiResponse> markOrderRead(String orderId) async {
    return ApiHandler.request(
      api: Api.catalog.markOrderRead(orderId),
      method: ApiMethod.put,
      authorization: true,
      jsonBody: {},
    );
  }

  Future<ApiResponse> markAllOrdersRead() async {
    return ApiHandler.request(
      api: Api.catalog.markAllRead,
      method: ApiMethod.put,
      authorization: true,
      jsonBody: {},
    );
  }
}
