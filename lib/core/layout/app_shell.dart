import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _getCurrentIndex(String location) {
    if (location.startsWith('/volunteer/dashboard')) return 0;
    if (location.startsWith('/volunteer/indisponibilidade')) return 1;
    if (location.startsWith('/perfil')) return 2;
    return 0; // Default para Home
  }

  void _onTabSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/volunteer/dashboard');
        break;
      case 1:
        context.push('/volunteer/indisponibilidade');
        break;
      case 2:
        context.push('/perfil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _getCurrentIndex(location);

    return Scaffold(
      body: child,
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed, // mais controle visual
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
          enableFeedback: true,
          items: [
            BottomNavigationBarItem(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              icon: AnimatedScale(
                scale: currentIndex == 0 ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.dashboard_outlined),
              ),
              activeIcon: const Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              icon: AnimatedScale(
                scale: currentIndex == 1 ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.event_busy_outlined),
              ),
              activeIcon: const Icon(Icons.event_busy),
              label: 'Indisponibilidade',
            ),
            BottomNavigationBarItem(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              icon: AnimatedScale(
                scale: currentIndex == 2 ? 1.1 : 1.0,
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