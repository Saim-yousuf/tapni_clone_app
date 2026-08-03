import 'package:tapni_app/utils/api_endpoint.dart';
import 'package:tapni_app/utils/api_handler.dart';

class InvitationRepo {
  Future<ApiResponse> createInvitation(Map<String, dynamic> body) async {
    return ApiHandler.request(
      api: Api.invitation.create,
      method: ApiMethod.post,
      authorization: true,
      jsonBody: body,
    );
  }

  Future<ApiResponse> updateInvitation(
    String id,
    Map<String, dynamic> body,
  ) async {
    return ApiHandler.request(
      api: Api.invitation.update(id),
      method: ApiMethod.put,
      authorization: true,
      jsonBody: body,
    );
  }

  Future<ApiResponse> getSent() async {
    return ApiHandler.request(
      api: Api.invitation.sent,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> getReceived() async {
    return ApiHandler.request(
      api: Api.invitation.received,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> getById(String id) async {
    return ApiHandler.request(
      api: Api.invitation.byId(id),
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> matchPhones(List<String> phones) async {
    return ApiHandler.request(
      api: Api.contact.matchPhones,
      method: ApiMethod.post,
      authorization: true,
      jsonBody: {'phones': phones},
    );
  }

  Future<ApiResponse> publishTemplate(Map<String, dynamic> body) async {
    return ApiHandler.request(
      api: Api.invitation.templates,
      method: ApiMethod.post,
      authorization: true,
      jsonBody: body,
    );
  }

  Future<ApiResponse> getPublicTemplates({
    String? country,
    String? category,
  }) async {
    final params = <String>[];
    if (country != null && country.isNotEmpty) {
      params.add('country=${Uri.encodeQueryComponent(country)}');
    }
    if (category != null && category.isNotEmpty) {
      params.add('category=${Uri.encodeQueryComponent(category)}');
    }
    final query = params.isEmpty ? '' : '?${params.join('&')}';
    return ApiHandler.request(
      api: '${Api.invitation.templates}$query',
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> getMyTemplates() async {
    return ApiHandler.request(
      api: Api.invitation.myTemplates,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> useTemplate(String id) async {
    return ApiHandler.request(
      api: Api.invitation.useTemplate(id),
      method: ApiMethod.post,
      authorization: true,
    );
  }

  Future<ApiResponse> deleteTemplate(String id) async {
    return ApiHandler.request(
      api: Api.invitation.templateById(id),
      method: ApiMethod.delete,
      authorization: true,
    );
  }
}
