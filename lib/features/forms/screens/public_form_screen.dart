import 'package:flutter/material.dart';
import 'package:servus_app/core/models/custom_form.dart';
import 'package:servus_app/core/models/form_submission.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/services/custom_form_service.dart';
import 'package:servus_app/services/ministry_functions_service.dart';
import 'package:servus_app/widgets/form_step_logo.dart';

class PublicFormScreen extends StatefulWidget {
  final String formId;

  const PublicFormScreen({
    super.key,
    required this.formId,
  });

  @override
  State<PublicFormScreen> createState() => _PublicFormScreenState();
}

class _PublicFormScreenState extends State<PublicFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final CustomFormService _formService = CustomFormService();
  final MinistryFunctionsService _ministryService = MinistryFunctionsService();
  
  CustomForm? _form;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  // Controllers para campos dinâmicos
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _formData = {};
  
  // Dados para seleção dinâmica
  List<Map<String, dynamic>> _availableMinistries = [];
  List<Map<String, dynamic>> _availableFunctions = [];
  int _currentStep = 0;

  final List<String> _steps = ['info', 'ministry', 'function', 'terms', 'submit'];

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  @override
  void dispose() {
    // Limpar controllers
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadForm() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final form = await _formService.getPublicForm(widget.formId);
      setState(() {
        _form = form;
        _initializeFormData();
      });
      
      // Carregar ministérios disponíveis
      await _loadMinistries();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar formulário: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMinistries() async {
    try {
      final ministries = await _ministryService.getMinistries();
      setState(() {
        _availableMinistries = ministries;
      });
    } catch (e) {
    }
  }

  Future<void> _loadMinistryFunctions(String ministryId) async {
    try {
      final functions = await _ministryService.getMinistryFunctions(ministryId);
      setState(() {
        _availableFunctions = functions;
      });
    } catch (e) {
    }
  }

  void _initializeFormData() {
    if (_form == null) return;

    for (final field in _form!.fields) {
      _controllers[field.id] = TextEditingController(text: field.defaultValue);
      _formData[field.id] = field.defaultValue;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Coletar dados dos campos
      for (final field in _form!.fields) {
        _formData[field.id] = _controllers[field.id]?.text ?? '';
      }

      // Criar dados de submissão
      final submissionData = FormSubmissionData(
        volunteerName: _formData['volunteerName'] ?? _formData['name'] ?? '',
        email: _formData['email'] ?? '',
        phone: _formData['phone'] ?? '',
        preferredMinistry: _formData['preferredMinistry'] ?? _formData['ministry'],
        preferredRole: _formData['role'] ?? 'volunteer',
        customFields: _formData,
        selectedFunctions: _formData['selectedFunctions'] ?? [],
      );

      await _formService.submitForm(widget.formId, submissionData);

      setState(() {
        _successMessage = _form!.settings.successMessage.isNotEmpty 
            ? _form!.settings.successMessage
            : 'Formulário enviado com sucesso! Aguarde a aprovação.';
      });

      // Limpar formulário após sucesso
      _clearForm();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao enviar formulário: $e';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _clearForm() {
    for (var controller in _controllers.values) {
      controller.clear();
    }
    _formData.clear();
    _initializeFormData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formulário de Cadastro'),
        backgroundColor: context.colors.primary,
        foregroundColor: context.colors.onPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: context.colors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: context.colors.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadForm,
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              : _form == null
                  ? const Center(child: Text('Formulário não encontrado'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Título e descrição
                            Text(
                              _form!.title,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.colors.onSurface,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            if (_form!.description.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                _form!.description,
                                style: TextStyle(
                                  color: context.colors.onSurface.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 32),

                            // Indicador de progresso
                            _buildProgressIndicator(),
                            const SizedBox(height: 32),

                            // Mensagem de sucesso
                            if (_successMessage != null)
                              Container(
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(bottom: 24),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _successMessage!,
                                        style: const TextStyle(color: Colors.green),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Campos do formulário
                            ..._form!.fields.map((field) => _buildField(field)),

                            const SizedBox(height: 32),

                            // Botão de envio
                            ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.colors.primary,
                                foregroundColor: context.colors.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text('Enviando...'),
                                      ],
                                    )
                                  : Text(
                                      _form!.settings.submitButtonText.isNotEmpty 
                                          ? _form!.settings.submitButtonText
                                          : 'Enviar Formulário',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildField(CustomFormField field) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.primary, // 🎨 Usar cor preta mais suave
                ),
          ),
          if (field.helpText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              field.helpText,
              style: TextStyle(
                color: context.colors.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 8),
          _buildFieldInput(field),
        ],
      ),
    );
  }

  Widget _buildFieldInput(CustomFormField field) {
    switch (field.type) {
      case FormFieldType.text:
      case FormFieldType.email:
      case FormFieldType.phone:
        return TextFormField(
          controller: _controllers[field.id],
          decoration: InputDecoration(
            hintText: field.placeholder,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: context.colors.outline.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: context.colors.primary,
                width: 2,
              ),
            ),
          ),
          keyboardType: field.type == FormFieldType.email
              ? TextInputType.emailAddress
              : field.type == FormFieldType.phone
                  ? TextInputType.phone
                  : TextInputType.text,
          validator: (value) {
            if (field.required && (value == null || value.isEmpty)) {
              return 'Este campo é obrigatório';
            }
            if (field.type == FormFieldType.email && value != null && value.isNotEmpty) {
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Email inválido';
              }
            }
            return null;
          },
          onChanged: (value) {
            _formData[field.id] = value;
            _updateStep();
          },
        );

      case FormFieldType.textarea:
        return TextFormField(
          controller: _controllers[field.id],
          decoration: InputDecoration(
            hintText: field.placeholder,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: context.colors.outline.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: context.colors.primary,
                width: 2,
              ),
            ),
          ),
          maxLines: 4,
          validator: (value) {
            if (field.required && (value == null || value.isEmpty)) {
              return 'Este campo é obrigatório';
            }
            return null;
          },
          onChanged: (value) {
            _formData[field.id] = value;
            _updateStep();
          },
        );

      case FormFieldType.select:
        return DropdownButtonFormField<String>(
          initialValue: _formData[field.id],
          decoration: InputDecoration(
            hintText: field.placeholder,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: context.colors.outline.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: context.colors.primary,
                width: 2,
              ),
            ),
          ),
          items: field.options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                style: TextStyle(
                  color: context.colors.primary, // 🎨 Usar cor primary
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _formData[field.id] = value;
            });
          },
          validator: (value) {
            if (field.required && (value == null || value.isEmpty)) {
              return 'Este campo é obrigatório';
            }
            return null;
          },
        );

      case FormFieldType.ministrySelect:
        return DropdownButtonFormField<String>(
          initialValue: _formData[field.id],
          decoration: InputDecoration(
            hintText: field.placeholder,
            border: InputBorder.none, // 🎨 Remover borda
            enabledBorder: InputBorder.none, // 🎨 Remover borda
            focusedBorder: InputBorder.none, // 🎨 Remover borda
            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12), // 🎨 Ajustar padding
          ),
          items: _availableMinistries.map((ministry) {
            final ministryId = ministry['_id'] ?? ministry['id'] ?? '';
            final ministryName = ministry['name'] ?? 'Ministério';
            return DropdownMenuItem<String>(
              value: ministryId,
              child: Text(
                ministryName,
                style: TextStyle(
                  color: context.colors.primary, // 🎨 Usar cor primary
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _formData[field.id] = value;
              _availableFunctions.clear(); // Limpar funções anteriores
            });
            if (value != null) {
              _loadMinistryFunctions(value);
            }
          },
          validator: (value) {
            if (field.required && (value == null || value.isEmpty)) {
              return 'Este campo é obrigatório';
            }
            return null;
          },
        );

      case FormFieldType.functionMultiselect:
        return DropdownButtonFormField<String>(
          initialValue: _formData[field.id],
          decoration: InputDecoration(
            hintText: field.placeholder,
            border: InputBorder.none, // 🎨 Remover borda
            enabledBorder: InputBorder.none, // 🎨 Remover borda
            focusedBorder: InputBorder.none, // 🎨 Remover borda
            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12), // 🎨 Ajustar padding
          ),
          items: _availableFunctions.map((function) {
            final functionId = function['_id'] ?? function['id'] ?? '';
            final functionName = function['name'] ?? 'Função';
            return DropdownMenuItem<String>(
              value: functionId,
              child: Text(
                functionName,
                style: TextStyle(
                  color: context.colors.primary, // 🎨 Usar cor primary
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: (_formData['preferredMinistry'] ?? _formData['ministry']) == null ? null : (value) {
            setState(() {
              _formData[field.id] = value;
            });
          },
          validator: (value) {
            if (field.required && (value == null || value.isEmpty)) {
              return 'Este campo é obrigatório';
            }
            return null;
          },
        );

      case FormFieldType.checkbox:
        return CheckboxListTile(
          title: Text(field.label),
          value: _formData[field.id] == true,
          onChanged: (value) {
            setState(() {
              _formData[field.id] = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        );

      case FormFieldType.date:
        return TextFormField(
          controller: _controllers[field.id],
          decoration: InputDecoration(
            hintText: field.placeholder,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: context.colors.outline.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: context.colors.primary,
                width: 2,
              ),
            ),
          ),
          readOnly: true,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              _controllers[field.id]?.text = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
              _formData[field.id] = date.toIso8601String();
            }
          },
          validator: (value) {
            if (field.required && (value == null || value.isEmpty)) {
              return 'Este campo é obrigatório';
            }
            return null;
          },
        );

      default:
        return TextFormField(
          controller: _controllers[field.id],
          decoration: InputDecoration(
            hintText: field.placeholder,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (field.required && (value == null || value.isEmpty)) {
              return 'Este campo é obrigatório';
            }
            return null;
          },
          onChanged: (value) {
            _formData[field.id] = value;
            _updateStep();
          },
        );
    }
  }

  Widget _buildProgressIndicator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Progresso do Formulário',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            FormProgressIndicator(
              steps: _steps,
              currentStep: _currentStep,
            ),
            const SizedBox(height: 16),
            Text(
              _getStepTitle(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getStepDescription(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Informações Pessoais';
      case 1:
        return 'Escolha do Ministério';
      case 2:
        return 'Função no Ministério';
      case 3:
        return 'Termos de Uso';
      case 4:
        return 'Envio do Formulário';
      default:
        return 'Informações Pessoais';
    }
  }

  String _getStepDescription() {
    switch (_currentStep) {
      case 0:
        return 'Preencha seus dados pessoais básicos';
      case 1:
        return 'Selecione o ministério de seu interesse';
      case 2:
        return 'Escolha a função que deseja exercer';
      case 3:
        return 'Leia e aceite os termos de uso';
      case 4:
        return 'Revise e envie seu formulário';
      default:
        return 'Preencha seus dados pessoais básicos';
    }
  }

  void _updateStep() {
    // Atualizar step baseado nos campos preenchidos
    final name = _formData['volunteerName'] ?? _formData['name'];
    final email = _formData['email'];
    final ministry = _formData['preferredMinistry'] ?? _formData['ministry'];
    final functions = _formData['selectedFunctions'] ?? _formData['function'];
    
    if (name != null && name.toString().isNotEmpty &&
        email != null && email.toString().isNotEmpty) {
      if (_currentStep < 1) {
        setState(() {
          _currentStep = 1;
        });
      }
    }

    if (ministry != null && ministry.toString().isNotEmpty) {
      if (_currentStep < 2) {
        setState(() {
          _currentStep = 2;
        });
      }
    }

    if (functions != null && functions.toString().isNotEmpty) {
      if (_currentStep < 3) {
        setState(() {
          _currentStep = 3;
        });
      }
    }

    if (_formData['agreedToTerms'] == true) {
      if (_currentStep < 4) {
        setState(() {
          _currentStep = 4;
        });
      }
    }
  }
}
