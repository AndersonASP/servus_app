import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/escalas/controllers/template/template_controller.dart';
import 'package:servus_app/features/leader/escalas/models/template_model.dart';

class TemplateFormScreen extends StatefulWidget {
  final TemplateModel? templateExistente;

  const TemplateFormScreen({super.key, this.templateExistente});

  @override
  State<TemplateFormScreen> createState() => _TemplateFormScreenState();
}

class _TemplateFormScreenState extends State<TemplateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController observacoesController = TextEditingController();

  final List<FuncaoEscala> funcoes = [];
  final List<String> ministeriosMock = [
    'Louvor',
    'Mídia',
    'Acolhimento',
    'Diaconato',
  ];

  @override
  void initState() {
    super.initState();
    final template = widget.templateExistente;
    if (template != null) {
      nomeController.text = template.nome;
      observacoesController.text = template.observacoes ?? '';
      funcoes.addAll(template.funcoes.map((f) => f.copyWith()));
    }
  }

  void _salvar() {
    if (_formKey.currentState!.validate() && funcoes.isNotEmpty) {
      final template = TemplateModel(
        id: widget.templateExistente?.id,
        nome: nomeController.text,
        funcoes: funcoes,
        observacoes: observacoesController.text,
      );

      final controller = context.read<TemplateController>();
      if (widget.templateExistente == null) {
        controller.adicionarTemplate(template);
      } else {
        controller.atualizarTemplate(template);
      }

      Navigator.pop(context);
    }
  }

  void _adicionarFuncao() {
    setState(() {
      funcoes.add(FuncaoEscala(

        nome: '',
        ministerioId: '',
        quantidade: 1,
      ));
    });
  }

  void _removerFuncao(int index) {
    setState(() {
      funcoes.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          widget.templateExistente == null ? 'Novo Template' : 'Editar Template',
          style: context.textStyles.titleLarge?.copyWith(
            color: context.colors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _salvar,
        label:  Text('Salvar', style: context.textStyles.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: context.colors.onPrimary,
        )),
        icon: const Icon(Icons.check),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome do template'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: observacoesController,
                decoration: const InputDecoration(labelText: 'Observações'),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              const Text(
                'Funções',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (funcoes.isEmpty)
                const Text('Nenhuma função adicionada ainda.'),
              ...funcoes.asMap().entries.map((entry) {
                final index = entry.key;
                final funcao = entry.value;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: funcao.nome,
                          decoration: const InputDecoration(labelText: 'Nome da função'),
                          onChanged: (value) => setState(() {
                            funcoes[index] = funcao.copyWith(nome: value);
                          }),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Obrigatório' : null,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: funcao.ministerioId.isEmpty ? null : funcao.ministerioId,
                          decoration: const InputDecoration(labelText: 'Ministério'),
                          items: ministeriosMock
                              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                              .toList(),
                          onChanged: (value) => setState(() {
                            funcoes[index] = funcao.copyWith(ministerioId: value!);
                          }),
                          validator: (value) =>
                              value == null ? 'Obrigatório' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: funcao.quantidade.toString(),
                          decoration: const InputDecoration(labelText: 'Quantidade'),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final qtd = int.tryParse(value) ?? 1;
                            setState(() {
                              funcoes[index] = funcao.copyWith(quantidade: qtd);
                            });
                          },
                          validator: (value) {
                            final qtd = int.tryParse(value ?? '');
                            if (qtd == null || qtd <= 0) {
                              return 'Informe um número válido';
                            }
                            return null;
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            onPressed: () => _removerFuncao(index),
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _adicionarFuncao,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar função'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}