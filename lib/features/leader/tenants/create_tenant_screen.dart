import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/context_extension.dart';
import '../../../shared/widgets/servus_snackbar.dart';

class CreateTenantScreen extends StatefulWidget {
  const CreateTenantScreen({super.key});

  @override
  State<CreateTenantScreen> createState() => _CreateTenantScreenState();
}

class _CreateTenantScreenState extends State<CreateTenantScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _adminFormKey = GlobalKey<FormState>();
  
  late TabController _tabController;
  bool _isLoading = false;
  
  // Dados do Tenant
  final _tenantNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Dados do Admin
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPhoneController = TextEditingController();
  
  // Máscara para telefone brasileiro
  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Atualiza o botão flutuante quando a aba muda
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tenantNameController.dispose();
    _descriptionController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPhoneController.dispose();
    super.dispose();
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
          'Criar nova igreja',
          style: context.textStyles.titleLarge?.copyWith(
            color: context.colors.onSurface
          )
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.colors.primary,
          unselectedLabelColor: context.colors.onSurface.withOpacity(0.6),
          indicatorColor: context.colors.primary,
          dividerColor: context.colors.outline.withOpacity(0.2), // Linha divisória mais suave
          dividerHeight: 0.5, // Altura reduzida da linha
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorWeight: 3, // Espessura do indicador
          tabs: const [
            Tab(
              icon: Icon(Icons.church),
              text: 'Igreja',
            ),
            Tab(
              icon: Icon(Icons.admin_panel_settings),
              text: 'Administrador',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTenantTab(),
          _buildAdminTab(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildTenantTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(
                    'Informações da Igreja',
                    style: context.textStyles.headlineSmall?.copyWith(
                      color: context.colors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Preencha os dados básicos da igreja que será criada.',
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colors.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _tenantNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da Igreja *',
                      hintText: 'Ex: Igreja Batista Central',
                      border: OutlineInputBorder(),
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                      prefixIcon: Icon(Icons.church),
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
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição (opcional)',
                      hintText: 'Breve descrição da igreja',
                      border: OutlineInputBorder(),
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colors.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.colors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: context.colors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Informações importantes',
                              style: context.textStyles.titleSmall?.copyWith(
                                color: context.colors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• O ID da igreja será gerado automaticamente pelo sistema\n'
                          '• Após criar a igreja, você poderá adicionar o administrador\n'
                          '• O administrador receberá um e-mail com as credenciais de acesso',
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                ),
              ),
            ),
          ),
          // Botão flutuante removido daqui - será adicionado como FloatingActionButton
        ],
      ),
    );
  }

  Widget _buildAdminTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Form(
              key: _adminFormKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(
                    'Administrador da Igreja',
                    style: context.textStyles.headlineSmall?.copyWith(
                      color: context.colors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Preencha os dados do administrador que gerenciará esta igreja.',
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colors.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _adminNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Administrador *',
                      hintText: 'Ex: Pastor João Silva',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
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
                      prefixIcon: Icon(Icons.email),
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
                    controller: _adminPhoneController,
                    inputFormatters: [_phoneMaskFormatter],
                    decoration: const InputDecoration(
                      labelText: 'Número de Telefone *',
                      hintText: 'Ex: (11) 99999-9999',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Telefone é obrigatório';
                      }
                      // Validar se o telefone tem pelo menos 10 dígitos (DDD + número)
                      final phoneDigits = value.replaceAll(RegExp(r'[^0-9]'), '');
                      if (phoneDigits.length < 10) {
                        return 'Telefone deve ter pelo menos 10 dígitos';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colors.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.colors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.admin_panel_settings,
                              color: context.colors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Permissões do Administrador',
                              style: context.textStyles.titleSmall?.copyWith(
                                color: context.colors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Este usuário terá acesso total para:\n'
                          '• Criar e gerenciar branches (filiais)\n'
                          '• Criar e gerenciar ministérios\n'
                          '• Gerenciar usuários e voluntários\n'
                          '• Configurar eventos e escalas\n'
                          '• Acessar relatórios e métricas',
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              color: Colors.green[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Credenciais de Acesso',
                              style: context.textStyles.titleSmall?.copyWith(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Após a criação, o administrador receberá um e-mail contendo:\n'
                          '• E-mail para login\n'
                          '• Senha provisória gerada automaticamente\n'
                          '• Instruções para primeiro acesso',
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                ),
              ),
            ),
          ),
          // Botão flutuante removido daqui - será adicionado como FloatingActionButton
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    if (_tabController.index == 0) {
      // Primeira aba - Igreja
      return FloatingActionButton.extended(
        onPressed: _validateAndGoToAdminTab,
        backgroundColor: context.colors.primary,
        foregroundColor: context.colors.onPrimary,
        icon: const Icon(Icons.arrow_forward),
        label: const Text('Continuar'),
      );
    } else {
      // Segunda aba - Administrador
      return FloatingActionButton.extended(
        onPressed: _isLoading ? null : _createTenantWithAdmin,
        backgroundColor: _isLoading 
            ? context.colors.primary.withOpacity(0.6)
            : context.colors.primary,
        foregroundColor: context.colors.onPrimary,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.check),
        label: Text(_isLoading ? 'Criando...' : 'Concluir'),
      );
    }
  }

  void _validateAndGoToAdminTab() {
    if (_formKey.currentState?.validate() ?? false) {
      _tabController.animateTo(1);
    }
  }

  Future<void> _createTenantWithAdmin() async {
    // Validar formulário do admin primeiro
    if (!(_adminFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dio = DioClient.instance;
      
      await dio.post(
        '/tenants/with-admin',
        data: {
          'tenantData': {
            'name': _tenantNameController.text,
            'description': _descriptionController.text.isNotEmpty 
                ? _descriptionController.text 
                : null,
          },
          'adminData': {
            'name': _adminNameController.text,
            'email': _adminEmailController.text,
            'phone': _adminPhoneController.text,
            'role': 'tenant_admin',
          },
        },
      );

      if (mounted) {
        // Mostrar sucesso com o novo padrão
        showTenantCreateSuccess(context, _tenantNameController.text);
        
        // Navegar de volta primeiro para evitar problemas de contexto
        Navigator.of(context).pop(true);
        
        // Mostrar informação sobre email após navegação (se ainda houver contexto válido)
        Future.delayed(const Duration(milliseconds: 100), () {
          // Não tentar mostrar SnackBar após navegação para evitar erros de contexto
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erro ao criar igreja';
        
        if (e is DioException) {
          if (e.response?.statusCode == 409) {
            errorMessage = 'Já existe uma igreja com este nome ou e-mail';
          } else if (e.response?.statusCode == 400) {
            errorMessage = 'Dados inválidos. Verifique as informações fornecidas.';
          } else if (e.response?.data != null && e.response!.data['message'] != null) {
            errorMessage = e.response!.data['message'];
          }
        }
        
        // Verificar se o contexto ainda está válido antes de mostrar erro
        if (mounted && context.mounted) {
          showTenantCreateError(context, _tenantNameController.text, errorMessage);
        }
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
