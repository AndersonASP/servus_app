import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppLeaderShell extends StatelessWidget {
  final Widget child;

  const AppLeaderShell({super.key, required this.child});

  bool _isProfile(String location) {
    return location.startsWith('/perfil');
  }

  bool _isEventForm(String location) {
    return location.contains('/leader/escalas') && location.contains('evento');
  }

  int _getCurrentIndex(String location) {
    if (location.startsWith('/leader/escalas')) return 1;
    if (location.startsWith('/leader/eventos')) return 2;
    if (location.startsWith('/leader/templates')) return 3;
    if (_isProfile(location)) return 4;
    return 0; // Dashboard é o padrão
  }

  void _onTabSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/leader/dashboard');
        break;
      case 1:
        context.push('/leader/escalas');
        break;
      case 2:
        context.go('/leader/eventos');
        break;
      case 3:
        context.go('/leader/templates');
        break;
      case 4:
        context.push('/perfil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final isEventForm = _isEventForm(location);
    final currentIndex = _getCurrentIndex(location);
    final hasPushedRoute = Navigator.of(context).canPop();

    return Scaffold(
      body: SafeArea(child: child),
      // Bottom navigation bar completo
      bottomNavigationBar: (hasPushedRoute || isEventForm) ? null : Container(
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
          enableFeedback: true,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          onTap: (index) => _onTabSelected(context, index),
          items: [
            BottomNavigationBarItem(
              backgroundColor: Theme.of(context).colorScheme.surface,
              icon: AnimatedScale(
                scale: currentIndex == 0 ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.dashboard_outlined),
              ),
              activeIcon: const Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              backgroundColor: Theme.of(context).colorScheme.surface,
              icon: AnimatedScale(
                scale: currentIndex == 1 ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.schedule_outlined),
              ),
              activeIcon: const Icon(Icons.schedule),
              label: 'Escalas',
            ),
            BottomNavigationBarItem(
              backgroundColor: Theme.of(context).colorScheme.surface,
              icon: AnimatedScale(
                scale: currentIndex == 2 ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.event_outlined),
              ),
              activeIcon: const Icon(Icons.event),
              label: 'Eventos',
            ),
            BottomNavigationBarItem(
              backgroundColor: Theme.of(context).colorScheme.surface,
              icon: AnimatedScale(
                scale: currentIndex == 3 ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.copy_outlined),
              ),
              activeIcon: const Icon(Icons.copy),
              label: 'Templates',
            ),
            BottomNavigationBarItem(
              backgroundColor: Theme.of(context).colorScheme.surface,
              icon: AnimatedScale(
                scale: currentIndex == 4 ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.person_outline),
              ),
              activeIcon: const Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
