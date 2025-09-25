import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';

/// Serviço centralizado para tratamento de erros
class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();
  factory ErrorHandlerService() => _instance;
  ErrorHandlerService._internal();

  /// Trata erros de forma amigável para o usuário
  void handleError(
    BuildContext context,
    dynamic error, {
    String? customMessage,
    VoidCallback? onRetry,
    bool showSnackbar = true,
  }) {
    final errorMessage = _getUserFriendlyMessage(error, customMessage);
    
    if (showSnackbar) {
      _showErrorSnackbar(context, errorMessage, onRetry: onRetry);
    }
  }

  /// Trata erros de Dio (requisições HTTP)
  void handleDioError(
    BuildContext context,
    DioException error, {
    String? customMessage,
    VoidCallback? onRetry,
    bool showSnackbar = true,
  }) {
    final errorMessage = _getDioErrorMessage(error, customMessage);
    
    if (showSnackbar) {
      _showErrorSnackbar(context, errorMessage, onRetry: onRetry);
    }
  }

  /// Trata erros de rede/conexão
  void handleNetworkError(
    BuildContext context, {
    String? customMessage,
    VoidCallback? onRetry,
    bool showSnackbar = true,
  }) {
    final errorMessage = customMessage ?? 
        'Verifique sua conexão com a internet e tente novamente.';
    
    if (showSnackbar) {
      _showErrorSnackbar(
        context, 
        errorMessage, 
        title: 'Sem Conexão',
        onRetry: onRetry,
      );
    }
  }

  /// Trata erros de autenticação
  void handleAuthError(
    BuildContext context, {
    String? customMessage,
    VoidCallback? onRetry,
    bool showSnackbar = true,
  }) {
    final errorMessage = customMessage ?? 
        'Sua sessão expirou. Faça login novamente.';
    
    if (showSnackbar) {
      _showErrorSnackbar(
        context, 
        errorMessage, 
        title: 'Sessão Expirada',
        onRetry: onRetry,
      );
    }
  }

  /// Trata erros de validação
  void handleValidationError(
    BuildContext context,
    String message, {
    String? title,
    bool showSnackbar = true,
  }) {
    if (showSnackbar) {
      showWarning(
        context, 
        message,
        title: title ?? 'Dados Inválidos',
      );
    }
  }

  /// Trata erros de servidor (5xx)
  void handleServerError(
    BuildContext context, {
    String? customMessage,
    VoidCallback? onRetry,
    bool showSnackbar = true,
  }) {
    final errorMessage = customMessage ?? 
        'O servidor está temporariamente indisponível. Tente novamente em alguns minutos.';
    
    if (showSnackbar) {
      _showErrorSnackbar(
        context, 
        errorMessage, 
        title: 'Servidor Indisponível',
        onRetry: onRetry,
      );
    }
  }

  /// Trata erros de permissão (403)
  void handlePermissionError(
    BuildContext context, {
    String? customMessage,
    bool showSnackbar = true,
  }) {
    final errorMessage = customMessage ?? 
        'Você não tem permissão para realizar esta ação.';
    
    if (showSnackbar) {
      _showErrorSnackbar(
        context, 
        errorMessage, 
        title: 'Acesso Negado',
      );
    }
  }

  /// Trata erros de recurso não encontrado (404)
  void handleNotFoundError(
    BuildContext context, {
    String? customMessage,
    bool showSnackbar = true,
  }) {
    final errorMessage = customMessage ?? 
        'O recurso solicitado não foi encontrado.';
    
    if (showSnackbar) {
      _showErrorSnackbar(
        context, 
        errorMessage, 
        title: 'Não Encontrado',
      );
    }
  }

  /// Converte erros técnicos em mensagens amigáveis
  String _getUserFriendlyMessage(dynamic error, String? customMessage) {
    if (customMessage != null) return customMessage;

    final errorString = error.toString().toLowerCase();

    // Erros de rede
    if (errorString.contains('socketexception') ||
        errorString.contains('timeoutexception') ||
        errorString.contains('connection refused') ||
        errorString.contains('network is unreachable')) {
      return 'Verifique sua conexão com a internet e tente novamente.';
    }

    // Erros de timeout
    if (errorString.contains('timeout')) {
      return 'A operação demorou muito para ser concluída. Tente novamente.';
    }

    // Erros de formato/parsing
    if (errorString.contains('format exception') ||
        errorString.contains('parsing error')) {
      return 'Erro ao processar os dados. Tente novamente.';
    }

    // Erros genéricos
    return 'Ocorreu um erro inesperado. Tente novamente.';
  }

  /// Converte erros de Dio em mensagens amigáveis
  String _getDioErrorMessage(DioException error, String? customMessage) {
    if (customMessage != null) return customMessage;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'A operação demorou muito para ser concluída. Verifique sua conexão e tente novamente.';

      case DioExceptionType.connectionError:
        return 'Não foi possível conectar ao servidor. Verifique sua conexão com a internet.';

      case DioExceptionType.badResponse:
        return _getHttpStatusMessage(error.response?.statusCode);

      case DioExceptionType.cancel:
        return 'A operação foi cancelada.';

      case DioExceptionType.unknown:
        return 'Ocorreu um erro inesperado. Tente novamente.';

      default:
        return 'Erro de conexão. Tente novamente.';
    }
  }

  /// Converte códigos de status HTTP em mensagens amigáveis
  String _getHttpStatusMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Dados inválidos. Verifique as informações e tente novamente.';
      case 401:
        return 'Sua sessão expirou. Faça login novamente.';
      case 403:
        return 'Você não tem permissão para realizar esta ação.';
      case 404:
        return 'O recurso solicitado não foi encontrado.';
      case 409:
        return 'Este item já existe. Verifique os dados e tente novamente.';
      case 422:
        return 'Dados inválidos. Verifique as informações e tente novamente.';
      case 429:
        return 'Muitas tentativas. Aguarde um momento e tente novamente.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'O servidor está temporariamente indisponível. Tente novamente em alguns minutos.';
      default:
        return 'Ocorreu um erro no servidor. Tente novamente.';
    }
  }

  /// Exibe snackbar de erro com opção de retry
  void _showErrorSnackbar(
    BuildContext context,
    String message, {
    String? title,
    VoidCallback? onRetry,
  }) {
    showError(
      context,
      message,
      title: title ?? 'Erro',
    );
  }

  /// Exibe diálogo de erro para casos críticos
  void showErrorDialog(
    BuildContext context,
    String message, {
    String? title,
    VoidCallback? onRetry,
    String? retryText,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? 'Erro'),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: Text(retryText ?? 'Tentar Novamente'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Método para logging de erros (para debug)
  void logError(dynamic error, {String? context}) {
    // Aqui você pode adicionar logging para serviços como Crashlytics, Sentry, etc.
  }
}
