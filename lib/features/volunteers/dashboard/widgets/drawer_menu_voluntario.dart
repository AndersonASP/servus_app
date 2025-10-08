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

            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    context.colors.outline.withValues(alpha: 0.1),
                    context.colors.outline.withValues(alpha: 0.2),
                    context.colors.outline.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                ),
              ),
            ),

            // Menu simplificado
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // 📊 Dashboard detalhado
                    ListTile(
                      leading: const Icon(Icons.dashboard_outlined),
                      title: const Text('Dashboard'),
                      subtitle: const Text('Visão geral detalhada'),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Implementar navegação para dashboard detalhado
                      },
                    ),

                    // 🎯 Eventos
                    ListTile(
                      leading: const Icon(Icons.event_outlined),
                      title: const Text('Eventos'),
                      subtitle: const Text('Calendário de eventos'),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Implementar navegação para eventos
                      },
                    ),

                    // 📋 Formulários (condicional)
                    if (modoAtual != 'Voluntário' && 
                        (usuario?.role == UserRole.tenant_admin || 
                         usuario?.role == UserRole.branch_admin))
                      ListTile(
                        leading: const Icon(Icons.assignment_outlined),
                        title: const Text('Formulários'),
                        subtitle: const Text('Preencher formulários'),
                        onTap: () {
                          Navigator.pop(context);
                          // TODO: Implementar navegação para formulários
                        },
                      ),

                    // ⚙️ Configurações
                    ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: const Text('Configurações'),
                      subtitle: const Text('Preferências do app'),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Implementar navegação para configurações
                      },
                    ),

                    // 🏢 Administração (apenas para servus_admin)
                    if (usuario?.role == UserRole.servus_admin)
                      ListTile(
                        leading: const Icon(Icons.business_outlined),
                        title: const Text('Nova Igreja'),
                        subtitle: const Text('Criar nova organização'),
                        onTap: () {
                          Navigator.pop(context);
                          // TODO: Implementar navegação para criar tenant
                        },
                      ),

                    // 👥 Gestão de Pessoas (apenas quando não está como voluntário)
                    if (modoAtual != 'Voluntário' && 
                        (usuario?.role == UserRole.tenant_admin || 
                         usuario?.role == UserRole.branch_admin || 
                         usuario?.role == UserRole.leader)) ...[
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.groups_outlined),
                        title: const Text('Ministérios'),
                        subtitle: const Text('Gerenciar ministérios'),
                        onTap: () {
                          Navigator.pop(context);
                          // TODO: Implementar navegação para ministérios
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.group_add_outlined),
                        title: const Text('Membros'),
                        subtitle: const Text('Gerenciar membros'),
                        onTap: () {
                          Navigator.pop(context);
                          // TODO: Implementar navegação para membros
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.people_outlined),
                        title: const Text('Voluntários'),
                        subtitle: const Text('Gerenciar voluntários'),
                        onTap: () {
                          Navigator.pop(context);
                          // TODO: Implementar navegação para voluntários
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const Spacer(),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    context.colors.outline.withValues(alpha: 0.1),
                    context.colors.outline.withValues(alpha: 0.2),
                    context.colors.outline.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                ),
              ),
            ),
            if (usuario?.role == UserRole.tenant_admin || usuario?.role == UserRole.leader || usuario?.role == UserRole.servus_admin)
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