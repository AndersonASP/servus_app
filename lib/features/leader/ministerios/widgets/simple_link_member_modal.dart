import 'package:flutter/material.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/core/models/member.dart';
import 'package:servus_app/features/leader/ministerios/controllers/ministerios_detalhes_controller.dart';
import 'package:servus_app/services/members_service.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:dio/dio.dart';

class SimpleLinkMemberModal extends StatefulWidget {
  final MinisterioDetalhesController controller;

  const SimpleLinkMemberModal({
    super.key,
    required this.controller,
  });

  @override
  State<SimpleLinkMemberModal> createState() => _SimpleLinkMemberModalState();
}

class _SimpleLinkMemberModalState extends State<SimpleLinkMemberModal> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Estados
  List<Member> _allMembers = [];
  List<Member> _filteredMembers = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedRole = 'volunteer';
  
  // Estados do fluxo
  Member? _selectedMember; // Um membro por vez
  List<Map<String, dynamic>> _availableFunctions = [];
  List<String> _selectedFunctionIds = []; // Funções selecionadas
  bool _isLoadingFunctions = false;

  @override
  void initState() {
    super.initState();
    print('🔍 SimpleLinkMemberModal initState');
    print('🔍 controller.ministerioId: "${widget.controller.ministerioId}"');
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _loadAllMembers();
    _loadMinistryFunctions(); // Carregar funções do ministério atual
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterMembers();
  }

  void _onScroll() {
    // Não precisa de paginação com autocomplete
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
          limit: 100, // Carregar mais membros
        ),
        context: context,
      );

      print('✅ Membros carregados: ${response.members.length}');
      setState(() {
        _allMembers = response.members;
        _filteredMembers = response.members;
      });
    } catch (e) {
      print('❌ Erro ao carregar membros: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterMembers() {
    final query = _searchController.text.toLowerCase().trim();
    
    if (query.isEmpty) {
      setState(() {
        _filteredMembers = _allMembers;
      });
      return;
    }

    setState(() {
      _filteredMembers = _allMembers.where((member) {
        return member.name.toLowerCase().contains(query) ||
               member.email.toLowerCase().contains(query);
      }).toList();
    });
    
    print('🔍 Filtro aplicado: "$query" -> ${_filteredMembers.length} membros');
  }

  void _selectMember(Member member) {
    setState(() {
      _selectedMember = member;
      _selectedFunctionIds = []; // Limpar funções selecionadas
    });
    
    // Recarregar funções quando um membro for selecionado
    _loadMinistryFunctions();
  }


  Future<void> _loadMinistryFunctions() async {
    print('🔍 _loadMinistryFunctions chamada');
    print('🔍 ministerioId: "${widget.controller.ministerioId}"');
    print('🔍 ministerioId.isEmpty: ${widget.controller.ministerioId.isEmpty}');
    
    if (widget.controller.ministerioId.isEmpty) {
      print('❌ ministerioId está vazio, retornando');
      return;
    }
    
    setState(() {
      _isLoadingFunctions = true;
    });

    try {
      final dio = Dio();
      final context = await TokenService.getContext();
      final token = context['token'];
      final baseUrl = context['baseUrl'];

      print('🔍 Carregando funções do ministério: ${widget.controller.ministerioId}');
      print('🔍 baseUrl: $baseUrl');
      
      final url = '$baseUrl/ministries/${widget.controller.ministerioId}/functions';
      print('🔍 URL completa: $url');

      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('✅ Resposta das funções: ${response.statusCode}');
      print('📊 Dados das funções: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> functionsData = response.data;
        print('🔍 Dados brutos das funções: $functionsData');
        print('🔍 Tipo dos dados: ${functionsData.runtimeType}');
        print('🔍 Quantidade de funções: ${functionsData.length}');
        
        if (functionsData.isNotEmpty) {
          print('🔍 Primeira função: ${functionsData.first}');
          print('🔍 Chaves da primeira função: ${functionsData.first.keys}');
        }
        
        setState(() {
          _availableFunctions = functionsData
            .map((f) {
              print('🔍 Processando função: $f');
              return {
                'id': f['functionId']?.toString() ?? f['_id']?.toString() ?? '',
                'name': f['name']?.toString() ?? f['functionName']?.toString() ?? 'Função sem nome',
                'isActive': f['isActive'] ?? true,
              };
            })
            .where((f) => f['id'].isNotEmpty && f['name'] != 'Função sem nome')
            .toList();
        });
        
        print('✅ Funções mapeadas: ${_availableFunctions.length}');
        print('✅ Funções finais: $_availableFunctions');
      } else {
        throw Exception('Erro ao carregar funções: ${response.statusMessage}');
      }
    } catch (e) {
      print('❌ Erro ao carregar funções: $e');
      setState(() {
        _errorMessage = 'Erro ao carregar funções: $e';
      });
    } finally {
      setState(() {
        _isLoadingFunctions = false;
      });
    }
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

  Future<void> _linkMember() async {
    if (_selectedMember == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      print('🔗 Iniciando vinculação do membro ${_selectedMember!.name}');
      print('   - Ministério: ${widget.controller.ministerioId}');
      print('   - Role: $_selectedRole');
      print('   - Funções: $_selectedFunctionIds');

      // PASSO 1: Vincular ao ministério
      print('📝 PASSO 1: Vinculando ao ministério...');
      final membershipSuccess = await widget.controller.vincularMembro(
        _selectedMember!.id, 
        _selectedRole,
      );
      
      if (!membershipSuccess) {
        throw Exception('Erro ao vincular membro ao ministério');
      }
      print('✅ Membro vinculado ao ministério');

      // PASSO 2: Vincular às funções (se houver)
      if (_selectedFunctionIds.isNotEmpty) {
        print('📝 PASSO 2: Vinculando às funções...');
        await _linkToFunctions(_selectedMember!.id, _selectedFunctionIds);
        print('✅ Funções vinculadas');
      }

      // Sucesso
      if (mounted && context.mounted) {
        final message = _selectedFunctionIds.isEmpty
            ? '${_selectedMember!.name} vinculado ao ministério!'
            : '${_selectedMember!.name} vinculado ao ministério com ${_selectedFunctionIds.length} função(ões)!';
            
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          print('⚠️ Erro ao mostrar SnackBar de sucesso: $e');
        }
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('❌ Erro na vinculação: $e');
      if (mounted && context.mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: $e'),
              backgroundColor: Colors.red,
            ),
          );
        } catch (e) {
          print('⚠️ Erro ao mostrar SnackBar de erro: $e');
        }
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _linkToFunctions(String memberId, List<String> functionIds) async {
    try {
      final dio = Dio();
      final context = await TokenService.getContext();
      final token = context['token'];
      final baseUrl = context['baseUrl'];

      print('🔧 Vinculando às funções: $functionIds');

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
          },
        ),
      );

      print('📡 Resposta das funções: ${response.statusCode}');
      print('📊 Dados da resposta: ${response.data}');

      if (response.statusCode != 200) {
        throw Exception('Erro ao vincular funções: ${response.statusMessage}');
      }
    } catch (e) {
      print('❌ Erro ao vincular funções: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: context.colors.surface,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_add,
                    color: context.colors.onPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Vincular Membro',
                      style: context.textStyles.titleLarge?.copyWith(
                        color: context.colors.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: context.colors.onPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _selectedMember == null 
                  ? _buildMemberSelection()
                  : _buildFunctionSelection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Autocomplete Search
          Autocomplete<Member>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return _filteredMembers.take(10);
              }
              
              final query = textEditingValue.text.toLowerCase();
              return _allMembers.where((member) {
                return member.name.toLowerCase().contains(query) ||
                       member.email.toLowerCase().contains(query);
              }).take(10);
            },
            displayStringForOption: (Member member) => '${member.name} (${member.email})',
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              _searchController.text = controller.text;
              return TextField(
                controller: controller,
                focusNode: focusNode,
                onSubmitted: (value) => onFieldSubmitted(),
                decoration: InputDecoration(
                  hintText: 'Digite o nome ou email do membro...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            controller.clear();
                            _searchController.clear();
                            _filterMembers();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: context.colors.surface,
                ),
              );
            },
            onSelected: (Member member) {
              _searchController.text = '${member.name} (${member.email})';
              _selectMember(member);
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final member = options.elementAt(index);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: context.colors.primary.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.person,
                              color: context.colors.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            member.name,
                            style: context.textStyles.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            member.email,
                            style: context.textStyles.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          onTap: () => onSelected(member),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Role Selection
          Text(
            'Função no Ministério:',
            style: context.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Radio<String>(
                value: 'volunteer',
                groupValue: _selectedRole,
                onChanged: (value) => setState(() => _selectedRole = value!),
              ),
              const Text('Voluntário'),
              const SizedBox(width: 24),
              Radio<String>(
                value: 'leader',
                groupValue: _selectedRole,
                onChanged: (value) => setState(() => _selectedRole = value!),
              ),
              const Text('Líder'),
            ],
          ),

          const SizedBox(height: 24),

          // Info ou Loading
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Carregando membros...',
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (_errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red[700],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Erro ao carregar membros: $_errorMessage',
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _buildFunctionSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected Member
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colors.primary),
            ),
            child: Row(
              children: [
                Icon(Icons.person, color: context.colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedMember!.name,
                        style: context.textStyles.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.primary,
                        ),
                      ),
                      if (_selectedMember!.email.isNotEmpty)
                        Text(
                          _selectedMember!.email,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedMember = null;
                      _selectedFunctionIds = [];
                      _availableFunctions = [];
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Functions
          Text(
            'Funções do Ministério:',
            style: context.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          if (_isLoadingFunctions)
            const Center(child: CircularProgressIndicator())
          else if (_availableFunctions.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este ministério não possui funções disponíveis.',
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableFunctions.map((function) {
                final isSelected = _selectedFunctionIds.contains(function['id']);
                return GestureDetector(
                  onTap: () => _toggleFunction(function['id']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? context.colors.primary 
                          : context.colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected 
                            ? context.colors.primary 
                            : context.colors.outline,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? Icons.check : Icons.add,
                          size: 16,
                          color: isSelected 
                              ? context.colors.onPrimary 
                              : context.colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          function['name'],
                          style: context.textStyles.bodySmall?.copyWith(
                            color: isSelected 
                                ? context.colors.onPrimary 
                                : context.colors.onSurfaceVariant,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 24),

          // Action Button
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _linkMember,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: context.colors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                      : Text(
                          _selectedFunctionIds.isEmpty
                              ? 'Vincular ao Ministério'
                              : 'Vincular com ${_selectedFunctionIds.length} função(ões)',
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
