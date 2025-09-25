import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/core/enums/user_role.dart';
import 'package:servus_app/features/leader/ministerios/controllers/ministerios_detalhes_controller.dart';
import 'package:servus_app/features/leader/ministerios/widgets/ministry_members_tab.dart';
import 'package:servus_app/features/ministries/widgets/ministry_functions_tab.dart';
import 'package:servus_app/features/ministries/controllers/ministry_functions_controller.dart';
import 'package:servus_app/features/ministries/services/ministry_functions_service.dart';
import 'package:servus_app/state/auth_state.dart';
import 'package:go_router/go_router.dart';

class MinisterioDetalhesScreen extends StatelessWidget {
  final String ministerioId;
  const MinisterioDetalhesScreen({super.key, required this.ministerioId});

  /// Determina para onde o usuário deve voltar baseado no seu role
  String _getBackRoute(BuildContext context) {
    final usuario = context.read<AuthState>().usuario;
    if (usuario?.role == UserRole.leader) {
      // Líder volta para o dashboard
      return '/leader/dashboard';
    } else {
      // Outros roles voltam para a lista de ministérios
      return '/leader/ministerio/lista';
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔍 [MinisterioDetalhesScreen] Construindo tela para ministério: $ministerioId');
    debugPrint('🔍 [MinisterioDetalhesScreen] Context mounted? ${context.mounted}');
    
    return ChangeNotifierProvider(
      create: (_) => MinisterioDetalhesController(ministerioId: ministerioId)..carregarDados(),
      child: Consumer<MinisterioDetalhesController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return Scaffold(
              appBar: AppBar(
                centerTitle: false,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go(_getBackRoute(context)),
                ),
                title: Text('Carregando...', style: context.textStyles.titleLarge
                  ?.copyWith(color: context.colors.onSurface)),
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (controller.isError) {
            return Scaffold(
              appBar: AppBar(
                centerTitle: false,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go(_getBackRoute(context)),
                ),
                title: Text('Erro', style: context.textStyles.titleLarge
                  ?.copyWith(color: context.colors.onSurface)),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erro ao carregar ministério',
                      style: context.textStyles.titleMedium?.copyWith(
                        color: Colors.red[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      controller.errorMessage,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: controller.carregarDados,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar Novamente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.primary,
                        foregroundColor: context.colors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return DefaultTabController(
            length: 3, // 3 abas: Informações, Membros, Funções
            child: Scaffold(
              appBar: AppBar(
                centerTitle: false,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go(_getBackRoute(context)),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ministério', style: context.textStyles.titleLarge
                      ?.copyWith(color: context.colors.onSurface)),
                    Text(
                      controller.nomeMinisterio,
                      style: context.textStyles.labelSmall?.copyWith(
                        color: context.colors.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                actions: [
                  // Botão de status
                  IconButton(
                    icon: Icon(
                      controller.iconeStatus,
                      color: controller.corStatus,
                    ),
                    onPressed: () => _showStatusDialog(context, controller),
                    tooltip: 'Alterar Status',
                  ),
                  // Botão de refresh
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: controller.carregarDados,
                    tooltip: 'Atualizar',
                  ),
                  // Menu de ações
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          context.push('/leader/ministerio/form', extra: controller.ministerio);
                          break;
                        case 'delete':
                          _showDeleteDialog(context, controller);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Excluir', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                bottom: TabBar(
                  indicatorColor: context.colors.primary.withOpacity(0.3),
                  indicatorWeight: 2,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.info_outline),
                      text: 'Informações',
                    ),
                    Tab(
                      icon: Icon(Icons.people),
                      text: 'Membros',
                    ),
                    Tab(
                      icon: Icon(Icons.work),
                      text: 'Funções',
                    ),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  // 1. Aba de Informações
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  // Card principal com informações do ministério
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                color: context.colors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.groups,
                                size: 40,
                                color: context.colors.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    controller.nomeMinisterio,
                                    style: context.textStyles.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: context.colors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        controller.iconeStatus,
                                        size: 16,
                                        color: controller.corStatus,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        controller.statusFormatado,
                                        style: context.textStyles.bodySmall?.copyWith(
                                          color: controller.corStatus,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        if (controller.descricao.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Descrição',
                            style: context.textStyles.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            controller.descricao,
                            style: context.textStyles.bodyMedium?.copyWith(
                              color: context.colors.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],

                        if (controller.funcoes.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Funções',
                            style: context.textStyles.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: controller.funcoes.map((funcao) => Container(
                              decoration: BoxDecoration(
                                color: context.colors.primary,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Text(
                                  funcao,
                                  style: context.textStyles.bodySmall?.copyWith(
                                    color: context.colors.onPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            )).toList(),
                          ),
                        ],

                        const SizedBox(height: 16),
                        Container(
                          height: 0.5,
                          decoration: BoxDecoration(
                            color: context.colors.onSurface.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(0.25),
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Informações de data
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Criado em',
                                    style: context.textStyles.bodySmall?.copyWith(
                                      color: context.colors.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                  Text(
                                    '${controller.formatarData(controller.dataCriacao)} às ${controller.formatarHora(controller.dataCriacao)}',
                                    style: context.textStyles.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (controller.dataAtualizacao != null)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Atualizado em',
                                      style: context.textStyles.bodySmall?.copyWith(
                                        color: context.colors.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                    Text(
                                      '${controller.formatarData(controller.dataAtualizacao)} às ${controller.formatarHora(controller.dataAtualizacao)}',
                                      style: context.textStyles.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // // Seção de ações
                  // Text(
                  //   'Ações',
                  //   style: context.textStyles.titleMedium?.copyWith(
                  //     fontWeight: FontWeight.w600,
                  //     color: context.colors.onSurface,
                  //   ),
                  // ),
                  // const SizedBox(height: 16),

                  // // Lista de opções
                  // _optionTile(
                  //   context,
                  //   Icons.groups,
                  //   "Membros",
                  //   controller.totalMembros > 0 
                  //       ? "${controller.totalMembros} ${controller.totalMembros == 1 ? 'membro' : 'membros'} (${controller.totalVoluntarios} voluntário${controller.totalVoluntarios == 1 ? '' : 's'}, ${controller.totalLideres} líder${controller.totalLideres == 1 ? '' : 'es'})"
                  //       : "Carregando...",
                  //   () {},
                  // ),
                  // _optionTile(
                  //   context,
                  //   Icons.manage_accounts,
                  //   "Funções",
                  //   "${controller.funcoes.length} ${controller.funcoes.length == 1 ? 'função' : 'funções'}",
                  //   () {},
                  // ),
                  // _optionTile(
                  //   context,
                  //   Icons.star_border,
                  //   "Classificações",
                  //   "0 ${controller.funcoes.length == 1 ? 'classificação' : 'classificações'}",
                  //   () {},
                  // ),
                  // _optionTile(
                  //   context,
                  //   Icons.admin_panel_settings,
                  //   "Administradores",
                  //   "0 ${controller.funcoes.length == 1 ? 'administrador' : 'administradores'}", r
                  //   () {},
                  // ),
                  // _optionTile(
                  //   context,
                  //   Icons.extension,
                  //   "Módulos",
                  //   "0 ${controller.funcoes.length == 1 ? 'módulo' : 'módulos'}",
                  //   () {},
                  // ),
                  // _optionTile(
                  //   context,
                  //   Icons.insert_drive_file,
                  //   "Modelos de roteiro",
                  //   "0 ${controller.funcoes.length == 1 ? 'modelo' : 'modelos'}",
                  //   () {},
                  // ),
                      ],
                    ),
                  ),
                  // 2. Aba de Membros
                  MinistryMembersTab(controller: controller),
                  // 3. Aba de Funções
                  ChangeNotifierProvider(
                    create: (_) => MinistryFunctionsController(MinistryFunctionsService()),
                    child: MinistryFunctionsTab(
                      ministryId: ministerioId,
                      ministryName: controller.nomeMinisterio,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  void _showStatusDialog(BuildContext context, MinisterioDetalhesController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Alterar Status',
          style: context.textStyles.titleLarge?.copyWith(color: context.colors.onSurface,),
        ),
        content: Text(
          'Deseja ${controller.isAtivo ? 'desativar' : 'ativar'} o ministério "${controller.nomeMinisterio}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await controller.alterarStatus(!controller.isAtivo);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ministério ${controller.isAtivo ? 'ativado' : 'desativado'} com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Erro ao alterar status do ministério'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: controller.isAtivo ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(controller.isAtivo ? 'Desativar' : 'Ativar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, MinisterioDetalhesController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirmar exclusão',
          style: context.textStyles.titleLarge?.copyWith(color: context.colors.onSurface),
        ),
        content: Text('Tem certeza que deseja excluir o ministério "${controller.nomeMinisterio}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await controller.removerMinisterio();
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ministério removido com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
                context.go(_getBackRoute(context));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Erro ao remover ministério'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}