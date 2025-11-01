import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:servus_app/core/error/notification_service.dart';

/// Interceptor simplificado para lidar com erros HTTP
/// 
/// Este interceptor agora apenas delega o tratamento de erros para o
/// NotificationService, que é responsável por exibir mensagens
/// amigáveis ao usuário de forma consistente.
class ErrorInterceptor extends Interceptor {
  final NotificationService _errorService = NotificationService();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('🔍 [ErrorInterceptor] Erro detectado:');
    debugPrint('   - Status: ${err.response?.statusCode}');
    debugPrint('   - URL: ${err.requestOptions.uri}');
    debugPrint('   - Tipo: ${err.type}');
    
    // Delegar tratamento de erro para o NotificationService
    _errorService.handleDioError(err);
    
    // Passar o erro adiante para outros interceptors
    handler.next(err);
  }
}
