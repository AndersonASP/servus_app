import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/core/models/custom_form.dart';
import 'package:servus_app/services/custom_form_service.dart';
import 'package:servus_app/services/ministry_functions_service.dart';
import 'package:servus_app/services/auth_context_service.dart';
import 'package:servus_app/widgets/form_step_logo.dart';

class CreateCustomFormScreen extends StatefulWidget {
  const CreateCustomFormScreen({super.key});

  @override
  State<CreateCustomFormScreen> createState() => _CreateCustomFormScreenState();
}

class _CreateCustomFormScreenState extends State<CreateCustomFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final CustomFormService _formService = CustomFormService();
  final MinistryFunctionsService _ministryService = MinistryFunctionsService();
  final AuthContextService _authContext = AuthContextService.instance;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _successMessageController = TextEditingController();

  List<CustomFormField> _fields = [];
  List<Map<String, dynamic>> _availableMinistries = [];
  List<String> _selectedMinistries = [];
  bool _isLoading = false;
  int _currentStep = 0;

  final List<String> _steps = ['info', 'ministry', 'fields', 'messages'];

  @override
  void initState() {
    super.initState();
    _initializeContext();
    _loadMinistries();
    _addDefaultFields();
  }

  void _initializeContext() {
    // Verificar se já existe contexto válido
    if (_authContext.hasContext) {
      return;
    }
    
    // Tentar obter contexto através do AuthIntegrationService
    // Este método deve ser chamado quando o usuário faz login
    
    // Se não há contexto válido, não podemos prosseguir
    throw Exception('Usuário não autenticado. Faça login primeiro.');
  }

  Future<void> _loadMinistries() async {
    try {
      final ministries = await _ministryService.getMinistries();
      setState(() {
        _availableMinistries = ministries;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar ministérios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addDefaultFields() {
    setState(() {
      _fields = [
        // Nome completo
        CustomFormField(
          id: 'name',
          label: 'Nome Completo',
          type: FormFieldType.text,
          required: true,
          placeholder: 'Digite seu nome completo',
          helpText: 'Nome completo como aparece no documento',
          order: 1,
          isSelected: true, // Campo padrão sempre selecionado
        ),
        // Email
        CustomFormField(
          id: 'email',
          label: 'Email',
          type: FormFieldType.email,
          required: true,
          placeholder: 'seu@email.com',
          helpText: 'Email para contato e notificações',
          order: 2,
          isSelected: true, // Campo padrão sempre selecionado
        ),
        // Telefone
        CustomFormField(
          id: 'phone',
          label: 'Telefone',
          type: FormFieldType.phone,
          required: true,
          placeholder: '(11) 99999-9999',
          helpText: 'Telefone com DDD',
          order: 3,
          isSelected: true, // Campo padrão sempre selecionado
        ),
        // Seleção de ministérios (múltipla escolha)
        CustomFormField(
          id: 'ministries',
          label: 'Ministérios de Interesse',
          type: FormFieldType.multiselect,
          required: true,
          placeholder: 'Selecione os ministérios',
          helpText: 'Escolha os ministérios onde deseja servir',
          order: 4,
          isSelected: true, // Campo padrão sempre selecionado
        ),
        // Seleção de funções (múltipla escolha)
        CustomFormField(
          id: 'functions',
          label: 'Funções de Interesse',
          type: FormFieldType.multiselect,
          required: true,
          placeholder: 'Selecione as funções',
          helpText: 'Escolha as funções que deseja exercer',
          order: 5,
          isSelected: true, // Campo padrão sempre selecionado
        ),
      ];
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _successMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/leader/forms'),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            'Criar Formulário Personalizado',
            style: context.textStyles.titleLarge?.copyWith(
              color: context.colors.onSurface,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveForm,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressIndicator(),
              const SizedBox(height: 32),
              _buildCurrentStep(),
              const SizedBox(height: 32),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Configuração do Formulário',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoSection();
      case 1:
        return _buildMinistriesSection();
      case 2:
        return _buildFieldsSection();
      case 3:
        return _buildMessagesSection();
      default:
        return _buildBasicInfoSection();
    }
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          OutlinedButton(
            onPressed: _previousStep,
            child: const Text('Anterior'),
          )
        else
          const SizedBox.shrink(),
        if (_currentStep < _steps.length - 1)
          ElevatedButton(
            onPressed: _nextStep,
            child: const Text('Próximo'),
          )
        else
          ElevatedButton(
            onPressed: _isLoading ? null : _saveForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Criar Formulário'),
          ),
      ],
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Informações Básicas';
      case 1:
        return 'Ministérios Disponíveis';
      case 2:
        return 'Campos do Formulário';
      case 3:
        return 'Mensagens Personalizadas';
      default:
        return 'Informações Básicas';
    }
  }

  String _getStepDescription() {
    switch (_currentStep) {
      case 0:
        return 'Configure o título e descrição do formulário';
      case 1:
        return 'Selecione os ministérios disponíveis no formulário';
      case 2:
        return 'Revise os campos padrão incluídos automaticamente';
      case 3:
        return 'Personalize as mensagens de sucesso';
      default:
        return 'Configure o título e descrição do formulário';
    }
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações Básicas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título do Formulário',
                hintText: 'Ex: Formulário de Inscrição - Evento Especial',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Título é obrigatório';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                hintText: 'Descreva o propósito do formulário',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinistriesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ministérios Disponíveis',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecione os ministérios disponíveis no formulário',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colors.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            if (_availableMinistries.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('Carregando ministérios...'),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableMinistries.map((ministry) {
                  final ministryId = ministry['_id'] ?? ministry['id'] ?? '';
                  final ministryName = ministry['name'] ?? 'Ministério';
                  final isSelected = _selectedMinistries.contains(ministryId);
                  
                  return _buildCustomChip(
                    label: ministryName,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedMinistries.remove(ministryId);
                        } else {
                          _selectedMinistries.add(ministryId);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            if (_selectedMinistries.isEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Selecione pelo menos um ministério',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldsSection() {
    return Column(
      children: [
        // Campos Padrão
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Campos Padrão do Formulário',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Estes campos são incluídos automaticamente em todos os formulários',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                ..._fields.take(5).map((field) => _buildFieldCard(field)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Campos Personalizados
        _buildCustomFieldsSection(),
      ],
    );
  }

  Widget _buildCustomFieldsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Campos Personalizados (Opcionais)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _addCustomField,
                  icon: const Icon(Icons.add),
                  tooltip: 'Adicionar Campo Personalizado',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione campos específicos para coletar informações adicionais',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colors.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            // Mostrar campos personalizados se existirem
            if (_fields.length > 5) ...[
              ..._fields.skip(5).map((field) => _buildFieldCard(field)),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.colors.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 32,
                      color: context.colors.outline,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nenhum campo personalizado',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Clique no botão + para adicionar campos específicos',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mensagens Personalizadas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _successMessageController,
              decoration: const InputDecoration(
                labelText: 'Mensagem de Sucesso',
                hintText: 'Ex: Obrigado! Seu cadastro foi enviado com sucesso. Aguarde a aprovação.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldCard(CustomFormField field) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: field.isSelected 
            ? context.colors.primaryContainer.withOpacity(0.3)
            : context.colors.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: field.isSelected 
              ? context.colors.primary.withOpacity(0.5)
              : context.colors.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Checkbox para alternar seleção
          Checkbox(
            value: field.isSelected,
            onChanged: (value) {
              setState(() {
                final index = _fields.indexWhere((f) => f.id == field.id);
                if (index != -1) {
                  _fields[index] = CustomFormField(
                    id: field.id,
                    label: field.label,
                    type: field.type,
                    required: field.required,
                    placeholder: field.placeholder,
                    helpText: field.helpText,
                    options: field.options,
                    defaultValue: field.defaultValue,
                    order: field.order,
                    isSelected: value ?? false,
                  );
                }
              });
            },
          ),
          Icon(
            _getFieldIcon(field.type),
            size: 20,
            color: field.isSelected 
                ? context.colors.primary
                : context.colors.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: field.isSelected 
                        ? context.colors.onSurface
                        : context.colors.onSurface.withOpacity(0.7),
                  ),
                ),
                if (field.helpText.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    field.helpText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (field.required)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Obrigatório',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }


  void _addCustomField() {
    showDialog(
      context: context,
      builder: (context) => _AddCustomFieldDialog(
        onFieldAdded: (field) {
          setState(() {
            _fields.add(field);
          });
        },
      ),
    );
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedMinistries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um ministério'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final form = CustomForm(
        id: '',
        title: _titleController.text,
        description: _descriptionController.text,
        tenantId: '', // TODO: Obter do contexto de autenticação
        createdBy: '', // TODO: Obter do contexto de autenticação
        fields: _fields.where((field) => field.isSelected).toList(),
        availableMinistries: _selectedMinistries,
        availableRoles: [], // Roles serão definidos pelos campos personalizados
        settings: FormSettings(
          allowMultipleSubmissions: false,
          requireApproval: true, // Sempre requer aprovação
          showProgress: true,
          successMessage: _successMessageController.text.isNotEmpty 
              ? _successMessageController.text
              : 'Obrigado! Seu cadastro foi enviado com sucesso. Aguarde a aprovação do líder do ministério.',
          submitButtonText: 'Enviar Cadastro',
        ),
        isActive: true,
        isPublic: true, // Formulário público
        submissionCount: 0,
        approvedCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _formService.createForm(form);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Formulário personalizado criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar formulário: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  IconData _getFieldIcon(String type) {
    switch (type) {
      case FormFieldType.text:
        return Icons.text_fields;
      case FormFieldType.email:
        return Icons.email;
      case FormFieldType.phone:
        return Icons.phone;
      case FormFieldType.date:
        return Icons.calendar_today;
      case FormFieldType.ministrySelect:
        return Icons.church;
      case FormFieldType.functionMultiselect:
        return Icons.work;
      case FormFieldType.checkbox:
        return Icons.check_box;
      default:
        return Icons.text_fields;
    }
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

class _AddCustomFieldDialog extends StatefulWidget {
  final Function(CustomFormField) onFieldAdded;

  const _AddCustomFieldDialog({
    required this.onFieldAdded,
  });

  @override
  State<_AddCustomFieldDialog> createState() => _AddCustomFieldDialogState();
}

class _AddCustomFieldDialogState extends State<_AddCustomFieldDialog> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _placeholderController = TextEditingController();
  final _helpTextController = TextEditingController();
  
  String _selectedType = FormFieldType.text;
  bool _isRequired = false;
  int _order = 10; // Começar após os campos padrão

  final List<String> _fieldTypes = [
    FormFieldType.text,
    FormFieldType.email,
    FormFieldType.phone,
    FormFieldType.textarea,
    FormFieldType.date,
    FormFieldType.number,
    FormFieldType.checkbox,
    FormFieldType.select,
  ];

  @override
  void dispose() {
    _labelController.dispose();
    _placeholderController.dispose();
    _helpTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar Campo Personalizado'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Campo',
                  hintText: 'Ex: Data de Nascimento',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nome do campo é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipo do Campo',
                ),
                items: _fieldTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getFieldTypeLabel(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _placeholderController,
                decoration: const InputDecoration(
                  labelText: 'Texto de Ajuda (Opcional)',
                  hintText: 'Ex: Digite sua data de nascimento',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _helpTextController,
                decoration: const InputDecoration(
                  labelText: 'Texto Explicativo (Opcional)',
                  hintText: 'Ex: Esta informação será usada para...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _isRequired,
                    onChanged: (value) {
                      setState(() {
                        _isRequired = value ?? false;
                      });
                    },
                  ),
                  const Text('Campo obrigatório'),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _addField,
          child: const Text('Adicionar'),
        ),
      ],
    );
  }

  String _getFieldTypeLabel(String type) {
    switch (type) {
      case FormFieldType.text:
        return 'Texto';
      case FormFieldType.email:
        return 'Email';
      case FormFieldType.phone:
        return 'Telefone';
      case FormFieldType.textarea:
        return 'Texto Longo';
      case FormFieldType.date:
        return 'Data';
      case FormFieldType.number:
        return 'Número';
      case FormFieldType.checkbox:
        return 'Caixa de Seleção';
      case FormFieldType.select:
        return 'Lista de Seleção';
      default:
        return 'Texto';
    }
  }

  void _addField() {
    if (_formKey.currentState!.validate()) {
      final field = CustomFormField(
        id: _labelController.text.toLowerCase().replaceAll(' ', '_'),
        label: _labelController.text,
        type: _selectedType,
        required: _isRequired,
        placeholder: _placeholderController.text,
        helpText: _helpTextController.text,
        order: _order,
        isSelected: false, // Campos personalizados não selecionados por padrão
      );
      
      widget.onFieldAdded(field);
      Navigator.of(context).pop();
    }
  }
}
