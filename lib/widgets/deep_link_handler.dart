import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:servus_app/services/deep_link_service.dart';

class DeepLinkHandler extends StatefulWidget {
  final Widget child;

  const DeepLinkHandler({
    super.key,
    required this.child,
  });

  @override
  State<DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<DeepLinkHandler> with WidgetsBindingObserver {
  final DeepLinkService _deepLinkService = DeepLinkService();
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initDeepLinks() async {
    try {
      
      // Verificar deep link inicial
      try {
        final Uri? initialLink = await _appLinks.getInitialLink();
        if (initialLink != null) {
          _handleIncomingLink(initialLink.toString());
        } else {
        }
      } catch (e) {
      }

      // Escutar deep links em tempo real
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) {
          _handleIncomingLink(uri.toString());
        },
        onError: (err) {
        },
      );
      
    } catch (e) {
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Quando o app volta do background, verificar se há deep links pendentes
    if (state == AppLifecycleState.resumed) {
      _checkPendingDeepLinks();
    }
  }

  void _checkPendingDeepLinks() async {
    try {
      // Verificar se há deep link inicial quando o app volta do background
      final Uri? initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleIncomingLink(initialLink.toString());
      } else {
      }
    } catch (e) {
    }
  }

  /// Processa um deep link recebido
  Future<void> _handleIncomingLink(String link) async {
    
    if (!mounted) {
      return;
    }

    // Aguardar um pouco para garantir que o contexto esteja pronto
    await Future.delayed(const Duration(milliseconds: 1000));

    try {
      final uri = Uri.parse(link);
      
      // Verificar se é um link de convite
      if (link.contains('invite')) {
        
        if (uri.scheme == 'servusapp') {
          await _deepLinkService.handleInviteLink(link, context);
        } else if (uri.scheme == 'https' && uri.host == 'servusapp.netlify.app') {
          await _deepLinkService.handleHttpInviteLink(link, context);
        } else {
        }
      } else {
      }
    } catch (e) {
    }
  }

  /// Processa um deep link recebido (método público para compatibilidade)
  Future<void> handleDeepLink(String link) async {
    await _handleIncomingLink(link);
  }

  /// Processa um link HTTP recebido (método público para compatibilidade)
  Future<void> handleHttpLink(String link) async {
    await _handleIncomingLink(link);
  }



  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
