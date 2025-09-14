import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/auth/controllers/login_controller.dart';
import 'package:servus_app/core/theme/app_theme.dart';
import 'package:servus_app/features/leader/dashboard/cards_details/escala_mensal/escala_mensal_controller.dart';
import 'package:servus_app/features/leader/escalas/controllers/escala/escala_controller.dart';
import 'package:servus_app/features/leader/escalas/controllers/evento/evento_controller.dart';
import 'package:servus_app/features/leader/escalas/controllers/template/template_controller.dart';
import 'package:servus_app/features/leader/ministerios/controllers/ministerio_controller.dart';
import 'package:servus_app/features/volunteers/indisponibilidade/bloqueios/controller/bloqueio_controller.dart';

import 'package:servus_app/features/volunteers/indisponibilidade/indisponibilidade_controller.dart';
import 'package:servus_app/features/perfil/perfil_controller.dart';
import 'package:servus_app/features/ministries/controllers/ministry_functions_controller.dart';
import 'package:servus_app/features/ministries/services/ministry_functions_service.dart';
import 'package:dio/dio.dart';
import 'package:servus_app/routes/app_router.dart';
import 'package:servus_app/state/app_state.dart';
import 'package:servus_app/state/auth_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authState = AuthState();
  await authState.carregarUsuarioDoLocalStorage();

  runApp(ServusApp(authState: authState));
}

class ServusApp extends StatelessWidget {
  final AuthState authState;

  const ServusApp({super.key, required this.authState});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider<AuthState>.value(
            value: authState), // ✅ usa o carregado
        ChangeNotifierProvider(create: (_) => LoginController()),
        ChangeNotifierProvider(create: (_) => IndisponibilidadeController()),
        ChangeNotifierProvider(create: (_) => PerfilController()),
        ChangeNotifierProvider(create: (_) => BloqueioController()),
        ChangeNotifierProvider(create: (_) => TemplateController()),
        ChangeNotifierProvider(create: (_) => EscalaController()),
        ChangeNotifierProvider(create: (_) => EscalaMensalController()),
        ChangeNotifierProvider(create: (_) => MinisterioController()),
        ChangeNotifierProvider(create: (_) => MinisterioController()),
        ChangeNotifierProvider(create: (_) => EventoController()),
        ChangeNotifierProvider(create: (_) => MinistryFunctionsController(MinistryFunctionsService())),

      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Servus',
        theme: ServusTheme.light,
        darkTheme: ServusTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: router,
        supportedLocales: const [
          Locale('pt', 'BR'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
