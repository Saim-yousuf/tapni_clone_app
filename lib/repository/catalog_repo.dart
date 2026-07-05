import 'package:tapni_app/models/catalog_order.dart';
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
  }) async {
    return ApiHandler.request(
      api: Api.catalog.orders,
      method: ApiMethod.post,
      authorization: true,
      jsonBody: {
        'businessId': businessId,
        'businessLinkId': businessLinkId,
        'catalogType': catalogType,
        'items': items,
      },
    );
  }

  Future<List<CatalogOrder>> getBusinessOrders({String? status}) async {
    final res = await ApiHandler.request(
      api: Api.catalog.incomingOrders,
      method: ApiMethod.get,
      authorization: true,
      queryParams: status != null ? {'status': status} : null,
    );
    if (!res.success) return [];
    return _parseOrders(res.data);
  }

  Future<List<CatalogOrder>> getCustomerOrders({String? status}) async {
    final res = await ApiHandler.request(
      api: Api.catalog.myOrders,
      method: ApiMethod.get,
      authorization: true,
      queryParams: status != null ? {'status': status} : null,
    );
    if (!res.success) return [];
    return _parseOrders(res.data);
  }

  Future<CatalogOrder?> getOrderById(String id) async {
    final res = await ApiHandler.request(
      api: Api.catalog.order(id),
      method: ApiMethod.get,
      authorization: true,
    );
    if (!res.success || res.data == null) return null;
    final payload = res.data is Map && res.data['data'] != null
        ? res.data['data'] as Map<String, dynamic>
        : res.data as Map<String, dynamic>;
    return CatalogOrder.fromJson(payload);
  }

  Future<ApiResponse> updateOrderStatus(String orderId, String status) async {
    return ApiHandler.request(
      api: Api.catalog.updateStatus(orderId),
      method: ApiMethod.put,
      authorization: true,
      jsonBody: {'status': status},
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
