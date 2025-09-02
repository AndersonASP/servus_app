import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/ministerios/controllers/ministerios_lista_controller.dart';

class MinisterioListScreen extends StatefulWidget {
  const MinisterioListScreen({super.key});

  @override
  State<MinisterioListScreen> createState() => _MinisterioListScreenState();
}

class _MinisterioListScreenState extends State<MinisterioListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final controller = context.read<MinisterioListController>();
      controller.carregarMaisMinisterios();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MinisterioListController()..carregarMinisterios(),
      child: Consumer<MinisterioListController>(
        builder: (context, controller, _) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: context.theme.scaffoldBackgroundColor,
              centerTitle: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/leader/dashboard'),
              ),
              title: Text(
                'Ministérios',
                style: context.textStyles.titleLarge
                    ?.copyWith(color: context.colors.onSurface),
              ),
              actions: [
                // Botão de filtros
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: (value) {
                    switch (value) {
                      case 'ativos':
                        controller.filtrarPorStatus(true);
                        break;
                      case 'todos':
                        controller.filtrarPorStatus(false);
                        break;
                      case 'limpar':
                        controller.limparFiltros();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'ativos',
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: controller.showOnlyActive ? context.colors.primary : null,
                          ),
                          const SizedBox(width: 8),
                          Text('Apenas Ativos'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'todos',
                      child: Row(
                        children: [
                          Icon(
                            Icons.list,
                            color: !controller.showOnlyActive ? context.colors.primary : null,
                          ),
                          const SizedBox(width: 8),
                          Text('Todos'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'limpar',
                      child: Row(
                        children: [
                          Icon(Icons.clear),
                          SizedBox(width: 8),
                          Text('Limpar Filtros'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: Column(
              children: [
                // Barra de busca
                Container(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar ministérios...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          controller.limparFiltros();
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        controller.buscarMinisterios(value);
                      }
                    },
                  ),
                ),
                
                // Contadores e informações
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Chip(
                        label: Text('Total: ${controller.totalItems}'),
                        backgroundColor: context.colors.primary.withOpacity(0.1),
                        labelStyle: TextStyle(color: context.colors.primary),
                      ),
                      const SizedBox(width: 8),
                      if (controller.totalPages > 1)
                        Text(
                          'Página ${controller.currentPage} de ${controller.totalPages}',
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.onSurface.withOpacity(0.7),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Lista de ministérios
                Expanded(
                  child: controller.isLoading && controller.ministerios.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : controller.ministerios.isEmpty
                          ? _buildEmptyState(context)
                          : RefreshIndicator(
                              onRefresh: () => controller.carregarMinisterios(refresh: true),
                              child: ListView.separated(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: controller.ministerios.length + (controller.hasMorePages ? 1 : 0),
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  if (index == controller.ministerios.length) {
                                    return _buildLoadingMore();
                                  }
                                  
                                  final ministerio = controller.ministerios[index];
                                  return _buildMinistryCard(context, ministerio, controller);
                                },
                              ),
                            ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              label: Text(
                'Novo Ministério',
                style: context.textStyles.bodyLarge?.copyWith(
                  color: context.colors.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                context.push('/leader/ministerio/form');
              },
              icon: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMinistryCard(BuildContext context, dynamic ministerio, MinisterioListController controller) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: ministerio.isActive 
              ? context.colors.primary 
              : Colors.grey,
          child: Icon(
            Icons.groups,
            color: ministerio.isActive 
                ? context.colors.onPrimary 
                : Colors.white,
          ),
        ),
        title: Text(
          ministerio.name, // Usando o campo correto do backend
          style: context.textStyles.titleMedium?.copyWith(
            color: context.colors.onSurface,
            fontWeight: FontWeight.w600,
            decoration: ministerio.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ministerio.description != null && ministerio.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                ministerio.description,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  ministerio.isActive ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: ministerio.isActive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  ministerio.isActive ? 'Ativo' : 'Inativo',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: ministerio.isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${ministerio.ministryFunctions.length} função(ões)',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Switch de status
            Switch(
              value: ministerio.isActive,
              onChanged: controller.isUpdating ? null : (value) {
                controller.alterarStatus(ministerio.id, value);
              },
            ),
            
            // Menu de ações
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    context.push('/leader/ministerio/form', extra: ministerio);
                    break;
                  case 'view':
                    context.push('/leader/ministerio-detalhes/${ministerio.id}');
                    break;
                  case 'delete':
                    _showDeleteConfirmation(context, ministerio, controller);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility),
                      SizedBox(width: 8),
                      Text('Ver Detalhes'),
                    ],
                  ),
                ),
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
        ),
        onTap: () {
          context.push('/leader/ministerio-detalhes/${ministerio.id}');
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum ministério encontrado',
            style: context.textStyles.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie o primeiro ministério para começar',
            style: context.textStyles.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/leader/ministerio/form'),
            icon: const Icon(Icons.add),
            label: const Text('Criar Ministério'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMore() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  void _showDeleteConfirmation(BuildContext context, dynamic ministerio, MinisterioListController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Tem certeza que deseja excluir o ministério "${ministerio.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.removerMinisterio(ministerio.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
