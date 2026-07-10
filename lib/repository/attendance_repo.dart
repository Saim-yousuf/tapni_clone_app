import 'package:tapni_app/utils/api_handler.dart';
import 'package:tapni_app/utils/api_endpoint.dart';

class AttendanceRepo {
  Future<ApiResponse> addEmployee(Map<String, dynamic> body) async {
    return ApiHandler.request(
      api: Api.attendance.employees,
      method: ApiMethod.post,
      authorization: true,
      jsonBody: body,
    );
  }

  Future<ApiResponse> getBusinessEmployees() async {
    return ApiHandler.request(
      api: Api.attendance.employees,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> updateEmployee(
    String id,
    Map<String, dynamic> body,
  ) async {
    return ApiHandler.request(
      api: Api.attendance.employee(id),
      method: ApiMethod.put,
      authorization: true,
      jsonBody: body,
    );
  }

  Future<ApiResponse> removeEmployee(String id) async {
    return ApiHandler.request(
      api: Api.attendance.employee(id),
      method: ApiMethod.delete,
      authorization: true,
    );
  }

  Future<ApiResponse> getMyEmployers() async {
    return ApiHandler.request(
      api: Api.attendance.myEmployers,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> getEmployeeStatus(String employeeUserId) async {
    return ApiHandler.request(
      api: Api.attendance.employeeStatus(employeeUserId),
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> getMyInvitations() async {
    return ApiHandler.request(
      api: Api.attendance.myInvitations,
      method: ApiMethod.get,
      authorization: true,
    );
  }

  Future<ApiResponse> acceptInvitation(String id) async {
    return ApiHandler.request(
      api: Api.attendance.acceptInvitation(id),
      method: ApiMethod.post,
      authorization: true,
    );
  }

  Future<ApiResponse> declineInvitation(String id) async {
    return ApiHandler.request(
      api: Api.attendance.declineInvitation(id),
      method: ApiMethod.post,
      authorization: true,
    );
  }

  Future<ApiResponse> markAttendance(Map<String, dynamic> body) async {
    return ApiHandler.request(
      api: Api.attendance.mark,
      method: ApiMethod.post,
      authorization: true,
      jsonBody: body,
    );
  }

  Future<ApiResponse> getTodayStatus(String employeeRefId) async {
    return ApiHandler.request(
      api: Api.attendance.today,
      method: ApiMethod.get,
      authorization: true,
      queryParams: {'employeeRefId': employeeRefId},
    );
  }

  Future<ApiResponse> getBusinessRecords({
    String? date,
    String? employeeRefId,
    int? month,
    int? year,
  }) async {
    return ApiHandler.request(
      api: Api.attendance.businessRecords,
      method: ApiMethod.get,
      authorization: true,
      queryParams: {
        if (date != null) 'date': date,
        if (employeeRefId != null) 'employeeRefId': employeeRefId,
        if (month != null) 'month': month.toString(),
        if (year != null) 'year': year.toString(),
      },
    );
  }

  Future<ApiResponse> getMyRecords({
    String? employeeRefId,
    int? month,
    int? year,
  }) async {
    return ApiHandler.request(
      api: Api.attendance.myRecords,
      method: ApiMethod.get,
      authorization: true,
      queryParams: {
        if (employeeRefId != null) 'employeeRefId': employeeRefId,
        if (month != null) 'month': month.toString(),
        if (year != null) 'year': year.toString(),
      },
    );
  }

  Future<ApiResponse> getSummary({
    required String employeeRefId,
    required int month,
    required int year,
  }) async {
    return ApiHandler.request(
      api: Api.attendance.summary,
      method: ApiMethod.get,
      authorization: true,
      queryParams: {
        'employeeRefId': employeeRefId,
        'month': month.toString(),
        'year': year.toString(),
      },
    );
  }
}
