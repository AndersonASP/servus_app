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

            // Menu simplificado e organizado
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // 🏠 PRINCIPAL
                    _buildMenuSection(
                      context,
                      title: 'Principal',
                      icon: Icons.home_outlined,
                      children: [
                        _buildMenuItem(
                          context,
                          icon: Icons.dashboard_outlined,
                          title: 'Dashboard',
                          subtitle: 'Visão geral detalhada',
                          onTap: () {
                            Navigator.pop(context);
                            // TODO: Implementar navegação para dashboard detalhado
                          },
                        ),
                        _buildMenuItem(
                          context,
                          icon: Icons.event_outlined,
                          title: 'Eventos',
                          subtitle: 'Calendário de eventos',
                          onTap: () {
                            Navigator.pop(context);
                            // TODO: Implementar navegação para eventos
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // 📋 FORMULÁRIOS (condicional)
                    if (modoAtual != 'Voluntário' && 
                        (usuario?.role == UserRole.tenant_admin || 
                         usuario?.role == UserRole.branch_admin))
                      _buildMenuSection(
                        context,
                        title: 'Ferramentas',
                        icon: Icons.build_outlined,
                        children: [
                          _buildMenuItem(
                            context,
                            icon: Icons.assignment_outlined,
                            title: 'Formulários',
                            subtitle: 'Preencher formulários',
                            onTap: () {
                              Navigator.pop(context);
                              // TODO: Implementar navegação para formulários
                            },
                          ),
                        ],
                      ),

                    // 👥 GESTÃO DE PESSOAS (apenas quando não está como voluntário)
                    if (modoAtual != 'Voluntário' && 
                        (usuario?.role == UserRole.tenant_admin || 
                         usuario?.role == UserRole.branch_admin || 
                         usuario?.role == UserRole.leader))
                      _buildMenuSection(
                        context,
                        title: 'Pessoas',
                        icon: Icons.people_outlined,
                        children: [
                          _buildMenuItem(
                            context,
                            icon: Icons.groups_outlined,
                            title: 'Ministérios',
                            subtitle: 'Gerenciar ministérios',
                            onTap: () {
                              Navigator.pop(context);
                              // TODO: Implementar navegação para ministérios
                            },
                          ),
                          _buildMenuItem(
                            context,
                            icon: Icons.group_add_outlined,
                            title: 'Membros',
                            subtitle: 'Gerenciar membros',
                            onTap: () {
                              Navigator.pop(context);
                              // TODO: Implementar navegação para membros
                            },
                          ),
                          _buildMenuItem(
                            context,
                            icon: Icons.people_outlined,
                            title: 'Voluntários',
                            subtitle: 'Gerenciar voluntários',
                            onTap: () {
                              Navigator.pop(context);
                              // TODO: Implementar navegação para voluntários
                            },
                          ),
                        ],
                      ),

                    const SizedBox(height: 8),

                    // 🏢 ADMINISTRAÇÃO (apenas para servus_admin)
                    if (usuario?.role == UserRole.servus_admin)
                      _buildMenuSection(
                        context,
                        title: 'Administração',
                        icon: Icons.business_outlined,
                        children: [
                          _buildMenuItem(
                            context,
                            icon: Icons.business_outlined,
                            title: 'Nova Igreja',
                            subtitle: 'Criar nova organização',
                            onTap: () {
                              Navigator.pop(context);
                              // TODO: Implementar navegação para criar tenant
                            },
                          ),
                        ],
                      ),

                    const SizedBox(height: 8),

                    // ⚙️ CONFIGURAÇÕES
                    _buildMenuItem(
                      context,
                      icon: Icons.settings_outlined,
                      title: 'Configurações',
                      subtitle: 'Preferências do app',
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Implementar navegação para configurações
                      },
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

  Widget _buildMenuSection(BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: context.colors.primary),
        title: Text(
          title,
          style: context.textStyles.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.primary,
          ),
        ),
        children: children,
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        childrenPadding: const EdgeInsets.only(bottom: 8),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8),
      child: ListTile(
        leading: Icon(icon, size: 20),
        title: Text(title),
        subtitle: Text(subtitle),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: onTap,
      ),
    );
  }

}