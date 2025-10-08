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

            // Menu de navegação - Scrollável
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
                            onTap: () {
                              Navigator.pop(context);
                              context.go('/leader/dashboard');
                            },
                          ),
                        ),
                        // Ministérios (não visível para servus_admin)
                        if (usuario.role != UserRole.servus_admin)
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: ListTile(
                              leading: const Icon(Icons.groups_outlined),
                              title: Text(usuario.role == UserRole.leader ? 'Meu ministério' : 'Ministérios'),
                              subtitle: Text(usuario.role == UserRole.leader ? 'Ver detalhes do meu ministério' : 'Gerenciar ministérios'),
                              onTap: () {
                                Navigator.pop(context);
                                
                                print('🔍 [DrawerMenuLider] ===== CLIQUE EM MEU MINISTÉRIO =====');
                                print('🔍 [DrawerMenuLider] Usuário role: ${usuario.role}');
                                print('🔍 [DrawerMenuLider] PrimaryMinistryId: ${usuario.primaryMinistryId}');
                                print('🔍 [DrawerMenuLider] PrimaryMinistryName: ${usuario.primaryMinistryName}');
                                print('🔍 [DrawerMenuLider] Ministérios: ${usuario.ministerios}');
                                
                                if (usuario.role == UserRole.leader) {
                                  // Usar o ministério principal do usuário
                                  if (usuario.primaryMinistryId != null) {
                                    final ministryId = usuario.primaryMinistryId!;
                                    final route = '/leader/ministerio-detalhes/$ministryId';
                                    print('🔍 [DrawerMenuLider] Navegando para: $route');
                                    context.push(route);
                                  } else {
                                    // Fallback para ID fixo se não houver ministério principal
                                    const fallbackId = '68d1b58da422169502e5e765';
                                    const fallbackRoute = '/leader/ministerio-detalhes/$fallbackId';
                                    print('🔍 [DrawerMenuLider] PrimaryMinistryId nulo, usando fallback: $fallbackRoute');
                                    context.push(fallbackRoute);
                                  }
                                } else {
                                  print('🔍 [DrawerMenuLider] Não é líder, navegando para lista de ministérios');
                                  context.push('/leader/ministerio/lista');
                                }
                                
                                print('🔍 [DrawerMenuLider] ===== FIM DO CLIQUE =====');
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
                        // Membros (visível apenas para tenant_admin e branch_admin)
                        if (usuario.role == UserRole.tenant_admin ||
                            usuario.role == UserRole.branch_admin)
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: ListTile(
                              leading: const Icon(Icons.group_add_outlined),
                              title: const Text('Membros'),
                              subtitle: const Text('Gerenciar membros'),
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/leader/members');
                              },
                            ),
                          ),
                        // Voluntários (visível para leader, tenant_admin e branch_admin)
                        if (usuario.role == UserRole.leader ||
                            usuario.role == UserRole.tenant_admin ||
                            usuario.role == UserRole.branch_admin)
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: ListTile(
                              leading: const Icon(Icons.people_outlined),
                              title: const Text('Voluntários'),
                              subtitle: const Text('Gerenciar voluntários'),
                              onTap: () {
                                Navigator.pop(context);
                                context.go('/leader/dashboard/voluntarios');
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
                        // 1. ESCALAS - Mais importante (funcionalidade core)
                        if (usuario.role != UserRole.servus_admin)
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: ListTile(
                              leading: const Icon(Icons.schedule_outlined),
                              title: const Text('Escalas'),
                              subtitle: const Text('Gerenciar escalas'),
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/leader/escalas');
                              },
                            ),
                          ),
                        // 2. EVENTOS - Depende de escalas
                        if (usuario.role != UserRole.servus_admin)
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: ListTile(
                              leading: const Icon(Icons.event_outlined),
                              title: const Text('Eventos'),
                              subtitle: const Text('Gerenciar eventos'),
                              onTap: () {
                                Navigator.pop(context);
                                context.go('/leader/eventos');
                              },
                            ),
                          ),
                        // 3. TEMPLATES - Ferramenta para escalas
                        if (usuario.role != UserRole.servus_admin)
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: ListTile(
                              leading: const Icon(Icons.copy_outlined),
                              title: const Text('Templates'),
                              subtitle: const Text('Modelos de escala'),
                              onTap: () {
                                Navigator.pop(context);
                                context.go('/leader/templates');
                              },
                            ),
                          ),
                        // 4. FORMULÁRIOS - Independente (visível apenas para tenant_admin e branch_admin)
                        if (usuario.role == UserRole.tenant_admin ||
                            usuario.role == UserRole.branch_admin)
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: ListTile(
                              leading: const Icon(Icons.assignment_outlined),
                              title: const Text('Formulários'),
                              subtitle: const Text('Criar e gerenciar'),
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/forms');
                              },
                            ),
                          ),
                      ],
                      ),
                    ),

                    // ⚙️ ADMINISTRAÇÃO (só aparece se tiver conteúdo)
                    if (usuario.role == UserRole.servus_admin)
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
                                context.push('/leader/tenants/create');
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
            const SizedBox(height: 24),
          ],
        ),
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

}
