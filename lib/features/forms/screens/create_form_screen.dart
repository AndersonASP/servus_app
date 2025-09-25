import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/core/models/custom_form.dart';
import 'package:servus_app/services/custom_form_service.dart';
import 'package:servus_app/services/ministry_functions_service.dart';
import 'package:servus_app/services/auth_context_service.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';

class CreateFormScreen extends StatefulWidget {
  const CreateFormScreen({super.key});

  @override
  State<CreateFormScreen> createState() => _CreateFormScreenState();
}

class _CreateFormScreenState extends State<CreateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final CustomFormService _formService = CustomFormService();
  final MinistryFunctionsService _ministryService = MinistryFunctionsService();
  final AuthContextService _authContext = AuthContextService.instance;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _successMessageController = TextEditingController();
  final _submitButtonTextController = TextEditingController();

  // Controllers para cores
  final _primaryColorController = TextEditingController(text: '#4058DB');
  final _backgroundColorController = TextEditingController(text: '#FFFFFF');
  final _textColorController = TextEditingController(text: '#1F2937');

  List<CustomFormField> _fields = [];
  List<String> _availableMinistries = [];
  List<String> _selectedMinistries = [];
  List<String> _selectedRoles = ['volunteer'];
  Map<String, String> _ministryNames = {}; // Map de ID para nome

  bool _isPublic = true;
  bool _requireApproval = false;
  bool _allowMultipleSubmissions = true;
  bool _showProgress = true;
  bool _isLoading = false;

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
        _availableMinistries =
            ministries.map((ministry) => ministry['_id'] as String).toList();
        _ministryNames = Map.fromEntries(
          ministries.map((ministry) => MapEntry(
                ministry['_id'] as String,
                ministry['name'] as String,
              )),
        );
      });
    } catch (e) {
      setState(() {
        _availableMinistries = [];
      });
    }
  }

  void _addDefaultFields() {
    setState(() {
      _fields = [
        // Nome completo
        CustomFormField(
          id: 'volunteerName',
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
        // 🆕 Data de nascimento
        CustomFormField(
          id: 'birthDate',
          label: 'Data de Nascimento',
          type: FormFieldType.date,
          required: true,
          placeholder: 'DD/MM/AAAA',
          helpText: 'Data de nascimento completa',
          order: 4,
          isSelected: true, // Campo padrão sempre selecionado
        ),
        // Seleção de ministérios (tipo específico)
        CustomFormField(
          id: 'preferredMinistry',
          label: 'Ministério de Interesse',
          type: FormFieldType.ministrySelect,
          required: true,
          placeholder: 'Selecione um ministério',
          helpText: 'Escolha o ministério onde deseja servir',
          order: 5,
          isSelected: true, // Campo padrão sempre selecionado
        ),
        // Seleção de funções (tipo específico)
        CustomFormField(
          id: 'selectedFunctions',
          label: 'Funções de Interesse',
          type: FormFieldType.functionMultiselect,
          required: true,
          placeholder: 'Selecione as funções',
          helpText: 'Escolha as funções que deseja exercer',
          order: 6,
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
    _submitButtonTextController.dispose();
    
    // Dispose dos controllers de cores
    _primaryColorController.dispose();
    _backgroundColorController.dispose();
    _textColorController.dispose();
    
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
            'Criar Formulário',
            style: context.textStyles.titleLarge?.copyWith(
              color: context.colors.onSurface,
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildFieldsSection(),
              const SizedBox(height: 24),
              _buildMinistriesSection(),
              const SizedBox(height: 24),
              _buildSettingsSection(),
              const SizedBox(height: 24),
              _buildColorCustomizationSection(),
              const SizedBox(height: 24),
              _buildAdvancedSettingsSection(),
              const SizedBox(height: 100), // Espaço para o FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _saveForm,
        backgroundColor: context.colors.primary,
        foregroundColor: context.colors.onPrimary,
        tooltip: 'Salvar Formulário',
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isLoading ? 'Salvando...' : 'Salvar'),
      ),
    );
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
                hintText: 'Ex: Cadastro de Voluntários',
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

  Widget _buildFieldsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Campos do Formulário',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurface,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _addField,
                  icon: const Icon(Icons.add),
                  tooltip: 'Adicionar Campo',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_fields.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color:
                      context.colors.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.colors.outline.withOpacity(0.2),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 48,
                      color: context.colors.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhum campo adicionado',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: context.colors.onSurface,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Adicione campos para coletar informações',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.colors.onSurface.withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              )
            else
              ..._fields.asMap().entries.map((entry) {
                final index = entry.key;
                final field = entry.value;
                return _buildFieldCard(field, index);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldCard(CustomFormField field, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.colors.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  field.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurface,
                      ),
                ),
              ),
              Icon(
                _getFieldIcon(field.type),
                size: 16,
                color: context.colors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                _getFieldTypeLabel(field.type),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.primary,
                    ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _removeField(index),
                icon: const Icon(Icons.delete, size: 20),
                color: Colors.red,
                tooltip: 'Remover Campo',
              ),
            ],
          ),
          if (field.required)
            Container(
              margin: const EdgeInsets.only(top: 4),
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
              'Selecione os ministérios que os voluntários podem escolher',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurface.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _availableMinistries.map((ministryId) {
                final isSelected = _selectedMinistries.contains(ministryId);
                final ministryName = _ministryNames[ministryId] ?? ministryId;
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? context.colors.primary.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: _buildCustomChip(
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
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configurações',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.onSurface,
                  ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Formulário Público'),
              subtitle: const Text('Permite acesso sem autenticação'),
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value),
            ),
            SwitchListTile(
              title: const Text('Requer Aprovação'),
              subtitle: const Text('Submissões precisam ser aprovadas'),
              value: _requireApproval,
              onChanged: (value) => setState(() => _requireApproval = value),
            ),
            SwitchListTile(
              title: const Text('Múltiplas Submissões'),
              subtitle:
                  const Text('Permite o mesmo email submeter várias vezes'),
              value: _allowMultipleSubmissions,
              onChanged: (value) =>
                  setState(() => _allowMultipleSubmissions = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorCustomizationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personalização de Cores',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Personalize as cores do formulário público',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurface.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 16),
            
            // Preview das cores
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getColorFromHex(_backgroundColorController.text),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.colors.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  // Header preview
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getColorFromHex(_primaryColorController.text),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Título do Formulário',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Descrição do formulário',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Campo preview
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Campo de Exemplo',
                      hintText: 'Digite aqui...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: TextStyle(
                      color: _getColorFromHex(_textColorController.text),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Botão preview
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getColorFromHex(_primaryColorController.text),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Botão de Exemplo'),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Controles de cores simplificados
            _buildColorSelector(
              'Cor Primária',
              _primaryColorController,
              Icons.palette,
            ),
            
            const SizedBox(height: 16),
            
            _buildColorSelector(
              'Fundo',
              _backgroundColorController,
              Icons.format_color_fill,
            ),
            
            const SizedBox(height: 16),
            
            _buildColorSelector(
              'Texto',
              _textColorController,
              Icons.text_fields,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSelector(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: context.colors.onSurface,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Quadrado de cor clicável
            GestureDetector(
              onTap: () => _showColorPicker(controller),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getColorFromHex(controller.text),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.colors.outline.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Campo de texto para código hex
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: '#000000',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (value) {
                  setState(() {}); // Atualizar preview
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showColorPicker(TextEditingController controller) {
    final tempController = TextEditingController(text: controller.text);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Escolher Cor', style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.onSurface)),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Paleta de cores predefinidas
              _buildColorPalette(tempController),
              const SizedBox(height: 16),
              // Campo para inserir código hex personalizado
              TextFormField(
                controller: tempController,
                decoration: const InputDecoration(
                  labelText: 'Código Hex',
                  hintText: '#000000',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && value.startsWith('#')) {
                    // Atualizar o controller temporário
                    tempController.text = value;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // Aplicar a cor selecionada ao controller original
              controller.text = tempController.text;
              setState(() {});
              Navigator.of(context).pop();
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPalette(TextEditingController controller) {
    final colors = [
      '#4058DB', '#667eea', '#FF6B6B', '#4ECDC4', '#45B7D1',
      '#96CEB4', '#FFEAA7', '#DDA0DD', '#98D8C8', '#F7DC6F',
      '#BB8FCE', '#85C1E9', '#F8C471', '#82E0AA', '#F1948A',
      '#000000', '#333333', '#666666', '#999999', '#CCCCCC',
      '#FFFFFF', '#FF0000', '#00FF00', '#0000FF', '#FFFF00',
    ];

    return StatefulBuilder(
      builder: (context, setState) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((color) {
            final isSelected = controller.text.toUpperCase() == color.toUpperCase();
            return GestureDetector(
              onTap: () {
                controller.text = color;
                setState(() {}); // Atualizar apenas o StatefulBuilder
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getColorFromHex(color),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey[300]!,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Color _getColorFromHex(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return const Color(0xFF4058DB); // Cor padrão em caso de erro
    }
  }

  Widget _buildAdvancedSettingsSection() {
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
                hintText: 'Ex: Obrigado! Sua submissão foi recebida.',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _submitButtonTextController,
              decoration: const InputDecoration(
                labelText: 'Texto do Botão de Envio',
                hintText: 'Ex: Enviar Formulário',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addField() {
    _showAddFieldDialog();
  }

  Future<void> _showAddFieldDialog() async {
    final result = await showDialog<CustomFormField>(
      context: context,
      builder: (context) => _AddFieldDialog(
        availableMinistries: _availableMinistries,
        fieldOrder: _fields.length,
      ),
    );

    if (result != null) {
      setState(() {
        _fields.add(result);
      });
    }
  }

  void _removeField(int index) {
    setState(() {
      _fields.removeAt(index);
    });
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Filtrar apenas campos selecionados
      final selectedFields =
          _fields.where((field) => field.isSelected).toList();

      final form = CustomForm(
        id: '',
        title: _titleController.text,
        description: _descriptionController.text,
        tenantId: _authContext.tenantId ?? '',
        createdBy: _authContext.userId ?? '',
        fields: selectedFields,
        availableMinistries: _selectedMinistries,
        availableRoles: _selectedRoles,
        settings: FormSettings(
          allowMultipleSubmissions: _allowMultipleSubmissions,
          requireApproval: _requireApproval,
          showProgress: _showProgress,
          successMessage: _successMessageController.text,
          submitButtonText: _submitButtonTextController.text,
          colorScheme: FormColorScheme(
            primaryColor: _primaryColorController.text,
            backgroundColor: _backgroundColorController.text,
            textColor: _textColorController.text,
          ),
        ),
        isActive: true,
        isPublic: _isPublic,
        submissionCount: 0,
        approvedCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _formService.createForm(form);

      if (mounted) {
        showSuccess(context, 'Formulário criado com sucesso!',
            title: 'Sucesso!');
        context.go('/forms?refresh=true&t=${DateTime.now().millisecondsSinceEpoch}');
      }
    } catch (e) {
      if (mounted) {
        showError(context, 'Erro ao criar formulário: $e', title: 'Erro');
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
      case FormFieldType.select:
        return Icons.arrow_drop_down;
      case FormFieldType.multiselect:
        return Icons.checklist;
      case FormFieldType.textarea:
        return Icons.notes;
      case FormFieldType.date:
        return Icons.calendar_today;
      case FormFieldType.number:
        return Icons.numbers;
      case FormFieldType.checkbox:
        return Icons.check_box;
      case FormFieldType.ministrySelect:
        return Icons.church;
      case FormFieldType.functionMultiselect:
        return Icons.work;
      default:
        return Icons.text_fields;
    }
  }

  String _getFieldTypeLabel(String type) {
    switch (type) {
      case FormFieldType.text:
        return 'Texto';
      case FormFieldType.email:
        return 'Email';
      case FormFieldType.phone:
        return 'Telefone';
      case FormFieldType.select:
        return 'Seleção';
      case FormFieldType.multiselect:
        return 'Múltipla Seleção';
      case FormFieldType.textarea:
        return 'Texto Longo';
      case FormFieldType.date:
        return 'Data';
      case FormFieldType.number:
        return 'Número';
      case FormFieldType.checkbox:
        return 'Checkbox';
      case FormFieldType.ministrySelect:
        return 'Ministério';
      case FormFieldType.functionMultiselect:
        return 'Função';
      default:
        return 'Texto';
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
          color: isSelected ? Theme.of(context).primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
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
                color: isSelected ? Colors.white : Colors.grey[700],
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

class _AddFieldDialog extends StatefulWidget {
  final List<String> availableMinistries;
  final int fieldOrder;

  const _AddFieldDialog({
    required this.availableMinistries,
    required this.fieldOrder,
  });

  @override
  State<_AddFieldDialog> createState() => _AddFieldDialogState();
}

class _AddFieldDialogState extends State<_AddFieldDialog> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _placeholderController = TextEditingController();
  final _helpTextController = TextEditingController();
  final _defaultValueController = TextEditingController();
  final _optionsController = TextEditingController();

  String _selectedType = FormFieldType.text;
  bool _isRequired = false;
  List<String> _options = [];

  @override
  void dispose() {
    _labelController.dispose();
    _placeholderController.dispose();
    _helpTextController.dispose();
    _defaultValueController.dispose();
    _optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Adicionar Campo',
          style: context.textStyles.titleLarge?.copyWith(
              color: context.colors.onSurface, fontWeight: FontWeight.bold)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tipo do campo
              Text(
                'Tipo do Campo',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                dropdownColor: context.colors.surface,
                items: [
                  DropdownMenuItem(
                      value: FormFieldType.text,
                      child: Text(_getFieldTypeName(FormFieldType.text),
                          style: TextStyle(color: context.colors.onSurface))),
                  DropdownMenuItem(
                      value: FormFieldType.email,
                      child: Text(_getFieldTypeName(FormFieldType.email),
                          style: TextStyle(color: context.colors.onSurface))),
                  DropdownMenuItem(
                      value: FormFieldType.phone,
                      child: Text(_getFieldTypeName(FormFieldType.phone),
                          style: TextStyle(color: context.colors.onSurface))),
                  DropdownMenuItem(
                      value: FormFieldType.textarea,
                      child: Text(_getFieldTypeName(FormFieldType.textarea),
                          style: TextStyle(color: context.colors.onSurface))),
                  DropdownMenuItem(
                      value: FormFieldType.select,
                      child: Text(_getFieldTypeName(FormFieldType.select),
                          style: TextStyle(color: context.colors.onSurface))),
                  DropdownMenuItem(
                      value: FormFieldType.multiselect,
                      child: Text(_getFieldTypeName(FormFieldType.multiselect),
                          style: TextStyle(color: context.colors.onSurface))),
                  DropdownMenuItem(
                      value: FormFieldType.checkbox,
                      child: Text(_getFieldTypeName(FormFieldType.checkbox),
                          style: TextStyle(color: context.colors.onSurface))),
                  DropdownMenuItem(
                      value: FormFieldType.number,
                      child: Text(_getFieldTypeName(FormFieldType.number),
                          style: TextStyle(color: context.colors.onSurface))),
                  DropdownMenuItem(
                      value: FormFieldType.date,
                      child: Text(_getFieldTypeName(FormFieldType.date),
                          style: TextStyle(color: context.colors.onSurface))),
                  DropdownMenuItem(
                      value: FormFieldType.ministrySelect,
                      child: Text(
                          _getFieldTypeName(FormFieldType.ministrySelect),
                          style: TextStyle(color: context.colors.onSurface))),
                  DropdownMenuItem(
                      value: FormFieldType.functionMultiselect,
                      child: Text(
                          _getFieldTypeName(FormFieldType.functionMultiselect),
                          style: TextStyle(color: context.colors.onSurface))),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Label do campo
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Campo *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nome do campo é obrigatório';
                  }
                  return null;
                },
              ),
              if (_selectedType == FormFieldType.text ||
                  _selectedType == FormFieldType.email ||
                  _selectedType == FormFieldType.phone ||
                  _selectedType == FormFieldType.textarea ||
                  _selectedType == FormFieldType.number) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _defaultValueController,
                  decoration: const InputDecoration(
                    labelText: 'Valor Padrão',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              // Placeholder
              TextFormField(
                controller: _placeholderController,
                decoration: const InputDecoration(
                  labelText: 'Texto de Exemplo',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Digite seu nome completo',
                ),
              ),
              const SizedBox(height: 16),

              // Texto de ajuda
              TextFormField(
                controller: _helpTextController,
                decoration: const InputDecoration(
                  labelText: 'Texto de Ajuda',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Este campo é obrigatório',
                ),
                maxLines: 2,
              ),

              // Opções para campos de seleção
              if (_selectedType == FormFieldType.select ||
                  _selectedType == FormFieldType.multiselect ||
                  _selectedType == FormFieldType.checkbox) ...[
                const SizedBox(height: 16),
                Text(
                  'Opções de Seleção',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _optionsController,
                  decoration: const InputDecoration(
                    labelText: 'Opções (uma por linha)',
                    border: OutlineInputBorder(),
                    hintText: 'Opção 1\nOpção 2\nOpção 3',
                  ),
                  maxLines: 4,
                  onChanged: (value) {
                    _options = value
                        .split('\n')
                        .where((line) => line.trim().isNotEmpty)
                        .toList();
                  },
                ),
              ],

              // Campo obrigatório - movido para o final
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
                  const SizedBox(width: 8),
                  const Text('Campo Obrigatório'),
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
          onPressed: _saveField,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colors.primary,
            foregroundColor: context.colors.onPrimary,
          ),
          child: const Text('Adicionar'),
        ),
      ],
    );
  }

  void _saveField() {
    if (_formKey.currentState!.validate()) {
      final field = CustomFormField(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        label: _labelController.text.trim(),
        type: _selectedType,
        required: _isRequired,
        placeholder: _placeholderController.text.trim(),
        helpText: _helpTextController.text.trim(),
        options: _options,
        defaultValue: _defaultValueController.text.trim(),
        order: widget.fieldOrder,
      );

      Navigator.of(context).pop(field);
    }
  }

  String _getFieldTypeName(String type) {
    switch (type) {
      case FormFieldType.text:
        return 'Texto';
      case FormFieldType.email:
        return 'Email';
      case FormFieldType.phone:
        return 'Telefone';
      case FormFieldType.textarea:
        return 'Texto Longo';
      case FormFieldType.select:
        return 'Seleção';
      case FormFieldType.multiselect:
        return 'Seleção Múltipla';
      case FormFieldType.checkbox:
        return 'Checkbox';
      case FormFieldType.number:
        return 'Número';
      case FormFieldType.date:
        return 'Data';
      case FormFieldType.ministrySelect:
        return 'Seleção de Ministério';
      case FormFieldType.functionMultiselect:
        return 'Funções do Ministério';
      default:
        return 'Texto';
    }
  }
}
