import 'package:tapni_app/utils/api_handler.dart';
import 'package:tapni_app/utils/api_endpoint.dart';

class AuthRepo {
  String errorMessage = "Auth Error:";

  Future<ApiResponse> login({
    required String email,
    required String password,
  }) async {
    return await ApiHandler.request(
      api: Api.auth.login,
      body: {"email": email, "password": password},
      method: ApiMethod.post,
    );
  }

  Future<ApiResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return await ApiHandler.request(
      api: Api.auth.register,
      body: {"name": name, "email": email, "password": password},
      method: ApiMethod.post,
    );
  }

  Future<ApiResponse> googleSignIn({required String token}) async {
    return await ApiHandler.request(
      api: Api.auth.googleSignIn,
      body: {"token": token},
      method: ApiMethod.post,
    );
  }

  Future<ApiResponse> profile() async {
    return await ApiHandler.request(
      api: Api.auth.profile,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> updateProfile({
    required Map<String, dynamic> jsonBody,
  }) async {
    return await ApiHandler.request(
      api: Api.auth.profile,
      method: ApiMethod.put,
      authorization: true,
      jsonBody: jsonBody,
    );
  }

  Future<ApiResponse> updateLinks({
    required Map<String, dynamic> jsonBody,
  }) async {
    return await ApiHandler.request(
      api: Api.auth.links,
      method: ApiMethod.put,
      authorization: true,
      jsonBody: jsonBody,
    );
  }

  Future<ApiResponse> linkCatalog() async {
    return await ApiHandler.request(
      api: Api.auth.linkCatalog,
      method: ApiMethod.get,
      authorization: true,
    );
  }
}
