import 'package:tapni_app/utils/api_endpoint.dart';
import 'package:tapni_app/utils/api_handler.dart';

class BusinessFeatureRepo {
  /// ApiHandler stores the full JSON body in [ApiResponse.data].
  /// Prefer nested `data` when present (standard BarQody envelope).
  static Map<String, dynamic> unwrapPayload(ApiResponse res) {
    if (res.data is! Map) return <String, dynamic>{};
    final root = Map<String, dynamic>.from(res.data as Map);
    final nested = root['data'];
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }
    return root;
  }

  Future<ApiResponse> getMyFeatures() {
    return ApiHandler.request(
      method: ApiMethod.get,
      api: Api.businessFeatures.mine,
      authorization: true,
    );
  }

  Future<ApiResponse> getSetupStatus() {
    return ApiHandler.request(
      method: ApiMethod.get,
      api: Api.businessFeatures.setup,
      authorization: true,
    );
  }

  Future<ApiResponse> setBusinessType(
    String businessType, {
    bool resetFeatures = false,
  }) {
    return ApiHandler.request(
      method: ApiMethod.put,
      api: Api.businessFeatures.businessType,
      authorization: true,
      jsonBody: {
        'businessType': businessType,
        'resetFeatures': resetFeatures,
      },
    );
  }

  Future<ApiResponse> activate(String feature) {
    return ApiHandler.request(
      method: ApiMethod.post,
      api: Api.businessFeatures.activate,
      authorization: true,
      jsonBody: {'feature': feature},
    );
  }

  Future<ApiResponse> deactivate(String feature) {
    return ApiHandler.request(
      method: ApiMethod.post,
      api: Api.businessFeatures.deactivate,
      authorization: true,
      jsonBody: {'feature': feature},
    );
  }
}
