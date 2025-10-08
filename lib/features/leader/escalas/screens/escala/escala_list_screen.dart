import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/escalas/controllers/escala/escala_controller.dart';
import 'package:servus_app/features/leader/escalas/controllers/evento/evento_controller.dart';
import 'package:servus_app/features/leader/escalas/controllers/substitution_controller.dart';
import 'package:servus_app/features/leader/escalas/models/escala_model.dart';
import 'package:servus_app/features/leader/escalas/screens/substitution/substitution_requests_screen.dart';
import 'package:servus_app/features/volunteers/indisponibilidade/indisponibilidade_screen.dart';
import 'escala_form_screen.dart';
import 'package:go_router/go_router.dart';

class EscalaListScreen extends StatelessWidget {
  const EscalaListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final escalaController = context.watch<EscalaController>();
    final eventoController = context.watch<EventoController>();
    final substitutionController = context.watch<SubstitutionController>();

    final escalas = escalaController.todas;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/leader/dashboard'),
        ),
        title: Text(
          'Escalas',
          style: context.textStyles.titleLarge?.copyWith(
            color: context.colors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          // Badge para solicitações pendentes
          if (substitutionController.hasPendingRequests)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SubstitutionRequestsScreen(),
                      ),
                    );
                  },
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${substitutionController.pendingRequestsCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          // Menu de opções
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'availability':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const IndisponibilidadeScreen(),
                    ),
                  );
                  break;
                case 'substitutions':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubstitutionRequestsScreen(),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'availability',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today),
                    SizedBox(width: 8),
                    Text('Disponibilidade'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'substitutions',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz),
                    SizedBox(width: 8),
                    Text('Solicitações de Troca'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: escalas.isEmpty
          ? const Center(child: Text('Nenhuma escala criada ainda.'))
          : ListView.builder(
              itemCount: escalas.length,
              itemBuilder: (context, index) {
                final escala = escalas[index];
                final evento = eventoController.buscarPorId(escala.eventoId);
                final dataFormatada = evento != null
                    ? '${evento.dataHora.day}/${evento.dataHora.month} ${evento.dataHora.hour}:${evento.dataHora.minute.toString().padLeft(2, '0')}'
                    : 'Data desconhecida';

                return Dismissible(
                  key: ValueKey(escala.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    escalaController.remover(escala.id);
                  },
                  child: ListTile(
                    title: Text(
                      evento?.nome ?? 'Evento desconhecido',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Data: $dataFormatada'),
                    trailing: Text(
                      escala.status == StatusEscala.publicada
                          ? 'Publicada'
                          : 'Rascunho',
                      style: TextStyle(
                        color: escala.status == StatusEscala.publicada
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                    onTap: () {
                      // No futuro: ir para a tela de visualização/edição da escala
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const EscalaFormScreen(), // por agora, reuso da form
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
            MaterialPageRoute(builder: (_) => const EscalaFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: Text('Nova Escala', style: context.textStyles.bodyLarge?.copyWith(
          color: context.colors.onPrimary,
          fontWeight: FontWeight.bold,
        ),),
      ),
    );
  }
}
