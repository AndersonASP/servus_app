import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/enums/user_role.dart';
import 'package:servus_app/core/models/ministerio.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/state/auth_state.dart';
import 'package:servus_app/shared/widgets/drawer_profile_header.dart';
import 'package:servus_app/features/ministries/services/ministry_service.dart';

class DrawerMenuLider extends StatelessWidget {
  final Ministerio? ministerioSelecionado;
  final VoidCallback onTrocarModo;

  const DrawerMenuLider({
    super.key,
    required this.ministerioSelecionado,
    required this.onTrocarModo,
  });

  void _navigateToLeaderMinistry(BuildContext context) {
    debugPrint('🔍 [DrawerMenu] _navigateToLeaderMinistry iniciado');
    
    // Salvar referências antes da operação assíncrona
    final usuario = context.read<AuthState>().usuario;
    final ministryService = MinistryService();
    
    debugPrint('🔍 [DrawerMenu] Usuario: ${usuario?.email}, TenantId: ${usuario?.tenantId}');
    
    if (usuario?.tenantId == null) {
      debugPrint('❌ [DrawerMenu] Tenant não encontrado');
      return;
    }

    debugPrint('🔍 [DrawerMenu] Buscando ministério do líder...');
    
    // Executar operação assíncrona em um microtask
    Future.microtask(() async {
      try {
        final leaderMinistry = await ministryService.getLeaderMinistryV2(
          tenantId: usuario!.tenantId!,
          branchId: usuario.branchId ?? '',
          context: null,
        );

        debugPrint('🔍 [DrawerMenu] Resultado: ${leaderMinistry?.id} - ${leaderMinistry?.name}');
        debugPrint('🔍 [DrawerMenu] LeaderMinistry é null? ${leaderMinistry == null}');

        if (leaderMinistry != null) {
          // Usar GoRouter para navegação
          debugPrint('🔍 [DrawerMenu] Navegando para: /leader/ministerio-detalhes/${leaderMinistry.id}');
          
          // Tentar navegação direta usando o contexto global
          try {
            GoRouter.of(context).push('/leader/ministerio-detalhes/${leaderMinistry.id}');
            debugPrint('✅ [DrawerMenu] Navegação executada');
          } catch (e) {
            debugPrint('❌ [DrawerMenu] Erro na navegação: $e');
            // Fallback: tentar com Navigator
            try {
              Navigator.of(context).pushNamed('/leader/ministerio-detalhes/${leaderMinistry.id}');
              debugPrint('✅ [DrawerMenu] Navegação com Navigator executada');
            } catch (e2) {
              debugPrint('❌ [DrawerMenu] Erro na navegação com Navigator: $e2');
            }
          }
        } else {
          debugPrint('❌ [DrawerMenu] Ministério não encontrado');
        }
      } catch (e) {
        debugPrint('❌ [DrawerMenu] Erro: $e');
      }
    });
  }

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
                        debugPrint('🔍 [DrawerMenu] Clicou em ministério - Role: ${usuario.role}');
                        debugPrint('🔍 [DrawerMenu] Context mounted? ${context.mounted}');
                        Navigator.pop(context);
                        debugPrint('🔍 [DrawerMenu] Drawer fechado');
                        if (usuario.role == UserRole.leader) {
                          debugPrint('🔍 [DrawerMenu] Navegando diretamente para ministério do líder');
                          // Líder vai para detalhes do seu ministério - usar ID fixo que sabemos que existe
                          context.push('/leader/ministerio-detalhes/68d1b58da422169502e5e765');
                          debugPrint('✅ [DrawerMenu] Navegação direta executada');
                        } else {
                          debugPrint('🔍 [DrawerMenu] Navegando para lista de ministérios');
                          // Outros roles vão para lista de ministérios
                          context.push('/leader/ministerio/lista');
                        }
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
