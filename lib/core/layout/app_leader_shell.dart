import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/shared/widgets/more_options_sheet_leader.dart';

class AppLeaderShell extends StatelessWidget {
  final Widget child;

  const AppLeaderShell({super.key, required this.child});

  int _getCurrentIndex(String location) {
    if (location.startsWith('/leader/dashboard')) return 0;
    if (location.startsWith('/leader/perfil') ||
        location.startsWith('/leader/ministerio') ||
        location.startsWith('/leader/indisponibilidade')) {
      return 1;
    }
    return 0;
  }

  void _onTabSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/leader/dashboard');
        break;
      case 1:
        MoreOptionsSheetLeader.show(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _getCurrentIndex(location);

    return Scaffold(
      body: child,
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Theme.of(context).colorScheme.primary,
        
        foregroundColor: Colors.white,
        spacing: 12,
        spaceBetweenChildren: 8,
        overlayOpacity: 0.8,
        children: [
          SpeedDialChild(
            child: Icon(Icons.event, color: context.colors.onPrimary,),
            label: 'Criar Evento',
            labelStyle: context.textStyles.bodyLarge?.copyWith(
                color: context.colors.onPrimary, fontWeight: FontWeight.w800),
            labelBackgroundColor: context.colors.primary,
            backgroundColor: context.colors.primary,
            onTap: () => context.push('/leader/eventos'),
          ),
          SpeedDialChild(
            child: Icon(Icons.list, color: context.colors.onPrimary),
            label: 'Criar Template',
            labelStyle: context.textStyles.bodyLarge?.copyWith(
                color: context.colors.onPrimary, fontWeight: FontWeight.w800),
            labelBackgroundColor: context.colors.primary,
            backgroundColor: context.colors.primary,
            onTap: () => context.push('/leader/templates'),
          ),
          SpeedDialChild(
            child: Icon(Icons.people, color: context.colors.onPrimary),
            label: 'Criar Escala',
            labelStyle: context.textStyles.bodyLarge?.copyWith(
                color: context.colors.onPrimary, fontWeight: FontWeight.w800),
            labelBackgroundColor: context.colors.primary,
            backgroundColor: context.colors.primary,
            onTap: () => context.push('/leader/escalas'),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Theme.of(context).colorScheme.surface,
        elevation: 10,
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.onSurface,
          unselectedItemColor:
              Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          selectedLabelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          unselectedLabelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          onTap: (index) => _onTabSelected(context, index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz),
              label: 'Mais',
            ),
          ],
        ),
      ),
    );
  }
}
