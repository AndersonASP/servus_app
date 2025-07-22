import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:servus_app/core/theme/color_scheme.dart';
import 'package:servus_app/core/theme/context_extension.dart';

class ChooseModeScreen extends StatelessWidget {
  const ChooseModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.primary,
      body: Align(
        alignment: const Alignment(0, -0.2), // Leve ajuste vertical
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Escolha seu modo',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 30,
                    color: context.colors.surface,
                  ),
            ),
            const SizedBox(height: 32),

            // Card: Modo Líder
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: 130,
              child: CardButton(
                title: 'Modo Líder',
                subtitle: 'Gerencie sua equipe de voluntários',
                icon: Icons.admin_panel_settings,
                onTap: () => context.go('/leader/dashboard'),
              ),
            ),

            const SizedBox(height: 20),

            // Card: Modo Voluntário
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: 130,
              child: CardButton(
                title: 'Modo Voluntário',
                subtitle: 'Veja suas escalas e faça check-in',
                icon: Icons.volunteer_activism,
                onTap: () => context.go('/volunteer/dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CardButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const CardButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Icon(icon, size: 48, color: context.colors.onSurface),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: context.colors.secondary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.colors.onSurface,
                            fontSize: 14,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.arrow_forward_ios, color: ServusColors.primaryDark),
            ],
          ),
        ),
      ),
    );
  }
}