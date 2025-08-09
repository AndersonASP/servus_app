import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  bool _isRefreshing = false;
  final List<Function()> _retryQueue = [];

  AuthInterceptor(this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final isRefreshEndpoint = err.requestOptions.path.contains('/auth/refresh');

    if (isUnauthorized && !isRefreshEndpoint) {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null) {
        await _logout();
        return handler.reject(err);
      }

      final completer = Completer<Response>();
      _retryQueue.add(() async {
        final retryRequest = err.requestOptions;
        final newAccessToken = prefs.getString('access_token');
        retryRequest.headers['Authorization'] = 'Bearer $newAccessToken';
        completer.complete(await dio.fetch(retryRequest));
      });

      if (!_isRefreshing) {
        _isRefreshing = true;
        final success = await _refreshToken();
        _isRefreshing = false;

        if (success) {
          for (var retry in _retryQueue) {
            retry();
          }
          _retryQueue.clear();
        } else {
          _retryQueue.clear();
          await _logout();
          return handler.reject(err);
        }
      }

      return handler.resolve(await completer.future);
    }

    return handler.next(err);
  }

  Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      if (refreshToken == null) return false;

      final response = await dio.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });

      final newAccessToken = response.data['access_token'];
      final newRefreshToken = response.data['refresh_token'];

      await prefs.setString('access_token', newAccessToken);
      await prefs.setString('refresh_token', newRefreshToken);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // Aqui você pode usar NavigationService ou outro meio para redirecionar para login
    // Ex: Get.toNamed('/login'); ou context.go('/login'); se tiver acesso
  }
}