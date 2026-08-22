import 'package:tapni_app/utils/api_handler.dart';
import 'package:tapni_app/utils/api_endpoint.dart';

class RewardRepo {
  Future<ApiResponse> getPrograms() async {
    return await ApiHandler.request(
      api: Api.loyalty.programs,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> createProgram(Map<String, dynamic> body) async {
    return await ApiHandler.request(
      api: Api.loyalty.programs,
      method: ApiMethod.post,
      authorization: true,
      jsonBody: body,
    );
  }

  Future<ApiResponse> getProgramById(String id) async {
    return await ApiHandler.request(
      api: Api.loyalty.program(id),
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> updateProgram(
    String id,
    Map<String, dynamic> body,
  ) async {
    return await ApiHandler.request(
      api: Api.loyalty.program(id),
      method: ApiMethod.put,
      authorization: true,
      jsonBody: body,
    );
  }

  Future<ApiResponse> toggleActive(String id) async {
    return await ApiHandler.request(
      api: Api.loyalty.toggleActive(id),
      method: ApiMethod.put,
      headers: {'Content-Type': 'application/json'},
      authorization: true,
      body: {},
    );
  }

  Future<ApiResponse> deleteProgram(String id) async {
    return await ApiHandler.request(
      api: Api.loyalty.program(id),
      method: ApiMethod.delete,
      authorization: true,
    );
  }

  Future<ApiResponse> getCustomerEnrollments(String customerId) async {
    return await ApiHandler.request(
      api: Api.enrollment.customerEnrollments(customerId),
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> enrollCustomer(
    String programId,
    String customerId,
  ) async {
    return await ApiHandler.request(
      api: Api.enrollment.enroll,
      method: ApiMethod.post,
      authorization: true,
      jsonBody: {'programId': programId, 'customerId': customerId},
    );
  }

  Future<ApiResponse> selfEnroll(String programId) async {
    return await ApiHandler.request(
      api: Api.enrollment.selfEnroll,
      method: ApiMethod.post,
      authorization: true,
      jsonBody: {'programId': programId},
    );
  }

  Future<ApiResponse> getMyEnrollments() async {
    return await ApiHandler.request(
      api: Api.enrollment.myEnrollments,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> getCustomerBusinessStatus(String customerId) async {
    return await ApiHandler.request(
      api: Api.businessEnrollment.customerStatus(customerId),
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> enrollCustomerInBusiness(String customerId) async {
    return await ApiHandler.request(
      api: Api.businessEnrollment.enroll,
      method: ApiMethod.post,
      authorization: true,
      jsonBody: {'customerId': customerId},
    );
  }

  Future<ApiResponse> addStamp(String enrollmentId) async {
    return await ApiHandler.request(
      api: Api.enrollment.addStamp(enrollmentId),
      method: ApiMethod.post,
      headers: {'Content-Type': 'application/json'},
      authorization: true,
      body: {},
    );
  }

  Future<ApiResponse> getCommunityTemplates({String? category}) async {
    final q = category != null && category.isNotEmpty
        ? '?category=${Uri.encodeQueryComponent(category)}'
        : '';
    return await ApiHandler.request(
      api: '${Api.loyalty.templates}$q',
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> publishLoyaltyTemplate(Map<String, dynamic> body) async {
    return await ApiHandler.request(
      api: Api.loyalty.templates,
      method: ApiMethod.post,
      authorization: true,
      jsonBody: body,
    );
  }

  Future<ApiResponse> useLoyaltyTemplate(String id) async {
    return await ApiHandler.request(
      api: Api.loyalty.useTemplate(id),
      method: ApiMethod.post,
      headers: {'Content-Type': 'application/json'},
      authorization: true,
      body: {},
    );
  }

  Future<ApiResponse> deleteLoyaltyTemplate(String id) async {
    return await ApiHandler.request(
      api: Api.loyalty.templateById(id),
      method: ApiMethod.delete,
      authorization: true,
    );
  }
}
