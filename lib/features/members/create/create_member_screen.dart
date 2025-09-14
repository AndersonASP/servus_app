import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:servus_app/core/models/member.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/services/members_service.dart';
import 'package:servus_app/shared/widgets/fab_safe_scroll_view.dart';
import 'package:servus_app/features/ministries/services/ministry_service.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/features/ministries/models/ministry_dto.dart';
import 'package:servus_app/features/members/widgets/function_selector_widget.dart';
import 'package:servus_app/features/ministries/services/user_function_service.dart';
import 'package:servus_app/features/ministries/services/ministry_functions_service.dart';
import 'package:servus_app/features/ministries/models/ministry_function.dart';
import 'package:servus_app/core/services/feedback_service.dart';

class CreateMemberScreen extends StatefulWidget {
  const CreateMemberScreen({super.key});

  @override
  State<CreateMemberScreen> createState() => _CreateMemberScreenState();
}

class _CreateMemberScreenState extends State<CreateMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  List<MembershipAssignment> _memberships = [];
  
  // Para listagem de branches e ministries
  List<Map<String, dynamic>> _availableBranches = [];
  List<Map<String, dynamic>> _availableMinistries = [];
  final Map<String, List<MinistryFunction>> _ministryFunctions = {}; // Cache das funções por ministério
  bool _showBranchSelection = false;
  
  // Serviços
  final MinistryService _ministryService = MinistryService();
  final UserFunctionService _userFunctionService = UserFunctionService();
  final MinistryFunctionsService _ministryFunctionsService = MinistryFunctionsService();
  
  // Dados do contexto
  String? _tenantId;
  String? _branchId;
  
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _clearAllCache();
    _loadBranchesAndMinistries();
  }

  /// Limpar todo o cache do frontend
  void _clearAllCache() {
    print('🧹 Limpando todo o cache do frontend...');
    _availableMinistries.clear();
    _ministryFunctions.clear();
    _memberships.clear();
    print('✅ Cache limpo com sucesso');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _createMember() async {
    // Prevenir duplo clique
    if (_isLoading) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar se pelo menos um vínculo foi adicionado
    if (_memberships.isEmpty) {
      FeedbackService.showValidationError(context, 'Adicione pelo menos um vínculo organizacional');
      return;
    }

    // Validar e corrigir vínculos duplicados (prioriza Líder sobre Voluntário)
    _validateAndFixDuplicateMemberships();

    // Validar dados obrigatórios dos vínculos
    if (!_validateMemberships()) {
      FeedbackService.showValidationError(context, 'Preencha todos os campos obrigatórios dos vínculos.');
      return;
    }

    // Verificar se o email já existe
    try {
      final membersResponse = await MembersService.getMembers(
        filter: MemberFilter(search: _emailController.text.trim()),
        context: context,
      );
      // Verificar se algum membro tem o email exato
      final emailExists = membersResponse.members.any(
        (member) => member.email.toLowerCase() == _emailController.text.trim().toLowerCase()
      );
      if (emailExists) {
        FeedbackService.showValidationError(context, 'Já existe um usuário com este email. Use um email diferente.');
        return;
      }
    } catch (e) {
      // Se der erro na verificação, continuar (pode ser que o filtro não funcione)
      print('Erro ao verificar email existente: $e');
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = CreateMemberRequest(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        birthDate: _birthDateController.text.trim().isEmpty ? null : _birthDateController.text.trim(),
        memberships: _memberships,
      );

      final member = await MembersService.createMember(request, context);
      
      // Criar vínculos UserFunction para funções selecionadas
      final userFunctionSuccess = await _createUserFunctions(member.id);
      
      if (mounted) {
        if (userFunctionSuccess) {
          Navigator.pop(context, true);
          FeedbackService.showCreateSuccess(context, 'Membro');
        } else {
          // Membro foi criado mas vínculos falharam
          Navigator.pop(context, true);
          FeedbackService.showWarning(context, 'Membro criado, mas alguns vínculos de funções falharam. Verifique os detalhes do membro.');
        }
      }
    } catch (e) {
      if (mounted) {
        _handleCreateMemberError(e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }





  /// Valida e corrige vínculos duplicados no mesmo ministério
  /// Prioriza Líder sobre Voluntário
  bool _validateAndFixDuplicateMemberships() {
    final Map<String, List<int>> ministryGroups = {};
    
    // Agrupar vínculos por ministério
    for (int i = 0; i < _memberships.length; i++) {
      final membership = _memberships[i];
      if (membership.ministryId != null && membership.ministryId!.isNotEmpty) {
        final key = '${membership.branchId ?? 'null'}_${membership.ministryId}';
        if (!ministryGroups.containsKey(key)) {
          ministryGroups[key] = [];
        }
        ministryGroups[key]!.add(i);
      }
    }
    
    bool hasChanges = false;
    final List<MembershipAssignment> newMemberships = [];
    final List<int> indicesToRemove = [];
    
    // Processar cada grupo de ministério
    for (final entry in ministryGroups.entries) {
      final indices = entry.value;
      if (indices.length > 1) {
        // Há vínculos duplicados neste ministério
        final memberships = indices.map((i) => _memberships[i]).toList();
        
        // Verificar se há líder
        final leaderMembership = memberships.firstWhere(
          (m) => m.role == 'leader',
          orElse: () => memberships.first,
        );
        
        // Se há líder, priorizar ele
        if (leaderMembership.role == 'leader') {
          // Coletar todas as funções dos voluntários para o líder
          final List<String> allFunctionIds = [...leaderMembership.functionIds];
          for (final membership in memberships) {
            if (membership.role == 'volunteer') {
              allFunctionIds.addAll(membership.functionIds);
            }
          }
          
          // Criar vínculo de líder com todas as funções
          final enhancedLeaderMembership = MembershipAssignment(
            role: leaderMembership.role,
            branchId: leaderMembership.branchId,
            ministryId: leaderMembership.ministryId,
            isActive: leaderMembership.isActive,
            functionIds: allFunctionIds.toSet().toList(), // Remove duplicatas
          );
          
          newMemberships.add(enhancedLeaderMembership);
          
          // Marcar outros vínculos para remoção
          for (final index in indices) {
            if (_memberships[index] != leaderMembership) {
              indicesToRemove.add(index);
            }
          }
          
          hasChanges = true;
        } else {
          // Se não há líder, manter apenas o primeiro vínculo
          newMemberships.add(leaderMembership);
          for (int i = 1; i < indices.length; i++) {
            indicesToRemove.add(indices[i]);
          }
          hasChanges = true;
        }
      } else {
        // Apenas um vínculo neste ministério, manter
        newMemberships.add(_memberships[indices.first]);
      }
    }
    
    // Aplicar correções
    if (hasChanges) {
      setState(() {
        // Remover vínculos duplicados
        indicesToRemove.sort((a, b) => b.compareTo(a)); // Ordem decrescente
        for (final index in indicesToRemove) {
          _memberships.removeAt(index);
        }
        
        // Substituir vínculos de líder com funções aprimoradas
        for (final enhancedMembership in newMemberships) {
          final index = _memberships.indexWhere((m) => 
            m.ministryId == enhancedMembership.ministryId && 
            m.branchId == enhancedMembership.branchId
          );
          if (index != -1) {
            _memberships[index] = enhancedMembership;
          }
        }
      });
      
      // Mostrar aviso sobre a correção
      FeedbackService.showInfo(
        context, 
        'Vínculos duplicados foram corrigidos. Líder tem prioridade e mantém todas as funções para escalas.'
      );
    }
    
    return !hasChanges; // Retorna true se não havia duplicatas
  }

  /// Valida se todos os vínculos têm dados obrigatórios
  bool _validateMemberships() {
    for (final membership in _memberships) {
      // Validar role
      if (membership.role.isEmpty) {
        return false;
      }
      
      // Para branch_admin, leader e volunteer, ministry é obrigatório
      if ((membership.role == 'branch_admin' || 
           membership.role == 'leader' || 
           membership.role == 'volunteer') && 
          (membership.ministryId == null || membership.ministryId!.isEmpty)) {
        return false;
      }
      
      // Para branch_admin, branch é obrigatório
      if (membership.role == 'branch_admin' && 
          (membership.branchId == null || membership.branchId!.isEmpty)) {
        return false;
      }
    }
    return true;
  }

  /// Valida se um valor existe na lista de branches
  String? _getValidBranchValue(String? branchId) {
    if (branchId == null || branchId.isEmpty) return null;
    if (_availableBranches.isEmpty) return null;
    return _availableBranches.any((branch) => branch['id'] == branchId) ? branchId : null;
  }

  /// Valida se um valor existe na lista de ministérios
  String? _getValidMinistryValue(String? ministryId) {
    if (ministryId == null || ministryId.isEmpty) return null;
    if (_availableMinistries.isEmpty) return null;
    return _availableMinistries.any((ministry) => ministry['id'] == ministryId) ? ministryId : null;
  }

  /// Trata erros específicos na criação do membro
  void _handleCreateMemberError(dynamic error) {
    String errorMessage = 'Erro ao criar membro';
    
    if (error.toString().contains('E11000') || 
        error.toString().contains('duplicate key') ||
        error.toString().contains('duplicate key error')) {
      // Verificar se é erro de email duplicado ou vínculo duplicado
      if (error.toString().contains('email_1') || 
          error.toString().contains('email:')) {
        errorMessage = 'Já existe um usuário com este email. Use um email diferente.';
      } else {
        errorMessage = 'Este vínculo já existe. Verifique se o membro já possui vínculos com os mesmos ministérios.';
      }
    } else if (error.toString().contains('SocketException') || 
               error.toString().contains('TimeoutException')) {
      errorMessage = 'Erro de conexão. Verifique sua internet e tente novamente.';
    } else if (error.toString().contains('401') || 
               error.toString().contains('Unauthorized')) {
      errorMessage = 'Sessão expirada. Faça login novamente.';
    } else if (error.toString().contains('403') || 
               error.toString().contains('Forbidden')) {
      errorMessage = 'Você não tem permissão para criar membros.';
    } else if (error.toString().contains('400') || 
               error.toString().contains('Bad Request')) {
      errorMessage = 'Dados inválidos. Verifique as informações fornecidas.';
    }
    
    FeedbackService.showError(context, errorMessage);
  }

  void _resetForm() {
    setState(() {
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _birthDateController.clear();
      _memberships.clear();
      _showBranchSelection = false;
      _currentStep = 0;
    });
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoContent();
      case 1:
        return _buildOrganizationalContent();
      case 2:
        return _buildSummaryContent();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBasicInfoContent() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nome completo *',
            border: OutlineInputBorder(),
            helperText: 'Nome completo do membro',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nome é obrigatório';
            }
            if (value.trim().length < 2) {
              return 'Nome deve ter pelo menos 2 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            helperText: 'Pelo menos um de email ou telefone é obrigatório',
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value != null && value.trim().isNotEmpty) {
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Email inválido';
              }
            }
            // Validar se pelo menos email ou telefone foi fornecido
            if ((value == null || value.trim().isEmpty) && 
                (_phoneController.text.trim().isEmpty)) {
              return 'Pelo menos um de email ou telefone é obrigatório';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Telefone',
            border: OutlineInputBorder(),
            helperText: 'Pelo menos um de email ou telefone é obrigatório',
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
            _PhoneInputFormatter(),
          ],
          validator: (value) {
            // Validar se pelo menos email ou telefone foi fornecido
            if ((value == null || value.trim().isEmpty) && 
                (_emailController.text.trim().isEmpty)) {
              return 'Pelo menos um de email ou telefone é obrigatório';
            }
            if (value != null && value.trim().isNotEmpty && value.length < 10) {
              return 'Telefone deve ter pelo menos 10 dígitos';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _birthDateController,
          decoration: const InputDecoration(
            labelText: 'Data de nascimento',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.calendar_today),
            helperText: 'Opcional',
          ),
          readOnly: true,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 anos atrás
              firstDate: DateTime.now().subtract(const Duration(days: 36500)), // 100 anos atrás
              lastDate: DateTime.now(),
            );
            if (date != null) {
              _birthDateController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            }
          },
        ),
      ],
    );
  }

  Widget _buildOrganizationalContent() {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Vínculos Organizacionais',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_memberships.isEmpty)
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Nenhum vínculo adicionado.\nClique em "Adicionar Vínculo" para começar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _addMembership,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar Vínculo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: context.colors.onPrimary,
                  ),
                ),
              ),
            ],
          )
        else
          ..._memberships.asMap().entries.map((entry) {
            final index = entry.key;
            final membership = entry.value;
            return _buildMembershipCard(index, membership);
          }).toList(),
        
        // Botão de adicionar vínculo após os cards
        if (_memberships.isNotEmpty) ...[
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: _addMembership,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Vínculo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: context.colors.onPrimary,
              ),
            ),
          ),
        ],
        
        // const SizedBox(height: 16),
        // Container(
        //   padding: const EdgeInsets.all(12),
        //   decoration: BoxDecoration(
        //     color: Colors.blue.shade50,
        //     borderRadius: BorderRadius.circular(8),
        //     border: Border.all(color: Colors.blue.shade200),
        //   ),
        //   child: Row(
        //     children: [
        //       Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
        //       const SizedBox(width: 8),
        //       Expanded(
        //         child: Text(
        //           'A senha será gerada automaticamente e enviada por email para o usuário.',
        //           style: TextStyle(
        //             color: Colors.blue.shade700,
        //             fontSize: 12,
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),

      ],
    );
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: false,
        title: const Text('Criar novo membro'),
        actions: [
          // Botão de voltar step
          if (_currentStep > 0)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _isLoading ? null : () {
                setState(() => _currentStep--);
              },
              tooltip: 'Step anterior',
            ),
          // Botão de reset
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _resetForm,
            tooltip: 'Limpar formulário',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: FabSafeScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Indicador de progresso
              _buildProgressIndicator(),
              const SizedBox(height: 24),
              // Conteúdo da seção atual
              _buildCurrentStepContent(),
              const SizedBox(height: 24),
              // Botões de navegação

            ],
          ),
        ),
      ),
      // Botão flutuante de navegação
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _handleFloatingActionButtonPress,
        icon: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Icon(_currentStep < 2 ? Icons.arrow_forward : Icons.check),
        label: _isLoading
            ? const Text('Criando...')
            : Text(_currentStep == 0 ? 'Próximo' : _currentStep == 1 ? 'Próximo' : 'Criar Membro'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _handleFloatingActionButtonPress() {
    if (_currentStep == 0) {
      // Validar dados básicos antes de prosseguir
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep = 1);
      }
    } else if (_currentStep == 1) {
      // Validar vínculos antes de prosseguir
      if (_memberships.isNotEmpty) {
        setState(() => _currentStep = 2);
      } else {
        FeedbackService.showValidationError(context, 'Adicione pelo menos um vínculo organizacional');
      }
    } else {
      // Último step - criar membro
      _createMember();
    }
  }

  Widget _buildSummaryContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumo das Informações',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Dados Básicos
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dados Básicos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow('Nome', _nameController.text.trim()),
                if (_emailController.text.trim().isNotEmpty)
                  _buildSummaryRow('Email', _emailController.text.trim()),
                if (_phoneController.text.trim().isNotEmpty)
                  _buildSummaryRow('Telefone', _phoneController.text.trim()),
                if (_birthDateController.text.trim().isNotEmpty)
                  _buildSummaryRow('Data de Nascimento', _birthDateController.text.trim()),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Vínculos Organizacionais
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vínculos Organizacionais',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                if (_memberships.isEmpty)
                  const Text(
                    'Nenhum vínculo adicionado',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  ..._memberships.asMap().entries.map((entry) {
                    final index = entry.key;
                    final membership = entry.value;
                    return _buildMembershipSummary(index + 1, membership);
                  }).toList(),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Informação sobre senha
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'A senha será gerada automaticamente e enviada por email para o usuário.',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipSummary(int index, MembershipAssignment membership) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vínculo $index',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          _buildSummaryRow('Role', _getRoleDisplayName(membership.role)),
          if (membership.branchId != null)
            _buildSummaryRow('Branch', _getBranchName(membership.branchId!)),
          if (membership.ministryId != null)
            _buildSummaryRow('Ministério', _getMinistryName(membership.ministryId!)),
          _buildSummaryRow('Status', membership.isActive == true ? 'Ativo' : 'Inativo'),
        ],
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'tenant_admin':
        return 'Administrador do Tenant';
      case 'branch_admin':
        return 'Administrador da Branch';
      case 'leader':
        return 'Líder';
      case 'volunteer':
        return 'Voluntário';
      default:
        return role;
    }
  }

  String _getBranchName(String branchId) {
    final branch = _availableBranches.firstWhere(
      (b) => b['id'] == branchId,
      orElse: () => {'name': 'Branch não encontrada'},
    );
    return branch['name'];
  }

  String _getMinistryName(String ministryId) {
    final ministry = _availableMinistries.firstWhere(
      (m) => m['id'] == ministryId,
      orElse: () => {'name': 'Ministério não encontrado'},
    );
    return ministry['name'];
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            _buildStepIndicator(0, 'Básicas'),
            Expanded(child: _buildStepConnector(0)),
            _buildStepIndicator(1, 'Organizacional'),
            Expanded(child: _buildStepConnector(1)),
            _buildStepIndicator(2, 'Resumo'),
          ],
        ),
      ],
    );
  }

  Widget _buildStepIndicator(int stepIndex, String label) {
    final isActive = _currentStep == stepIndex;
    final isCompleted = _currentStep > stepIndex;
    
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted 
              ? Theme.of(context).primaryColor 
              : (isActive ? Theme.of(context).primaryColor : Colors.grey[300]),
          ),
          child: Center(
            child: isCompleted 
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text(
                  '${stepIndex + 1}',
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive || isCompleted 
              ? Theme.of(context).primaryColor 
              : Colors.grey[600],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(int stepIndex) {
    final isCompleted = _currentStep > stepIndex;
    return Container(
      height: 2,
      color: isCompleted 
        ? Theme.of(context).primaryColor 
        : Colors.grey[300],
    );
  }

  /// Verifica se o usuário atual é tenant ou leader para aprovação automática
  Future<bool> _shouldAutoApproveFunctions() async {
    try {
      final userRole = TokenService.userRole;
      final membershipRole = TokenService.membershipRole;
      
      debugPrint('🔐 Verificando permissões para aprovação automática:');
      debugPrint('   - User Role: $userRole');
      debugPrint('   - Membership Role: $membershipRole');
      
      // Aprovar automaticamente se for:
      // - servus_admin (role global)
      // - tenant_admin (role de tenant)
      // - leader (role de membership)
      final shouldApprove = userRole == 'servus_admin' || 
                           userRole == 'tenant_admin' || 
                           membershipRole == 'leader';
      
      debugPrint('   - Aprovação automática: $shouldApprove');
      return shouldApprove;
    } catch (e) {
      debugPrint('❌ Erro ao verificar permissões: $e');
      return false; // Em caso de erro, não aprovar automaticamente
    }
  }

  /// Criar vínculos UserFunction para as funções selecionadas (voluntários e líderes)
  Future<bool> _createUserFunctions(String userId) async {
    try {
      debugPrint('🔄 Iniciando criação de vínculos UserFunction para usuário: $userId');
      debugPrint('📋 Total de memberships: ${_memberships.length}');
      
      // Verificar se o usuário atual é tenant ou leader para aprovação automática
      final shouldAutoApprove = await _shouldAutoApproveFunctions();
      debugPrint('🔐 Aprovação automática: $shouldAutoApprove');
      
      // Validar dados antes de prosseguir
      if (!_validateMembershipData()) {
        debugPrint('❌ Dados de membership inválidos');
        return false;
      }
      
      int totalFunctions = 0;
      int successCount = 0;
      int errorCount = 0;
      
      for (int i = 0; i < _memberships.length; i++) {
        final membership = _memberships[i];
        debugPrint('📋 Membership $i: role=${membership.role}, ministryId=${membership.ministryId}, functionIds=${membership.functionIds.length}');
        
        // Criar funções para voluntários e líderes
        if ((membership.role == 'volunteer' || membership.role == 'leader') && 
            membership.ministryId != null && 
            membership.ministryId!.isNotEmpty &&
            membership.functionIds.isNotEmpty) {
          
          // Validar se os IDs são válidos (24 caracteres hexadecimais)
          if (!_isValidObjectId(userId)) {
            debugPrint('❌ ID do usuário inválido: $userId');
            errorCount++;
            continue;
          }
          
          if (!_isValidObjectId(membership.ministryId!)) {
            debugPrint('❌ ID do ministério inválido: ${membership.ministryId}');
            errorCount++;
            continue;
          }
          
          for (final functionId in membership.functionIds) {
            totalFunctions++;
            
            if (!_isValidObjectId(functionId)) {
              debugPrint('❌ ID da função inválido: $functionId');
              errorCount++;
              continue;
            }
            
            try {
              debugPrint('✅ Criando UserFunction: userId=$userId (${userId.length} chars), ministryId=${membership.ministryId} (${membership.ministryId!.length} chars), functionId=$functionId (${functionId.length} chars)');
              await _userFunctionService.createUserFunction(
                userId: userId,
                ministryId: membership.ministryId!,
                functionId: functionId,
                status: shouldAutoApprove ? 'approved' : null, // Aprovar automaticamente se for tenant ou leader
                context: context,
              );
              successCount++;
              debugPrint('✅ UserFunction criado com sucesso${shouldAutoApprove ? ' (aprovado automaticamente)' : ''}');
            } catch (e) {
              errorCount++;
              debugPrint('❌ Erro ao criar UserFunction: $e');
            }
          }
        }
      }
      
      debugPrint('📊 Resumo da criação de UserFunctions:');
      debugPrint('   - Total de funções: $totalFunctions');
      debugPrint('   - Sucessos: $successCount');
      debugPrint('   - Erros: $errorCount');
      
      return errorCount == 0;
    } catch (e) {
      debugPrint('❌ Erro geral ao criar vínculos UserFunction: $e');
      return false;
    }
  }

  /// Valida se uma string é um ObjectId válido do MongoDB
  bool _isValidObjectId(String id) {
    if (id.isEmpty) return false;
    // ObjectId deve ter exatamente 24 caracteres hexadecimais
    final isValid = RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id);
    if (!isValid) {
      debugPrint('❌ ID inválido: "$id" (${id.length} caracteres)');
    }
    return isValid;
  }

  /// Valida se os dados de membership estão corretos
  bool _validateMembershipData() {
    debugPrint('🔍 Validando dados de membership...');
    
    if (_memberships.isEmpty) {
      debugPrint('❌ Nenhum membership encontrado');
      return false;
    }
    
    for (int i = 0; i < _memberships.length; i++) {
      final membership = _memberships[i];
      debugPrint('🔍 Validando membership $i:');
      debugPrint('   - role: ${membership.role}');
      debugPrint('   - ministryId: ${membership.ministryId}');
      debugPrint('   - functionIds: ${membership.functionIds.length}');
      
      // Verificar se tem ministério
      if (membership.ministryId == null || membership.ministryId!.isEmpty) {
        debugPrint('❌ Membership $i sem ministério');
        return false;
      }
      
      // Verificar se o ministério existe na lista disponível
      final ministryExists = _availableMinistries.any((m) => m['id'] == membership.ministryId);
      if (!ministryExists) {
        debugPrint('❌ Membership $i com ministério inexistente: ${membership.ministryId}');
        debugPrint('   - Ministérios disponíveis: ${_availableMinistries.map((m) => m['id']).toList()}');
        return false;
      }
      
      // Verificar se tem funções para voluntários e líderes
      if ((membership.role == 'volunteer' || membership.role == 'leader') && 
          membership.functionIds.isEmpty) {
        debugPrint('❌ Membership $i sem funções para role ${membership.role}');
        return false;
      }
    }
    
    debugPrint('✅ Dados de membership válidos');
    return true;
  }

  /// Carrega todas as funções de um ministério para líder
  Future<void> _loadAllMinistryFunctions(String ministryId) async {
    try {
      debugPrint('🔄 Carregando funções para ministério: $ministryId');
      final functions = await _ministryFunctionsService.getMinistryFunctions(
        ministryId,
        active: true,
      );
      _ministryFunctions[ministryId] = functions;
      debugPrint('✅ Carregadas ${functions.length} funções para ministério $ministryId');
      for (final function in functions) {
        debugPrint('   - ${function.name} (ID: ${function.functionId})');
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar funções do ministério: $e');
    }
  }

  /// Retorna todos os IDs das funções de um ministério
  List<String> _getAllMinistryFunctionIds(String ministryId) {
    final functions = _ministryFunctions[ministryId] ?? [];
    final functionIds = functions.map((f) => f.functionId).toList();
    debugPrint('🔍 Obtendo IDs das funções para ministério $ministryId: ${functionIds.length} funções');
    return functionIds;
  }

  // ===== MÉTODOS AUXILIARES PARA VÍNCULOS =====

  void _addMembership() {
    setState(() {
      _memberships.add(MembershipAssignment(
        role: 'volunteer',
        isActive: true,
        functionIds: [],
      ));
    });
  }

  void _removeMembership(int index) {
    setState(() {
      _memberships.removeAt(index);
    });
  }

  void _updateMembership(int index, MembershipAssignment membership) {
    print('🔄 Atualizando membership $index:');
    print('   - role: ${membership.role}');
    print('   - ministryId: ${membership.ministryId}');
    print('   - branchId: ${membership.branchId}');
    print('   - functionIds: ${membership.functionIds.length}');
    
    setState(() {
      _memberships[index] = membership;
    });
    
    print('✅ Membership $index atualizado com sucesso');
    print('   - Total de memberships: ${_memberships.length}');
    for (int i = 0; i < _memberships.length; i++) {
      print('   - Membership $i: role=${_memberships[i].role}, ministryId=${_memberships[i].ministryId}');
    }
  }

  Widget _buildMembershipCard(int index, MembershipAssignment membership) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vínculo ${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: () => _removeMembership(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Remover vínculo',
                ),
              ],
            ),
            const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Nível de Acesso*',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(
                    color: context.colors.onSurface,
                  ),
                  helperText: 'Selecione o nível de acesso para este vínculo',
                  helperStyle: TextStyle(
                    color: context.colors.onSurface,
                  ),
                ),
                initialValue: membership.role,
                style: TextStyle(
                  color: context.colors.onSurface,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'tenant_admin', 
                    child: Text('Administrador da Igreja (Sede)'),
                  ),
                  DropdownMenuItem(
                    value: 'branch_admin', 
                    child: Text('Administrador de Campus'),
                  ),
                  DropdownMenuItem(
                    value: 'leader', 
                    child: Text('Líder de Ministério'),
                  ),
                  DropdownMenuItem(
                    value: 'volunteer', 
                    child: Text('Voluntário'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    // Se selecionar branch_admin, expandir automaticamente a seleção de branch
                    if (value == 'branch_admin') {
                      setState(() {
                        _showBranchSelection = true;
                      });
                    }
                    
                    // Se selecionar líder, carregar todas as funções do ministério
                    if (value == 'leader' && membership.ministryId != null && membership.ministryId!.isNotEmpty) {
                      _loadAllMinistryFunctions(membership.ministryId!);
                    }
                    
                    _updateMembership(index, MembershipAssignment(
                      role: value,
                      branchId: membership.branchId,
                      ministryId: membership.ministryId,
                      isActive: membership.isActive,
                      functionIds: value == 'leader' && membership.ministryId != null 
                          ? _getAllMinistryFunctionIds(membership.ministryId!)
                          : membership.functionIds,
                    ));
                  }
                },
            ),
            const SizedBox(height: 16),
            // Campos condicionais para branchId e ministryId baseados no role
            if (membership.role == 'branch_admin' || membership.role == 'leader' || membership.role == 'volunteer') ...[
              // Botão para mostrar/ocultar seleção de branch
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showBranchSelection = !_showBranchSelection;
                      });
                    },
                    icon: Icon(_showBranchSelection ? Icons.visibility_off : Icons.visibility),
                    label: Text(_showBranchSelection ? 'Ocultar Branch' : 'Selecionar Branch'),
                  ),
                ],
              ),
              if (_showBranchSelection) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  decoration: const InputDecoration(
                    labelText: 'Branch (opcional)',
                    border: OutlineInputBorder(),
                    helperText: 'Selecione uma branch para filtrar os ministérios',
                  ),
                  value: _getValidBranchValue(membership.branchId),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Nenhuma branch (ministérios do tenant)'),
                    ),
                    ..._availableBranches.map((branch) => DropdownMenuItem<String?>(
                      value: branch['id'],
                      child: Text(branch['name']),
                    )),
                  ],
                  onChanged: (value) {
                    _updateMembership(index, MembershipAssignment(
                      role: membership.role,
                      branchId: value,
                      ministryId: null, // Reset ministry when branch changes
                      isActive: membership.isActive,
                    ));
                    // Reload ministries based on selected branch
                    _loadMinistriesForBranch(value);
                  },
                ),
              ],
            ],
            if (membership.role == 'leader' || membership.role == 'volunteer') ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                decoration: InputDecoration(
                  labelText: 'Ministério *',
                  border: const OutlineInputBorder(),
                  helperText: 'Selecione o ministério para este vínculo',
                  labelStyle: TextStyle(
                    color: context.colors.onSurface,
                  ),
                  helperStyle: TextStyle(
                    color: context.colors.onSurface,
                  ),
                ),
                value: _getValidMinistryValue(membership.ministryId),
                style: TextStyle(
                  color: context.colors.onSurface,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Selecione um ministério'),
                  ),
                  ..._availableMinistries.map((ministry) => DropdownMenuItem<String?>(
                    value: ministry['id'],
                    child: Text(ministry['name']),
                  )),
                ],
                onChanged: (value) {
                  print('🔄 Ministério selecionado para membership $index:');
                  print('   - value: $value');
                  print('   - membership.role: ${membership.role}');
                  print('   - membership.ministryId atual: ${membership.ministryId}');
                  
                  // Se for líder e tiver ministério, carregar todas as funções
                  if (membership.role == 'leader' && value != null && value.isNotEmpty) {
                    _loadAllMinistryFunctions(value);
                  }
                  
                  final newMembership = MembershipAssignment(
                    role: membership.role,
                    branchId: membership.branchId,
                    ministryId: value,
                    isActive: membership.isActive,
                    functionIds: membership.role == 'leader' && value != null && value.isNotEmpty
                        ? _getAllMinistryFunctionIds(value)
                        : [], // Reset functions when ministry changes for volunteers
                  );
                  
                  print('   - Novo membership criado:');
                  print('     - role: ${newMembership.role}');
                  print('     - ministryId: ${newMembership.ministryId}');
                  print('     - functionIds: ${newMembership.functionIds.length}');
                  
                  _updateMembership(index, newMembership);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ministério é obrigatório para este role';
                  }
                  return null;
                },
              ),
              // Seleção de funções do ministério (apenas para voluntários, não para líderes)
              if (membership.ministryId != null && membership.ministryId!.isNotEmpty) ...[
                if (membership.role == 'volunteer') ...[
                  const SizedBox(height: 16),
                  FunctionSelectorWidget(
                    ministryId: membership.ministryId!,
                    selectedFunctionIds: membership.functionIds,
                    onFunctionsChanged: (functionIds) {
                      _updateMembership(index, MembershipAssignment(
                        role: membership.role,
                        branchId: membership.branchId,
                        ministryId: membership.ministryId,
                        isActive: membership.isActive,
                        functionIds: functionIds,
                      ));
                    },
                    enabled: !_isLoading,
                  ),
                ] else if (membership.role == 'leader') ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Como líder, você terá acesso automático a todas as funções deste ministério.',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
            // const SizedBox(height: 16),
            // SwitchListTile(
            //   title: const Text('Atiawvo'),
            //   value: membership.isActive ?? true,
            //   onChanged: (value) {
            //     _updateMembership(index, MembershipAssignment(
            //       role: membership.role,
            //       branchId: membership.branchId,
            //       ministryId: membership.ministryId,
            //       isActive: value,
            //     ));
            //   },
            // ),
          ],
        ),
      ),
    );
  }

  // ===== MÉTODOS AUXILIARES PARA BRANCHES E MINISTRIES =====

  Future<void> _loadBranchesAndMinistries() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Carregar contexto do usuário
      await _loadUserContext();
      
      // Carregar branches do usuário
      await _loadUserBranches();
      
      // Carregar ministérios
      await _loadMinistries();

    } catch (e) {
      // print('Erro ao carregar branches e ministries: $e');
      if (mounted) {
        FeedbackService.showLoadError(context, 'dados iniciais');
      }
      // Em caso de erro, usar dados mock como fallback
      _loadMockData();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserContext() async {
    try {
      final context = await TokenService.getContext();
      _tenantId = context['tenantId'];
      _branchId = context['branchId'];
      
      // print('🔍 Contexto carregado:');
      // print('   - Tenant ID: $_tenantId');
      // print('   - Branch ID: $_branchId');
    } catch (e) {
      // print('Erro ao carregar contexto: $e');
    }
  }

  Future<void> _loadUserBranches() async {
    try {
      // Por enquanto, vamos usar as branches do contexto do usuário
      // TODO: Implementar endpoint para listar todas as branches do tenant
      if (_tenantId != null) {
        // Simular branches baseadas no contexto atual
        _availableBranches = [];
        
        // Se o usuário tem contexto de branch, adicionar essa branch
        if (_branchId != null && _branchId!.isNotEmpty) {
          _availableBranches.add({
            'id': _branchId,
            'name': 'Filial Atual', // TODO: Buscar nome real da branch
          });
        }
        
        // Adicionar opção de ministérios do tenant (sem branch)
        _availableBranches.add({
          'id': null,
          'name': 'Ministérios do Tenant',
        });
      }
    } catch (e) {
      // print('Erro ao carregar branches: $e');
    }
  }

  Future<void> _loadMinistries() async {
    try {
      if (_tenantId == null) {
        // print('❌ Tenant ID não encontrado');
        return;
      }

      print('🧹 Limpando cache de ministérios...');
      _availableMinistries = [];

      // Carregar ministérios do tenant (sem branch)
      try {
        final tenantMinistries = await _ministryService.listMinistries(
          tenantId: _tenantId!,
          branchId: '', // Branch vazio para ministérios do tenant
          filters: ListMinistryDto(limit: 100), // Buscar todos
        );

        for (final ministry in tenantMinistries.items) {
          print('📋 Ministério carregado: id=${ministry.id}, name=${ministry.name}');
          _availableMinistries.add({
            'id': ministry.id,
            'name': ministry.name,
            'branchId': null, // Ministério do tenant
          });
        }
      } catch (e) {
        // print('Erro ao carregar ministérios do tenant: $e');
      }

      // Carregar ministérios da branch atual (se houver)
      if (_branchId != null && _branchId!.isNotEmpty) {
        try {
          final branchMinistries = await _ministryService.listMinistries(
            tenantId: _tenantId!,
            branchId: _branchId!,
            filters: ListMinistryDto(limit: 100), // Buscar todos
          );

          for (final ministry in branchMinistries.items) {
            _availableMinistries.add({
              'id': ministry.id,
              'name': ministry.name,
              'branchId': _branchId, // Ministério da branch
            });
          }
        } catch (e) {
          // print('Erro ao carregar ministérios da branch: $e');
        }
      }

      // print('✅ Ministérios carregados: ${_availableMinistries.length}');
      // for (final ministry in _availableMinistries) {
      //   print('   - ${ministry['name']} (Branch: ${ministry['branchId'] ?? 'Tenant'})');
      // }

    } catch (e) {
      // print('Erro ao carregar ministérios: $e');
      if (mounted) {
        FeedbackService.showLoadError(context, 'ministérios');
      }
    }
  }

  void _loadMockData() {
    // Dados mock como fallback
    _availableBranches = [
      {'id': 'branch1', 'name': 'Filial Centro'},
      {'id': 'branch2', 'name': 'Filial Norte'},
      {'id': 'branch3', 'name': 'Filial Sul'},
    ];
    
    _availableMinistries = [
      {'id': 'ministry1', 'name': 'Ministério de Música', 'branchId': 'branch1'},
      {'id': 'ministry2', 'name': 'Ministério de Louvor', 'branchId': 'branch1'},
      {'id': 'ministry3', 'name': 'Ministério de Crianças', 'branchId': 'branch2'},
      {'id': 'ministry4', 'name': 'Ministério de Jovens', 'branchId': null}, // Ministério do tenant
      {'id': 'ministry5', 'name': 'Ministério de Evangelismo', 'branchId': null},
    ];
  }

  void _loadMinistriesForBranch(String? branchId) {
    // Este método agora é chamado quando o usuário seleciona uma branch
    // Os ministérios já foram carregados em _loadMinistries()
    // Aqui apenas filtramos os ministérios disponíveis baseado na branch selecionada
    
    try {
      if (branchId == null) {
        // Mostrar ministérios do tenant (sem branch específica)
        setState(() {
          _availableMinistries = _availableMinistries.where((m) => m['branchId'] == null).toList();
        });
      } else {
        // Mostrar ministérios da branch específica
        setState(() {
          _availableMinistries = _availableMinistries.where((m) => m['branchId'] == branchId).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        FeedbackService.showLoadError(context, 'ministérios da filial');
      }
    }
  }
}

// ===== FORMATTERS DE MÁSCARA =====

class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove todos os caracteres não numéricos
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    // Limita a 11 dígitos
    final limitedDigits = digitsOnly.length > 11 
        ? digitsOnly.substring(0, 11) 
        : digitsOnly;
    
    // Aplica a máscara baseada no tamanho
    String formattedText = '';
    int selectionIndex = 0;
    
    if (limitedDigits.length <= 2) {
      formattedText = limitedDigits;
      selectionIndex = limitedDigits.length;
    } else if (limitedDigits.length <= 7) {
      formattedText = '(${limitedDigits.substring(0, 2)}) ${limitedDigits.substring(2)}';
      selectionIndex = formattedText.length;
    } else {
      formattedText = '(${limitedDigits.substring(0, 2)}) ${limitedDigits.substring(2, 7)}-${limitedDigits.substring(7)}';
      selectionIndex = formattedText.length;
    }
    
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}



class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
