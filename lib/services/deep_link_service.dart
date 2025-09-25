import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:servus_app/services/invite_code_service.dart';
import 'package:servus_app/core/error/error_handler_service.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final InviteCodeService _inviteCodeService = InviteCodeService();

  /// Processa um deep link de convite
  /// Formato: servusapp://invite?code=XXXX&ministry=NOME
  Future<void> handleInviteLink(String link, BuildContext context) async {
    try {
      
      // Extrair parâmetros da URL
      final uri = Uri.parse(link);
      
      if (uri.scheme != 'servusapp' || uri.host != 'invite') {
        return;
      }

      final code = uri.queryParameters['code'];
      final ministry = uri.queryParameters['ministry'];

      if (code == null || code.isEmpty) {
        ErrorHandlerService().showErrorDialog(
          context, 
          'O link de convite não contém um código válido. Verifique se o link está correto.',
          title: 'Link Inválido',
          retryText: 'Digitar Código',
          onRetry: () => context.go('/invite/code'),
        );
        return;
      }


      // Validar o código
      final validation = await _inviteCodeService.validateInviteCode(code);
      
      if (!validation.isValid) {
        _showErrorDialog(context, validation.message ?? 'Código de convite inválido');
        return;
      }


      // Navegar para tela de cadastro
      context.push('/invite/register', extra: {
        'code': code.toUpperCase(),
        'ministryName': validation.ministryName ?? ministry ?? 'Ministério',
        'ministryId': validation.ministryId!,
      });

    } catch (e) {
      ErrorHandlerService().logError(e, context: 'processamento de deep link');
      _showErrorDialog(context, 'Não foi possível processar o link de convite. Verifique se o link está correto.');
    }
  }

  /// Processa um link HTTP/HTTPS de convite
  /// Formato: https://servusapp.netlify.app/invite?code=XXXX&ministry=NOME
  Future<void> handleHttpInviteLink(String link, BuildContext context) async {
    try {
      
      final uri = Uri.parse(link);
      
      // Verificar se é um link de convite válido
      if (!uri.path.contains('/invite')) {
        return;
      }

      final code = uri.queryParameters['code'];
      final ministry = uri.queryParameters['ministry'];

      if (code == null || code.isEmpty) {
        _showErrorDialog(context, 'O link de convite não contém um código válido. Verifique se o link está correto.');
        return;
      }


      // Validar o código
      final validation = await _inviteCodeService.validateInviteCode(code);
      
      if (!validation.isValid) {
        _showErrorDialog(context, validation.message ?? 'Código de convite inválido');
        return;
      }


      // Navegar para tela de cadastro
      context.push('/invite/register', extra: {
        'code': code.toUpperCase(),
        'ministryName': validation.ministryName ?? ministry ?? 'Ministério',
        'ministryId': validation.ministryId!,
      });

    } catch (e) {
      ErrorHandlerService().logError(e, context: 'processamento de link HTTP');
      _showErrorDialog(context, 'Não foi possível processar o link de convite. Verifique se o link está correto.');
    }
  }

  /// Mostra um diálogo de erro
  void _showErrorDialog(BuildContext context, String message) {
    ErrorHandlerService().showErrorDialog(
      context, 
      message,
      title: 'Erro',
      retryText: 'Digitar Código',
      onRetry: () => context.go('/invite/code'),
    );
  }

  /// Gera um link de convite
  String generateInviteLink(String code, String ministryName) {
    // Link custom scheme para app instalado
    final customSchemeLink = 'servusapp://invite?code=$code&ministry=${Uri.encodeComponent(ministryName)}';
    
    return customSchemeLink;
  }

  /// Gera um link HTTP de convite (fallback)
  String generateHttpInviteLink(String code, String ministryName) {
    // Usando domínio gratuito temporário
    // TODO: Trocar por servusapp.com quando comprar o domínio
    return 'https://servusapp.netlify.app/invite?code=$code&ministry=${Uri.encodeComponent(ministryName)}';
  }
}
