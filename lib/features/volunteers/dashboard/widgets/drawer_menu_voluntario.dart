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

            // Menu
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // 🏠 PRINCIPAL
                    Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        leading: const Icon(Icons.home_outlined),
                        title: const Text('Principal'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: ListTile(
                              leading: const Icon(Icons.dashboard_outlined),
                              title: const Text('Dashboard'),
                              subtitle: const Text('Visão geral'),
                              onTap: () {
                                Navigator.pop(context);
                                // TODO: Implementar navegação para dashboard do voluntário
                              },
                            ),
                          ),
                          // Ministérios (visível apenas quando NÃO está visualizando como voluntário)
                          if (modoAtual != 'Voluntário' && 
                              (usuario!.role == UserRole.tenant_admin || 
                               usuario.role == UserRole.branch_admin || 
                               usuario.role == UserRole.leader))
                            Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: ListTile(
                                leading: const Icon(Icons.groups_outlined),
                                title: const Text('Ministérios'),
                                subtitle: const Text('Gerenciar ministérios'),
                                onTap: () {
                                  Navigator.pop(context);
                                  // TODO: Implementar navegação para ministérios
                                },
                              ),
                            ),
                        ],
                      ),
                    ),

                    // 👥 PESSOAS
                    Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        leading: const Icon(Icons.people_outlined),
                        title: const Text('Pessoas'),
                        children: [
                          // Membros (visível apenas quando NÃO está visualizando como voluntário)
                          if (modoAtual != 'Voluntário' && 
                              (usuario!.role == UserRole.tenant_admin || 
                               usuario.role == UserRole.branch_admin || 
                               usuario.role == UserRole.leader))
                            Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: ListTile(
                                leading: const Icon(Icons.group_add_outlined),
                                title: const Text('Membros'),
                                subtitle: const Text('Gerenciar membros'),
                                onTap: () {
                                  Navigator.pop(context);
                                  // TODO: Implementar navegação para tela de membros
                                },
                              ),
                            ),
                          // Voluntários (visível apenas quando NÃO está visualizando como voluntário)
                          if (modoAtual != 'Voluntário' && 
                              (usuario!.role == UserRole.tenant_admin || 
                               usuario.role == UserRole.branch_admin || 
                               usuario.role == UserRole.leader))
                            Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: ListTile(
                                leading: const Icon(Icons.people_outlined),
                                title: const Text('Voluntários'),
                                subtitle: const Text('Gerenciar voluntários'),
                                onTap: () {
                                  Navigator.pop(context);
                                  // TODO: Implementar navegação para voluntários
                                },
                              ),
                            ),
                        ],
                      ),
                    ),

                    // 📋 GERENCIAR
                    Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        leading: const Icon(Icons.description_outlined),
                        title: const Text('Gerenciar'),
                        children: [
                          // 1. MINHAS ESCALAS - Mais importante para voluntário
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: ListTile(
                              leading: const Icon(Icons.schedule_outlined),
                              title: const Text('Minhas Escalas'),
                              subtitle: const Text('Ver escalas atribuídas'),
                              onTap: () {
                                Navigator.pop(context);
                                // TODO: Implementar navegação para escalas do voluntário
                              },
                            ),
                          ),
                          // 2. EVENTOS - Depende de escalas
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: ListTile(
                              leading: const Icon(Icons.event_outlined),
                              title: const Text('Eventos'),
                              subtitle: const Text('Ver eventos próximos'),
                              onTap: () {
                                Navigator.pop(context);
                                // TODO: Implementar navegação para eventos do voluntário
                              },
                            ),
                          ),
                          // 3. FORMULÁRIOS - Independente (visível apenas quando NÃO está visualizando como voluntário)
                          if (modoAtual != 'Voluntário' && 
                              (usuario!.role == UserRole.tenant_admin || 
                               usuario.role == UserRole.branch_admin))
                            Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: ListTile(
                                leading: const Icon(Icons.assignment_outlined),
                                title: const Text('Formulários'),
                                subtitle: const Text('Criar e gerenciar'),
                                onTap: () {
                                  Navigator.pop(context);
                                  // TODO: Implementar navegação para formulários
                                },
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ⚙️ ADMINISTRAÇÃO (só aparece se tiver conteúdo)
                    if (usuario!.role == UserRole.servus_admin)
                      Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          leading: const Icon(Icons.settings_outlined),
                          title: const Text('Administração'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: ListTile(
                                leading: const Icon(Icons.business_outlined),
                                title: const Text('Nova igreja'),
                                subtitle: const Text('Nova organização'),
                                onTap: () {
                                  Navigator.pop(context);
                                  // TODO: Implementar navegação para criar tenant
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

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
            if (usuario.role == UserRole.tenant_admin || usuario.role == UserRole.leader || usuario.role == UserRole.servus_admin)
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