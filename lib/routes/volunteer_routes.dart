import 'package:go_router/go_router.dart';
import 'package:servus_app/features/volunteers/dashboard/dashboard_screen.dart';
import 'package:servus_app/features/volunteers/dashboard/escala/escala_detalhes/escala_detalhes.dart';
import 'package:servus_app/features/volunteers/indisponibilidade/bloqueios/screens/bloqueio_screen.dart';
import 'package:servus_app/features/volunteers/indisponibilidade/indisponibilidade_screen.dart';

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
    path: '/volunteer/indisponibilidade/bloquear',
    builder: (context, state) {
      final args = state.extra as Map<String, dynamic>;
      return BloqueioScreen(
        onConfirmar: args['onConfirmar'],
        motivoInicial: args['motivoInicial'],
        ministeriosDisponiveis: args['ministeriosDisponiveis'],
      );
    },
  ),
  GoRoute(
    path: '/volunteer/detalhes-escalas',
    builder: (context, state) => const EscalaDetalheScreen(),
  ),
];
