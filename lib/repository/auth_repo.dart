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

  Future<ApiResponse> sendPhoneOtp({required String phone}) async {
    return await ApiHandler.request(
      api: Api.auth.otpSend,
      body: {"phone": phone},
      method: ApiMethod.post,
    );
  }

  Future<ApiResponse> verifyPhoneOtp({
    required String phone,
    required String otp,
  }) async {
    return await ApiHandler.request(
      api: Api.auth.otpVerify,
      body: {"phone": phone, "otp": otp},
      method: ApiMethod.post,
    );
  }

  Future<ApiResponse> completePhoneSignup({
    required String phone,
    required String verificationToken,
    required String name,
    String? country,
    String? profilePhoto,
  }) async {
    return await ApiHandler.request(
      api: Api.auth.otpComplete,
      body: {
        "phone": phone,
        "verificationToken": verificationToken,
        "name": name,
        if (country != null && country.isNotEmpty) "country": country,
        if (profilePhoto != null && profilePhoto.isNotEmpty)
          "profilePhoto": profilePhoto,
      },
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

  Future<ApiResponse> searchPublicUsers({required String query}) async {
    return await ApiHandler.request(
      api: Api.auth.searchUsers(query),
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> checkUsernameAvailability({
    required String username,
  }) async {
    return await ApiHandler.request(
      api: Api.auth.checkUsername(username.trim().toLowerCase()),
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> submitUsernameClaim({
    required String username,
    required String reason,
    String? businessEmail,
  }) async {
    return await ApiHandler.request(
      api: Api.auth.submitUsernameClaim,
      method: ApiMethod.post,
      authorization: true,
      jsonBody: {
        'username': username.trim().toLowerCase(),
        'reason': reason.trim(),
        if (businessEmail != null && businessEmail.trim().isNotEmpty)
          'businessEmail': businessEmail.trim().toLowerCase(),
      },
    );
  }

  Future<ApiResponse> myUsernameClaims() async {
    return await ApiHandler.request(
      api: Api.auth.myUsernameClaims,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> profileByUsername({
    required String username,
    bool isScan = false,
    String? cardId,
  }) async {
    return await ApiHandler.request(
      api: Api.auth.profileByUsername(username, isScan: isScan, cardId: cardId),
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> profileById({
    required String id,
    bool isScan = false,
    String? cardId,
  }) async {
    return await ApiHandler.request(
      api: Api.auth.profileById(id, isScan: isScan, cardId: cardId),
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

  Future<ApiResponse> addGalleryItem({
    required String image,
    String caption = '',
  }) async {
    return await ApiHandler.request(
      api: Api.auth.gallery,
      method: ApiMethod.post,
      authorization: true,
      jsonBody: {
        'image': image,
        if (caption.trim().isNotEmpty) 'caption': caption.trim(),
      },
    );
  }

  Future<ApiResponse> deleteGalleryItem({required String itemId}) async {
    return await ApiHandler.request(
      api: Api.auth.galleryItem(itemId),
      method: ApiMethod.delete,
      authorization: true,
    );
  }

  Future<ApiResponse> linkCatalog() async {
    return await ApiHandler.request(
      api: Api.auth.linkCatalog,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> getAnalytics({String range = '7d'}) async {
    return await ApiHandler.request(
      api: Api.auth.analytics,
      method: ApiMethod.get,
      authorization: true,
      queryParams: {'range': range},
    );
  }

  Future<ApiResponse> saveFcmToken({
    required String token,
    required String platform,
  }) async {
    return await ApiHandler.request(
      api: Api.auth.saveFcmToken,
      jsonBody: {"token": token, "platform": platform},
      method: ApiMethod.post,
      authorization: true,
    );
  }

  Future<ApiResponse> removeFcmToken({required String token}) async {
    return await ApiHandler.request(
      api: Api.auth.removeFcmToken,
      jsonBody: {"token": token},
      method: ApiMethod.delete,
      authorization: true,
    );
  }

  Future<ApiResponse> createDevicePairing({
    required String deviceName,
    required String platform,
    required String deviceKey,
  }) async {
    return await ApiHandler.request(
      api: Api.auth.createDevicePairing,
      jsonBody: {
        "deviceName": deviceName,
        "platform": platform,
        "deviceKey": deviceKey,
      },
      method: ApiMethod.post,
    );
  }

  Future<ApiResponse> getDevicePairingStatus({required String code}) async {
    return await ApiHandler.request(
      api: Api.auth.devicePairingStatus(code),
      method: ApiMethod.get,
    );
  }

  Future<ApiResponse> approveDevicePairing({
    required String code,
    required String deviceName,
    required String platform,
    required String deviceKey,
  }) async {
    return await ApiHandler.request(
      api: Api.auth.approveDevicePairing,
      jsonBody: {
        "code": code,
        "deviceName": deviceName,
        "platform": platform,
        "deviceKey": deviceKey,
      },
      method: ApiMethod.post,
      authorization: true,
    );
  }

  Future<ApiResponse> listDeviceSessions() async {
    return await ApiHandler.request(
      api: Api.auth.deviceSessions,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> revokeDeviceSession(String sessionId) async {
    return await ApiHandler.request(
      api: Api.auth.revokeDeviceSession(sessionId),
      method: ApiMethod.delete,
      authorization: true,
    );
  }

  Future<ApiResponse> revokeCurrentDeviceSession() async {
    return await ApiHandler.request(
      api: Api.auth.revokeCurrentDeviceSession,
      method: ApiMethod.delete,
      authorization: true,
    );
  }

  Future<ApiResponse> registerDeviceSession({
    required String deviceName,
    required String platform,
    required String deviceKey,
  }) async {
    return await ApiHandler.request(
      api: Api.auth.registerDeviceSession,
      jsonBody: {
        "deviceName": deviceName,
        "platform": platform,
        "deviceKey": deviceKey,
      },
      method: ApiMethod.post,
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
