import 'package:go_router/go_router.dart';
import 'package:servus_app/features/login/login_screen.dart';
import 'package:servus_app/features/splash/welcome_screen.dart';

import '../features/splash/splash_screen.dart';
// import outros arquivos de tela aqui

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
  ],
);
