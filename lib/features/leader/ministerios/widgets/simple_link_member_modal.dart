import 'package:flutter/material.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/core/models/member.dart';
import 'package:servus_app/features/leader/ministerios/controllers/ministerios_detalhes_controller.dart';
import 'package:servus_app/services/members_service.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';
import 'package:dio/dio.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:servus_app/core/enums/user_role.dart';
import 'package:servus_app/state/auth_state.dart';
import 'package:provider/provider.dart';

class SimpleLinkMemberModal extends StatefulWidget {
  final MinisterioDetalhesController controller;

  const SimpleLinkMemberModal({
    super.key,
    required this.controller,
  });

  @override
  State<SimpleLinkMemberModal> createState() => _SimpleLinkMemberModalState();
}

class _SimpleLinkMemberModalState extends State<SimpleLinkMemberModal> with TickerProviderStateMixin {
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
  
  // Controllers para animações
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  /// Verifica se o usuário logado pode vincular líderes
  bool get _canLinkLeaders {
    try {
      final authState = Provider.of<AuthState>(context, listen: false);
      final userRole = authState.usuario?.role;
      
      // Debug: Log do role do usuário
      print('🔍 [SimpleLinkMemberModal] Verificando permissões:');
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
      print('❌ [SimpleLinkMemberModal] Erro ao verificar permissões: $e');
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    
    // Inicializar animações
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _loadAllMembers();
    _loadMinistryFunctions(); // Carregar funções do ministério atual
    
    // Iniciar animação após um pequeno delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
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
      final response = await MembersService.getMembers(
        filter: MemberFilter(
          page: 1,
          limit: 100, // Carregar mais membros
        ),
        context: context,
      );

      setState(() {
        _allMembers = response.members;
        _filteredMembers = response.members;
      });
    } catch (e) {
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
    
    if (widget.controller.ministerioId.isEmpty) {
      return;
    }
    
    setState(() {
      _isLoadingFunctions = true;
    });

    try {
      final dio = DioClient.instance;
      final context = await TokenService.getContext();
      final token = context['token'];

      
      final url = '/ministries/${widget.controller.ministerioId}/functions';

      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );


      if (response.statusCode == 200) {
        final List<dynamic> functionsData = response.data;
        
        if (functionsData.isNotEmpty) {
        }
        
        setState(() {
          _availableFunctions = functionsData
            .map((f) {
              return {
                'id': f['functionId']?.toString() ?? f['_id']?.toString() ?? '',
                'name': f['name']?.toString() ?? f['functionName']?.toString() ?? 'Função sem nome',
                'isActive': f['isActive'] ?? true,
              };
            })
            .where((f) => f['id'].isNotEmpty && f['name'] != 'Função sem nome')
            .toList();
        });
        
      } else {
        throw Exception('Erro ao carregar funções: ${response.statusMessage}');
      }
    } catch (e) {
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
    
  }

  Future<void> _linkMember() async {
    if (_selectedMember == null) return;

    try {
      setState(() {
        _isLoading = true;
      });


      // PASSO 1: Vincular ao ministério
      final membershipSuccess = await widget.controller.vincularMembro(
        _selectedMember!.id, 
        _selectedRole,
      );
      
      if (!membershipSuccess) {
        throw Exception('Erro ao vincular membro ao ministério');
      }

      // PASSO 2: Vincular às funções (se houver)
      if (_selectedFunctionIds.isNotEmpty) {
        await _linkToFunctions(_selectedMember!.id, _selectedFunctionIds);
      }

      // Sucesso
      if (mounted && context.mounted) {
        final message = _selectedFunctionIds.isEmpty
            ? '${_selectedMember!.name} vinculado ao ministério!'
            : '${_selectedMember!.name} vinculado ao ministério com ${_selectedFunctionIds.length} função(ões)!';
            
        try {
          ServusSnackQueue.addToQueue(
            context: context,
            message: message,
            type: ServusSnackType.success,
          );
        } catch (e) {
        }
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted && context.mounted) {
        try {
          ServusSnackQueue.addToQueue(
            context: context,
            message: 'Erro: $e',
            type: ServusSnackType.error,
          );
        } catch (e) {
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
      final dio = DioClient.instance;
      final context = await TokenService.getContext();
      final token = context['token'];


      final response = await dio.post(
        '/ministries/${widget.controller.ministerioId}/members/$memberId/functions',
        data: {
          'functionIds': functionIds,
          'status': 'pending',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );


      if (response.statusCode != 200) {
        throw Exception('Erro ao vincular funções: ${response.statusMessage}');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Dialog(
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
            ),
          ),
        );
      },
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
                    borderRadius: BorderRadius.circular(20),
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
              // Mostrar opção de líder apenas se o usuário tem permissão
              if (_canLinkLeaders) ...[
                Radio<String>(
                  value: 'leader',
                  groupValue: _selectedRole,
                  onChanged: (value) => setState(() => _selectedRole = value!),
                ),
                const Text('Líder'),
              ],
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
                          : context.colors.surfaceContainerHighest,
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
