import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/core/models/member.dart';
import 'package:servus_app/features/leader/ministerios/controllers/ministerios_detalhes_controller.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';
import 'package:servus_app/core/enums/user_role.dart';
import 'package:servus_app/state/auth_state.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/services/members_service.dart';

class AutocompleteLinkMemberModal extends StatefulWidget {
  final MinisterioDetalhesController controller;

  const AutocompleteLinkMemberModal({
    super.key,
    required this.controller,
  });

  @override
  State<AutocompleteLinkMemberModal> createState() => _AutocompleteLinkMemberModalState();
}

class _AutocompleteLinkMemberModalState extends State<AutocompleteLinkMemberModal> {
  final TextEditingController _searchController = TextEditingController();
  
  // Estados
  List<Member> _availableMembers = []; // Membros ativos do tenant
  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedRole = 'volunteer';
  
  // Estados do fluxo
  Member? _selectedMember;
  List<Map<String, dynamic>> _availableFunctions = [];
  List<String> _selectedFunctionIds = [];
  bool _isLoadingFunctions = false;

  /// Verifica se o usuário logado pode vincular líderes
  bool get _canLinkLeaders {
    try {
      final authState = Provider.of<AuthState>(context, listen: false);
      final userRole = authState.usuario?.role;
      
      // Debug: Log do role do usuário
      print('🔍 [AutocompleteLinkMemberModal] Verificando permissões:');
      print('   - Usuario: ${authState.usuario != null}');
      print('   - User Role: $userRole');
      print('   - UserRole.tenant_admin: ${UserRole.tenant_admin}');
      print('   - UserRole.branch_admin: ${UserRole.branch_admin}');
      print('   - Tenant Admin: ${userRole == UserRole.tenant_admin}');
      print('   - Branch Admin: ${userRole == UserRole.branch_admin}');
      print('   - Can Link Leaders: ${userRole == UserRole.tenant_admin || userRole == UserRole.branch_admin}');
      
      // TenantAdmin e BranchAdmin podem vincular líderes
      return userRole == UserRole.tenant_admin || userRole == UserRole.branch_admin;
    } catch (e) {
      print('❌ [AutocompleteLinkMemberModal] Erro ao verificar permissões: $e');
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAllMembers();
    _loadMinistryFunctions();
  }

  // ✅ CORREÇÃO: Método para recarregar dados quando necessário
  Future<void> _refreshData() async {
    print('🔄 [AutocompleteLinkMemberModal] Recarregando dados...');
    await _loadAllMembers();
    await _loadMinistryFunctions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Obter tenantId do token
  Future<String?> _getTenantId() async {
    final token = await TokenService.getAccessToken();
    if (token == null) return null;
    
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(resp);
      
      return payloadMap['tenantId'];
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadAllMembers() async {
    if (_isLoading) return;
    
    print('🔍 [AutocompleteLinkMemberModal] ===== INICIANDO _loadAllMembers =====');
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('🔍 [AutocompleteLinkMemberModal] Carregando membros do tenant...');
      
      // ✅ CORREÇÃO: Usar a mesma API que funciona na lista de membros
      // Buscar membros através do MembershipService (que funciona)
      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];
      
      if (tenantId == null) {
        throw Exception('Tenant ID não encontrado');
      }
      
      print('🔍 [AutocompleteLinkMemberModal] Usando MembershipService...');
      print('   - Tenant ID: $tenantId');
      print('   - Branch ID: $branchId');
      
      // 🆕 CORREÇÃO: Usar endpoint correto para buscar todos os membros do tenant
      // Como não existe endpoint específico para todos os membros do tenant,
      // vamos usar o MembersService que já funciona
      final membersResponse = await MembersService.getMembers(
        filter: MemberFilter(isActive: true),
        context: null,
      );
      
      print('🔍 [AutocompleteLinkMemberModal] MembersService retornou:');
      print('   - Total de membros: ${membersResponse.members.length}');
      
      // 🆕 CORREÇÃO: Usar diretamente a resposta do MembersService
      final response = membersResponse;

      print('🔍 [AutocompleteLinkMemberModal] ===== RESPOSTA RECEBIDA =====');
      print('   - Status da resposta: OK');
      print('   - Total de membros ativos: ${response.members.length}');
      
      if (response.members.isEmpty) {
        print('⚠️ [AutocompleteLinkMemberModal] ATENÇÃO: Lista de membros está VAZIA!');
        print('   - Isso pode indicar problema na API ou filtro');
      } else {
        print('   - Primeiros 3 membros:');
        for (int i = 0; i < response.members.length && i < 3; i++) {
          final member = response.members[i];
          print('     ${i + 1}. ${member.name} (${member.id}) - Role: ${member.role} - Ativo: ${member.isActive}');
        }
      }
      
      // ✅ CORREÇÃO: Mostrar TODOS os membros ativos (sem filtrar por vinculação)
      print('🔍 [AutocompleteLinkMemberModal] Definindo membros disponíveis...');
      print('   - Total de membros ativos: ${response.members.length}');
      
      setState(() {
        _availableMembers = response.members; // Todos os membros ativos estão disponíveis
      });
      
      print('🔍 [AutocompleteLinkMemberModal] Membros definidos:');
      print('   - _availableMembers.length: ${_availableMembers.length}');
      
    } catch (e) {
      print('❌ [AutocompleteLinkMemberModal] Erro ao carregar membros: $e');
      setState(() {
        _errorMessage = 'Erro ao carregar membros: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ✅ REMOVIDO: Não precisamos mais carregar membros vinculados
  // O autocomplete agora mostra TODOS os membros ativos do tenant

  Future<void> _loadMinistryFunctions() async {
    if (widget.controller.ministerioId.isEmpty) {
      return;
    }
    
    setState(() {
      _isLoadingFunctions = true;
    });

    try {
      final dio = DioClient.instance;
      final token = await TokenService.getAccessToken();


      // Obter tenantId do token
      final tenantId = await _getTenantId();
      
      
      final response = await dio.get(
        '/ministries/${widget.controller.ministerioId}/functions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            if (tenantId != null) 'x-tenant-id': tenantId,
          },
        ),
      );


      if (response.statusCode == 200) {
        final List<dynamic> functionsData = response.data;
        
        setState(() {
          _availableFunctions = functionsData.map((f) {
            return {
              'id': f['functionId']?.toString() ?? f['_id']?.toString() ?? f['id']?.toString() ?? '',
              'name': f['name']?.toString() ?? f['functionName']?.toString() ?? 'Função sem nome',
              'description': f['description']?.toString() ?? '',
            };
          }).where((f) => (f['id'] as String).isNotEmpty && f['name'] != 'Função sem nome').toList();
        });
      } else {
      }
    } finally {
      setState(() {
        _isLoadingFunctions = false;
      });
    }
  }

  void _selectMember(Member member) {
    setState(() {
      _selectedMember = member;
      _selectedFunctionIds = [];
    });
    
    // Limpar o campo de busca
    _searchController.clear();
    
    // Recarregar funções quando um membro for selecionado
    _loadMinistryFunctions();
  }

  void _removeSelectedMember() {
    setState(() {
      _selectedMember = null;
      _selectedFunctionIds = [];
    });
  }

  void _toggleFunction(String functionId) {
    setState(() {
      if (_selectedFunctionIds.contains(functionId)) {
        _selectedFunctionIds.remove(functionId);
      } else {
        _selectedFunctionIds.add(functionId);
      }
    });
    
  }

  Future<void> _linkToFunctions(String memberId, List<String> functionIds) async {
    try {
      final dio = DioClient.instance;
      final token = await TokenService.getAccessToken();
      final tenantId = await _getTenantId();


      await dio.post(
        '/ministries/${widget.controller.ministerioId}/members/$memberId/functions',
        data: {
          'functionIds': functionIds,
          'status': 'pending',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            if (tenantId != null) 'x-tenant-id': tenantId,
          },
        ),
      );

    } catch (e) {
      rethrow;
    }
  }

  Future<void> _linkMember() async {
    if (_selectedMember == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // ✅ CORREÇÃO: Validar se o membro está ativo antes de vincular
      if (_selectedMember!.isActive != true) {
        throw Exception('Não é possível vincular ${_selectedMember!.name} pois o usuário está inativo');
      }
      
      // PASSO 1: Vincular membro ao ministério (membership)
      final membershipSuccess = await widget.controller.vincularMembro(
        _selectedMember!.id, 
        _selectedRole,
      );
      
      if (!membershipSuccess) {
        throw Exception('Erro ao vincular ${_selectedMember!.name} ao ministério');
      }

      // PASSO 2: Vincular às funções (se houver)
      if (_selectedFunctionIds.isNotEmpty) {
        await _linkToFunctions(_selectedMember!.id, _selectedFunctionIds);
      }

      // Sucesso
      if (mounted) {
        final message = _selectedFunctionIds.isEmpty
            ? '${_selectedMember!.name} vinculado ao ministério!'
            : '${_selectedMember!.name} vinculado ao ministério com ${_selectedFunctionIds.length} função(ões)!';
        
        showSuccess(context, message);
        
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        showError(context, 'Erro: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          minHeight: 300,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_add, color: context.colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vincular Membro',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: context.colors.onPrimaryContainer),
                  ),
                ],
              ),
            ),
            
            // Conteúdo
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildContent(),
              ),
            ),
            
            // Botões
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: _buildActionButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
        // Autocomplete para busca de membros
        Autocomplete<Member>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<Member>.empty();
            }
            
            // ✅ CORREÇÃO: Usar sempre _availableMembers (já filtrados corretamente)
            final membersToSearch = _availableMembers;
            
            print('🔍 [AutocompleteLinkMemberModal] Buscando membros para: "${textEditingValue.text}"');
            print('   - Usando lista: membros ativos do tenant');
            print('   - Total na lista: ${membersToSearch.length}');
            
            final results = membersToSearch.where((member) {
              final query = textEditingValue.text.toLowerCase();
              final matches = member.name.toLowerCase().contains(query) ||
                             member.email.toLowerCase().contains(query);
              
              if (matches) {
                print('   - Sugestão: ${member.name} (${member.id})');
              }
              
              return matches;
            }).toList();
            
            print('   - Total de sugestões: ${results.length}');
            
            return results;
          },
          displayStringForOption: (Member member) => '${member.name} (${member.email})',
          onSelected: (Member member) {
            _selectMember(member);
            // Limpar o campo após seleção
            Future.microtask(() {
              _searchController.clear();
            });
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'Digite o nome ou email do membro...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                    bottomLeft: Radius.zero,
                    bottomRight: Radius.zero,
                  ),
                  borderSide: BorderSide(
                    color: context.colors.outline.withOpacity(0.3),
                    width: 1.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                    bottomLeft: Radius.zero,
                    bottomRight: Radius.zero,
                  ),
                  borderSide: BorderSide(
                    color: context.colors.outline.withOpacity(0.3),
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                    bottomLeft: Radius.zero,
                    bottomRight: Radius.zero,
                  ),
                  borderSide: BorderSide(
                    color: context.colors.primary.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                  topLeft: Radius.zero,
                  topRight: Radius.zero,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                        topLeft: Radius.zero,
                        topRight: Radius.zero,
                      ),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return InkWell(
                          onTap: () => onSelected(option),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.surface,
                              borderRadius: index == options.length - 1
                                  ? const BorderRadius.only(
                                      bottomLeft: Radius.circular(28),
                                      bottomRight: Radius.circular(28),
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: context.colors.primary,
                                  radius: 16,
                                  child: Text(
                                    option.name[0].toUpperCase(),
                                    style: TextStyle(
                                      color: context.colors.onPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: context.colors.onSurface,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        option.email,
                                        style: TextStyle(
                                          color: context.colors.onSurface,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        
        // ✅ CORREÇÃO: Mensagem informativa atualizada
        if (_availableMembers.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nenhum membro ativo encontrado no tenant.',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: context.colors.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: context.colors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Todos os membros ativos do tenant estão disponíveis para vinculação.',
                    style: TextStyle(
                      color: context.colors.onSurface.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Membro selecionado
        if (_selectedMember != null) _buildSelectedMember(),
        
        // Seleção de Role (Voluntário ou Líder) - apenas se membro selecionado
        if (_selectedMember != null) ...[
          const SizedBox(height: 16),
          _buildRoleSelection(),
        ],
        
        // Funções (apenas para voluntários)
        if (_selectedMember != null && _selectedRole == 'volunteer') ...[
          const SizedBox(height: 16),
          _buildFunctionsSection(),
        ],
        ],
      ),
    );
  }

  Widget _buildSelectedMember() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.colors.primary.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: context.colors.primary,
              radius: 24,
              child: Text(
                _selectedMember!.name[0].toUpperCase(),
                style: TextStyle(
                  color: context.colors.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedMember!.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: context.colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedMember!.email,
                    style: TextStyle(
                      color: context.colors.onPrimaryContainer.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _removeSelectedMember,
              icon: Icon(Icons.close, color: context.colors.onPrimaryContainer),
              tooltip: 'Remover seleção',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.colors.outline.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipo de Vínculo',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: context.colors.onSurface,
              fontSize: 14,
            ),
          ),
          Row(
            children: [
              Radio<String>(
                value: 'volunteer',
                groupValue: _selectedRole,
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                    // Limpar funções selecionadas ao mudar para líder
                    if (value == 'leader') {
                      _selectedFunctionIds = [];
                    }
                  });
                },
              ),
              const Text('Voluntário'),
              const SizedBox(width: 16),
              // Mostrar opção de líder apenas se o usuário tem permissão
              if (_canLinkLeaders) ...[
                Radio<String>(
                  value: 'leader',
                  groupValue: _selectedRole,
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                      // Limpar funções selecionadas ao mudar para líder
                      if (value == 'leader') {
                        _selectedFunctionIds = [];
                      }
                    });
                  },
                ),
                const Text('Líder'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.colors.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.work, color: context.colors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Funções do Ministério',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurface,
                ),
              ),
              if (_isLoadingFunctions) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          
          if (_isLoadingFunctions)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Carregando funções...', style: TextStyle(color: Colors.grey)),
              ),
            )
          else if (_availableFunctions.isEmpty) ...[
            // Debug info
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.yellow.withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DEBUG INFO:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('_isLoadingFunctions: $_isLoadingFunctions'),
                  Text('_availableFunctions.length: ${_availableFunctions.length}'),
                  Text('_availableFunctions: $_availableFunctions'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nenhuma função disponível para este ministério',
                      style: TextStyle(color: Colors.orange[700]),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadMinistryFunctions,
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            ),
          ]
          else
            _buildResponsiveFunctionsList(),
        ],
      ),
    );
  }

  Widget _buildResponsiveFunctionsList() {
    // Calcular altura baseada na quantidade de funções
    final functionCount = _availableFunctions.length;
    final maxHeight = MediaQuery.of(context).size.height * 0.4; // Máximo 40% da tela
    
    // Altura baseada na quantidade de funções
    double calculatedHeight;
    if (functionCount <= 2) {
      calculatedHeight = 80; // Altura mínima para poucas funções
    } else if (functionCount <= 4) {
      calculatedHeight = 120; // Altura média
    } else if (functionCount <= 6) {
      calculatedHeight = 160; // Altura maior
    } else {
      calculatedHeight = 200; // Altura máxima com scroll
    }
    
    // Limitar altura máxima
    final finalHeight = calculatedHeight > maxHeight ? maxHeight : calculatedHeight;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: finalHeight,
        minHeight: 60,
      ),
      child: functionCount > 6 
        ? SingleChildScrollView(
            child: _buildFunctionsWrap(),
          )
        : _buildFunctionsWrap(),
    );
  }

  Widget _buildFunctionsWrap() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableFunctions.map((function) {
        final functionId = function['id']?.toString() ?? '';
        if (functionId.isEmpty) return const SizedBox.shrink();
        
        final isSelected = _selectedFunctionIds.contains(functionId);
        return GestureDetector(
          onTap: () => _toggleFunction(functionId),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected 
                  ? context.colors.primary 
                  : context.colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected 
                    ? context.colors.primary
                    : context.colors.outline.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: context.colors.primary.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ] : null,
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
                  function['name'],
                  style: TextStyle(
                    color: isSelected 
                        ? Colors.white 
                        : context.colors.onSurface,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
          child: const Text(
            'Cancelar',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _selectedMember == null || _isLoading 
              ? null 
              : _linkMember,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colors.primary,
            foregroundColor: context.colors.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Vincular Membro',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
