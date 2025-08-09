import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/color_scheme.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/dashboard/cards_details/voluntarios/voluntario_details_controller.dart';

class CardDetailsVoluntariosScreen extends StatelessWidget {
  const CardDetailsVoluntariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VoluntariosController(),
      child: Consumer<VoluntariosController>(
        builder: (context, controller, _) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: context.theme.scaffoldBackgroundColor,
              title: const Text('Voluntários'),
              centerTitle: false,
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: controller.aplicarFiltro,
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'todos', child: Text('Todos')),
                    PopupMenuItem(value: 'ativos', child: Text('Ativos')),
                    PopupMenuItem(value: 'inativos', child: Text('Inativos')),
                  ],
                ),
              ],
            ),
            body: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.voluntariosFiltrados.length,
              itemBuilder: (context, index) {
                final voluntario = controller.voluntariosFiltrados[index];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: context.colors.primary.withOpacity(0.1),
                      child: Icon(Icons.person, color: context.colors.primary),
                    ),
                    title: Text(
                      voluntario.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(voluntario.funcao),
                    trailing: Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Transform.scale(
                          scale: 0.75,
                          child: Switch(
                            value: voluntario.ativo,
                            onChanged: (_) =>
                                controller.alternarStatus(voluntario),
                            activeColor: ServusColors.success,
                            inactiveThumbColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}