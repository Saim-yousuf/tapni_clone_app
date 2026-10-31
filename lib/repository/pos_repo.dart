import 'package:tapni_app/utils/api_endpoint.dart';
import 'package:tapni_app/utils/api_handler.dart';

class PosConnectionInfo {
  final String? id;
  final String status;
  final String posTenantId;
  final String posBaseUrl;
  final String defaultBranchId;
  final String lastError;
  final DateTime? lastSyncedAt;

  const PosConnectionInfo({
    this.id,
    this.status = 'disconnected',
    this.posTenantId = '',
    this.posBaseUrl = '',
    this.defaultBranchId = '',
    this.lastError = '',
    this.lastSyncedAt,
  });

  bool get isActive => status == 'active';

  factory PosConnectionInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PosConnectionInfo();
    return PosConnectionInfo(
      id: json['id']?.toString(),
      status: json['status']?.toString() ?? 'disconnected',
      posTenantId: json['posTenantId']?.toString() ?? '',
      posBaseUrl: json['posBaseUrl']?.toString() ?? '',
      defaultBranchId: json['defaultBranchId']?.toString() ?? '',
      lastError: json['lastError']?.toString() ?? '',
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.tryParse(json['lastSyncedAt'].toString())
          : null,
    );
  }
}

class PosRepo {
  Future<PosConnectionInfo> getConnection() async {
    final res = await ApiHandler.request(
      api: Api.pos.connection,
      method: ApiMethod.get,
      authorization: true,
    );
    if (!res.success) return const PosConnectionInfo();
    final data = res.data is Map && res.data['data'] != null
        ? res.data['data'] as Map<String, dynamic>?
        : res.data as Map<String, dynamic>?;
    return PosConnectionInfo.fromJson(data);
  }

  Future<ApiResponse> upsertConnection({
    required String status,
    String? posTenantId,
    String? posBaseUrl,
    String? defaultBranchId,
  }) {
    return ApiHandler.request(
      api: Api.pos.connection,
      method: ApiMethod.put,
      authorization: true,
      jsonBody: {
        'status': status,
        if (posTenantId != null) 'posTenantId': posTenantId,
        if (posBaseUrl != null) 'posBaseUrl': posBaseUrl,
        if (defaultBranchId != null) 'defaultBranchId': defaultBranchId,
      },
    );
  }

  Future<ApiResponse> disconnect() {
    return ApiHandler.request(
      api: Api.pos.connection,
      method: ApiMethod.delete,
      authorization: true,
    );
  }
}
