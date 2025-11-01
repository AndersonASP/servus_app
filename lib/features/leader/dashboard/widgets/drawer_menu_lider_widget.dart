import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/enums/user_role.dart';
import 'package:servus_app/core/models/ministerio.dart';
import 'package:servus_app/core/models/usuario_logado.dart';
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
    final usuario = Provider.of<AuthState>(context, listen: false).usuario!;

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
              picture: usuario.picture?.isNotEmpty == true ? usuario.picture! : '',
              onTapPerfil: () => context.push('/perfil'),
              exibirTrocaModo: true,
              modoAtual: _labelDoPapel(usuario.role),
            ),
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

            const SizedBox(height: 16),

            // Menu de navegação - Simplificado e organizado
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // 🏠 PRINCIPAL - Acesso rápido
                    _buildMenuSection(
                      context,
                      title: 'Principal',
                      icon: Icons.home_outlined,
                      children: [
                        _buildMenuItem(
                          context,
                          icon: Icons.dashboard_outlined,
                          title: 'Dashboard',
                          subtitle: 'Visão geral',
                          onTap: () {
                            Navigator.pop(context);
                            context.go('/leader/dashboard');
                          },
                        ),
                        if (usuario.role != UserRole.servus_admin)
                          _buildMenuItem(
                            context,
                            icon: Icons.groups_outlined,
                            title: usuario.role == UserRole.leader ? 'Meu ministério' : 'Ministérios',
                            subtitle: usuario.role == UserRole.leader ? 'Ver detalhes' : 'Gerenciar',
                            onTap: () {
                              Navigator.pop(context);
                              if (usuario.role == UserRole.leader) {
                                if (usuario.primaryMinistryId != null) {
                                  context.push('/leader/ministerio-detalhes/${usuario.primaryMinistryId}');
                                } else {
                                  context.push('/leader/ministerio-detalhes/68d1b58da422169502e5e765');
                                }
                              } else {
                                context.push('/leader/ministerio/lista');
                              }
                            },
                          ),
                      ],
                    ),

                    // 👥 PESSOAS - Gestão de pessoas (apenas se tiver itens)
                    if (_hasPeopleItems(usuario)) ...[
                      const SizedBox(height: 8),
                      _buildMenuSection(
                        context,
                        title: 'Pessoas',
                        icon: Icons.people_outlined,
                        children: [
                          if (usuario.role == UserRole.tenant_admin || usuario.role == UserRole.branch_admin)
                            _buildMenuItem(
                              context,
                              icon: Icons.group_add_outlined,
                              title: 'Membros',
                              subtitle: 'Gerenciar membros',
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/leader/members');
                              },
                            ),
                          if (usuario.role == UserRole.leader || usuario.role == UserRole.tenant_admin || usuario.role == UserRole.branch_admin)
                            _buildMenuItem(
                              context,
                              icon: Icons.people_outlined,
                              title: 'Voluntários',
                              subtitle: 'Gerenciar voluntários',
                              onTap: () {
                                Navigator.pop(context);
                                context.go('/leader/dashboard/voluntarios');
                              },
                            ),
                        ],
                      ),
                    ],

                    // 📋 FERRAMENTAS - Funcionalidades administrativas (apenas se tiver itens)
                    if (_hasToolsItems(usuario)) ...[
                      const SizedBox(height: 8),
                      _buildMenuSection(
                        context,
                        title: 'Ferramentas',
                        icon: Icons.build_outlined,
                        children: [
                          if (usuario.role == UserRole.tenant_admin || usuario.role == UserRole.branch_admin)
                            _buildMenuItem(
                              context,
                              icon: Icons.assignment_outlined,
                              title: 'Formulários',
                              subtitle: 'Criar e gerenciar',
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/forms');
                              },
                            ),
                          if (usuario.role == UserRole.servus_admin)
                            _buildMenuItem(
                              context,
                              icon: Icons.business_outlined,
                              title: 'Nova igreja',
                              subtitle: 'Nova organização',
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/leader/tenants/create');
                              },
                            ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 8),

                    // ⚙️ CONFIGURAÇÕES
                    _buildMenuItem(
                      context,
                      icon: Icons.settings_outlined,
                      title: 'Configurações',
                      subtitle: 'Preferências do app',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/leader/configuracoes');
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Rodapé fixo
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
            if (usuario.role == UserRole.tenant_admin ||
                usuario.role == UserRole.branch_admin ||
                usuario.role == UserRole.leader)
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Trocar para voluntário'),
                onTap: onTrocarModo,
              ),
            const SizedBox(height: 16),
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
        leading: Icon(icon, color: context.colors.onSurface),
        title: Text(
          title,
          style: context.textStyles.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.onSurface,
          ),
        ),
        children: children,
        initiallyExpanded: false, // Colapsado por padrão
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        iconColor: context.colors.onSurface,
        collapsedIconColor: context.colors.onSurface.withValues(alpha: 0.6),
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

  String _labelDoPapel(UserRole role) {
    switch (role) {
      case UserRole.servus_admin:
        return 'Servus Admin';
      case UserRole.tenant_admin:
        return 'Admin da Igreja';
      case UserRole.branch_admin:
        return 'Admin da Filial';
      case UserRole.leader:
        return 'Líder';
      case UserRole.volunteer:
        return 'Voluntário';
    }
  }

  // Verifica se a seção "Pessoas" tem itens para o usuário
  bool _hasPeopleItems(UsuarioLogado usuario) {
    // Membros: apenas tenant_admin e branch_admin
    final hasMembers = usuario.role == UserRole.tenant_admin || usuario.role == UserRole.branch_admin;
    
    // Voluntários: leader, tenant_admin e branch_admin
    final hasVolunteers = usuario.role == UserRole.leader || 
                         usuario.role == UserRole.tenant_admin || 
                         usuario.role == UserRole.branch_admin;
    
    return hasMembers || hasVolunteers;
  }

  // Verifica se a seção "Ferramentas" tem itens para o usuário
  bool _hasToolsItems(UsuarioLogado usuario) {
    // Formulários: apenas tenant_admin e branch_admin
    final hasForms = usuario.role == UserRole.tenant_admin || usuario.role == UserRole.branch_admin;
    
    // Nova igreja: apenas servus_admin
    final hasNewChurch = usuario.role == UserRole.servus_admin;
    
    return hasForms || hasNewChurch;
  }

}
