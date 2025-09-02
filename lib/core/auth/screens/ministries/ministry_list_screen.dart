import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/auth/controllers/ministry_controller.dart';
import 'package:servus_app/core/models/ministry_dto.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';
import 'package:servus_app/core/auth/screens/ministries/ministry_form_dialog.dart';
import 'package:servus_app/core/auth/screens/ministries/ministry_details_dialog.dart';

class MinistryListScreen extends StatefulWidget {
  const MinistryListScreen({super.key});

  @override
  State<MinistryListScreen> createState() => _MinistryListScreenState();
}

class _MinistryListScreenState extends State<MinistryListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MinistryController>().loadMinistries(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<MinistryController>().loadMoreMinistries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ministérios'),
        backgroundColor: context.theme.primaryColor,
        foregroundColor: context.colors.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateMinistryDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: Consumer<MinistryController>(
              builder: (context, controller, child) {
                if (controller.isLoading && controller.ministries.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.ministries.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () => controller.loadMinistries(refresh: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.ministries.length + (controller.currentPage < controller.totalPages ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == controller.ministries.length) {
                        return _buildLoadingMore();
                      }
                      
                      final ministry = controller.ministries[index];
                      return _buildMinistryCard(ministry, controller);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barra de pesquisa
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar ministérios...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  context.read<MinistryController>().clearFilters();
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (value) {
              context.read<MinistryController>().applyFilters(search: value);
            },
          ),
          
          const SizedBox(height: 16),
          
          // Filtros
          Row(
            children: [
              Consumer<MinistryController>(
                builder: (context, controller, child) {
                  return FilterChip(
                    label: Text('Ativos: ${controller.totalItems}'),
                    selected: controller.showOnlyActive,
                    onSelected: (selected) {
                      controller.applyFilters(showOnlyActive: selected);
                    },
                  );
                },
              ),
              const SizedBox(width: 8),
              Consumer<MinistryController>(
                builder: (context, controller, child) {
                  return             Text(
              'Página ${controller.currentPage} de ${controller.totalPages}',
              style: context.textStyles.bodySmall,
            );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMinistryCard(MinistryResponse ministry, MinistryController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: ministry.isActive 
              ? context.theme.primaryColor 
              : Colors.grey,
          child: Text(
            ministry.name[0].toUpperCase(),
            style: TextStyle(
              color: ministry.isActive 
                  ? context.colors.onPrimary 
                  : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          ministry.name,
          style: context.textStyles.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            decoration: ministry.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ministry.description != null && ministry.description!.isNotEmpty)
              Text(
                ministry.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  ministry.isActive ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: ministry.isActive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  ministry.isActive ? 'Ativo' : 'Inativo',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: ministry.isActive ? Colors.green : Colors.red,
                  ),
                ),
                const Spacer(),
                Text(
                  '${ministry.ministryFunctions.length} função(ões)',
                  style: context.textStyles.bodySmall,
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMinistryAction(value, ministry, controller),
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
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(ministry.isActive ? Icons.block : Icons.check_circle),
                  const SizedBox(width: 8),
                  Text(ministry.isActive ? 'Desativar' : 'Ativar'),
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
        onTap: () {
          controller.selectMinistry(ministry);
          _showMinistryDetails(ministry);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.church_outlined,
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
            onPressed: () => _showCreateMinistryDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Criar Ministério'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.theme.primaryColor,
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

  void _handleMinistryAction(String action, MinistryResponse ministry, MinistryController controller) {
    switch (action) {
      case 'edit':
        _showEditMinistryDialog(context, ministry, controller);
        break;
      case 'toggle':
        _toggleMinistryStatus(ministry, controller);
        break;
      case 'delete':
        _showDeleteConfirmation(ministry, controller);
        break;
    }
  }

  void _toggleMinistryStatus(MinistryResponse ministry, MinistryController controller) {
    controller.toggleMinistryStatus(ministry.id, !ministry.isActive).then((_) {
      showServusSnack(
        context,
        message: 'Ministério ${ministry.isActive ? 'desativado' : 'ativado'} com sucesso',
        type: ServusSnackType.success,
      );
    }).catchError((e) {
      showServusSnack(
        context,
        message: 'Erro ao alterar status: ${e.toString()}',
        type: ServusSnackType.error,
      );
    });
  }

  void _showDeleteConfirmation(MinistryResponse ministry, MinistryController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Tem certeza que deseja excluir o ministério "${ministry.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteMinistry(ministry, controller);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _deleteMinistry(MinistryResponse ministry, MinistryController controller) {
    controller.deleteMinistry(ministry.id).then((_) {
      showServusSnack(
        context,
        message: 'Ministério excluído com sucesso',
        type: ServusSnackType.success,
      );
    }).catchError((e) {
      showServusSnack(
        context,
        message: 'Erro ao excluir: ${e.toString()}',
        type: ServusSnackType.error,
      );
    });
  }

  void _showCreateMinistryDialog(BuildContext context) {
    _showMinistryFormDialog(context, null);
  }

  void _showEditMinistryDialog(BuildContext context, MinistryResponse ministry, MinistryController controller) {
    _showMinistryFormDialog(context, ministry);
  }

  void _showMinistryFormDialog(BuildContext context, MinistryResponse? ministry) {
    showDialog(
      context: context,
      builder: (context) => MinistryFormDialog(ministry: ministry),
    );
  }

  void _showMinistryDetails(MinistryResponse ministry) {
    showDialog(
      context: context,
      builder: (context) => MinistryDetailsDialog(ministry: ministry),
    );
  }
} 