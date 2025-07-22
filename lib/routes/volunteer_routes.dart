import 'package:go_router/go_router.dart';
import 'package:servus_app/features/volunteers/dashboard/dashboard_screen.dart';
import 'package:servus_app/features/volunteers/indisponibilidade/indisponibilidade_screen.dart';
import 'package:servus_app/features/perfil/perfil_sceen.dart';

final List<GoRoute> volunteerRoutes = [
  GoRoute(
    path: '/volunteer/dashboard',
    builder: (context, state) => const DashboardScreen(),
  ),
  GoRoute(
    path: '/volunteer/indisponibilidade',
    builder: (context, state) => const IndisponibilidadeScreen(),
  ),
  GoRoute(
    path: '/volunteer/perfil',
    builder: (context, state) => const PerfilScreen(),
  ),
];
