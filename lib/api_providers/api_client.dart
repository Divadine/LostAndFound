import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:lost_and_found/api_providers/api_endpoints.dart';
import 'package:lost_and_found/enums/current_state.dart';
import 'package:lost_and_found/models/api_model/response_model.dart';

class ApiClient {
  late final Dio dio;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndPoints.baseUrl,
        headers: {
          "Content-Type": "application/json",
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
      ),
    );
  }

  // ============================================================
  // COMMON REQUEST
  // ============================================================

  Future<ResponseModel> request(
      String path, {
        String method = 'GET',
        dynamic data,
        bool addToken = true,
        Map<String, dynamic>? queryParameters,
      }) async {


    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return ResponseModel(
        status: 0,
        message: "No internet connection. Please check your network.",
        currentState: CurrentState.noInternet,
      );
    }

    try {
      final Map<String, dynamic> headers = {
        "Content-Type": "application/json",
      };

      // Add token only when required
      // if (addToken) {
      //   final token = AppUtils.jwtToken;
      //
      //   if (token != null && token.isNotEmpty) {
      //     headers["Authorization"] = "Bearer $token";
      //   }
      // }



      final response = await dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          headers: headers,
        ),
      );

      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      log("Unexpected Error: $e");

      return ResponseModel(
        status: 0,
        message: "Something went wrong. Please try again.",
        currentState: CurrentState.somethingWentWrong,
      );
    }
  }

  // ============================================================
  // POST
  // ============================================================

  Future<ResponseModel> post(
      String path, {
        dynamic data,
        bool addToken = true,
      }) {
    return request(
      path,
      method: 'POST',
      data: data,
      addToken: addToken,
    );
  }

  // ============================================================
  // GET
  // ============================================================

  Future<ResponseModel> get(
      String path, {
        Map<String, dynamic>? queryParams,
        bool addToken = true,
      }) {
    return request(
      path,
      method: 'GET',
      queryParameters: queryParams,
      addToken: addToken,
    );
  }

  // ============================================================
  // PUT
  // ============================================================

  Future<ResponseModel> put(
      String path, {
        dynamic data,
        bool addToken = true,
      }) {
    return request(
      path,
      method: 'PUT',
      data: data,
      addToken: addToken,
    );
  }

  // ============================================================
  // PATCH
  // ============================================================

  Future<ResponseModel> patch(
      String path, {
        dynamic data,
        bool addToken = true,
      }) {
    return request(
      path,
      method: 'PATCH',
      data: data,
      addToken: addToken,
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<ResponseModel> delete(
      String path, {
        dynamic data,
        bool addToken = true,
      }) {
    return request(
      path,
      method: 'DELETE',
      data: data,
      addToken: addToken,
    );
  }

  // ============================================================
  // RESPONSE HANDLER
  // ============================================================

  ResponseModel _handleResponse(Response response) {
    final responseData = response.data;

    if (responseData == null) {
      return ResponseModel(
        status: 0,
        message: "Empty response from server.",
        currentState: CurrentState.somethingWentWrong,
      );
    }

    if (responseData is! Map<String, dynamic>) {
      return ResponseModel(
        status: 0,
        message: "Invalid response from server.",
        currentState: CurrentState.somethingWentWrong,
      );
    }

    final status = _parseStatus(responseData["status"]);

    return ResponseModel(
      status: status,
      message: responseData["message"]?.toString() ?? "",
      data: responseData["data"],
      currentState: status == 1 ? CurrentState.success : CurrentState.somethingWentWrong,
    );
  }

  // ============================================================
  // DIO ERROR HANDLER
  // ============================================================

  ResponseModel _handleDioError(DioException error) {
    log("Dio Error Type: ${error.type}");
    log("Dio Error: ${error.message}");
    log("Status Code: ${error.response?.statusCode}");

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return ResponseModel(
          status: 0,
          message: "Connection timeout. Please try again.",
          currentState: CurrentState.somethingWentWrong,
        );

      case DioExceptionType.sendTimeout:
        return ResponseModel(
          status: 0,
          message: "Request timeout. Please try again.",
          currentState: CurrentState.somethingWentWrong,
        );

      case DioExceptionType.receiveTimeout:
        return ResponseModel(
          status: 0,
          message: "Server response timeout. Please try again.",
          currentState: CurrentState.somethingWentWrong,
        );

      case DioExceptionType.connectionError:
        return ResponseModel(
          status: 0,
          message: "No internet connection.",
          currentState: CurrentState.noInternet,
        );

      case DioExceptionType.badResponse:
        return _handleServerError(error);

      case DioExceptionType.cancel:
        return ResponseModel(
          status: 0,
          message: "Request cancelled.",
          currentState: CurrentState.somethingWentWrong,
        );

      default:
        return ResponseModel(
          status: 0,
          message: "Something went wrong. Please try again.",
          currentState: CurrentState.somethingWentWrong,
        );
    }
  }

  // ============================================================
  // SERVER ERROR
  // ============================================================

  ResponseModel _handleServerError(DioException error) {
    final response = error.response;

    if (response?.statusCode == 401) {
      // e.g. AppPreferences.clearSession(); Get.offAllNamed('/login');
    }

    // If backend itself sends a message, use it.
    if (response?.data is Map<String, dynamic>) {
      final data = response!.data as Map<String, dynamic>;

      final serverMessage = data["message"]?.toString();

      if (serverMessage != null && serverMessage.isNotEmpty) {
        return ResponseModel(
          status: 0,
          message: serverMessage,
          currentState: CurrentState.somethingWentWrong,
        );
      }
    }

    switch (response?.statusCode) {
      case 400:
        return ResponseModel(
          status: 0,
          message: "Bad request.",
            currentState: CurrentState.somethingWentWrong
        );

      case 401:
        return ResponseModel(
          status: 0,
          message: "Session expired. Please login again.",
            currentState: CurrentState.somethingWentWrong

        );

      case 403:
        return ResponseModel(
          status: 0,
          message: "Access denied.",
            currentState: CurrentState.somethingWentWrong

        );

      case 404:
        return ResponseModel(
          status: 0,
          message: "Requested resource not found.",
            currentState: CurrentState.somethingWentWrong

        );

      case 500:
        return ResponseModel(
          status: 0,
          message: "Server error. Please try again later.",
            currentState: CurrentState.somethingWentWrong
        );

      default:
        return ResponseModel(
          status: 0,
          message: "Server error. Please try again.",
            currentState: CurrentState.somethingWentWrong
        );
    }
  }

  int _parseStatus(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }
}