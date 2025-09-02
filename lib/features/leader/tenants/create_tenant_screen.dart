import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/context_extension.dart';

class CreateTenantScreen extends StatefulWidget {
  const CreateTenantScreen({super.key});

  @override
  State<CreateTenantScreen> createState() => _CreateTenantScreenState();
}

class _CreateTenantScreenState extends State<CreateTenantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adminFormKey = GlobalKey<FormState>();
  
  int _currentStep = 0;
  bool _isLoading = false;
  
  // Dados do Tenant
  final _tenantNameController = TextEditingController();
  final _tenantIdController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Dados do Admin
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Define senha padrão
    _adminPasswordController.text = '123456';
  }

  @override
  void dispose() {
    _tenantNameController.dispose();
    _tenantIdController.dispose();
    _descriptionController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  /// Gera ID do tenant baseado no nome da organização
  String _generateTenantId(String organizationName) {
    return organizationName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '') // Remove caracteres especiais
        .replaceAll(RegExp(r'\s+'), '-') // Substitui espaços por hífens
        .replaceAll(RegExp(r'^-+|-+$'), ''); // Remove hífens no início e fim
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.onSurface),
          onPressed: () => context.go('/leader/dashboard'),
        ),
        centerTitle: false,
        title: Text(
          'Criar novo tenant',
          style: context.textStyles.titleLarge?.copyWith(
            color: context.colors.onSurface
          )
        ),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: [
                if (_currentStep > 0)
                  ElevatedButton(
                    onPressed: details.onStepCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                    ),
                    child: const Text('Voltar'),
                  ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: context.colors.onPrimary,
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
                      : Text(_currentStep == 1 ? 'Criar Tenant' : 'Continuar'),
                ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Informações do Tenant'),
            subtitle: const Text('Dados básicos da organização'),
            content: _buildTenantForm(),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('Administrador do Tenant'),
            subtitle: const Text('Usuário que gerenciará o tenant'),
            content: _buildAdminForm(),
            isActive: _currentStep >= 1,
          ),
        ],
      ),
    );
  }

  Widget _buildTenantForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _tenantNameController,
            decoration: const InputDecoration(
              labelText: 'Nome da Organização *',
              hintText: 'Ex: Igreja Batista Central',
              border: OutlineInputBorder(),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
            ),
            onChanged: (value) {
              // Gera automaticamente o ID do tenant baseado no nome
              if (value.isNotEmpty) {
                final generatedId = _generateTenantId(value);
                _tenantIdController.text = generatedId;
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nome é obrigatório';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tenantIdController,
            decoration: const InputDecoration(
              labelText: 'ID do Tenant *',
              hintText: 'Ex: igreja-central',
              border: OutlineInputBorder(),
              helperText: 'ID gerado automaticamente (pode ser editado)',
              floatingLabelBehavior: FloatingLabelBehavior.auto,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'ID é obrigatório';
              }
              if (!RegExp(r'^[a-z0-9-]+$').hasMatch(value)) {
                return 'ID deve conter apenas letras minúsculas, números e hífens';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Descrição',
              hintText: 'Breve descrição da organização',
              border: OutlineInputBorder(),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminForm() {
    return Form(
      key: _adminFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _adminNameController,
            decoration: const InputDecoration(
              labelText: 'Nome do Administrador *',
              hintText: 'Ex: Pastor João Silva',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nome é obrigatório';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _adminEmailController,
            decoration: const InputDecoration(
              labelText: 'E-mail *',
              hintText: 'Ex: pastor@igreja.com',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'E-mail é obrigatório';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'E-mail inválido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _adminPasswordController,
            decoration: const InputDecoration(
              labelText: 'Senha *',
              hintText: 'Senha padrão gerada automaticamente',
              border: OutlineInputBorder(),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              helperText: 'Senha padrão: "123456" (usuário deverá alterar no primeiro login)',
            ),
            obscureText: true,
            readOnly: true, // Senha é gerada automaticamente
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Senha é obrigatória';
              }
              if (value.length < 6) {
                return 'Senha deve ter pelo menos 6 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Informações',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Este usuário será criado como Tenant Admin e terá acesso total para:\n'
                  '• Criar branches (filiais)\n'
                  '• Criar ministérios\n'
                  '• Gerenciar usuários\n'
                  '• Configurar eventos e escalas\n\n'
                  '⚠️ IMPORTANTE: A senha padrão é "123456". O usuário será obrigado a alterá-la no primeiro login.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onStepContinue() async {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        setState(() {
          _currentStep = 1;
        });
      }
    } else if (_currentStep == 1) {
      if (_adminFormKey.currentState!.validate()) {
        await _createTenantWithAdmin();
      }
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep = _currentStep - 1;
      });
    }
  }

  Future<void> _createTenantWithAdmin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dio = DioClient.instance;
      
      final response = await dio.post(
        '/tenants/with-admin',
        data: {
          'tenantData': {
            'name': _tenantNameController.text,
            'tenantId': _tenantIdController.text,
            'description': _descriptionController.text,
          },
          'adminData': {
            'name': _adminNameController.text,
            'email': _adminEmailController.text,
            'password': _adminPasswordController.text,
            'role': 'volunteer', // Será convertido para tenant_admin pelo backend
          },
        },
      );

      if (mounted) {
        // Mostrar sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tenant "${_tenantNameController.text}" criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navegar de volta
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar tenant: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
