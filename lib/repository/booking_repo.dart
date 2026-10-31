import 'package:tapni_app/models/bookable_resource.dart';
import 'package:tapni_app/utils/api_endpoint.dart';
import 'package:tapni_app/utils/api_handler.dart';

class BookingRepo {
  Future<List<BookableResource>> listResources({
    required String businessId,
    String? type,
    bool authorize = false,
  }) async {
    final res = await ApiHandler.request(
      api: Api.booking.resources,
      method: ApiMethod.get,
      authorization: authorize,
      queryParams: {
        'businessId': businessId,
        if (type != null && type.isNotEmpty) 'type': type,
      },
    );
    if (!res.success || res.data == null) return [];
    final list = res.data is List
        ? res.data as List
        : (res.data is Map && res.data['data'] is List
            ? res.data['data'] as List
            : <dynamic>[]);
    return list
        .map((e) => BookableResource.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Owner list (auth) — includes inactive rows.
  Future<ApiResponse> listMine({
    required String businessId,
    String? type,
  }) {
    return ApiHandler.request(
      api: Api.booking.resources,
      method: ApiMethod.get,
      authorization: true,
      queryParams: {
        'businessId': businessId,
        'includeInactive': '1',
        if (type != null && type.isNotEmpty) 'type': type,
      },
    );
  }

  Future<ApiResponse> createResource({
    required String type,
    required String name,
    String tableToken = '',
    String? refUserId,
    Map<String, dynamic>? meta,
    int sortOrder = 0,
  }) {
    return ApiHandler.request(
      api: Api.booking.resources,
      method: ApiMethod.post,
      authorization: true,
      jsonBody: {
        'type': type,
        'name': name.trim(),
        if (tableToken.trim().isNotEmpty) 'tableToken': tableToken.trim(),
        if (refUserId != null && refUserId.isNotEmpty) 'refUserId': refUserId,
        if (meta != null) 'meta': meta,
        'sortOrder': sortOrder,
      },
    );
  }

  Future<ApiResponse> updateResource(
    String id, {
    String? name,
    String? tableToken,
    bool? isActive,
    Map<String, dynamic>? meta,
    int? sortOrder,
  }) {
    return ApiHandler.request(
      api: Api.booking.resource(id),
      method: ApiMethod.put,
      authorization: true,
      jsonBody: {
        if (name != null) 'name': name.trim(),
        if (tableToken != null) 'tableToken': tableToken.trim(),
        if (isActive != null) 'isActive': isActive,
        if (meta != null) 'meta': meta,
        if (sortOrder != null) 'sortOrder': sortOrder,
      },
    );
  }

  Future<ApiResponse> deleteResource(String id) {
    return ApiHandler.request(
      api: Api.booking.resource(id),
      method: ApiMethod.delete,
      authorization: true,
    );
  }

  Future<ApiResponse> syncTeamStaff() {
    return ApiHandler.request(
      api: Api.booking.syncTeam,
      method: ApiMethod.post,
      authorization: true,
      jsonBody: {},
    );
  }

  Future<List<Map<String, dynamic>>> calendarBusy({
    String? businessId,
    bool mine = false,
    String? from,
    String? to,
  }) async {
    final res = await ApiHandler.request(
      api: Api.booking.calendarBusy,
      method: ApiMethod.get,
      authorization: true,
      queryParams: {
        if (mine) 'scope': 'mine',
        if (businessId != null && businessId.isNotEmpty)
          'businessId': businessId,
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
      },
    );
    if (!res.success || res.data == null) return [];
    final payload = res.data is Map && res.data['data'] != null
        ? res.data['data'] as Map<String, dynamic>
        : res.data as Map<String, dynamic>;
    final blocks = payload['blocks'] as List<dynamic>? ?? [];
    return blocks
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
}
