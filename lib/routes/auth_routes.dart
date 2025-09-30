import 'package:go_router/go_router.dart';
import 'package:servus_app/core/auth/screens/choose_mode/choose_mode_screen.dart';
import 'package:servus_app/core/auth/screens/splash_screen.dart';
import 'package:servus_app/core/navigation/custom_transitions.dart';
import '../core/auth/screens/welcome_screen.dart';
import '../core/auth/screens/login/login_screen.dart';

final List<GoRoute> authRoutes = [
  GoRoute(
    path: '/',
    pageBuilder: (context, state) => CustomTransitions.fade(
      context,
      state,
      const SplashScreen(),
    ),
  ),
  GoRoute(
    path: '/welcome',
    pageBuilder: (context, state) => CustomTransitions.fade(
      context,
      state,
      const WelcomeScreen(),
    ),
  ),
  GoRoute(
    path: '/login',
    pageBuilder: (context, state) => CustomTransitions.slideLeft(
      context,
      state,
      const LoginScreen(),
    ),
  ),
  GoRoute(
    path: '/choose-role',
    pageBuilder: (context, state) => CustomTransitions.scale(
      context,
      state,
      const ChooseModeScreen(),
    ),
  ),
];