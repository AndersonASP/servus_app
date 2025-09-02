import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/escalas/controllers/evento/evento_controller.dart';
import 'evento_form_screen.dart';
import 'package:go_router/go_router.dart';

class EventoListScreen extends StatelessWidget {
  const EventoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EventoController>(
      builder: (context, controller, _) {
        final eventos = controller.todos;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/leader/dashboard'),
            ),
            title: Text('Eventos', style: context.textStyles.titleLarge?.copyWith(
              color: context.colors.onSurface,
              fontWeight: FontWeight.bold,
            ),),
            centerTitle: false,
          ),
          body: eventos.isEmpty
              ? const Center(child: Text('Nenhum evento cadastrado.'))
              : ListView.builder(
                  itemCount: eventos.length,
                  itemBuilder: (context, index) {
                    final evento = eventos[index];
                    return Dismissible(
                      key: ValueKey(evento.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        controller.removerEvento(evento.id);
                      },
                      child: ListTile(
                        title: Text(
                          evento.nome,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${evento.dataHora.day}/${evento.dataHora.month} às ${evento.dataHora.hour}:${evento.dataHora.minute.toString().padLeft(2, '0')}',
                        ),
                        trailing: Icon(
                          evento.recorrente ? Icons.repeat : Icons.event,
                          color: evento.recorrente
                              ? Colors.orange
                              : Colors.grey,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventoFormScreen(
                                eventoExistente: evento,
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
                  builder: (_) => const EventoFormScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: Text('Novo Evento', style: context.textStyles.bodyLarge?.copyWith(
              color: context.colors.onPrimary,
              fontWeight: FontWeight.bold,
            ),),
          ),
        );
      },
    );
  }
}