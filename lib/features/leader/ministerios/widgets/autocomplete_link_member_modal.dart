import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/core/models/member.dart';
import 'package:servus_app/features/leader/ministerios/controllers/ministerios_detalhes_controller.dart';
import 'package:servus_app/services/members_service.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/core/constants/env.dart';
import 'package:dio/dio.dart';

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
  List<Member> _allMembers = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedRole = 'volunteer';
  
  // Estados do fluxo
  Member? _selectedMember;
  List<Map<String, dynamic>> _availableFunctions = [];
  List<String> _selectedFunctionIds = [];
  bool _isLoadingFunctions = false;

  @override
  void initState() {
    super.initState();
    _loadAllMembers();
    _loadMinistryFunctions();
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
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('🔍 Carregando todos os membros...');
      final response = await MembersService.getMembers(
        filter: MemberFilter(
          page: 1,
          limit: 100,
        ),
        context: context,
      );

      print('✅ Membros carregados: ${response.members.length}');
      setState(() {
        _allMembers = response.members;
      });
    } catch (e) {
      print('❌ Erro ao carregar membros: $e');
      setState(() {
        _errorMessage = 'Erro ao carregar membros: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMinistryFunctions() async {
    if (widget.controller.ministerioId.isEmpty) {
      print('❌ Ministério ID vazio');
      return;
    }
    
    setState(() {
      _isLoadingFunctions = true;
    });

    try {
      final dio = Dio();
      final token = await TokenService.getAccessToken();
      final baseUrl = Env.baseUrl;

      print('🔍 Carregando funções do ministério: ${widget.controller.ministerioId}');
      print('🔍 URL: $baseUrl/ministries/${widget.controller.ministerioId}/functions');
      print('🔍 Token: ${token?.substring(0, 20)}...');

      // Obter tenantId do token
      final tenantId = await _getTenantId();
      print('🔍 TenantId: $tenantId');
      
      print('🔍 Headers enviados:');
      print('   - Authorization: Bearer ${token?.substring(0, 20)}...');
      print('   - Content-Type: application/json');
      print('   - x-tenant-id: $tenantId');
      
      final response = await dio.get(
        '$baseUrl/ministries/${widget.controller.ministerioId}/functions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            if (tenantId != null) 'x-tenant-id': tenantId,
          },
        ),
      );

      print('✅ Resposta das funções: ${response.statusCode}');
      print('📊 Dados recebidos: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> functionsData = response.data;
        print('📊 Número de funções: ${functionsData.length}');
        
        setState(() {
          _availableFunctions = functionsData.map((f) {
            print('🔍 Processando função: $f');
            return {
              'id': f['functionId']?.toString() ?? f['_id']?.toString() ?? f['id']?.toString() ?? '',
              'name': f['name']?.toString() ?? f['functionName']?.toString() ?? 'Função sem nome',
              'description': f['description']?.toString() ?? '',
            };
          }).where((f) => (f['id'] as String).isNotEmpty && f['name'] != 'Função sem nome').toList();
        });
        print('✅ Funções processadas: ${_availableFunctions.length}');
        print('📋 Funções: ${_availableFunctions.map((f) => f['name']).toList()}');
      } else {
        print('❌ Erro na resposta: ${response.statusCode}');
        print('❌ Dados: ${response.data}');
      }
    } catch (e) {
      print('❌ Erro ao carregar funções: $e');
      print('❌ Stack trace: ${StackTrace.current}');
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
    
    print('🔧 Funções selecionadas: $_selectedFunctionIds');
  }

  Future<void> _linkToFunctions(String memberId, List<String> functionIds) async {
    try {
      final dio = Dio();
      final token = await TokenService.getAccessToken();
      final baseUrl = Env.baseUrl;
      final tenantId = await _getTenantId();

      print('🔧 Vinculando às funções: $functionIds');
      print('🔧 TenantId: $tenantId');

      final response = await dio.post(
        '$baseUrl/ministries/${widget.controller.ministerioId}/members/$memberId/functions',
        data: {
          'functionIds': functionIds,
          'status': 'em_treino',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            if (tenantId != null) 'x-tenant-id': tenantId,
          },
        ),
      );

      print('✅ Funções vinculadas: ${response.statusCode}');
    } catch (e) {
      print('❌ Erro ao vincular funções: $e');
      throw e;
    }
  }

  Future<void> _linkMember() async {
    if (_selectedMember == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      print('🔗 Vinculando ${_selectedMember!.name} ao ministério...');
      
      // PASSO 1: Vincular membro ao ministério (membership)
      final membershipSuccess = await widget.controller.vincularMembro(
        _selectedMember!.id, 
        _selectedRole,
      );
      
      if (!membershipSuccess) {
        throw Exception('Erro ao vincular ${_selectedMember!.name} ao ministério');
      }
      print('✅ ${_selectedMember!.name} vinculado ao ministério');

      // PASSO 2: Vincular às funções (se houver)
      if (_selectedFunctionIds.isNotEmpty) {
        print('📝 Vinculando ${_selectedMember!.name} às funções...');
        await _linkToFunctions(_selectedMember!.id, _selectedFunctionIds);
        print('✅ Funções vinculadas para ${_selectedMember!.name}');
      }

      // Sucesso
      if (mounted) {
        final message = _selectedFunctionIds.isEmpty
            ? '${_selectedMember!.name} vinculado ao ministério!'
            : '${_selectedMember!.name} vinculado ao ministério com ${_selectedFunctionIds.length} função(ões)!';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      print('❌ Erro ao vincular membro: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
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
                color: context.colors.surfaceVariant.withOpacity(0.3),
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
              onPressed: _loadAllMembers,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Autocomplete para busca de membros
        Autocomplete<Member>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<Member>.empty();
            }
            
            return _allMembers.where((member) {
              final query = textEditingValue.text.toLowerCase();
              return member.name.toLowerCase().contains(query) ||
                     member.email.toLowerCase().contains(query);
            });
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
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        
        // Membro selecionado
        if (_selectedMember != null) _buildSelectedMember(),
        
        // Funções (se houver membro selecionado)
        if (_selectedMember != null) ...[
          const SizedBox(height: 16),
          _buildFunctionsSection(),
        ],
      ],
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

  Widget _buildFunctionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant.withOpacity(0.3),
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
            SizedBox(
              height: 200, // Altura fixa para evitar problemas de layout
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Wrap(
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
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
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
        ),
      ],
    );
  }
}
