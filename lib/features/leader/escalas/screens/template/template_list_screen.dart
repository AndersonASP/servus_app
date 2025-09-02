import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/escalas/controllers/template/template_controller.dart';
import 'template_form_screen.dart';
import 'package:go_router/go_router.dart';

class TemplateListScreen extends StatelessWidget {
  const TemplateListScreen({super.key});

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
          body: templates.isEmpty
              ? const Center(child: Text('Nenhum template cadastrado.'))
              : ListView.builder(
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
                      child: ListTile(
                        title: Text(
                          template.nome,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                            '${template.funcoes.length} função(ões) definidas'),
                        trailing: const Icon(Icons.edit),
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