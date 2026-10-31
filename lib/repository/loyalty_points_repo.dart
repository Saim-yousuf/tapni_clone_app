import 'package:tapni_app/utils/api_endpoint.dart';
import 'package:tapni_app/utils/api_handler.dart';

class LoyaltyPointsRepo {
  Future<ApiResponse> getBusinessPoints() async {
    return ApiHandler.request(
      api: Api.loyaltyPoints.business,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> purchaseBusinessPoints(String packageId) async {
    return ApiHandler.request(
      api: Api.loyaltyPoints.businessPurchase,
      method: ApiMethod.post,
      authorization: true,
      jsonBody: {'packageId': packageId},
    );
  }

  Future<ApiResponse> getBusinessActivity() async {
    return ApiHandler.request(
      api: Api.loyaltyPoints.businessActivity,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> getBusinessRedemptionSettings() async {
    return ApiHandler.request(
      api: Api.loyaltyPoints.businessRedemptionSettings,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> updateBusinessRedemptionSettings({
    required bool redemptionEnabled,
    required int minPointsToRedeem,
    required int maxPointsPerOrder,
    double? currencyPerPoint,
    bool clearCurrencyPerPoint = false,
  }) async {
    return ApiHandler.request(
      api: Api.loyaltyPoints.businessRedemptionSettings,
      method: ApiMethod.put,
      authorization: true,
      jsonBody: {
        'redemptionEnabled': redemptionEnabled,
        'minPointsToRedeem': minPointsToRedeem,
        'maxPointsPerOrder': maxPointsPerOrder,
        if (clearCurrencyPerPoint)
          'currencyPerPoint': null
        else if (currencyPerPoint != null)
          'currencyPerPoint': currencyPerPoint,
      },
    );
  }

  Future<ApiResponse> getCustomerPoints() async {
    return ApiHandler.request(
      api: Api.loyaltyPoints.customer,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> getCustomerActivity() async {
    return ApiHandler.request(
      api: Api.loyaltyPoints.customerActivity,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> getCustomerCheckoutPoints(String businessId) async {
    return ApiHandler.request(
      api: Api.loyaltyPoints.customerCheckout(businessId),
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> quoteRedemption({
    required String businessId,
    required double subtotalAmount,
    required int pointsToRedeem,
  }) async {
    return ApiHandler.request(
      api: Api.loyaltyPoints.redemptionQuote,
      method: ApiMethod.post,
      authorization: true,
      jsonBody: {
        'businessId': businessId,
        'subtotalAmount': subtotalAmount,
        'pointsToRedeem': pointsToRedeem,
      },
    );
  }

  Future<ApiResponse> getStampHistory(String enrollmentId) async {
    return ApiHandler.request(
      api: Api.loyaltyPoints.stampHistory(enrollmentId),
      method: ApiMethod.get,
      authorization: true,
    );
  }
}
