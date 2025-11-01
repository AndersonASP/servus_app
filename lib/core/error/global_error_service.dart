import 'package:flutter/material.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';

/// Serviço global para mostrar erros do backend
class GlobalErrorService {
  static final GlobalErrorService _instance = GlobalErrorService._internal();
  factory GlobalErrorService() => _instance;
  GlobalErrorService._internal();

  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Inicializa o serviço com a chave do navigator
  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  /// Mostra erro do servidor no ServusSnackbar
  void showServerError(String message, int? statusCode) {
    // Tentar obter contexto de diferentes formas
    BuildContext? context = _navigatorKey?.currentContext;
    
    // Se não conseguir pelo navigatorKey, tentar pelo WidgetsBinding
    if (context == null) {
      try {
        context = WidgetsBinding.instance.rootElement;
      } catch (e) {
        debugPrint('❌ [GlobalErrorService] Não foi possível obter contexto: $e');
      }
    }
    
    if (context != null) {
      try {
        // Verificar se o contexto tem Overlay disponível
        Overlay.of(context);
        
        // Limpar a mensagem - remover informações técnicas desnecessárias
        String cleanMessage = _cleanServerMessage(message);
        
        // Determinar o tipo de erro baseado no status code
        if (statusCode == 403) {
          showError(context, cleanMessage, title: 'Acesso Negado');
        } else if (statusCode == 401) {
          showError(context, cleanMessage, title: 'Sessão Expirada');
        } else if (statusCode == 404) {
          showError(context, cleanMessage, title: 'Não Encontrado');
        } else if (statusCode == 400 || statusCode == 422) {
          showWarning(context, cleanMessage, title: 'Dados Inválidos');
        } else if (statusCode != null && statusCode >= 500) {
          showError(context, cleanMessage, title: 'Erro do Servidor');
        } else {
          showError(context, cleanMessage, title: 'Erro');
        }
      } catch (e) {
        // Se não conseguir mostrar o snackbar, pelo menos logar o erro
        debugPrint('❌ [GlobalErrorService] Erro ao mostrar snackbar: $e');
        debugPrint('❌ [GlobalErrorService] Mensagem do servidor: $message');
      }
    } else {
      // Fallback: apenas logar o erro se não conseguir mostrar snackbar
      debugPrint('❌ [GlobalErrorService] Contexto não disponível para mostrar snackbar');
      debugPrint('❌ [GlobalErrorService] Mensagem: $message (Status: $statusCode)');
    }
  }

  /// Limpa a mensagem do servidor removendo informações técnicas desnecessárias
  String _cleanServerMessage(String message) {
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
      // Geralmente está no início da string antes das informações técnicas
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
}
