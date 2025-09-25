import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:servus_app/core/theme/context_extension.dart';

class AppLeaderShell extends StatelessWidget {
  final Widget child;

  const AppLeaderShell({super.key, required this.child});

  bool _isDashboard(String location) {
    return location == '/leader/dashboard';
  }

  bool _isSettings(String location) {
    return location.startsWith('/leader/configuracoes');
  }

  int _getCurrentIndex(String location) {
    if (_isSettings(location)) return 1;
    return 0; // Dashboard é o padrão
  }

  void _onHomePressed(BuildContext context) {
    context.go('/leader/dashboard');
  }

  void _onSettingsPressed(BuildContext context) {
    context.push('/leader/configuracoes');
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final isDashboard = _isDashboard(location);
    final currentIndex = _getCurrentIndex(location);

    return Scaffold(
        body: child,
        // SpeedDial apenas no dashboard
        floatingActionButton: isDashboard
            ? SpeedDial(
                icon: Icons.add,
                activeIcon: Icons.close,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                spacing: 12,
                spaceBetweenChildren: 8,
                overlayOpacity: 0.8,
                children: [
                  SpeedDialChild(
                    child: Icon(Icons.people, color: context.colors.onPrimary),
                    label: 'Criar Escala',
                    labelStyle: context.textStyles.bodyLarge?.copyWith(
                        color: context.colors.onPrimary,
                        fontWeight: FontWeight.w800),
                    labelBackgroundColor: context.colors.primary,
                    backgroundColor: context.colors.primary,
                    onTap: () => context.push('/leader/escalas'),
                  ),
                  SpeedDialChild(
                    child: Icon(Icons.list, color: context.colors.onPrimary),
                    label: 'Criar Template',
                    labelStyle: context.textStyles.bodyLarge?.copyWith(
                        color: context.colors.onPrimary,
                        fontWeight: FontWeight.w800),
                    labelBackgroundColor: context.colors.primary,
                    backgroundColor: context.colors.primary,
                    onTap: () => context.push('/leader/templates'),
                  ),
                  SpeedDialChild(
                    child:
                        Icon(Icons.person_add, color: context.colors.onPrimary),
                    label: 'Novo Voluntário',
                    labelStyle: context.textStyles.bodyLarge?.copyWith(
                        color: context.colors.onPrimary,
                        fontWeight: FontWeight.w800),
                    labelBackgroundColor: context.colors.primary,
                    backgroundColor: context.colors.primary,
                    onTap: () => context.push('/leader/voluntarios'),
                  ),
                ],
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        // Bottom navigation bar com Home e Configurações
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: BottomNavigationBar(
            elevation: 0,
            currentIndex: currentIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: Theme.of(context).colorScheme.onSurface,
            unselectedItemColor:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            onTap: (index) {
              if (index == 0) {
                _onHomePressed(context);
              } else if (index == 1) {
                _onSettingsPressed(context);
              }
            },
            items: [
              BottomNavigationBarItem(
                backgroundColor: Theme.of(context).colorScheme.surface,
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                backgroundColor: Theme.of(context).colorScheme.surface,
                icon: Icon(Icons.settings),
                label: 'Configurações',
              ),
            ],
          ),
        ));
  }
}
