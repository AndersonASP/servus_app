import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:servus_app/features/forms/screens/public_form_web_screen.dart';

class WebRoutes {
  static bool get isWeb => kIsWeb;

  static List<RouteBase> get routes {
    if (!isWeb) return [];

    return [
      // Rota para formulários públicos na web
      GoRoute(
        path: '/forms/public/:formId',
        builder: (context, state) {
          final formId = state.pathParameters['formId']!;
          return PublicFormWebScreen(formId: formId);
        },
      ),
    ];
  }

  /// Verifica se a URL atual é um formulário público
  static bool isPublicFormUrl(String url) {
    return url.contains('/forms/public/');
  }

  /// Extrai o ID do formulário da URL
  static String? extractFormIdFromUrl(String url) {
    final regex = RegExp(r'/forms/public/([a-f0-9]{24})');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  /// Detecta automaticamente a rota inicial baseada na URL atual
  static String getInitialRoute() {
    if (!isWeb) return '/';
    
    // No Flutter Web, podemos usar a URL atual
    final currentUrl = Uri.base.path;
    
    // Se estamos em uma página de formulário público, usar essa rota
    if (isPublicFormUrl(currentUrl)) {
      return currentUrl;
    }
    
    return '/';
  }
}
