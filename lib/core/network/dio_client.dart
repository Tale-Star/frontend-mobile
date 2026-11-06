import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';

/// Cliente HTTP centralizado basado en Dio.
class DioClient {
  late final Dio dio;

  DioClient({
    required SecureStorageService secureStorageService,
    void Function()? onUnauthorized,
    String? customBaseUrl,
  }) {
    final baseOptions = BaseOptions(
      baseUrl: customBaseUrl ?? ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      responseType: ResponseType.json,
    );

    dio = Dio(baseOptions);

    dio.interceptors.addAll([
      AuthInterceptor(
        secureStorageService: secureStorageService,
        onUnauthorized: onUnauthorized,
      ),
      if (kDebugMode && AppConfig.instance.enableDebugLogs)
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
        ),
    ]);
  }
}
