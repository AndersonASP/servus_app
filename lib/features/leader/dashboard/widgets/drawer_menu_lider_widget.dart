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

    // Debug temporário para identificar o problema
    // print('DEBUG: usuario.role no build = ${usuario.role}');
    // print('DEBUG: usuario completo = $usuario');

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
              modoAtual: _labelDoPapel(usuario.role),
            ),
            Divider(
              height: 10,
              thickness: 0.6,
              color: context.colors.onSurface.withValues(alpha: 0.2),
            ),

            // // Ministério atual
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            //   child: Text(
            //     'Ministério atual:',
            //     style: Theme.of(context).textTheme.labelMedium,
            //   ),
            // ),
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16),
            //   child: Text(
            //     ministerioSelecionado?.nome ?? 'Carregando...',
            //     style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            //           fontWeight: FontWeight.w600,
            //           color: context.colors.primary,
            //         ),
            //   ),
            // ),

            const SizedBox(height: 16),

            // Menu de navegação
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
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
                      title: const Text('Ministérios'),
                      subtitle: const Text('Gerenciar ministérios'),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/leader/ministerio/lista');
                      },
                    ),


                  // Membros (visível para tenant_admin, branch_admin e leader)
                  if (usuario.role == UserRole.tenant_admin ||
                      usuario.role == UserRole.branch_admin ||
                      usuario.role == UserRole.leader)
                    ListTile(
                      leading: const Icon(Icons.group_add),
                      title: const Text('Membros'),
                      subtitle: const Text('Gerenciar membros'),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/leader/members');
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

                  // Voluntários (não visível para servus_admin)
                  // if (usuario.role != UserRole.servus_admin)
                  //   ListTile(
                  //     leading: const Icon(Icons.people),
                  //     title: const Text('Voluntários'),
                  //     subtitle: const Text('Gerenciar voluntários'),
                  //     onTap: () {
                  //       Navigator.pop(context);
                  //       context.go('/leader/dashboard/voluntarios');
                  //     },
                  //   ),
                ],
              ),
            ),

            const Spacer(),

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
    // print('DEBUG: _labelDoPapel recebeu role: $role');
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
      default:
        return 'Papel não definido';
    }
  }
}
