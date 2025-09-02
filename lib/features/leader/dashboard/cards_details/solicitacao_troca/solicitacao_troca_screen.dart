import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/dashboard/cards_details/solicitacao_troca/solicitacao_troca_controller.dart';

class CardDetailsSolicitacoesTrocaScreen extends StatelessWidget {
  const CardDetailsSolicitacoesTrocaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SolicitacoesTrocaController(),
      child: Consumer<SolicitacoesTrocaController>(
        builder: (context, controller, _) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: context.theme.scaffoldBackgroundColor,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/leader/dashboard'),
              ),
              title: const Text('Solicitações de Troca'),
              centerTitle: false,
            ),
            body: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.solicitacoes.length,
              itemBuilder: (context, index) {
                final solicitacao = controller.solicitacoes[index];

                final corStatus = switch (solicitacao.status) {
                  'aceito' => Colors.green,
                  'recusado' => Colors.red,
                  _ => Colors.orange
                };

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Voluntário escalado e sugerido para troca
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              solicitacao.voluntario,
                              style: context.textStyles.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: context.colors.onSurface,
                                fontSize: 16
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.swap_horiz),
                            const SizedBox(width: 8),
                            Text(
                              solicitacao.substituto,
                              style: context.textStyles.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: context.colors.onSurface,
                                fontSize: 16
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Escala
                        Text(
                          'Escala: ${solicitacao.escala}',
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: context.colors.onSurface,
                          ),
                        ),

                        // Motivo
                        Text(
                          'Motivo: ${solicitacao.motivo}',
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: context.colors.onSurface,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Status
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Status: ${solicitacao.status.toUpperCase()}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: corStatus,
                              ),
                            ),
                          ],
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