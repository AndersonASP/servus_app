import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/enums/user_role.dart';
import 'package:servus_app/core/models/ministerio.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/state/auth_state.dart';
import 'package:servus_app/shared/widgets/drawer_profile_header.dart';

class DrawerMenuLider extends StatelessWidget {
  final Ministerio? ministerioSelecionado;
  final VoidCallback onTrocarModo;

  const DrawerMenuLider({
    super.key,
    required this.ministerioSelecionado,
    required this.onTrocarModo,
  });

  @override
  Widget build(BuildContext context) {
    final usuario = context.read<AuthState>().usuario!;

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DrawerProfileHeader(
              nome: usuario.nome,
              email: usuario.email,
              picture: usuario.picture ?? '',
              onTapPerfil: () => context.push('/perfil'),
              exibirTrocaModo: true,
              modoAtual: 'Líder',
            ),
            Divider(
              height: 10,
              thickness: 0.6,
              color: context.colors.onSurface.withValues(alpha: 0.2),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Ministério atual:',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                ministerioSelecionado?.nome ?? 'Carregando...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colors.primary,
                    ),
              ),
            ),

            const Spacer(),

            Divider(
              height: 10,
              thickness: 0.6,
              color: context.colors.onSurface.withValues(alpha: 0.2),
            ),
            if (usuario.role == UserRole.admin || usuario.role == UserRole.leader)
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Trocar para voluntário'),
                onTap: onTrocarModo,
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}