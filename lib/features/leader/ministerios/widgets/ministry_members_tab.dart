import 'package:flutter/material.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/ministerios/controllers/ministerios_detalhes_controller.dart';
import 'package:servus_app/features/leader/ministerios/widgets/autocomplete_link_member_modal.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/core/network/dio_client.dart';

class MinistryMembersTab extends StatefulWidget {
  final MinisterioDetalhesController controller;

  const MinistryMembersTab({
    super.key,
    required this.controller,
  });

  @override
  State<MinistryMembersTab> createState() => _MinistryMembersTabState();
}

class _MinistryMembersTabState extends State<MinistryMembersTab> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  // Estados para controle de expansão dos cards
  Set<String> _expandedCards = <String>{};
  Map<String, List<Map<String, dynamic>>> _memberFunctions = <String, List<Map<String, dynamic>>>{};
  Map<String, bool> _loadingFunctions = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Carrega os membros quando o widget é inicializado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.carregarMembros(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.controller.carregarMaisMembros();
    }
  }

  void _showLinkMemberModal() {
    showDialog(
      context: context,
      builder: (context) => AutocompleteLinkMemberModal(controller: widget.controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Barra de pesquisa
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar membros...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: context.colors.surface,
              ),
              onChanged: (value) {
                setState(() {});
                // TODO: Implementar busca em tempo real
              },
            ),
          ),

          // Lista de membros
          Expanded(
            child: _buildMembersList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLinkMemberModal,
        icon: const Icon(Icons.person_add),
        label: const Text('Vincular Membro'),
        backgroundColor: context.colors.primary,
        foregroundColor: context.colors.onPrimary,
      ),
    );
  }

  Widget _buildMembersList() {
    if (widget.controller.isLoadingMembers && widget.controller.membros.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (widget.controller.membersErrorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar membros',
              style: context.textStyles.titleMedium?.copyWith(
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.controller.membersErrorMessage,
              style: context.textStyles.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => widget.controller.carregarMembros(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: context.colors.onPrimary,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.controller.membros.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum membro encontrado',
              style: context.textStyles.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Este ministério ainda não possui membros vinculados.',
              style: context.textStyles.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => widget.controller.carregarMembros(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.controller.membros.length + 
            (widget.controller.hasMoreMembers ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= widget.controller.membros.length) {
            // Indicador de carregamento para paginação
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final membro = widget.controller.membros[index];
          return _buildMemberCard(membro);
        },
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> membro) {
    // A nova API retorna 'userId' populated, não 'user'
    final user = membro['userId'] ?? membro['user'] ?? {};
    final role = membro['role'] ?? 'volunteer';
    final isActive = membro['isActive'] ?? true;
    final membershipId = membro['_id'] ?? '';
    final userId = user['_id'] ?? '';
    final isExpanded = _expandedCards.contains(membershipId);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          // Cabeçalho do card (sempre visível)
          InkWell(
            onTap: () => _toggleCardExpansion(membershipId, userId),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Foto do usuário
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: context.colors.primary.withValues(alpha: 0.1),
                    backgroundImage: user['picture'] != null 
                        ? NetworkImage(user['picture']) 
                        : null,
                    child: user['picture'] == null
                        ? Icon(
                            role == 'leader' ? Icons.admin_panel_settings : Icons.person,
                            color: context.colors.primary,
                            size: 24,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  
                  // Nome do usuário
                  Expanded(
                    child: Text(
                      user['name'] ?? 'Nome não informado',
                      style: context.textStyles.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  
                  // Indicador de expansão
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                      transform: Matrix4.identity()..scale(isExpanded ? 1.1 : 1.0),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Menu de opções
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'remove':
                          _showRemoveMemberDialog(membershipId, user['name'] ?? 'Membro');
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(Icons.remove_circle, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Desvincular do ministério', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.more_vert,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Conteúdo expansível
          AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            child: ClipRect(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.topCenter,
                heightFactor: isExpanded ? 1.0 : 0.0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  opacity: isExpanded ? 1.0 : 0.0,
                  child: isExpanded 
                      ? _buildExpandedContent(membershipId, userId, role, isActive)
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Toggle da expansão do card
  void _toggleCardExpansion(String membershipId, String userId) {
    setState(() {
      if (_expandedCards.contains(membershipId)) {
        _expandedCards.remove(membershipId);
      } else {
        _expandedCards.add(membershipId);
        // Carregar funções se ainda não foram carregadas
        if (!_memberFunctions.containsKey(membershipId)) {
          _loadMemberFunctions(membershipId, userId);
        }
      }
    });
  }

  // Carregar funções do membro no ministério
  Future<void> _loadMemberFunctions(String membershipId, String userId) async {
    print('🔍 [FRONTEND] _loadMemberFunctions iniciado');
    print('🔍 [FRONTEND] membershipId: $membershipId');
    print('🔍 [FRONTEND] userId: $userId');
    
    if (_loadingFunctions[membershipId] == true) {
      print('⚠️ [FRONTEND] Já está carregando funções para este membership');
      return;
    }
    
    setState(() {
      _loadingFunctions[membershipId] = true;
    });

    try {
      print('🚀 [FRONTEND] Chamando _getUserFunctionsInMinistry...');
      // Buscar funções do usuário no ministério atual
      final functions = await _getUserFunctionsInMinistry(userId);
      print('✅ [FRONTEND] Funções obtidas: ${functions.length}');
      
      setState(() {
        _memberFunctions[membershipId] = functions;
        _loadingFunctions[membershipId] = false;
      });
      
      print('✅ [FRONTEND] Estado atualizado com ${functions.length} funções');
    } catch (e) {
      print('❌ [FRONTEND] Erro ao carregar funções: $e');
      setState(() {
        _memberFunctions[membershipId] = [];
        _loadingFunctions[membershipId] = false;
      });
    }
  }

  // Buscar funções do usuário no ministério atual
  Future<List<Map<String, dynamic>>> _getUserFunctionsInMinistry(String userId) async {
    try {
      print('🔍 [FRONTEND] _getUserFunctionsInMinistry iniciado');
      print('🔍 [FRONTEND] userId recebido: $userId');
      
      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];
      final ministryId = widget.controller.ministerioId;

      print('🔍 [FRONTEND] Context obtido:');
      print('   - tenantId: $tenantId');
      print('   - branchId: $branchId');
      print('   - ministryId: $ministryId');

      if (tenantId == null || ministryId.isEmpty) {
        print('❌ [FRONTEND] Context inválido - retornando lista vazia');
        return [];
      }

      // Fazer requisição para buscar funções do usuário no ministério específico
      final dio = DioClient.instance;

      String url = '/user-functions/user/$userId/ministry/$ministryId';
      Map<String, String> queryParams = {};

      if (branchId != null && branchId.isNotEmpty) {
        queryParams['branchId'] = branchId;
      }

      print('🔍 [FRONTEND] Fazendo requisição:');
      print('   - URL: $url');
      print('   - Query params: $queryParams');
      
      final response = await dio.get(
        url,
        queryParameters: queryParams,
      );
      
      print('🔍 [FRONTEND] Resposta recebida:');
      print('   - Status: ${response.statusCode}');
      print('   - Data: ${response.data}');
      
      if (response.statusCode == 200) {
        final List<dynamic> functionsData = response.data;
        print('✅ [FRONTEND] Funções encontradas: ${functionsData.length}');
        for (int i = 0; i < functionsData.length; i++) {
          print('   - Função $i: ${functionsData[i]}');
        }
        return functionsData.cast<Map<String, dynamic>>();
      }
      
      print('❌ [FRONTEND] Status não é 200 - retornando lista vazia');
      return [];
    } catch (e) {
      print('❌ [FRONTEND] Erro ao buscar funções do usuário: $e');
      return [];
    }
  }

  // Conteúdo expandido do card
  Widget _buildExpandedContent(String membershipId, String userId, String role, bool isActive) {
    final functions = _memberFunctions[membershipId] ?? [];
    final isLoading = _loadingFunctions[membershipId] ?? false;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            height: 1,
            color: Colors.grey[200],
            thickness: 0.5,
          ),
          const SizedBox(height: 16),
          
          // Informações do vínculo
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.admin_panel_settings,
                label: role == 'leader' ? 'Líder' : 'Voluntário',
                color: role == 'leader' ? Colors.blue : Colors.green,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                icon: Icons.circle,
                label: isActive ? 'Ativo' : 'Inativo',
                color: isActive ? Colors.green : Colors.red,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Seção de funções
          Text(
            'Funções no Ministério',
            style: context.textStyles.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (functions.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Nenhuma função atribuída',
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          else
            ...functions.map((function) => _buildFunctionItem(function)),
        ],
      ),
    );
  }

  // Widget para chips de informação
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: context.textStyles.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Widget para item de função
  Widget _buildFunctionItem(Map<String, dynamic> function) {
    print('🔍 [FRONTEND] _buildFunctionItem processando:');
    print('   - function: $function');
    print('   - function[\'function\']: ${function['function']}');
    print('   - function[\'function\'][\'name\']: ${function['function']?['name']}');
    print('   - function[\'name\']: ${function['name']}');
    print('   - function[\'status\']: ${function['status']}');
    
    final functionName = function['function']?['name'] ?? function['name'] ?? 'Função não informada';
    final status = function['status'] ?? 'pending';
    final statusText = _getStatusText(status);
    final statusColor = _getStatusColor(status);
    final primaryColor = context.colors.primary;
    
    print('✅ [FRONTEND] Dados processados:');
    print('   - functionName: $functionName');
    print('   - status: $status');
    print('   - statusText: $statusText');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.work, color: primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  functionName,
                  style: context.textStyles.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (function['function']?['description'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    function['function']['description'],
                    style: context.textStyles.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusText,
              style: context.textStyles.bodySmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Obter texto do status
  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'Aprovada';
      case 'pending':
        return 'Pendente';
      case 'rejected':
        return 'Rejeitada';
      default:
        return 'Desconhecido';
    }
  }

  // Obter cor do status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showRemoveMemberDialog(String membershipId, String memberName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remover membro',
          style: context.textStyles.titleLarge?.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        content: Text(
          'Tem certeza que deseja remover "$memberName" deste ministério?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await widget.controller.removerMembro(membershipId);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$memberName removido do ministério com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Erro ao remover membro do ministério'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}
