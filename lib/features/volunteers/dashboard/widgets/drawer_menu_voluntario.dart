import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/enums/user_role.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/shared/widgets/drawer_profile_header.dart';
import 'package:servus_app/state/auth_state.dart';

class DrawerMenuVoluntario extends StatelessWidget {
  final String nome;
  final String email;
  final VoidCallback onTapPerfil;
  final bool exibirTrocaModo;
  final String modoAtual;
  final VoidCallback onTrocarModo;

  const DrawerMenuVoluntario({
    super.key,
    required this.nome,
    required this.email,
    required this.onTapPerfil,
    this.exibirTrocaModo = false,
    this.modoAtual = 'Voluntário',
    required this.onTrocarModo,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthState>(context, listen: false);
    final usuario = auth.usuario;
    return Drawer(
      backgroundColor: context.colors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho do perfil com troca de modo
            DrawerProfileHeader(
                nome: nome,
                email: email,
                picture: usuario?.picture ?? '',
                onTapPerfil: onTapPerfil,
                exibirTrocaModo: exibirTrocaModo,
                modoAtual: modoAtual),

            Divider(
              height: 10,
              thickness: 0.6,
              color: context.colors.onSurface.withValues(alpha: 0.2),
            ),

            // Menu
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [],
              ),
            ),

            const Spacer(),
            Divider(
              height: 10,
              thickness: 0.6,
              color: context.colors.onSurface.withValues(alpha: 0.2),
            ),
            if (usuario!.role == UserRole.tenant_admin || usuario.role == UserRole.leader || usuario.role == UserRole.servus_admin)
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Trocar para admin'),
                onTap: onTrocarModo,
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
