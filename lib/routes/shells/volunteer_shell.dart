import 'package:go_router/go_router.dart';
import 'package:servus_app/core/layout/app_shell.dart';
import 'package:servus_app/routes/volunteer_routes.dart';

final ShellRoute volunteerShellRoute = ShellRoute(
  builder: (context, state, child) => AppShell(child: child),
  routes: volunteerRoutes
);