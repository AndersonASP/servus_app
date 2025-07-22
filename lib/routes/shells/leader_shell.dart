import 'package:go_router/go_router.dart';
import 'package:servus_app/routes/leader_routes.dart';
import '../../core/layout/app_shell.dart';

final ShellRoute leaderShellRoute = ShellRoute(
  builder: (context, state, child) => AppShell(child: child),
  routes: leaderRoutes,
);