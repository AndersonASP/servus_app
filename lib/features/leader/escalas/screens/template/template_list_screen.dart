import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/escalas/controllers/template/template_controller.dart';
import 'package:servus_app/features/leader/escalas/models/template_model.dart';
import 'template_form_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:servus_app/widgets/app_card.dart';
import 'package:servus_app/widgets/soft_divider.dart';
import 'package:servus_app/widgets/empty_state.dart';
import 'package:servus_app/widgets/error_state.dart';
import 'package:servus_app/widgets/loading_skeleton.dart';

class TemplateListScreen extends StatelessWidget {
  const TemplateListScreen({super.key});

  void _confirmarExclusao(BuildContext context, TemplateController controller, TemplateModel template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Tem certeza que deseja excluir o template "${template.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await controller.removerTemplate(template.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Template "${template.nome}" excluído com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao excluir template: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TemplateController>(
      builder: (context, controller, _) {
        final templates = controller.todos;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.go('/leader/dashboard'),
                      ),
                      Expanded(
                        child: Text(
                          'Templates de Escala',
                          style: context.textStyles.titleLarge?.copyWith(
                            color: context.colors.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const SoftDivider(),
                // Body
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (controller.isLoadingMinistries) {
                        return ListView.separated(
                          itemCount: 6,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          padding: const EdgeInsets.all(12),
                          itemBuilder: (_, __) => const AppCard(child: SkeletonListTile()),
                        );
                      }
                      
                      if (controller.errorMessage != null) {
                        return ErrorState(
                          message: controller.errorMessage,
                          onRetry: () => controller.refreshMinisterios(),
                        );
                      }
                      
                      if (templates.isEmpty) {
                        return EmptyState(
                          icon: Icons.description_outlined,
                          title: 'Nenhum template cadastrado',
                          subtitle: 'Crie seu primeiro template para facilitar a criação de escalas',
                        );
                      }
                      
                      return ListView.separated(
                        itemCount: templates.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        padding: const EdgeInsets.all(12),
                        itemBuilder: (context, index) {
                          final template = templates[index];

                          return Dismissible(
                            key: ValueKey(template.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) {
                              controller.removerTemplate(template.id);
                            },
                            child: AppCard(
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: context.colors.primary.withValues(alpha: 0.1),
                                  child: Icon(
                                    Icons.description_outlined,
                                    color: context.colors.primary,
                                  ),
                                ),
                                title: Text(
                                  template.nome,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('${template.funcoes.length} função(ões) definidas'),
                                    if (template.observacoes?.isNotEmpty == true) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        template.observacoes!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    switch (value) {
                                      case 'edit':
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => TemplateFormScreen(
                                              templateExistente: template,
                                            ),
                                          ),
                                        );
                                        break;
                                      case 'duplicate':
                                        try {
                                          await controller.duplicarTemplate(template.id);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Template "${template.nome}" duplicado com sucesso!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Erro ao duplicar template: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                        break;
                                      case 'delete':
                                        _confirmarExclusao(context, controller, template);
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
                                      value: 'duplicate',
                                      child: Row(
                                        children: [
                                          Icon(Icons.copy),
                                          SizedBox(width: 8),
                                          Text('Duplicar'),
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TemplateFormScreen(
                                        templateExistente: template,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TemplateFormScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: Text(
              'Novo Template',
              style: context.textStyles.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.onPrimary,
              ),
            ),
          ),
        );
      },
    );
  }
}