import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:servus_app/core/navigation/custom_transitions.dart';
import 'package:servus_app/features/ministries/models/ministry_dto.dart';
import 'package:servus_app/features/leader/dashboard/cards_details/escala_mensal/escala_mensal_screen.dart';
import 'package:servus_app/features/leader/dashboard/leader_dashboard_screen.dart';
import 'package:servus_app/features/leader/dashboard/cards_details/solicitacao_troca/solicitacao_troca_screen.dart';
import 'package:servus_app/features/leader/escalas/screens/escala/escala_list_screen.dart';
import 'package:servus_app/features/leader/escalas/screens/evento/evento_list_screen.dart';
import 'package:servus_app/features/leader/escalas/screens/template/template_list_screen.dart';
import 'package:servus_app/features/leader/ministerios/screens/ministerio_form_screen.dart';
import 'package:servus_app/features/leader/ministerios/screens/ministerio_edit_screen.dart';
import 'package:servus_app/features/leader/ministerios/screens/ministerios_detalhes_screen.dart';
import 'package:servus_app/features/leader/ministerios/screens/ministerios_lista_screen.dart';
import 'package:servus_app/features/leader/tenants/create_tenant_screen.dart';
import 'package:servus_app/features/members/dashboard/members_dashboard_screen.dart';
import 'package:servus_app/features/members/create/create_member_screen.dart';
import 'package:servus_app/features/branches/dashboard/branches_dashboard_screen.dart';
import 'package:servus_app/features/branches/create/create_branch_screen.dart';
import 'package:servus_app/features/forms/screens/forms_list_screen.dart';
import 'package:servus_app/features/forms/screens/create_form_screen.dart';
import 'package:servus_app/features/forms/screens/create_volunteer_form_screen.dart';
import 'package:servus_app/features/forms/screens/form_details_screen.dart';
import 'package:servus_app/features/forms/screens/form_submissions_screen.dart';
import 'package:servus_app/features/forms/screens/public_form_screen.dart';
import 'package:servus_app/features/leader/volunteers/screens/volunteers_dashboard_screen.dart';
import 'package:servus_app/features/leader/volunteers/screens/volunteer_approvals_screen.dart';
import 'package:servus_app/features/leader/volunteers/screens/volunteers_list_screen.dart';

// import 'package:servus_app/features/leader/perfil/perfil_screen.dart'; // futuro

final List<GoRoute> leaderRoutes = [
  GoRoute(
    path: '/leader/dashboard',
    pageBuilder: (context, state) => CustomTransitions.dashboard(
      context,
      state,
      const DashboardLiderScreen(),
    ),
  ),
  GoRoute(
    path: '/leader/dashboard/solicitacao-troca',
    pageBuilder: (context, state) => CustomTransitions.slideLeft(
      context,
      state,
      const CardDetailsSolicitacoesTrocaScreen(),
    ),
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
    builder: (context, state) {
      debugPrint('🔍 [LeaderRoutes] Navegando para lista de ministérios');
      return const MinisterioListScreen();
    },
  ),
  GoRoute(
    path: '/leader/ministerio/edit',
    builder: (context, state) => const MinisterioEditScreen(),
  ),
        GoRoute(
          path: '/leader/ministerio-detalhes/:id',
          builder: (context, state) {
            final ministerioId = state.pathParameters['id']!;
            debugPrint('🔍 [LeaderRoutes] Navegando para detalhes do ministério: $ministerioId');
            debugPrint('🔍 [LeaderRoutes] State: ${state.uri}');
            debugPrint('🔍 [LeaderRoutes] Path parameters: ${state.pathParameters}');
            debugPrint('🔍 [LeaderRoutes] Criando MinisterioDetalhesScreen...');
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
    pageBuilder: (context, state) => CustomTransitions.dashboard(
      context,
      state,
      const MembersDashboardScreen(),
    ),
  ),
  GoRoute(
    path: '/leader/members/create',
    pageBuilder: (context, state) => CustomTransitions.form(
      context,
      state,
      const CreateMemberScreen(),
    ),
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
        // Rotas de formulários
        GoRoute(
          path: '/leader/forms',
          pageBuilder: (context, state) => CustomTransitions.dashboard(
            context,
            state,
            const FormsListScreen(),
          ),
        ),
        // Rota de redirecionamento para compatibilidade
        GoRoute(
          path: '/forms',
          redirect: (context, state) => '/leader/forms',
        ),
        GoRoute(
          path: '/forms/create',
          pageBuilder: (context, state) => CustomTransitions.form(
            context,
            state,
            const CreateFormScreen(),
          ),
        ),
        GoRoute(
          path: '/forms/create-volunteer',
          pageBuilder: (context, state) => CustomTransitions.form(
            context,
            state,
            const CreateCustomFormScreen(),
          ),
        ),
        GoRoute(
          path: '/forms/:formId/details',
          builder: (context, state) {
            final formId = state.pathParameters['formId']!;
            return FormDetailsScreen(formId: formId);
          },
        ),
        GoRoute(
          path: '/forms/:formId/submissions',
          builder: (context, state) {
            final formId = state.pathParameters['formId']!;
            final formTitle = state.uri.queryParameters['title'] ?? 'Formulário';
            return FormSubmissionsScreen(
              formId: formId,
              formTitle: formTitle,
            );
          },
        ),
        GoRoute(
          path: '/forms/public/:formId',
          builder: (context, state) {
            final formId = state.pathParameters['formId']!;
            return PublicFormScreen(formId: formId);
          },
        ),
  // Rotas de voluntários
  GoRoute(
    path: '/leader/dashboard/voluntarios',
    builder: (context, state) => const VolunteersDashboardScreen(),
  ),
  GoRoute(
    path: '/leader/volunteers/approvals',
    builder: (context, state) => const VolunteerApprovalsScreen(),
  ),
  GoRoute(
    path: '/leader/volunteers/list',
    builder: (context, state) => const VolunteersListScreen(),
  ),
  // Rotas de funções

];
