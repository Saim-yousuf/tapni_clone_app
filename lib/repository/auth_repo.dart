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

  Future<ApiResponse> profileByUsername({required String username}) async {
    return await ApiHandler.request(
      api: Api.auth.profileByUsername(username),
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> profileById({required String id}) async {
    return await ApiHandler.request(
      api: Api.auth.profileById("6a22f75c7b8029607d0cbae9"),
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

  Future<ApiResponse> getContactCategories() async {
    return await ApiHandler.request(
      api: Api.contact.getCategories,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> createContactCategory({
    required String name,
    required String color,
  }) async {
    return await ApiHandler.request(
      api: Api.contact.createCategory,
      jsonBody: {"name": name, "color": color},
      method: ApiMethod.post,
      authorization: true,
    );
  }

  Future<ApiResponse> deleteContactCategory(String id) async {
    return await ApiHandler.request(
      api: Api.contact.deleteCategory(id),
      method: ApiMethod.delete,
      authorization: true,
    );
  }

  Future<ApiResponse> getContacts() async {
    return await ApiHandler.request(
      api: Api.contact.getContacts,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> addManualContact({
    required String name,
    required String email,
    required String phone,
    required String company,
    String jobTitle = '',
    String website = '',
    String note = '',
    String address = '',
  }) async {
    return await ApiHandler.request(
      api: Api.contact.addManual,
      jsonBody: {
        "name": name,
        "email": email,
        "phone": phone,
        "company": company,
        "jobTitle": jobTitle,
        "website": website,
        "note": note,
        "address": address,
      },
      method: ApiMethod.post,
      authorization: true,
    );
  }

  Future<ApiResponse> addScannedContact({required String username}) async {
    return await ApiHandler.request(
      api: Api.contact.addScanned,
      body: {"username": username},
      method: ApiMethod.post,
      authorization: true,
    );
  }

  Future<ApiResponse> exchangeContact({String? username, String? id}) async {
    return await ApiHandler.request(
      api: Api.contact.exchange,
      body: {"username": username ?? "", "id": id ?? ""},
      method: ApiMethod.post,
      authorization: true,
    );
  }

  Future<ApiResponse> updateContact({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    return await ApiHandler.request(
      api: Api.contact.updateContact(id),
      jsonBody: data,
      method: ApiMethod.put,
      authorization: true,
    );
  }

  Future<ApiResponse> deleteContact(String id) async {
    return await ApiHandler.request(
      api: Api.contact.deleteContact(id),
      method: ApiMethod.delete,
      authorization: true,
    );
  }
}
