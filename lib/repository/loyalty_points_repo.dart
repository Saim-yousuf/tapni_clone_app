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

  Future<ApiResponse> getStampHistory(String enrollmentId) async {
    return ApiHandler.request(
      api: Api.loyaltyPoints.stampHistory(enrollmentId),
      method: ApiMethod.get,
      authorization: true,
    );
  }
}
