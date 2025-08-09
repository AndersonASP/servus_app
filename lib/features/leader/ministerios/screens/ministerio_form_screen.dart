import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/ministerios/controllers/ministerio_controller.dart';

class MinisterioFormScreen extends StatelessWidget {
  const MinisterioFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MinisterioController(),
      child: Consumer<MinisterioController>(
        builder: (context, controller, _) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: context.colors.onSurface),
                onPressed: () => context.pop(),
              ),
              centerTitle: false,
              title: Text('Novo Ministério', style: context.textStyles.titleLarge
                    ?.copyWith(color: context.colors.onSurface)),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nome do ministério',
                      style: context.textStyles.labelLarge?.copyWith(
                        color: context.colors.onSurface
                      )),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller.nomeController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Ex: Louvor, Mídia, Acolhimento...',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ativo Switch
                  Row(
                    children: [
                      Switch(
                        value: controller.ativo,
                        onChanged: controller.toggleAtivo,
                      ),
                      const SizedBox(width: 8),
                      Text(controller.ativo ? 'Ativo' : 'Inativo'),
                    ],
                  ),

                  // // Módulo de Louvor
                  // Row(
                  //   children: [
                  //     Switch(
                  //       value: controller.moduloLouvorAtivo,
                  //       onChanged: controller.toggleModuloLouvor,
                  //     ),
                  //     const SizedBox(width: 8),
                  //     Text(
                  //       controller.moduloLouvorAtivo
                  //           ? 'Módulo de Louvor ativo'
                  //           : 'Módulo de Louvor inativo',
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),

            // ✅ Botão Flutuante no canto inferior direito
            floatingActionButton: FloatingActionButton.extended(
              onPressed: controller.isSaving
                  ? null
                  : () => controller.salvarMinisterio(),
              icon: controller.isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check),
              label: controller.isSaving
                  ? Text('Salvando...', style: context.textStyles.bodyLarge?.copyWith(
                    color: context.colors.onPrimary,
                    fontWeight: FontWeight.w800
                  ))
                  : Text('Salvar', style: context.textStyles.bodyLarge?.copyWith(
                    color: context.colors.onPrimary,
                    fontWeight: FontWeight.w800
                  )),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        },
      ),
    );
  }
}