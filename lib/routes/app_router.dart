import 'package:go_router/go_router.dart';
import 'package:servus_app/features/perfil/perfil_screen.dart';
import 'package:servus_app/features/volunteers/dashboard/escala/escala_detalhes/escala_detalhes.dart';
import 'package:servus_app/routes/auth_routes.dart';
import 'package:servus_app/routes/qr_routes.dart';
import 'package:servus_app/routes/invite_routes.dart';
import 'package:servus_app/routes/shells/leader_shell.dart';
import 'package:servus_app/routes/shells/volunteer_shell.dart';
import 'package:servus_app/routes/web_routes.dart';

// Router principal para a aplicação completa
final GoRouter mainRouter = GoRouter(
  initialLocation: WebRoutes.getInitialRoute(),
  routes: [
    ...authRoutes,
    ...qrRoutes,
    ...inviteRoutes,
    ...WebRoutes.routes,
    volunteerShellRoute,
    leaderShellRoute,
    GoRoute(
      path: '/escala_detalhe',
      builder: (context, state) => const EscalaDetalheScreen(),
    ),
    GoRoute(
      path: '/perfil',
      builder: (context, state) => const PerfilScreen(),
    ),
  ],
);

// Router simplificado para formulários públicos
final GoRouter publicFormRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ...WebRoutes.routes,
  ],
);

// Manter compatibilidade com código existente
final GoRouter router = mainRouter;
