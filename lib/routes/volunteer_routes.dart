import 'package:go_router/go_router.dart';
import 'package:servus_app/core/navigation/custom_transitions.dart';
import 'package:servus_app/features/volunteers/dashboard/dashboard_screen.dart';
import 'package:servus_app/features/volunteers/dashboard/escala/escala_detalhes/escala_detalhes.dart';
import 'package:servus_app/features/volunteers/indisponibilidade/bloqueios/screens/bloqueio_screen.dart';
import 'package:servus_app/features/volunteers/indisponibilidade/indisponibilidade_screen.dart';

final List<GoRoute> volunteerRoutes = [
  GoRoute(
    path: '/volunteer/dashboard',
    pageBuilder: (context, state) => CustomTransitions.dashboard(
      context,
      state,
      const DashboardScreen(),
    ),
  ),
  GoRoute(
    path: '/volunteer/escalas',
    pageBuilder: (context, state) => CustomTransitions.scale(
      context,
      state,
      const EscalaDetalheScreen(),
    ),
  ),
  GoRoute(
    path: '/volunteer/indisponibilidade',
    pageBuilder: (context, state) => CustomTransitions.slideLeft(
      context,
      state,
      const IndisponibilidadeScreen(),
    ),
  ),
  GoRoute(
    path: '/volunteer/indisponibilidade/bloquear',
    pageBuilder: (context, state) {
      final args = state.extra as Map<String, dynamic>;
      return CustomTransitions.slideUp(
        context,
        state,
        BloqueioScreen(
          onConfirmar: args['onConfirmar'],
          motivoInicial: args['motivoInicial'],
          ministeriosDisponiveis: args['ministeriosDisponiveis'],
        ),
      );
    },
  ),
  // Manter rota antiga para compatibilidade
  GoRoute(
    path: '/volunteer/detalhes-escalas',
    pageBuilder: (context, state) => CustomTransitions.scale(
      context,
      state,
      const EscalaDetalheScreen(),
    ),
  ),
];
