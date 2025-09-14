import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:servus_app/features/ministries/models/ministry_dto.dart';
import 'package:servus_app/features/leader/dashboard/cards_details/escala_mensal/escala_mensal_screen.dart';
import 'package:servus_app/features/leader/dashboard/leader_dashboard_screen.dart';
import 'package:servus_app/features/leader/dashboard/cards_details/solicitacao_troca/solicitacao_troca_screen.dart';
import 'package:servus_app/features/leader/escalas/screens/escala/escala_list_screen.dart';
import 'package:servus_app/features/leader/escalas/screens/evento/evento_list_screen.dart';
import 'package:servus_app/features/leader/escalas/screens/template/template_list_screen.dart';
import 'package:servus_app/features/leader/ministerios/screens/ministerio_form_screen.dart';
import 'package:servus_app/features/leader/ministerios/screens/ministerios_detalhes_screen.dart';
import 'package:servus_app/features/leader/ministerios/screens/ministerios_lista_screen.dart';
import 'package:servus_app/features/leader/tenants/create_tenant_screen.dart';
import 'package:servus_app/features/members/dashboard/members_dashboard_screen.dart';
import 'package:servus_app/features/members/create/create_member_screen.dart';
import 'package:servus_app/features/branches/dashboard/branches_dashboard_screen.dart';
import 'package:servus_app/features/branches/create/create_branch_screen.dart';

// import 'package:servus_app/features/leader/perfil/perfil_screen.dart'; // futuro

final List<GoRoute> leaderRoutes = [
  GoRoute(
    path: '/leader/dashboard',
    builder: (context, state) => const DashboardLiderScreen(),
  ),
  GoRoute(
    path: '/leader/dashboard/solicitacao-troca',
    builder: (context, state) => const CardDetailsSolicitacoesTrocaScreen(),
  ),
  GoRoute(
    path: '/leader/escalas',
    builder: (context, state) => const EscalaListScreen(),
  ),
  GoRoute(
    path: '/leader/templates',
    builder: (context, state) => const TemplateListScreen(),
  ),
  GoRoute(
    path: '/leader/eventos',
    builder: (context, state) => const EventoListScreen(),
  ),
  GoRoute(
    path: '/leader/escalas-mensal',
    builder: (context, state) => const EscalaMensalScreen(),
  ),
  GoRoute(
    path: '/leader/ministerio/form',
    builder: (context, state) {
      final ministerio = state.extra as MinistryResponse?;
      return MinisterioFormScreen(ministerio: ministerio);
    },
  ),
  GoRoute(
    path: '/leader/ministerio/lista',
    builder: (context, state) => const MinisterioListScreen(),
  ),
  GoRoute(
    path: '/leader/ministerio-detalhes/:id',
    builder: (context, state) {
      final ministerioId = state.pathParameters['id']!;
      return MinisterioDetalhesScreen(ministerioId: ministerioId);
    },
  ),
  GoRoute(
    path: '/leader/tenants/create',
    builder: (context, state) => const CreateTenantScreen(),
  ),
  // Rotas de membros
  GoRoute(
    path: '/leader/members',
    builder: (context, state) => const MembersDashboardScreen(),
  ),
  GoRoute(
    path: '/leader/members/create',
    builder: (context, state) => const CreateMemberScreen(),
  ),
  GoRoute(
    path: '/leader/members/details/:id',
    builder: (context, state) {
      // TODO: Implementar busca do membro por ID
      return const Scaffold(
        body: Center(
          child: Text('Detalhes do membro em desenvolvimento'),
        ),
      );
    },
  ),
  // Rotas de filiais (branches)
  GoRoute(
    path: '/leader/branches',
    builder: (context, state) => const BranchesDashboardScreen(),
  ),
  GoRoute(
    path: '/leader/branches/create',
    builder: (context, state) => const CreateBranchScreen(),
  ),
  GoRoute(
    path: '/leader/branches/details/:id',
    builder: (context, state) {
      // TODO: Implementar busca da filial por ID
      return const Scaffold(
        body: Center(
          child: Text('Detalhes da filial em desenvolvimento'),
        ),
      );
    },
  ),
  // Rotas de funções

];
