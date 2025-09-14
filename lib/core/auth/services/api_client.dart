import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:servus_app/core/constants/env.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio dio;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: Env.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['device-id'] = 'flutter-app';
        return handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401) {
          final refreshed = await _tryRefreshToken();

          if (refreshed) {
            // Tenta de novo a mesma requisição
            final prefs = await SharedPreferences.getInstance();
            final newToken = prefs.getString('access_token');
            e.requestOptions.headers['Authorization'] = 'Bearer $newToken';

            final retryResponse = await dio.fetch(e.requestOptions);
            return handler.resolve(retryResponse);
          }
        }
        return handler.next(e);
      },
    ));
  }

  /// Método para tentar atualizar o token
  Future<bool> _tryRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    if (refreshToken == null) return false;

    try {
      final response = await dio.post(
        '/auth/refresh',
        data: jsonEncode({"refreshToken": refreshToken}),
        options: Options(headers: {
          'Content-Type': 'application/json',
          'device-id': 'flutter-app',
        }),
      );

      if (response.statusCode == 200 && response.data != null) {
        await prefs.setString('access_token', response.data['access_token']);
        await prefs.setString('refresh_token', response.data['refresh_token']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}