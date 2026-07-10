import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:tapni_app/helper/log_helper.dart';
import 'package:tapni_app/utils/preference_helper.dart';

enum ApiMethod { get, post, put, delete, multipartPost, multipartPut }

class ApiHandler {
  static Future<ApiResponse> request({
    required ApiMethod method,
    required String api,
    Map<String, String>? body,
    Map<String, dynamic>? jsonBody,
    Map<String, String?>? queryParams,
    List<File>? multiFile,
    List<String>? multiField,
    dynamic file,
    String? field,
    bool authorization = false,
    bool multiFileAdd = false,
    String? tokenKey,
    Map<String, String>? headers,
  }) async {
    try {
      headers = {
        'Content-Type': 'application/json',
        if (authorization)
          'Authorization':
              "Bearer ${SharedPrefHelper.getString(tokenKey ?? SharedPrefHelper.utils.authorizedToken)}",
        ...?headers,
      };

      final uri = Uri.parse(api).replace(
        queryParameters: {...(Uri.parse(api).queryParameters), ...?queryParams},
      );

      PrintLog.logMessage("API: $uri");
      PrintLog.logMessage("Headers: $headers");
      if (jsonBody != null) PrintLog.logMessage("JSON Body: $jsonBody");
      if (body != null) PrintLog.logMessage("Form Body: $body");

      http.Response response;

      String? encodedBody;
      final payload = jsonBody ?? body;
      if (payload != null) {
        encodedBody = jsonEncode(payload);
      }

      switch (method) {
        case ApiMethod.get:
          response = await http.get(uri, headers: headers);
          break;

        case ApiMethod.post:
          response = await http.post(
            uri,
            headers: headers,
            body: encodedBody,
          );
          break;

        case ApiMethod.put:
          response = await http.put(
            uri,
            headers: headers,
            body: encodedBody,
          );
          break;

        case ApiMethod.delete:
          response = await http.delete(
            uri,
            headers: headers,
            body: encodedBody,
          );
          break;

        case ApiMethod.multipartPost:
        case ApiMethod.multipartPut:
          final request =
              http.MultipartRequest(
                  method == ApiMethod.multipartPost ? "POST" : "PUT",
                  uri,
                )
                ..headers.addAll(headers)
                ..fields.addAll(body ?? {});

          if (file != null) {
            request.files.add(
              file is File
                  ? await http.MultipartFile.fromPath(field!, file.path)
                  : http.MultipartFile.fromBytes(field!, file as List<int>),
            );
          }

          if (multiFile != null && multiField != null) {
            for (var i = 0; i < multiFile.length; i++) {
              final fileStream = http.ByteStream(multiFile[i].openRead());
              final fileLength = await multiFile[i].length();
              final fileName = multiFileAdd
                  ? '${multiField[i]}[]'
                  : multiField[i];
              request.files.add(
                http.MultipartFile(
                  fileName,
                  fileStream,
                  fileLength,
                  filename: multiFile[i].path.split('/').last,
                ),
              );
            }
          }

          final streamedResponse = await request.send();
          response = await http.Response.fromStream(streamedResponse);
          break;
      }

      PrintLog.logMessage("Response Code: ${response.statusCode}");
      PrintLog.logMessage("Response Body: ${response.body}");

      return _handleResponse(response);
    } catch (e) {
      PrintLog.logMessage("Request failed: $e");
      return ApiResponse<dynamic>(
        success: false,
        statusCode: 0,
        message: 'Request failed: $e',
      );
    }
  }

  static ApiResponse<dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    dynamic decoded;

    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        return ApiResponse<dynamic>(
          success: false,
          statusCode: statusCode,
          message: statusCode >= 400
              ? 'Request failed ($statusCode)'
              : 'Invalid server response',
        );
      }
    }

    return ApiResponse.fromJson(statusCode, decoded);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => "ApiException($statusCode): $message";
}

class ApiResponse<T> {
  final bool success;
  final int statusCode;
  final String? message;
  final T? data;

  ApiResponse({
    required this.success,
    required this.statusCode,
    this.message,
    this.data,
  });

  factory ApiResponse.fromJson(int statusCode, dynamic json) {
    final success = statusCode >= 200 && statusCode < 300;

    return ApiResponse<T>(
      success: success,
      statusCode: statusCode,
      message: json is Map && json['message'] != null
          ? json['message'].toString()
          : json is Map && json['error'] != null
          ? json['error'].toString()
          : (success ? null : "Unexpected error occurred"),
      data: json as T?,
    );
  }
}
