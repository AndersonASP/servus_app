import 'package:flutter/material.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/ministerios/controllers/ministerios_detalhes_controller.dart';
import 'package:servus_app/features/leader/ministerios/widgets/autocomplete_link_member_modal.dart';
import 'package:servus_app/features/leader/ministerios/widgets/invite_code_modal.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';
import 'package:servus_app/shared/widgets/fab_safe_scroll_view.dart';

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

  void _showInviteCodeModal() {
    showDialog(
      context: context,
      builder: (context) => InviteCodeModal(
        ministryId: widget.controller.ministerioId,
        ministryName: widget.controller.nomeMinisterio,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FabSafeScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // Barra de pesquisa
            Padding(
              padding: const EdgeInsets.all(5),
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
                    borderRadius: BorderRadius.circular(20),
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
            _buildMembersList(),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Botão de convite por código
          FloatingActionButton.extended(
            onPressed: _showInviteCodeModal,
            icon: const Icon(Icons.card_giftcard),
            label: const Text('Convidar'),
            backgroundColor: context.colors.secondary,
            foregroundColor: context.colors.onSecondary,
            heroTag: 'invite_button',
          ),
          const SizedBox(width: 8),
          // Botão de vincular membro existente
          FloatingActionButton.extended(
            onPressed: _showLinkMemberModal,
            icon: const Icon(Icons.person_add),
            label: const Text('Vincular'),
            backgroundColor: context.colors.primary,
            foregroundColor: context.colors.onPrimary,
            heroTag: 'link_button',
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildMembersList() {
    if (widget.controller.isLoadingMembers && widget.controller.membros.isEmpty) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (widget.controller.membersErrorMessage.isNotEmpty) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
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
        ),
      );
    }

    if (widget.controller.membros.isEmpty) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
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
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => widget.controller.carregarMembros(refresh: true),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: widget.controller.membros.length + 
            (widget.controller.hasMoreMembers ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
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
      margin: const EdgeInsets.fromLTRB(5, 0, 5, 8),
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
    
    if (_loadingFunctions[membershipId] == true) {
      return;
    }
    
    setState(() {
      _loadingFunctions[membershipId] = true;
    });

    try {
      // Buscar funções do usuário no ministério atual
      final functions = await _getMemberFunctionsInMinistry(userId);
      
      setState(() {
        _memberFunctions[membershipId] = functions;
        _loadingFunctions[membershipId] = false;
      });
      
    } catch (e) {
      setState(() {
        _memberFunctions[membershipId] = [];
        _loadingFunctions[membershipId] = false;
      });
    }
  }

  // Buscar funções do usuário no ministério atual
  Future<List<Map<String, dynamic>>> _getMemberFunctionsInMinistry(String userId) async {
    try {
      
      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];
      final ministryId = widget.controller.ministerioId;


      if (tenantId == null || ministryId.isEmpty) {
        return [];
      }

      // Fazer requisição para buscar funções do usuário no ministério específico
      final dio = DioClient.instance;

      String url = '/member-functions/user/$userId/ministry/$ministryId';
      Map<String, String> queryParams = {};

      if (branchId != null && branchId.isNotEmpty) {
        queryParams['branchId'] = branchId;
      }

      
      final response = await dio.get(
        url,
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> functionsData = response.data;
        return functionsData.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
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
    
    // Suportar a estrutura retornada pelo backend MemberFunctionService
    // O backend retorna: { function: { name, description }, status, ... }
    // Se function é null/undefined, significa que a função não foi populada (função deletada)
    final functionData = function['function'];
    final functionName = functionData != null && functionData['name'] != null 
        ? functionData['name'] 
        : 'Função não encontrada';
    final functionDescription = functionData?['description'];
    final status = function['status'] ?? 'pending';
    final statusText = _getStatusText(status);
    final statusColor = _getStatusColor(status);
    final primaryColor = context.colors.primary;
    

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
                if (functionDescription != null && functionDescription.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    functionDescription,
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
      case 'aprovado': // ✅ Suporte ao status em português do backend
        return 'Aprovada';
      case 'pending':
        return 'Pendente';
      case 'rejected':
      case 'rejeitado': // ✅ Suporte ao status em português do backend
        return 'Rejeitada';
      default:
        return 'Desconhecido ($status)'; // ✅ Mostrar o status real para debug
    }
  }

  // Obter cor do status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
      case 'aprovado': // ✅ Suporte ao status em português do backend
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
      case 'rejeitado': // ✅ Suporte ao status em português do backend
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showRemoveMemberDialog(String membershipId, String memberName) {
    // Encontrar o membro na lista para obter informações detalhadas
    final membro = widget.controller.membros.firstWhere(
      (m) => m['_id'] == membershipId,
      orElse: () => {},
    );
    
    final user = membro['userId'] ?? membro['user'] ?? {};
    final role = membro['role'] ?? 'volunteer';
    final memberEmail = user['email'] ?? 'Email não informado';
    final memberPhone = user['phone'] ?? 'Telefone não informado';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Desvincular do Ministério',
                style: context.textStyles.titleLarge?.copyWith(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Você está prestes a desvincular:',
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            
            // Informações do membro
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          memberName,
                          style: context.textStyles.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.email, color: Colors.red.shade600, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          memberEmail,
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: Colors.red.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone, color: Colors.red.shade600, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          memberPhone,
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: Colors.red.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        role == 'leader' ? Icons.admin_panel_settings : Icons.person,
                        color: Colors.red.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        role == 'leader' ? 'Líder do Ministério' : 'Voluntário',
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Aviso sobre consequências
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Consequências da desvinculação:',
                        style: context.textStyles.bodySmall?.copyWith(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Todas as funções do membro neste ministério serão removidas\n'
                    '• O membro perderá acesso às atividades do ministério\n'
                    '• Esta ação não pode ser desfeita automaticamente',
                    style: context.textStyles.bodySmall?.copyWith(
                      color: Colors.orange.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: context.colors.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _confirmRemoveMember(context, membershipId, memberName),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Desvincular'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemoveMember(BuildContext context, String membershipId, String memberName) async {
    // Salvar referência do navigator antes de qualquer operação assíncrona
    final navigator = Navigator.of(context);
    
    // Fechar dialog de confirmação
    navigator.pop();
    
    // Mostrar loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Desvinculando membro...',
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final success = await widget.controller.removerMembro(membershipId);
      
      // Fechar loading
      if (mounted) navigator.pop();
      
      if (success) {
        if (mounted) {
          showSuccess(context, '$memberName foi desvinculado do ministério com sucesso!');
        }
      } else {
        if (mounted) {
          showError(context, 'Erro ao desvincular membro do ministério. Tente novamente.');
        }
      }
    } catch (e) {
      // Fechar loading
      if (mounted) navigator.pop();
      
      if (mounted) {
        String errorMessage = 'Erro ao desvincular membro';
        
        if (e.toString().contains('permissão') || e.toString().contains('403')) {
          errorMessage = 'Você não tem permissão para desvincular este membro. Verifique se você é líder deste ministério.';
        } else if (e.toString().contains('não encontrado') || e.toString().contains('404')) {
          errorMessage = 'Membro não encontrado ou já foi desvinculado';
        } else if (e.toString().contains('conexão') || e.toString().contains('timeout')) {
          errorMessage = 'Problema de conexão. Verifique sua internet e tente novamente';
        } else if (e.toString().contains('membership ativo')) {
          errorMessage = 'Problema de permissão: Verifique se você tem acesso a este ministério';
        } else {
          errorMessage = 'Erro ao desvincular membro: ${e.toString()}';
        }
        
        showError(context, errorMessage);
      }
    }
  }
}
