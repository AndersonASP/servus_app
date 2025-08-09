import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/auth/controllers/choose_mode_controller.dart';
import 'package:servus_app/core/enums/user_role.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/state/auth_state.dart';

class ChooseModeScreen extends StatefulWidget {
  const ChooseModeScreen({super.key});

  @override
  State<ChooseModeScreen> createState() => _ChooseModeScreenState();
}

class _ChooseModeScreenState extends State<ChooseModeScreen> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildAnimatedCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: 130,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              color: context.colors.primary,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Icon(icon, size: 48, color: context.colors.onPrimary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                    color: context.colors.onPrimary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              subtitle,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: context.colors.onPrimary,
                                    fontSize: 14,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.arrow_forward_ios, color: context.colors.onPrimary, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthState>(context);
    final usuario = auth.usuario;

    if (usuario == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const SizedBox.shrink();
    }

    final controller = ChooseModeController(auth: auth);

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: Align(
        alignment: const Alignment(0, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Escolha como deseja acessar',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 25,
                    color: context.colors.onSurface,
                  ),
            ),
            const SizedBox(height: 32),
            if (controller.isAdmin || controller.isLider)
              buildAnimatedCard(
                title: controller.isAdmin ? 'Admin' : 'Líder',
                subtitle: controller.isAdmin
                    ? 'Acesse todos os ministérios e usuários'
                    : 'Gerencie sua equipe de voluntários',
                icon: Icons.admin_panel_settings,
                onTap: () => controller.selecionarPapel(
                  context,
                  controller.isAdmin ? UserRole.admin : UserRole.leader,
                ),
              ),
            if (controller.isVoluntario)
              buildAnimatedCard(
                title: 'Voluntário',
                subtitle: 'Veja suas escalas e faça check-in',
                icon: Icons.volunteer_activism,
                onTap: () => controller.selecionarPapel(context, UserRole.volunteer),
              ),
          ],
        ),
      ),
    );
  }
}