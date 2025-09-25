import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/volunteers/controllers/volunteers_controller.dart';
import 'package:servus_app/features/members/create/create_member_screen.dart';
import 'package:servus_app/state/auth_state.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';
import 'package:servus_app/shared/widgets/fab_safe_scroll_view.dart';

class VolunteersDashboardScreen extends StatefulWidget {
  const VolunteersDashboardScreen({super.key});

  @override
  State<VolunteersDashboardScreen> createState() => _VolunteersDashboardScreenState();
}

class _VolunteersDashboardScreenState extends State<VolunteersDashboardScreen> {
  late final VolunteersController controller;
  String _selectedFilter = 'total'; // 'total', 'pending'
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthState>(context, listen: false);
    controller = VolunteersController(auth: auth);
    controller.init();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Consumer<VolunteersController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: context.theme.scaffoldBackgroundColor,
            appBar: AppBar(
              title: const Text('Voluntários'),
              centerTitle: false,
              backgroundColor: Colors.transparent,
              foregroundColor: context.colors.onSurface,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: context.colors.onSurface,
                ),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/leader/dashboard');
                  }
                },
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: context.colors.onSurface,
                  ),
                  onPressed: () => controller.refreshVolunteers(),
                ),
              ],
            ),
            body: controller.isLoading && !controller.isInitialized
                ? const Center(child: CircularProgressIndicator())
                : FabSafeScrollView(
                    controller: _scrollController,
                    child: RefreshIndicator(
                      onRefresh: () => controller.refreshVolunteers(),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cards de estatísticas (agora funcionam como filtros)
                            _buildStatsCards(context, controller),
                            
                            const SizedBox(height: 24),
                            
                            // Lista de voluntários
                            _buildVolunteersList(context, controller),
                          ],
                        ),
                      ),
                    ),
                  ),
            // Botão flutuante para criar novo voluntário
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateMemberScreen(
                      restrictToVolunteer: true,
                      restrictToLeaderMinistry: true,
                    ),
                  ),
                );
                if (result == true) {
                  controller.refreshVolunteers();
                }
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Novo Voluntário'),
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          );
        },
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context, VolunteersController controller) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Total',
            controller.totalVolunteers.toString(),
            Icons.people,
            Colors.blue,
            'total',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'Pendentes',
            controller.pendingApprovalsCount.toString(),
            Icons.pending,
            Colors.orange,
            'pending',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color, String filterType) {
    final isSelected = _selectedFilter == filterType;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = filterType;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : context.colors.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: context.textStyles.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildVolunteersList(BuildContext context, VolunteersController controller) {
    // Filtrar voluntários baseado no filtro selecionado
    List<Map<String, dynamic>> filteredVolunteers = [];
    
    switch (_selectedFilter) {
      case 'pending':
        filteredVolunteers = controller.pendingApprovals;
        break;
      case 'total':
      default:
        // Mostrar apenas voluntários aprovados (da tabela membership)
        filteredVolunteers = controller.volunteers;
        break;
    }

    if (filteredVolunteers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: context.colors.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum voluntário encontrado',
              style: context.textStyles.titleMedium?.copyWith(
                color: context.colors.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Os voluntários aparecerão aqui quando se registrarem',
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getFilterTitle(),
          style: context.textStyles.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        ...filteredVolunteers.map((volunteer) => 
          _buildExpandableVolunteerCard(context, volunteer)
        ),
      ],
    );
  }

  String _getFilterTitle() {
    switch (_selectedFilter) {
      case 'pending':
        return 'Voluntários Pendentes';
      case 'total':
      default:
        return 'Voluntários Aprovados';
    }
  }

  Widget _buildExpandableVolunteerCard(BuildContext context, Map<String, dynamic> volunteer) {
    return _ExpandableVolunteerCard(
      volunteer: volunteer,
      controller: controller,
      onApprove: (volunteerId, notes, context) async {
        debugPrint('🎯 [VolunteersDashboard] Iniciando aprovação...');
        debugPrint('   - Volunteer ID: $volunteerId');
        debugPrint('   - Source: ${volunteer['source']}');
        debugPrint('   - Source type: ${volunteer['source'].runtimeType}');
        debugPrint('   - Notes: $notes');
        debugPrint('   - Volunteer completo: $volunteer');
        
        // Verificar se é voluntário de invite (precisa escolher função)
        if (volunteer['source'] == 'invite') {
          debugPrint('🎯 [VolunteersDashboard] Voluntário de invite - abrindo dialog de função');
          // Para invites, mostrar dialog para escolher função
          await _showFunctionSelectionDialog(context, volunteerId, notes, volunteer);
        } else {
          debugPrint('🎯 [VolunteersDashboard] Voluntário de formulário - aprovando diretamente');
          // Para formulários, aprovar diretamente
          final success = await controller.approveVolunteer(volunteerId, notes: notes);
          debugPrint('🎯 [VolunteersDashboard] Resultado da aprovação: $success');
          
          if (success) {
            showSuccess(context, 'Voluntário aprovado com sucesso!');
          } else {
            showError(context, 'Erro ao aprovar voluntário');
          }
        }
      },
      onReject: (volunteerId, notes, context) async {
        final success = await controller.rejectVolunteer(volunteerId, notes: notes);
        unawaited(() async {
          if (success) {
            showSuccess(context, 'Voluntário rejeitado');
          } else {
            showError(context, 'Erro ao rejeitar voluntário');
          }
        }());
      },
    );
  }

  /// Mostra dialog para seleção de função para voluntários de invite
  Future<void> _showFunctionSelectionDialog(
    BuildContext context, 
    String volunteerId, 
    String? notes, 
    Map<String, dynamic> volunteer
  ) async {
    debugPrint('🎯 [FunctionDialog] Iniciando dialog de seleção de função...');
    debugPrint('   - Volunteer ID: $volunteerId');
    debugPrint('   - Ministry: ${volunteer['ministry']}');
    debugPrint('   - Ministry type: ${volunteer['ministry'].runtimeType}');
    
    // Extrair ministryId de forma mais segura
    String? ministryId;
    final ministry = volunteer['ministry'];
    
    if (ministry is Map<String, dynamic>) {
      ministryId = ministry['id']?.toString();
    } else if (ministry is List && ministry.isNotEmpty) {
      // Se for uma lista, pegar o primeiro elemento
      final firstMinistry = ministry.first;
      if (firstMinistry is Map<String, dynamic>) {
        ministryId = firstMinistry['id']?.toString();
      }
    }
    
    debugPrint('   - Ministry ID: $ministryId');
    debugPrint('   - Ministry ID type: ${ministryId.runtimeType}');
    
    if (ministryId == null || ministryId.isEmpty) {
      debugPrint('❌ [FunctionDialog] Ministério não encontrado');
      showError(context, 'Ministério não encontrado');
      return;
    }

    debugPrint('🔍 [FunctionDialog] Buscando funções do ministério: $ministryId');
        // Buscar funções do ministério
        final functions = await controller.getMinistryFunctions(ministryId);
        debugPrint('🔍 [FunctionDialog] Funções encontradas: ${functions.length}');
        debugPrint('🔍 [FunctionDialog] Primeira função (raw): ${functions.isNotEmpty ? functions.first : 'Nenhuma'}');
    
    if (functions.isEmpty) {
      debugPrint('❌ [FunctionDialog] Nenhuma função disponível');
      showError(context, 'Nenhuma função disponível para este ministério');
      return;
    }

        List<String> selectedFunctionIds = [];
        List<String> selectedFunctionNames = [];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.person_add, color: context.colors.primary),
              const SizedBox(width: 8),
              Text('Escolher Função', style: context.textStyles.titleLarge?.copyWith(
                color: context.colors.onSurface,
                fontWeight: FontWeight.bold,
              )),
            ],
          ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Para aprovar este voluntário, escolha uma ou mais funções:',
                    style: TextStyle(
                      fontSize: 16,
                      color: context.colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...functions.map((function) {
                    debugPrint('🔍 [FunctionDialog] Processando função: $function');
                    debugPrint('🔍 [FunctionDialog] - id: ${function['id']}');
                    debugPrint('🔍 [FunctionDialog] - name: ${function['name']}');
                    debugPrint('🔍 [FunctionDialog] - description: ${function['description']}');
                    
                    return CheckboxListTile(
                      title: Text(function['name'] ?? 'Nome não encontrado'),
                      subtitle: function['description'] != null 
                        ? Text(function['description'], style: TextStyle(fontSize: 12))
                        : null,
                      value: selectedFunctionIds.contains(function['id']),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedFunctionIds.add(function['id']);
                            selectedFunctionNames.add(function['name'] ?? '');
                          } else {
                            selectedFunctionIds.remove(function['id']);
                            selectedFunctionNames.remove(function['name'] ?? '');
                          }
                        });
                      },
                    );
                  }).toList(),
                ],
              ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: context.colors.onPrimary,
              ),
              onPressed: selectedFunctionIds.isNotEmpty ? () async {
                debugPrint('🎯 [FunctionDialog] Aprovando com funções: $selectedFunctionIds');
                Navigator.of(context).pop();
                
                // Aprovar com funções selecionadas
                final success = await controller.approveVolunteer(
                  volunteerId, 
                  functionIds: selectedFunctionIds,
                  notes: notes,
                );
                
                debugPrint('🎯 [FunctionDialog] Resultado da aprovação: $success');
                if (success) {
                  final functionNames = selectedFunctionNames.join(', ');
                  showSuccess(context, 'Voluntário aprovado como: $functionNames!');
                } else {
                  showError(context, 'Erro ao aprovar voluntário');
                }
              } : null,
              child: const Text('Aprovar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandableVolunteerCard extends StatefulWidget {
  final Map<String, dynamic> volunteer;
  final Function(String volunteerId, String? notes, BuildContext context) onApprove;
  final Function(String volunteerId, String? notes, BuildContext context) onReject;
  final VolunteersController controller;

  const _ExpandableVolunteerCard({
    required this.volunteer,
    required this.onApprove,
    required this.onReject,
    required this.controller,
  });

  @override
  State<_ExpandableVolunteerCard> createState() => _ExpandableVolunteerCardState();
}

class _ExpandableVolunteerCardState extends State<_ExpandableVolunteerCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  final TextEditingController _notesController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _getFunctionNames(dynamic functions) {
    if (functions == null) return '';
    
    final functionsList = functions as List;
    final functionNames = functionsList.map((f) {
      if (f is Map<String, dynamic>) {
        // Verificar se é a estrutura do backend (funções aprovadas)
        if (f.containsKey('name')) {
          return f['name'] ?? 'Função não informada';
        }
        // Verificar se é a estrutura da tab members (com function nested)
        if (f.containsKey('function') && f['function'] is Map<String, dynamic>) {
          return f['function']['name'] ?? 'Função não informada';
        }
        return f.toString();
      }
      return f.toString();
    }).toList();
    
    return functionNames.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    // Debug: verificar dados do voluntário
    debugPrint('🔍 [Dashboard] Dados do voluntário no card:');
    debugPrint('   - Nome: ${widget.volunteer['name']}');
    debugPrint('   - Source: ${widget.volunteer['source']}');
    debugPrint('   - Source tipo: ${widget.volunteer['source'].runtimeType}');
    debugPrint('   - Todos os campos: ${widget.volunteer.keys.toList()}');
    
    final status = widget.volunteer['status'] ?? 'pending';
    final statusColor = status == 'approved' ? Colors.green : 
                      status == 'rejected' ? Colors.red : Colors.orange;
    final statusText = status == 'approved' ? 'Aprovado' : 
                      status == 'rejected' ? 'Rejeitado' : 'Pendente';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Cabeçalho do card (sempre visível)
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: context.colors.primary.withOpacity(0.1),
                    child: Text(
                      (widget.volunteer['name'] ?? 'V')[0].toUpperCase(),
                      style: TextStyle(
                        color: context.colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.volunteer['name'] ?? 'Nome não informado',
                                style: context.textStyles.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.3),
                                ),
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
                        const SizedBox(height: 4),
                        Text(
                          widget.volunteer['email'] ?? 'Email não informado',
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: context.colors.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.volunteer['phone'] ?? 'Telefone não informado',
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: context.colors.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Chip de origem
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getSourceColor(widget.volunteer['source']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getSourceColor(widget.volunteer['source']).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getSourceIcon(widget.volunteer['source']),
                                size: 12,
                                color: _getSourceColor(widget.volunteer['source']),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getSourceText(widget.volunteer['source']),
                                style: context.textStyles.bodySmall?.copyWith(
                                  color: _getSourceColor(widget.volunteer['source']),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Menu de ações
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: context.colors.onSurface.withOpacity(0.7),
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'delete':
                          _showDeleteConfirmation(context);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Excluir', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.expand_more,
                      color: context.colors.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Conteúdo expandido com animação
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isExpanded 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _isExpanded ? 1.0 : 0.0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _isExpanded ? 1.0 : 0.0,
                      child: Container(
                        height: 1,
                        color: context.colors.outline.withOpacity(0.1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Ministério/Servindo em baseado no status
                  if (widget.volunteer['ministry'] != null)
                    _buildInfoRow(
                      context,
                      status == 'approved' ? 'Servindo em:' : 'Ministério de interesse:',
                      widget.volunteer['ministry']?['name'] ?? 'Ministério não informado',
                      Icons.church,
                    ),
                  
                  // Funções baseado no status
                  if (widget.volunteer['functions'] != null && 
                      (widget.volunteer['functions'] as List).isNotEmpty)
                    _buildInfoRow(
                      context,
                      status == 'approved' ? 'Funções:' : 'Funções de interesse:',
                      _getFunctionNames(widget.volunteer['functions']),
                      Icons.work,
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Botões de ação (apenas para pendentes)
                  if (status == 'pending') ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _notesController,
                            decoration: InputDecoration(
                              labelText: 'Observações (opcional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              debugPrint('🎯 [Button] Botão Rejeitar clicado!');
                              final volunteerId = widget.volunteer['id']?.toString();
                              debugPrint('🎯 [Button] Volunteer ID extraído (rejeitar): $volunteerId');
                              
                              if (volunteerId != null) {
                                debugPrint('🎯 [Button] Chamando onReject...');
                                widget.onReject(
                                  volunteerId,
                                  _notesController.text.trim().isEmpty 
                                    ? null 
                                    : _notesController.text.trim(),
                                  context,
                                );
                                debugPrint('🎯 [Button] onReject chamado com sucesso');
                              } else {
                                debugPrint('❌ [Button] Volunteer ID é null! (rejeitar)');
                              }
                            },
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Rejeitar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              debugPrint('🎯 [Button] Botão Aprovar clicado!');
                              final volunteerId = widget.volunteer['id']?.toString();
                              debugPrint('🎯 [Button] Volunteer ID extraído: $volunteerId');
                              debugPrint('🎯 [Button] Volunteer data: ${widget.volunteer}');
                              
                              if (volunteerId != null) {
                                debugPrint('🎯 [Button] Chamando onApprove...');
                                widget.onApprove(
                                  volunteerId,
                                  _notesController.text.trim().isEmpty
                                    ? null
                                    : _notesController.text.trim(),
                                  context,
                                );
                                debugPrint('🎯 [Button] onApprove chamado com sucesso');
                              } else {
                                debugPrint('❌ [Button] Volunteer ID é null!');
                              }
                            },
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Aprovar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: context.colors.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textStyles.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final volunteerName = widget.volunteer['name'] ?? 'Nome não informado';
    final volunteerEmail = widget.volunteer['email'] ?? 'Email não informado';
    final ministryName = widget.volunteer['ministry']?['name'] ?? 'Ministério não informado';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Confirmar Exclusão',
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
              'Você está prestes a excluir permanentemente:',
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            
            // Informações do voluntário
            Container(
              padding: const EdgeInsets.all(12),
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
                          volunteerName,
                          style: context.textStyles.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.email, color: Colors.red.shade600, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          volunteerEmail,
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
                      Icon(Icons.church, color: Colors.red.shade600, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ministryName,
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: Colors.red.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
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
                      Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'EXCLUSÃO COMPLETA E PERMANENTE',
                          style: context.textStyles.bodySmall?.copyWith(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Esta ação irá remover permanentemente:',
                    style: context.textStyles.bodySmall?.copyWith(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• O usuário da base de dados\n• Todos os vínculos com ministérios\n• Todas as funções atribuídas\n• Todos os dados relacionados',
                    style: context.textStyles.bodySmall?.copyWith(
                      color: Colors.red.shade600,
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
              style: TextStyle(color: context.colors.onSurface.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () => _confirmDeletion(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Excluir Permanentemente'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeletion(BuildContext context) async {
    if (!mounted) return;
    
    // Salvar referências antes de qualquer operação assíncrona
    final navigator = Navigator.of(context);
    
    navigator.pop(); // Fechar dialog de confirmação
    
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
              'Excluindo voluntário...',
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final volunteerId = widget.volunteer['id'] ?? widget.volunteer['userId'] ?? widget.volunteer['_id'];
      
      if (volunteerId == null) {
        if (mounted) navigator.pop(); // Fechar loading
        if (mounted) showError(context, 'ID do voluntário não encontrado');
        return;
      }
      
      final success = await widget.controller.deleteVolunteer(
        volunteerId.toString(),
        context,
      );
      
      if (mounted) navigator.pop(); // Fechar loading
      
      if (mounted) {
        if (success) {
          showSuccess(context, 'Voluntário e todos os dados relacionados foram removidos permanentemente!');
        } else {
          showError(context, 'Erro ao excluir voluntário');
        }
      }
    } catch (e) {
      if (mounted) navigator.pop(); // Fechar loading
      if (mounted) showError(context, 'Erro inesperado ao excluir voluntário');
    }
  }

  /// Retorna o ícone apropriado para a origem do voluntário
  IconData _getSourceIcon(String? source) {
    switch (source) {
      case 'invite':
        return Icons.qr_code;
      case 'form':
        return Icons.description;
      case 'manual':
        return Icons.person_add;
      default:
        return Icons.help_outline;
    }
  }

  /// Retorna o texto descritivo para a origem do voluntário
  String _getSourceText(String? source) {
    debugPrint('🔍 [Dashboard] _getSourceText recebido: "$source" (tipo: ${source.runtimeType})');
    
    switch (source) {
      case 'invite':
        debugPrint('✅ [Dashboard] Source reconhecido como invite');
        return 'Código de Convite';
      case 'form':
        debugPrint('✅ [Dashboard] Source reconhecido como form');
        return 'Formulário Online';
      case 'manual':
        debugPrint('✅ [Dashboard] Source reconhecido como manual');
        return 'Cadastro Manual';
      default:
        debugPrint('⚠️ [Dashboard] Source não reconhecido: "$source"');
        return 'Origem não informada';
    }
  }

  /// Retorna a cor apropriada para a origem do voluntário
  Color _getSourceColor(String? source) {
    switch (source) {
      case 'invite':
        return Colors.purple;
      case 'form':
        return Colors.blue;
      case 'manual':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
