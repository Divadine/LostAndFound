import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lost_and_found/api_providers/api_endpoints.dart';

class ApiClient {
  late Dio dio;

  ApiClient(){
    dio = Dio(BaseOptions(
      baseUrl: ApiEndPoints.baseUrl,
      headers: {
        "Content-Type":"application/json"
      },
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
    ));

    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true,));
  }

  Future<Response> post(String path, Map<String,dynamic>data,) async {
    return await dio.post(path,data: data);
  }

}