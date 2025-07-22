import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/app_theme.dart';
import 'package:servus_app/features/volunteers/indisponibilidade/indisponibilidade_controller.dart';
import 'package:servus_app/core/auth/login/login_controller.dart';
import 'package:servus_app/features/perfil/perfil_controller.dart';
import 'package:servus_app/routes/app_router.dart';
import 'package:servus_app/state/app_state.dart';

void main() {
  runApp(const ServusApp());
}

class ServusApp extends StatelessWidget {
  const ServusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => LoginController()),
        ChangeNotifierProvider(create: (_) => IndisponibilidadeController()),
        ChangeNotifierProvider(create: (_) => PerfilController()),
        ChangeNotifierProvider(create: (_) => PerfilController()..carregarImagemSalva()),
        ChangeNotifierProvider(
          create: (_) {
            final perfilController = PerfilController();
            perfilController.carregarImagemSalva(); // 👈 chamada aqui
            return perfilController;
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Servus',
            theme: ServusTheme.light,
            themeMode: ThemeMode.system,
            routerConfig: router,
            supportedLocales: const [
              Locale('pt', 'BR'), // ← aqui define o idioma padrão
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }
}