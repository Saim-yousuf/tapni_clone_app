import 'package:tapni_app/utils/api_handler.dart';
import 'package:tapni_app/utils/api_endpoint.dart';

class SubscriptionRepo {
  String errorMessage = "Subscription Error:";

  Future<ApiResponse> getPlans() async {
    return await ApiHandler.request(
      api: Api.subscription.plans,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> getMySubscription() async {
    return await ApiHandler.request(
      api: Api.subscription.my,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> checkout({required String planId}) async {
    return await ApiHandler.request(
      api: Api.subscription.checkout,
      jsonBody: {"planId": planId},
      method: ApiMethod.post,
      authorization: true,
    );
  }

  Future<ApiResponse> confirmCheckout({required String checkoutId}) async {
    return await ApiHandler.request(
      api: Api.subscription.confirm,
      jsonBody: {"checkoutId": checkoutId},
      method: ApiMethod.post,
      authorization: true,
    );
  }

  Future<ApiResponse> cancelSubscription() async {
    return await ApiHandler.request(
      api: Api.subscription.cancel,
      method: ApiMethod.post,
      authorization: true,
    );
  }
}
