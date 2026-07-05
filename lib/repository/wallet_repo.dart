import 'package:tapni_app/utils/api_handler.dart';
import 'package:tapni_app/utils/api_endpoint.dart';

class WalletRepo {
  Future<ApiResponse> getMyCompanyCards() async {
    return ApiHandler.request(
      api: Api.wallet.companyCards,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> getMyGoogleWalletLink() async {
    return ApiHandler.request(
      api: Api.wallet.myGoogleCard,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> getCompanyGoogleWalletLink(String businessUserId) async {
    return ApiHandler.request(
      api: Api.wallet.googleBusinessCard(businessUserId),
      method: ApiMethod.get,
      authorization: true,
    );
  }
}
