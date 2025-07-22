import 'package:go_router/go_router.dart';
import 'package:servus_app/features/volunteers/dashboard/dashboard_screen.dart';

final List<GoRoute> leaderRoutes = [
  GoRoute(
    path: '/dashboard',
    builder: (context, state) => const DashboardScreen(),
  ),
  GoRoute(
    path: '/voluntarios',
    builder: (context, state) => const DashboardScreen(),
  ),
  GoRoute(
    path: '/indisponibilidade',
    builder: (context, state) => const DashboardScreen(),
  ),
  GoRoute(
    path: '/perfil',
    builder: (context, state) => const DashboardScreen(),
  ),
];