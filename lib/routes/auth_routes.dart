import 'package:go_router/go_router.dart';
import 'package:servus_app/core/auth/screens/choose_mode/choose_mode_screen.dart';
import 'package:servus_app/core/auth/screens/splash_screen.dart';
import '../core/auth/screens/welcome_screen.dart';
import '../core/auth/screens/login/login_screen.dart';

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