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

  void _salvar() async {
    if (_formKey.currentState!.validate() && funcoes.isNotEmpty) {
      final template = TemplateModel(
        id: widget.templateExistente?.id,
        nome: nomeController.text,
        funcoes: funcoes,
        observacoes: observacoesController.text,
      );

      final controller = context.read<TemplateController>();
      try {
        if (widget.templateExistente == null) {
          await controller.adicionarTemplate(template);
        } else {
          await controller.atualizarTemplate(template);
        }
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (funcoes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos uma função ao template'),
          backgroundColor: Colors.orange,
        ),
      );
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
      floatingActionButton: Consumer<TemplateController>(
        builder: (context, controller, _) {
          return FloatingActionButton.extended(
            onPressed: controller.isLoading ? null : _salvar,
            label: Text(
              controller.isLoading ? 'Salvando...' : 'Salvar', 
              style: context.textStyles.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.onPrimary,
              )
            ),
            icon: controller.isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.check),
          );
        },
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
                        Consumer<TemplateController>(
                          builder: (context, controller, _) {
                            if (controller.isLoadingMinistries) {
                              return DropdownButtonFormField<String>(
                                decoration: const InputDecoration(labelText: 'Ministério'),
                                items: const [],
                                hint: const Text('Carregando ministérios...'),
                                onChanged: null,
                              );
                            }
                            
                            if (!controller.hasMinistries) {
                              return DropdownButtonFormField<String>(
                                decoration: const InputDecoration(labelText: 'Ministério'),
                                items: const [],
                                hint: const Text('Nenhum ministério encontrado'),
                                onChanged: null,
                              );
                            }
                            
                            return DropdownButtonFormField<String>(
                              initialValue: funcao.ministerioId.isEmpty ? null : funcao.ministerioId,
                              decoration: const InputDecoration(labelText: 'Ministério'),
                              items: controller.ministerios
                                  .map((m) => DropdownMenuItem(
                                    value: m.id, 
                                    child: Text(m.name),
                                  ))
                                  .toList(),
                              onChanged: (value) => setState(() {
                                funcoes[index] = funcao.copyWith(ministerioId: value!);
                              }),
                              validator: (value) =>
                                  value == null ? 'Obrigatório' : null,
                            );
                          },
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