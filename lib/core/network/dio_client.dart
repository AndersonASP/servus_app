import 'package:dio/dio.dart';
import 'package:servus_app/core/auth/services/auth_interceptor.dart';
import 'package:servus_app/core/constants/env.dart';

class DioClient {
  static Dio? _dio;

  static Dio get instance {
    if (_dio == null) {
      final dio = Dio(BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
      ));

      dio.interceptors.add(AuthInterceptor(dio));
      _dio = dio;
    }

    return _dio!;
  }
}