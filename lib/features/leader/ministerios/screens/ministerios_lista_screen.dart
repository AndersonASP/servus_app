import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/ministerios/controllers/ministerios_lista_controller.dart';

class MinisterioListScreen extends StatelessWidget {
  const MinisterioListScreen({super.key});

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
              title: Text(
                'Ministérios',
                style: context.textStyles.titleLarge
                    ?.copyWith(color: context.colors.onSurface),
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              label: Text(
                'Novo',
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
            body: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.ministerios.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final ministerio = controller.ministerios[index];
                      return ListTile(
                        leading: const Icon(Icons.groups),
                        title: Text(
                          ministerio.nome,
                          style: context.textStyles.titleMedium
                              ?.copyWith(color: context.colors.onSurface),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: ministerio.ativo,
                              onChanged: (value) {
                                controller.alterarStatus(ministerio.id, value);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/leader/ministerio/form',
                                  arguments: ministerio,
                                );
                              },
                            ),
                          ],
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
