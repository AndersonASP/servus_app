import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/shared/widgets/more_options_sheet.dart';
// import 'package:servus_app/shared/widgets/more_options_sheet.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _getCurrentIndex(String location) {
    if (location.startsWith('/volunteer/indisponibilidade')) return 0;
    if (location.startsWith('/volunteer/dashboard')) return 1;
    if (location.startsWith('/perfil')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _getCurrentIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: context.colors.primary,
        unselectedItemColor: context.colors.onSurface.withOpacity(0.9),
        onTap: (index) {
          switch (index) {
            case 0:
              context.push('/volunteer/indisponibilidade');
              break;
            case 1:
              context.push('/volunteer/dashboard');
              break;
            case 2:
              MoreOptionsSheet.show(context);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.event_busy),
            label: 'Indisponibilidade',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'Mais',
          )
        ],
      ),
    );
  }
}