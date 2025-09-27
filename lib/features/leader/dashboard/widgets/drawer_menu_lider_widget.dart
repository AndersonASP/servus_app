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
            Divider(
              height: 10,
              thickness: 0.6,
              color: context.colors.onSurface.withValues(alpha: 0.2),
            ),

            const SizedBox(height: 16),

            // Menu de navegação - Scrollável
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                  // Dashboard
                  ListTile(
                    leading: const Icon(Icons.dashboard),
                    title: const Text('Dashboard'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/leader/dashboard');
                    },
                  ),

                  // Ministérios (não visível para servus_admin)
                  if (usuario.role != UserRole.servus_admin)
                    ListTile(
                      leading: const Icon(Icons.groups),
                      title: Text(usuario.role == UserRole.leader ? 'Meu ministério' : 'Ministérios'),
                      subtitle: Text(usuario.role == UserRole.leader ? 'Ver detalhes do meu ministério' : 'Gerenciar ministérios'),
                      onTap: () {
                        // 🔍 LOGS DETALHADOS PARA DEBUG DO MENU "MEU MINISTÉRIO"
                        debugPrint('🎯 [DrawerMenu] ===== CLIQUE NO MENU MINISTÉRIO =====');
                        debugPrint('🔍 [DrawerMenu] Usuário logado:');
                        debugPrint('   - Nome: ${usuario.nome}');
                        debugPrint('   - Email: ${usuario.email}');
                        debugPrint('   - Role: ${usuario.role}');
                        debugPrint('   - É líder: ${usuario.isLider}');
                        debugPrint('   - É voluntário: ${usuario.isVoluntario}');
                        debugPrint('   - Ministério principal ID: ${usuario.primaryMinistryId}');
                        debugPrint('   - Ministério principal nome: ${usuario.primaryMinistryName}');
                        debugPrint('   - Tenant ID: ${usuario.tenantId}');
                        debugPrint('   - Branch ID: ${usuario.branchId}');
                        debugPrint('🔍 [DrawerMenu] Context mounted? ${context.mounted}');
                        
                        Navigator.pop(context);
                        debugPrint('🔍 [DrawerMenu] Drawer fechado');
                        
                        if (usuario.role == UserRole.leader) {
                          debugPrint('🎯 [DrawerMenu] USUÁRIO É LÍDER - Navegando para ministério do líder');
                          
                          // 🆕 Usar o ministério principal do usuário
                          if (usuario.primaryMinistryId != null) {
                            final ministryId = usuario.primaryMinistryId!;
                            final route = '/leader/ministerio-detalhes/$ministryId';
                            debugPrint('✅ [DrawerMenu] Ministério principal encontrado:');
                            debugPrint('   - ID: $ministryId');
                            debugPrint('   - Nome: ${usuario.primaryMinistryName}');
                            debugPrint('   - Rota: $route');
                            context.push(route);
                            debugPrint('✅ [DrawerMenu] Navegação executada para ministério principal');
                          } else {
                            // Fallback para ID fixo se não houver ministério principal
                            const fallbackId = '68d1b58da422169502e5e765';
                            const fallbackRoute = '/leader/ministerio-detalhes/$fallbackId';
                            debugPrint('⚠️ [DrawerMenu] PROBLEMA: Ministério principal não encontrado!');
                            debugPrint('   - primaryMinistryId é null');
                            debugPrint('   - Usando fallback ID: $fallbackId');
                            debugPrint('   - Rota fallback: $fallbackRoute');
                            context.push(fallbackRoute);
                            debugPrint('⚠️ [DrawerMenu] Navegação executada com fallback');
                          }
                        } else {
                          debugPrint('🔍 [DrawerMenu] Usuário não é líder, navegando para lista de ministérios');
                          debugPrint('   - Role atual: ${usuario.role}');
                          debugPrint('   - Rota: /leader/ministerio/lista');
                          context.push('/leader/ministerio/lista');
                          debugPrint('✅ [DrawerMenu] Navegação para lista executada');
                        }
                        
                        debugPrint('🎯 [DrawerMenu] ===== FIM DO CLIQUE NO MENU MINISTÉRIO =====');
                      },
                    ),


                  // Membros (visível apenas para tenant_admin e branch_admin)
                  if (usuario.role == UserRole.tenant_admin ||
                      usuario.role == UserRole.branch_admin)
                    ListTile(
                      leading: const Icon(Icons.group_add),
                      title: const Text('Membros'),
                      subtitle: const Text('Gerenciar membros'),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/leader/members');
                      },
                    ),

                  // Voluntários (visível para leader, tenant_admin e branch_admin)
                  if (usuario.role == UserRole.leader ||
                      usuario.role == UserRole.tenant_admin ||
                      usuario.role == UserRole.branch_admin)
                    ListTile(
                      leading: const Icon(Icons.people),
                      title: const Text('Voluntários'),
                      subtitle: const Text('Gerenciar voluntários'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/leader/dashboard/voluntarios');
                      },
                    ),

                  // Formulários (visível apenas para tenant_admin e branch_admin)
                  if (usuario.role == UserRole.tenant_admin ||
                      usuario.role == UserRole.branch_admin)
                    ListTile(
                      leading: const Icon(Icons.assignment),
                      title: const Text('Formulários'),
                      subtitle: const Text('Criar e gerenciar'),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/forms');
                      },
                    ),
                  // Criar Tenants (apenas para ServusAdmin)
                  if (usuario.role == UserRole.servus_admin)
                    ListTile(
                      leading: const Icon(Icons.business),
                      title: const Text('Nova igreja'),
                      subtitle: const Text('Nova organização'),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/leader/tenants/create');
                      },
                    ),

                  // Escalas (não visível para servus_admin)
                  if (usuario.role != UserRole.servus_admin)
                    ListTile(
                      leading: const Icon(Icons.schedule),
                      title: const Text('Escalas'),
                      subtitle: const Text('Gerenciar escalas'),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/leader/escalas');
                      },
                    ),

                  // Eventos (não visível para servus_admin)
                  if (usuario.role != UserRole.servus_admin)
                    ListTile(
                      leading: const Icon(Icons.event),
                      title: const Text('Eventos'),
                      subtitle: const Text('Gerenciar eventos'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/leader/eventos');
                      },
                    ),

                  // Templates (não visível para servus_admin)
                  if (usuario.role != UserRole.servus_admin)
                    ListTile(
                      leading: const Icon(Icons.copy),
                      title: const Text('Templates'),
                      subtitle: const Text('Modelos de escala'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/leader/templates');
                      },
                    ),

                  ],
                ),
              ),
            ),

            // Rodapé fixo
            Divider(
              height: 10,
              thickness: 0.6,
              color: context.colors.onSurface.withValues(alpha: 0.2),
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
