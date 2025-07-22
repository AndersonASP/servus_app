import 'package:go_router/go_router.dart';
import 'package:servus_app/core/auth/choose_mode_screen.dart';
import '../core/auth/splash/splash_screen.dart';
import '../core/auth/splash/welcome_screen.dart';
import '../core/auth/login/login_screen.dart';

final List<GoRoute> authRoutes = [
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
  GoRoute(
    path: '/choose-role',
    builder: (context, state) => const ChooseModeScreen(),
  ),
];