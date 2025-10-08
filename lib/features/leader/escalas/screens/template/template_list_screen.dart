import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/escalas/controllers/template/template_controller.dart';
import 'package:servus_app/features/leader/escalas/models/template_model.dart';
import 'template_form_screen.dart';
import 'package:go_router/go_router.dart';

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
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/leader/dashboard'),
            ),
            title: Text('Templates de Escala', style: context.textStyles.titleLarge?.copyWith(
              color: context.colors.onSurface,
              fontWeight: FontWeight.bold,
            ),),
            centerTitle: false,
          ),
          body: Consumer<TemplateController>(
            builder: (context, controller, _) {
              if (controller.isLoadingMinistries) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Carregando ministérios...'),
                    ],
                  ),
                );
              }
              
              if (controller.errorMessage != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Erro ao carregar ministérios',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        controller.errorMessage!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => controller.refreshMinisterios(),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                );
              }
              
              if (templates.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum template cadastrado',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crie seu primeiro template para facilitar a criação de escalas',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                itemCount: templates.length,
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
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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