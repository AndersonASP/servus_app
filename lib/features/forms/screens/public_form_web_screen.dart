import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:servus_app/core/models/custom_form.dart';
import 'package:servus_app/core/network/dio_client.dart';

class PublicFormWebScreen extends StatefulWidget {
  final String formId;

  const PublicFormWebScreen({
    super.key,
    required this.formId,
  });

  @override
  State<PublicFormWebScreen> createState() => _PublicFormWebScreenState();
}

class _PublicFormWebScreenState extends State<PublicFormWebScreen> {
  final Dio _dio = DioClient.instance;
  final _formKey = GlobalKey<FormState>();
  
  CustomForm? _form;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  String? _errorMessage;
  String? _successMessage;

  // Controllers para os campos dinâmicos
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, List<String>> _multiselectValues = {};
  
  // Dados dinâmicos para ministérios e funções
  List<String> _availableFunctions = [];
  List<String> _selectedMinistries = [];
  List<String> _selectedFunctions = [];
  bool _isLoadingFunctions = false;

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  @override
  void dispose() {
    // Dispose dos controllers
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadForm() async {
    try {
      final response = await _dio.get('/forms/public/${widget.formId}/api');
      
      if (response.statusCode == 200) {
        final formData = response.data['data'];
        final form = CustomForm.fromMap(formData);
        
        // Criar controllers para os campos
        for (final field in form.fields) {
          if (field.type == FormFieldType.multiselect || 
              field.type == FormFieldType.functionMultiselect) {
            _multiselectValues[field.id] = [];
          } else {
            _controllers[field.id] = TextEditingController(
              text: field.defaultValue,
            );
          }
        }
        
        setState(() {
          _form = form;
          _isLoading = false;
        });
        
        // Os campos já vêm enriquecidos do backend via /api
        // Não precisamos carregar ministérios separadamente
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar formulário: ${e.toString()}';
        _isLoading = false;
      });
    }
  }


  Future<void> _loadAvailableFunctions(List<String> ministryIds) async {
    if (ministryIds.isEmpty) {
      setState(() {
        _availableFunctions = [];
        _selectedFunctions = [];
      });
      return;
    }

    try {
      setState(() {
        _isLoadingFunctions = true;
      });

      final ministriesParam = ministryIds.join(',');
      final response = await _dio.get('/forms/public/${widget.formId}/functions?ministries=$ministriesParam');
      
      if (response.statusCode == 200) {
        final functionsData = response.data['data'];
        
        // O backend retorna um objeto com allFunctions, não uma lista direta
        List<String> functions = [];
        if (functionsData is Map && functionsData['allFunctions'] != null) {
          final allFunctions = functionsData['allFunctions'] as List;
          functions = allFunctions.map((f) => f['label'] ?? f['value'] ?? f.toString()).cast<String>().toList();
        } else if (functionsData is List) {
          // Fallback para compatibilidade
          functions = functionsData.cast<String>().toList();
        }
        
        setState(() {
          _availableFunctions = functions;
          _selectedFunctions = []; // Reset seleções quando mudam os ministérios
          _isLoadingFunctions = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingFunctions = false;
      });
      print('Erro ao carregar funções: $e');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Preparar dados do formulário
      final Map<String, dynamic> formData = {};
      
      // Adicionar campos obrigatórios baseados nos campos do formulário
      String? volunteerName;
      String? email;
      String? phone;
      
      for (final field in _form!.fields) {
        print('Campo: ${field.label} (${field.type}) - ID: ${field.id}');
        print('Valor: ${_controllers[field.id]?.text}');
        
        final fieldValue = _controllers[field.id]?.text ?? '';
        
        // Mapear por tipo primeiro
        if (field.type == FormFieldType.email && email == null) {
          email = fieldValue;
          print('Mapeado como email: $email');
        } else if (field.type == FormFieldType.phone && phone == null) {
          phone = fieldValue;
          print('Mapeado como phone: $phone');
        } else if (field.type == FormFieldType.text && volunteerName == null) {
          // Para campos de texto, verificar se é nome
          if (field.label.toLowerCase().contains('nome') || 
              field.label.toLowerCase().contains('name') ||
              field.label.toLowerCase().contains('voluntário') ||
              field.label.toLowerCase().contains('volunteer')) {
            volunteerName = fieldValue;
            print('Mapeado como volunteerName: $volunteerName');
          }
        }
      }
      
      // Se não encontrou por tipo, usar o primeiro campo de texto como nome
      if (volunteerName == null || volunteerName.isEmpty) {
        for (final field in _form!.fields) {
          if (field.type == FormFieldType.text) {
            final fieldValue = _controllers[field.id]?.text ?? '';
            if (fieldValue.isNotEmpty) {
              volunteerName = fieldValue;
              print('Usando primeiro campo de texto como volunteerName: $volunteerName');
              break;
            }
          }
        }
      }
      
      // Adicionar campos obrigatórios
      formData['volunteerName'] = volunteerName ?? '';
      formData['email'] = email ?? '';
      formData['phone'] = phone ?? '';
      
      print('Campos obrigatórios finais:');
      print('volunteerName: ${formData['volunteerName']}');
      print('email: ${formData['email']}');
      print('phone: ${formData['phone']}');
      
      // Adicionar ministério preferido se selecionado
      if (_selectedMinistries.isNotEmpty) {
        formData['preferredMinistry'] = _selectedMinistries.first;
      }
      
      // Adicionar funções selecionadas
      if (_selectedFunctions.isNotEmpty) {
        formData['selectedFunctions'] = _selectedFunctions;
      }
      
      // Adicionar campos customizados
      for (final field in _form!.fields) {
        if (field.type == FormFieldType.multiselect || 
            field.type == FormFieldType.functionMultiselect) {
          formData[field.id] = _multiselectValues[field.id] ?? [];
        } else if (field.type == FormFieldType.ministrySelect) {
          // Já adicionado acima como preferredMinistry
          continue;
        } else {
          final controller = _controllers[field.id];
          if (controller != null) {
            formData[field.id] = controller.text;
          }
        }
      }

      print('Payload final sendo enviado: $formData');
      
      final response = await _dio.post(
        '/forms/${widget.formId}/submit',
        data: formData,
      );

      if (response.statusCode == 201) {
        setState(() {
          _isSubmitted = true;
          _successMessage = _form!.settings.successMessage.isNotEmpty 
              ? _form!.settings.successMessage
              : 'Obrigado! Sua submissão foi recebida com sucesso.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao enviar formulário: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    if (_isSubmitted) {
      return _buildSuccessScreen();
    }

    return _buildFormScreen();
  }

  Widget _buildLoadingScreen() {
    final primaryColor = _form?.settings.colorScheme.primaryColorValue ?? const Color(0xFF4058DB);
    
    return Scaffold(
      backgroundColor: primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              'Carregando formulário...',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    final primaryColor = _form?.settings.colorScheme.primaryColorValue ?? const Color(0xFF4058DB);
    
    return Scaffold(
      backgroundColor: primaryColor,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                'Erro ao carregar formulário',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Erro desconhecido',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _loadForm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    final primaryColor = _form?.settings.colorScheme.primaryColorValue ?? const Color(0xFF4058DB);
    
    return Scaffold(
      backgroundColor: primaryColor,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              Text(
                'Sucesso!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _successMessage ?? 'Formulário enviado com sucesso!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormScreen() {
    final colorScheme = _form?.settings.colorScheme;
    final primaryColor = colorScheme?.primaryColorValue ?? const Color(0xFF4058DB);
    final backgroundColor = colorScheme?.backgroundColorValue ?? Colors.white;
    
    return Scaffold(
      backgroundColor: primaryColor,
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _form!.title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_form!.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _form!.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Form
              Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Error message
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            border: Border.all(color: Colors.red[200]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[600]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red[600]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // Form fields
                      ..._form!.fields.map((field) => _buildFormField(field)),
                      
                      const SizedBox(height: 32),
                      
                      // Submit button
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4058DB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(CustomFormField field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                field.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (field.required) ...[
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
          if (field.helpText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              field.helpText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
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
          keyboardType: _getKeyboardType(field.type),
          decoration: InputDecoration(
            hintText: field.placeholder,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: field.required ? (value) {
            if (value?.isEmpty ?? true) {
              return 'Este campo é obrigatório';
            }
            return null;
          } : null,
        );

      case FormFieldType.textarea:
        return TextFormField(
          controller: _controllers[field.id],
          maxLines: 4,
          decoration: InputDecoration(
            hintText: field.placeholder,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: field.required ? (value) {
            if (value?.isEmpty ?? true) {
              return 'Este campo é obrigatório';
            }
            return null;
          } : null,
        );

      case FormFieldType.number:
        return TextFormField(
          controller: _controllers[field.id],
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: field.placeholder,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: field.required ? (value) {
            if (value?.isEmpty ?? true) {
              return 'Este campo é obrigatório';
            }
            return null;
          } : null,
        );

      case FormFieldType.date:
        return TextFormField(
          controller: _controllers[field.id],
          readOnly: true,
          decoration: InputDecoration(
            hintText: field.placeholder,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              _controllers[field.id]?.text = 
                  '${date.year.toString().padLeft(4, '0')}-'
                  '${date.month.toString().padLeft(2, '0')}-'
                  '${date.day.toString().padLeft(2, '0')}';
            }
          },
          validator: field.required ? (value) {
            if (value?.isEmpty ?? true) {
              return 'Este campo é obrigatório';
            }
            return null;
          } : null,
        );

      case FormFieldType.select:
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            hintText: field.placeholder,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: field.options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (value) {
            _controllers[field.id]?.text = value ?? '';
          },
          validator: field.required ? (value) {
            if (value?.isEmpty ?? true) {
              return 'Este campo é obrigatório';
            }
            return null;
          } : null,
        );

      case FormFieldType.multiselect:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selecione as opções:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: field.options.map((option) {
                  final isSelected = _multiselectValues[field.id]?.contains(option) ?? false;
                  return FilterChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _multiselectValues[field.id]?.add(option);
                        } else {
                          _multiselectValues[field.id]?.remove(option);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );

      case FormFieldType.ministrySelect:
        return _buildMinistrySelectField(field);

      case FormFieldType.functionMultiselect:
        return _buildFunctionMultiselectField(field);

      default:
        return TextFormField(
          controller: _controllers[field.id],
          decoration: InputDecoration(
            hintText: field.placeholder,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: field.required ? (value) {
            if (value?.isEmpty ?? true) {
              return 'Este campo é obrigatório';
            }
            return null;
          } : null,
        );
    }
  }

  TextInputType _getKeyboardType(String fieldType) {
    switch (fieldType) {
      case FormFieldType.email:
        return TextInputType.emailAddress;
      case FormFieldType.phone:
        return TextInputType.phone;
      case FormFieldType.number:
        return TextInputType.number;
      default:
        return TextInputType.text;
    }
  }

  Widget _buildMinistrySelectField(CustomFormField field) {
    // Usar os dados já enriquecidos do backend
    final options = field.options;
    
    if (options.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Nenhum ministério disponível para este formulário',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      );
    }

    // Preparar opções para o dropdown
    final dropdownItems = options.map((option) {
      // As opções vêm no formato "value|label" do backend
      final parts = option.split('|');
      final ministryId = parts.isNotEmpty ? parts[0] : option;
      final ministryName = parts.length > 1 ? parts[1] : option;
      return DropdownMenuItem<String>(
        value: ministryId,
        child: Text(ministryName),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecione o ministério de interesse:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedMinistries.isNotEmpty ? _selectedMinistries.first : null,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            hint: const Text('Escolha um ministério'),
            items: dropdownItems,
            onChanged: (String? selectedMinistryId) async {
              setState(() {
                _selectedMinistries.clear();
                if (selectedMinistryId != null) {
                  _selectedMinistries.add(selectedMinistryId);
                }
              });
              
              // Carregar funções baseadas no ministério selecionado
              await _loadAvailableFunctions(_selectedMinistries);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, selecione um ministério';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionMultiselectField(CustomFormField field) {
    if (_isLoadingFunctions) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Carregando funções...'),
          ],
        ),
      );
    }

    if (_selectedMinistries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Selecione primeiro os ministérios de interesse',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      );
    }

    if (_availableFunctions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Nenhuma função disponível para o ministério selecionado',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecione as funções de interesse:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableFunctions.map((function) {
              final isSelected = _selectedFunctions.contains(function);
              
              return _buildCustomChip(
                label: function,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedFunctions.remove(function);
                    } else {
                      _selectedFunctions.add(function);
                    }
                  });
                  
                  // Atualizar o valor do campo multiselect
                  _multiselectValues[field.id] = List.from(_selectedFunctions);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Widget personalizado para chips seguindo o padrão do sistema
  Widget _buildCustomChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).primaryColor 
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).primaryColor 
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? Colors.white 
                    : Colors.grey[700],
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
