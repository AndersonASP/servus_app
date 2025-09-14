import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/escalas/screens/escala/voluntario_model.dart';
import '../../controllers/escala/escala_controller.dart';
import '../../models/escala_model.dart';
import '../../models/template_model.dart';
import '../../controllers/evento/evento_controller.dart';
import '../../controllers/template/template_controller.dart';

// MOCK de voluntários - substitua por controller real se já tiver
final List<VoluntarioModel> mockVoluntarios = [
  VoluntarioModel(id: 'v1', nome: 'João'),
  VoluntarioModel(id: 'v2', nome: 'Maria'),
  VoluntarioModel(id: 'v3', nome: 'Lucas'),
  VoluntarioModel(id: 'v4', nome: 'Ana'),
];

class EscalaFormScreen extends StatefulWidget {
  const EscalaFormScreen({super.key});

  @override
  State<EscalaFormScreen> createState() => _EscalaFormScreenState();
}

class _EscalaFormScreenState extends State<EscalaFormScreen> {
  String? eventoIdSelecionado;
  String? templateIdSelecionado;

  final Map<String, String?> selecaoVoluntariosPorFuncao =
      {}; // funcaoId -> voluntarioId

  void _salvar() {
    if (eventoIdSelecionado == null || templateIdSelecionado == null) return;

    final escalados = selecaoVoluntariosPorFuncao.entries
        .where((entry) => entry.value != null)
        .map((entry) => Escalado(
              funcaoId: entry.key,
      
              voluntarioId: entry.value!,
            ))
        .toList();

    final novaEscala = EscalaModel(
      eventoId: eventoIdSelecionado!,
      templateId: templateIdSelecionado!,
      escalados: escalados,
    );

    final escalaController = context.read<EscalaController>();
    escalaController.adicionar(novaEscala);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final eventoController = context.watch<EventoController>();
    final templateController = context.watch<TemplateController>();

    final eventos = eventoController.todos;
    final templates = templateController.todos;

    final templateSelecionado = templates.firstWhere(
      (t) => t.id == templateIdSelecionado,
      orElse: () => TemplateModel(nome: '', funcoes: []),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Criar Escala',
          style: context.textStyles.titleLarge?.copyWith(
            color: context.colors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _salvar,
        icon: const Icon(Icons.check),
        label: Text('Salvar', style: context.textStyles.bodyLarge?.copyWith(
          color: context.colors.onPrimary,
          fontWeight: FontWeight.bold,
        ),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              value: eventoIdSelecionado,
              decoration: const InputDecoration(labelText: 'Evento'),
              items: eventos
                  .map((e) => DropdownMenuItem(
                        value: e.id,
                        child: Text(e.nome),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  eventoIdSelecionado = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: templateIdSelecionado,
              decoration: const InputDecoration(labelText: 'Template'),
              items: templates
                  .map((t) => DropdownMenuItem(
                        value: t.id,
                        child: Text(t.nome),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  templateIdSelecionado = value;
                  selecaoVoluntariosPorFuncao.clear();
                });
              },
            ),
            const SizedBox(height: 24),
            if (templateSelecionado.funcoes.isEmpty)
              const Text('Selecione um template para ver funções.')
            else ...[
              const Text(
                'Preencher escala:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...templateSelecionado.funcoes.map((f) {
                final key = f.id;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${f.nome} (${f.quantidade} pessoa${f.quantidade > 1 ? 's' : ''})'),
                      DropdownButtonFormField<String>(
                        value: selecaoVoluntariosPorFuncao[key],
                        decoration: const InputDecoration(
                            labelText: 'Selecionar voluntário'),
                        items: mockVoluntarios
                            .map((v) => DropdownMenuItem(
                                  value: v.id,
                                  child: Text(v.nome),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selecaoVoluntariosPorFuncao[key] = value;
                          });
                        },
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
