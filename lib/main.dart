import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/app_theme.dart';
import 'package:servus_app/features/login/login_controller.dart';
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
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Servus',
            theme: ServusTheme.light,
            darkTheme: ServusTheme.light,
            themeMode: ThemeMode.system,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
