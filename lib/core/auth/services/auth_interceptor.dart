import 'dart:async';
import 'package:dio/dio.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/core/error/error_handler_service.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  bool _isRefreshing = false;
  final List<Function()> _retryQueue = [];
  int _refreshRetryCount = 0;
  static const int _maxRefreshRetries = 2; // Máximo de 2 tentativas de refresh

  AuthInterceptor(this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Adiciona device-id em todas as requisições
    final deviceId = await TokenService.getDeviceId();
    options.headers['device-id'] = deviceId;

    // Adiciona token de autorização se disponível
    final token = await TokenService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Adiciona headers de contexto se disponível
    final context = await TokenService.getContext();
    if (context['tenantId'] != null) {
      options.headers['x-tenant-id'] = context['tenantId'];
    } else {
    }
    if (context['branchId'] != null) {
      options.headers['x-branch-id'] = context['branchId'];
    }
    if (context['ministryId'] != null) {
      options.headers['x-ministry-id'] = context['ministryId'];
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final isRefreshEndpoint = err.requestOptions.path.contains('/auth/refresh');

    if (isUnauthorized && !isRefreshEndpoint) {
      // Verifica se o token está expirado
      if (await TokenService.isTokenExpired()) {
        // Verifica se ainda temos tentativas de refresh disponíveis
        if (_refreshRetryCount < _maxRefreshRetries) {
          await _handleTokenRefresh(err, handler);
        } else {
          ErrorHandlerService().logError('Máximo de tentativas de refresh atingido');
          await _logout();
          handler.reject(err);
        }
      } else {
        // Token válido mas servidor retornou 401 - pode ser problema de permissão
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }

  Future<void> _handleTokenRefresh(DioException err, ErrorInterceptorHandler handler) async {
    final refreshToken = await TokenService.getRefreshToken();
    
    if (refreshToken == null) {
      await _logout();
      handler.reject(err);
      return;
    }

    final completer = Completer<Response>();
    _retryQueue.add(() async {
      final retryRequest = err.requestOptions;
      final newAccessToken = await TokenService.getAccessToken();
      if (newAccessToken != null) {
        retryRequest.headers['Authorization'] = 'Bearer $newAccessToken';
      }
      completer.complete(await dio.fetch(retryRequest));
    });

    if (!_isRefreshing) {
      _isRefreshing = true;
      _refreshRetryCount++; // Incrementa contador de tentativas
      
      final success = await _refreshToken();
      _isRefreshing = false;

      if (success) {
        // Reset contador em caso de sucesso
        _refreshRetryCount = 0;
        
        // Executa todas as requisições pendentes
        for (var retry in _retryQueue) {
          retry();
        }
        _retryQueue.clear();
        
        // Resolve a requisição original
        try {
          final response = await completer.future;
          handler.resolve(response);
        } catch (e) {
          handler.reject(err);
        }
      } else {
        _retryQueue.clear();
        // Se falhou e atingiu o limite, faz logout
        if (_refreshRetryCount >= _maxRefreshRetries) {
          ErrorHandlerService().logError('Refresh falhou após múltiplas tentativas');
          await _logout();
        }
        handler.reject(err);
      }
    } else {
      // Aguarda o refresh em andamento
      try {
        final response = await completer.future;
        handler.resolve(response);
      } catch (e) {
        handler.reject(err);
      }
    }
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await TokenService.getRefreshToken();
      if (refreshToken == null) return false;

      final deviceId = await TokenService.getDeviceId();
      final context = await TokenService.getContext();

      final response = await dio.post(
        '/auth/refresh',
        data: {
          'refresh_token': refreshToken,
        },
        options: Options(
          headers: {
            'device-id': deviceId,
            if (context['tenantId'] != null) 'x-tenant-id': context['tenantId'],
            if (context['branchId'] != null) 'x-branch-id': context['branchId'],
            if (context['ministryId'] != null) 'x-ministry-id': context['ministryId'],
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        
        await TokenService.saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          expiresIn: data['expires_in'] ?? 3600,
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      ErrorHandlerService().logError(e, context: 'renovação de token');
      return false;
    }
  }

  Future<void> _logout() async {
    await TokenService.clearAll();
    // Aqui você pode usar NavigationService ou outro meio para redirecionar para login
    // Ex: Get.toNamed('/login'); ou context.go('/login'); se tiver acesso
  }
}