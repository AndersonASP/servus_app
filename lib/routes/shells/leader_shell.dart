import 'package:go_router/go_router.dart';
import 'package:servus_app/core/layout/app_leader_shell.dart';
import 'package:servus_app/routes/leader_routes.dart';

final ShellRoute leaderShellRoute = ShellRoute(
  builder: (context, state, child) => AppLeaderShell(child: child),
  routes: leaderRoutes,
);