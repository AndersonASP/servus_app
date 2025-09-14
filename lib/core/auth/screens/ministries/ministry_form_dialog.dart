import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/features/ministries/controllers/ministry_controller.dart';
import 'package:servus_app/features/ministries/models/ministry_dto.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';

class MinistryFormDialog extends StatefulWidget {
  final MinistryResponse? ministry;

  const MinistryFormDialog({
    super.key,
    this.ministry,
  });

  @override
  State<MinistryFormDialog> createState() => _MinistryFormDialogState();
}

class _MinistryFormDialogState extends State<MinistryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _functionController = TextEditingController();
  
  List<String> _ministryFunctions = [];
  bool _isActive = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.ministry != null) {
      _nameController.text = widget.ministry!.name;
      _descriptionController.text = widget.ministry!.description ?? '';
      _ministryFunctions = List.from(widget.ministry!.ministryFunctions);
      // Carregar funções no campo de texto
      if (_ministryFunctions.isNotEmpty) {
        _functionController.text = _ministryFunctions.join(', ');
      }
      _isActive = widget.ministry!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _functionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.ministry != null;
    
    return AlertDialog(
      title: Text(isEditing ? 'Editar Ministério' : 'Criar Ministério'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nome do ministério
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Ministério *',
                  hintText: 'Ex: Ministério de Música',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome é obrigatório';
                  }
                  if (value.trim().length < 3) {
                    return 'Nome deve ter pelo menos 3 caracteres';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Descrição
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Descreva o propósito do ministério',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 200,
              ),
              
              const SizedBox(height: 16),
              
              // Funções do ministério
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Funções do Ministério',
                    style: context.textStyles.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  
                  // Lista de funções
                  if (_ministryFunctions.isNotEmpty) ...[
                    Text(
                      'Funções que serão adicionadas:',
                      style: context.textStyles.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _ministryFunctions.map((function) => Chip(
                        label: Text(function),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            _ministryFunctions.remove(function);
                            // Atualizar o texto do campo
                            _functionController.text = _ministryFunctions.join(', ');
                          });
                        },
                      )).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  const SizedBox(height: 8),
                  
                  // Campo para múltiplas funções
                  TextFormField(
                    controller: _functionController,
                    decoration: const InputDecoration(
                      labelText: 'Funções do Ministério',
                      hintText: 'Digite as funções separadas por vírgula (Ex: Baixista, Tecladista, Sonoplasta)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    maxLines: 3,
                    onChanged: _processFunctionsInput,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Status ativo/inativo
              SwitchListTile(
                title: const Text('Ministério Ativo'),
                subtitle: Text(_isActive ? 'Ministério está funcionando' : 'Ministério está inativo'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitForm,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Atualizar' : 'Criar'),
        ),
      ],
    );
  }

  void _processFunctionsInput(String input) {
    if (input.trim().isEmpty) {
      setState(() {
        _ministryFunctions.clear();
      });
      return;
    }

    // Processar funções separadas por vírgula, ponto e vírgula ou quebra de linha
    final functions = input
        .split(RegExp(r'[,;\n]'))
        .map((f) => f.trim())
        .where((f) => f.isNotEmpty)
        .toSet() // Remove duplicatas
        .toList();

    setState(() {
      _ministryFunctions = functions;
    });
  }

  void _addFunction(String function) {
    if (function.trim().isNotEmpty) {
      setState(() {
        _ministryFunctions.add(function.trim());
        _functionController.clear();
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final controller = context.read<MinistryController>();
      final success = widget.ministry != null
          ? await controller.updateMinistry(
              widget.ministry!.id,
              UpdateMinistryDto(
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
                ministryFunctions: _ministryFunctions,
                isActive: _isActive,
              ),
            )
          : await controller.createMinistry(
              CreateMinistryDto(
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
                ministryFunctions: _ministryFunctions,
                isActive: _isActive,
              ),
            );

      if (success) {
        Navigator.of(context).pop();
        showServusSnack(
          context,
          message: widget.ministry != null
              ? 'Ministério atualizado com sucesso!'
              : 'Ministério criado com sucesso!',
          type: ServusSnackType.success,
        );
      }
    } catch (e) {
      showServusSnack(
        context,
        message: 'Erro: ${e.toString()}',
        type: ServusSnackType.error,
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
} 