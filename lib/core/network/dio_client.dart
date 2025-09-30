import 'package:dio/dio.dart';
import 'package:servus_app/core/auth/services/auth_interceptor.dart';
import 'package:servus_app/core/constants/env.dart';

class DioClient {
  static Dio? _dio;

  static Dio get instance {
    if (_dio == null) {
      final dio = Dio(BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        contentType: 'application/json',
      ));

      // Interceptor de retry para timeouts
      dio.interceptors.add(RetryInterceptor(
        dio: dio,
        logPrint: print,
        retries: 1, // ✅ CORREÇÃO: Reduzido para 1 retry apenas
        retryDelays: const [
          Duration(seconds: 2), // ✅ CORREÇÃO: Apenas 1 delay
        ],
      ));

      dio.interceptors.add(AuthInterceptor(dio));
      _dio = dio;
    }

    return _dio!;
  }
}

// Interceptor para retry automático
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int retries;
  final List<Duration> retryDelays;
  final void Function(String message)? logPrint;

  RetryInterceptor({
    required this.dio,
    this.retries = 3,
    this.retryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 3),
    ],
    this.logPrint,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    print('🔄 [RetryInterceptor] Erro detectado: ${err.response?.statusCode}');
    print('🔄 [RetryInterceptor] URL: ${err.requestOptions.uri}');
    
    final extra = RetryOptions.fromExtra(err.requestOptions) ??
        RetryOptions(retries: retries, retryDelays: retryDelays);

    final shouldRetry = extra.retries > 0 && _shouldRetry(err);
    print('🔄 [RetryInterceptor] Deve fazer retry: $shouldRetry (${extra.retries} retries left)');
    
    if (!shouldRetry) {
      print('🔄 [RetryInterceptor] Não fazendo retry, passando erro adiante');
      return handler.next(err);
    }

    extra.retries--;
    final delay = retryDelays[retries - extra.retries - 1];
    print('🔄 [RetryInterceptor] Fazendo retry em ${delay.inSeconds}s');
    logPrint?.call(
      '🔄 Retrying request ${err.requestOptions.path} in ${delay.inSeconds}s (${extra.retries} retries left)',
    );

    await Future.delayed(delay);

    try {
      print('🔄 [RetryInterceptor] Executando retry...');
      final response = await dio.fetch(err.requestOptions);
      print('🔄 [RetryInterceptor] Retry bem-sucedido: ${response.statusCode}');
      handler.resolve(response);
    } catch (e) {
      print('🔄 [RetryInterceptor] Retry falhou: $e');
      if (e is DioException) {
        err.requestOptions.extra[RetryOptions.extraKey] = extra;
        return onError(e, handler);
      }
      handler.next(err);
    }
  }

  bool _shouldRetry(DioException err) {
    // Não faz retry para endpoints de refresh para evitar loops infinitos
    if (err.requestOptions.path.contains('/auth/refresh')) {
      return false;
    }
    
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        (err.response?.statusCode != null && err.response!.statusCode! >= 500);
  }
}

class RetryOptions {
  static const String extraKey = 'retry_options';
  int retries;
  final List<Duration> retryDelays;

  RetryOptions({required this.retries, required this.retryDelays});

  static RetryOptions? fromExtra(RequestOptions request) {
    return request.extra[extraKey] as RetryOptions?;
  }
}