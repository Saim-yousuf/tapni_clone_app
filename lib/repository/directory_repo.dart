import 'package:tapni_app/utils/api_endpoint.dart';
import 'package:tapni_app/utils/api_handler.dart';

class DirectoryRepo {
  Future<ApiResponse> syncContacts(List<Map<String, dynamic>> contacts) {
    return ApiHandler.request(
      api: Api.directory.sync,
      method: ApiMethod.post,
      authorization: true,
      jsonBody: {'contacts': contacts},
    );
  }

  Future<ApiResponse> getSyncStatus() {
    return ApiHandler.request(
      api: Api.directory.syncStatus,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> lookup(String phone) {
    return ApiHandler.request(
      api: Api.directory.lookup(phone),
      method: ApiMethod.get,
      authorization: true,
    );
  }
}
