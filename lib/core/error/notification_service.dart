import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';

/// Serviço centralizado para exibição de notificações
/// 
/// Este serviço centraliza todas as notificações (sucesso, warning, erro, info) no ServusSnackbar,
/// proporcionando uma experiência uniforme e mensagens amigáveis ao usuário.
/// 
/// DIFERENÇA IMPORTANTE: Este serviço é para notificações na UI,
/// NÃO para notificações push do sistema operacional.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Inicializa o serviço com a chave do navigator
  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  /// Obtém o contexto atual de forma segura
  BuildContext? get _currentContext {
    return _navigatorKey?.currentContext;
  }

  /// Verifica se o contexto está disponível e montado
  bool get _isContextAvailable {
    final context = _currentContext;
    return context != null && context.mounted;
  }

  // ========================================
  // MÉTODOS CENTRALIZADOS PARA NOTIFICAÇÕES
  // ========================================

  /// Exibe uma notificação de sucesso
  void showSuccess(String message, {String? title}) {
    if (!_isContextAvailable) {
      _logFallback('Success', message);
      return;
    }

    showServusSnack(
      _currentContext!,
      message: message,
      title: title ?? 'Sucesso',
      type: ServusSnackType.success,
    );
  }

  /// Exibe uma notificação de warning
  void showWarning(String message, {String? title}) {
    if (!_isContextAvailable) {
      _logFallback('Warning', message);
      return;
    }

    showServusSnack(
      _currentContext!,
      message: message,
      title: title ?? 'Atenção',
      type: ServusSnackType.warning,
    );
  }

  /// Exibe uma notificação de erro
  void showError(String message, {String? title}) {
    if (!_isContextAvailable) {
      _logFallback('Error', message);
      return;
    }

    showServusSnack(
      _currentContext!,
      message: message,
      title: title ?? 'Erro',
      type: ServusSnackType.error,
    );
  }

  /// Exibe uma notificação de informação
  void showInfo(String message, {String? title}) {
    if (!_isContextAvailable) {
      _logFallback('Info', message);
      return;
    }

    showServusSnack(
      _currentContext!,
      message: message,
      title: title ?? 'Informação',
      type: ServusSnackType.info,
    );
  }

  // ========================================
  // MÉTODOS PRINCIPAIS PARA DIFERENTES TIPOS DE ERRO
  // ========================================

  /// Trata erros de DioException de forma inteligente
  void handleDioError(
    DioException error, {
    String? customMessage,
    VoidCallback? onRetry,
    bool showSnackbar = true,
  }) {
    if (!showSnackbar) return;

    final message = _extractDioErrorMessage(error, customMessage);
    final statusCode = error.response?.statusCode;
    
    // Usar os métodos centralizados baseados no status code
    switch (statusCode) {
      case 400:
      case 422:
        showWarning(message, title: 'Dados Inválidos');
        break;
      case 401:
        showError('Sua sessão expirou. Faça login novamente.', title: 'Sessão Expirada');
        break;
      case 403:
        showError('Você não tem permissão para realizar esta ação.', title: 'Acesso Negado');
        break;
      case 404:
        showError(message, title: 'Não Encontrado');
        break;
      case 409:
        showWarning(message, title: 'Conflito');
        break;
      case 429:
        showWarning('Você fez muitas requisições. Tente novamente em breve.', title: 'Muitas Requisições');
        break;
      case 500:
      case 502:
      case 503:
      case 504:
        showError('Ocorreu um erro no servidor. Tente novamente mais tarde.', title: 'Erro do Servidor');
        break;
      default:
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.connectionError) {
          showError('Verifique sua conexão com a internet e tente novamente.', title: 'Sem Conexão');
        } else {
          showError(message, title: 'Erro');
        }
    }
  }

  /// Trata erros de validação (400, 422)
  void handleValidationError(
    String message, {
    VoidCallback? onRetry,
    bool showSnackbar = true,
  }) {
    if (!showSnackbar) return;
    
    showWarning(_cleanMessage(message), title: 'Dados Inválidos');
  }

  /// Trata erros de autenticação (401)
  void handleAuthError({
    String? customMessage,
    VoidCallback? onRetry,
    bool showSnackbar = true,
  }) {
    if (!showSnackbar) return;
    
    final message = customMessage ?? 'Sua sessão expirou. Faça login novamente.';
    showError(message, title: 'Sessão Expirada');
  }

  /// Trata erros de permissão (403)
  void handlePermissionError({
    String? customMessage,
    VoidCallback? onRetry,
    bool showSnackbar = true,
  }) {
    if (!showSnackbar) return;
    
    final message = customMessage ?? 'Você não tem permissão para realizar esta ação.';
    showError(message, title: 'Acesso Negado');
  }

  /// Trata erros de recurso não encontrado (404)
  void handleNotFoundError({
    String? customMessage,
    String? resourceName,
    VoidCallback? onRetry,
    bool showSnackbar = true,
  }) {
    if (!showSnackbar) return;
    
    String message;
    if (customMessage != null) {
      message = customMessage;
    } else if (resourceName != null) {
      message = '$resourceName não encontrado.';
    } else {
      message = 'Recurso não encontrado.';
    }
    
    showError(message, title: 'Não Encontrado');
  }

  /// Trata erros de conflito (409) - como email duplicado
  void handleConflictError({
    String? customMessage,
    String? conflictType,
    VoidCallback? onRetry,
    bool showSnackbar = true,
  }) {
    if (!showSnackbar) return;
    
    String message;
    if (customMessage != null) {
      message = customMessage;
    } else if (conflictType == 'email') {
      message = 'Já existe um usuário com este email. Use um email diferente.';
    } else if (conflictType == 'name') {
      message = 'Já existe um item com este nome. Use um nome diferente.';
    } else {
      message = 'Este item já existe. Verifique os dados e tente novamente.';
    }
    
    showWarning(message, title: 'Item Já Existe');
  }

  /// Trata erros de servidor (500+)
  void handleServerError({
    String? customMessage,
    VoidCallback? onRetry,
    bool showSnackbar = true,
  }) {
    if (!showSnackbar) return;
    
    final message = customMessage ?? 'Erro interno do servidor. Tente novamente em alguns minutos.';
    showError(message, title: 'Erro do Servidor');
  }

  /// Trata erros de rede/conexão
  void handleNetworkError({
    String? customMessage,
    VoidCallback? onRetry,
    bool showSnackbar = true,
  }) {
    if (!showSnackbar) return;
    
    final message = customMessage ?? 'Verifique sua conexão com a internet e tente novamente.';
    showError(message, title: 'Sem Conexão');
  }

  /// Trata erros genéricos
  void handleGenericError(
    dynamic error, {
    String? customMessage,
    VoidCallback? onRetry,
    bool showSnackbar = true,
  }) {
    if (!showSnackbar) return;
    
    String message;
    if (customMessage != null) {
      message = customMessage;
    } else if (error is DioException) {
      message = _extractDioErrorMessage(error);
    } else {
      message = _cleanMessage(error.toString());
    }
    
    showError(message, title: 'Erro');
  }


  // ========================================
  // MÉTODOS AUXILIARES
  // ========================================

  /// Extrai mensagem amigável de DioException
  String _extractDioErrorMessage(DioException error, [String? customMessage]) {
    if (customMessage != null) return customMessage;

    // Tentar extrair mensagem do servidor
    if (error.response?.data is Map) {
      final data = error.response!.data as Map;
      final serverMessage = data['message']?.toString();
      if (serverMessage != null && serverMessage.isNotEmpty) {
        return serverMessage;
      }
    }

    // Fallback baseado no tipo de erro
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Timeout na conexão. Verifique sua internet e tente novamente.';
      case DioExceptionType.connectionError:
        return 'Erro de conexão. Verifique sua internet e tente novamente.';
      case DioExceptionType.badResponse:
        return _getHttpErrorMessage(error.response?.statusCode);
      case DioExceptionType.cancel:
        return 'Operação cancelada.';
      case DioExceptionType.unknown:
        return 'Erro desconhecido. Tente novamente.';
      default:
        return 'Erro na operação. Tente novamente.';
    }
  }

  /// Retorna mensagem baseada no código HTTP
  String _getHttpErrorMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Dados inválidos. Verifique as informações fornecidas.';
      case 401:
        return 'Sessão expirada. Faça login novamente.';
      case 403:
        return 'Você não tem permissão para realizar esta ação.';
      case 404:
        return 'Recurso não encontrado.';
      case 409:
        return 'Este item já existe. Verifique os dados e tente novamente.';
      case 422:
        return 'Dados inválidos. Verifique as informações fornecidas.';
      case 429:
        return 'Muitas tentativas. Aguarde um momento e tente novamente.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'Erro interno do servidor. Tente novamente em alguns minutos.';
      default:
        return 'Erro na operação. Tente novamente.';
    }
  }

  /// Limpa mensagens removendo informações técnicas desnecessárias
  String _cleanMessage(String message) {
    // Se a mensagem contém informações técnicas, extrair apenas a parte útil
    if (message.contains('DioException') || 
        message.contains('bad response') || 
        message.contains('status code') ||
        message.contains('RequestOptions') ||
        message.contains('validateStatus') ||
        message.contains('Client error') ||
        message.contains('server error') ||
        message.contains('Read more about status codes') ||
        message.contains('https://developer.mozilla.org')) {
      
      // Tentar extrair apenas a mensagem limpa do servidor
      List<String> lines = message.split('\n');
      for (String line in lines) {
        line = line.trim();
        if (line.isNotEmpty && 
            !line.contains('DioException') && 
            !line.contains('bad response') &&
            !line.contains('status code') &&
            !line.contains('RequestOptions') &&
            !line.contains('validateStatus') &&
            !line.contains('Client error') &&
            !line.contains('server error') &&
            !line.contains('Read more about') &&
            !line.contains('https://') &&
            !line.contains('The status code') &&
            !line.contains('In order to resolve') &&
            !line.contains('you typically have') &&
            !line.contains('Read more about status codes')) {
          return line;
        }
      }
      
      // Se não conseguir extrair, retornar uma mensagem genérica
      return 'Ocorreu um erro. Tente novamente.';
    }
    
    // Se a mensagem já está limpa, retornar como está
    return message;
  }

  /// Log de fallback quando não consegue mostrar snackbar
  void _logFallback(String type, String message) {
    String emoji;
    switch (type.toLowerCase()) {
      case 'success':
        emoji = '✅';
        break;
      case 'warning':
        emoji = '⚠️';
        break;
      case 'error':
        emoji = '❌';
        break;
      case 'info':
        emoji = 'ℹ️';
        break;
      default:
        emoji = '📝';
    }
    
    debugPrint('$emoji [NotificationService] Contexto não disponível para mostrar $type');
    debugPrint('$emoji [NotificationService] Mensagem: $message');
  }

}
