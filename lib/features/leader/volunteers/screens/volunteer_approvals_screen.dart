import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/volunteers/controllers/volunteers_controller.dart';

class VolunteerApprovalsScreen extends StatefulWidget {
  const VolunteerApprovalsScreen({super.key});

  @override
  State<VolunteerApprovalsScreen> createState() => _VolunteerApprovalsScreenState();
}

class _VolunteerApprovalsScreenState extends State<VolunteerApprovalsScreen> {
  VolunteersController? controller;

  @override
  void initState() {
    super.initState();
    // Não criar controller aqui - será passado pelo Provider
  }

  @override
  void dispose() {
    // Não dispose do controller aqui - será gerenciado pelo Provider pai
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VolunteersController>(
      builder: (context, controller, _) {
        this.controller = controller; // Armazenar referência
        
        return Scaffold(
            backgroundColor: context.theme.scaffoldBackgroundColor,
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Aprovações de Voluntários'),
                  Text(
                    'Apenas dos seus ministérios',
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.transparent,
              foregroundColor: context.colors.onSurface,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              centerTitle: false,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: context.colors.onSurface,
                ),
                onPressed: () => Navigator.of(context).pop(),
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
                : controller.pendingApprovals.isEmpty
                    ? _buildEmptyState(context)
                    : RefreshIndicator(
                        onRefresh: () => controller.refreshVolunteers(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: controller.pendingApprovals.length,
                          itemBuilder: (context, index) {
                            final volunteer = controller.pendingApprovals[index];
                            return _buildApprovalCard(context, volunteer);
                          },
                        ),
                      ),
          );
        },
      );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.approval_outlined,
              size: 80,
              color: context.colors.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhuma aprovação pendente',
              style: context.textStyles.headlineSmall?.copyWith(
                color: context.colors.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Não há voluntários pendentes nos seus ministérios',
              style: context.textStyles.bodyLarge?.copyWith(
                color: context.colors.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => controller!.refreshVolunteers(),
              icon: const Icon(Icons.refresh),
              label: const Text('Atualizar'),
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

  Widget _buildApprovalCard(BuildContext context, Map<String, dynamic> volunteer) {
    // Debug: verificar dados do voluntário
    debugPrint('🔍 [ApprovalCard] Dados do voluntário:');
    debugPrint('   - Nome: ${volunteer['name']}');
    debugPrint('   - Source: ${volunteer['source']}');
    debugPrint('   - Source tipo: ${volunteer['source'].runtimeType}');
    debugPrint('   - Todos os campos: ${volunteer.keys.toList()}');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.colors.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho com nome e ministério
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: context.colors.primary.withOpacity(0.1),
                child: Text(
                  (volunteer['name'] ?? 'V')[0].toUpperCase(),
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
                    Text(
                      volunteer['name'] ?? 'Nome não informado',
                      style: context.textStyles.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Chip de origem
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getSourceColor(volunteer['source']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getSourceColor(volunteer['source']).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getSourceIcon(volunteer['source']),
                          size: 14,
                          color: _getSourceColor(volunteer['source']),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getSourceText(volunteer['source']),
                          style: context.textStyles.bodySmall?.copyWith(
                            color: _getSourceColor(volunteer['source']),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Chip de status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'Pendente',
                      style: context.textStyles.bodySmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Informações de contato
          _buildInfoRow(context, Icons.email, 'Email', volunteer['email'] ?? 'Não informado'),
          const SizedBox(height: 8),
          _buildInfoRow(context, Icons.phone, 'Telefone', volunteer['phone'] ?? 'Não informado'),
          
          // Origem do voluntário
          const SizedBox(height: 8),
          _buildInfoRow(context, _getSourceIcon(volunteer['source']), 'Origem', _getSourceText(volunteer['source'])),
          
          // Ministério de interesse - DESTAQUE
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: context.colors.primary.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.church,
                  color: context.colors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ministério de interesse:',
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        volunteer['ministry']?['name'] ?? 'Ministério não informado',
                        style: context.textStyles.bodyLarge?.copyWith(
                          color: context.colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Funções selecionadas - DESTAQUE com chips
          if (volunteer['functions'] != null && (volunteer['functions'] as List).isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.colors.primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.work_outline,
                        color: context.colors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Funções de interesse:',
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: (volunteer['functions'] as List).map((function) {
                      return Chip(
                        label: Text(
                          function is String ? function : function.toString(),
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.onPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: context.colors.primary.withOpacity(0.15),
                        side: BorderSide(
                          color: context.colors.primary.withOpacity(0.4),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Data de submissão
          Text(
            'Submetido em: ${_formatDate(volunteer['createdAt'])}',
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurface.withOpacity(0.6),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Botões de ação
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRejectDialog(context, volunteer),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Rejeitar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colors.error,
                    side: BorderSide(color: context.colors.error),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showApproveDialog(context, volunteer),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Aprovar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: context.colors.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: context.textStyles.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: context.colors.onSurface.withOpacity(0.7),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  void _showApproveDialog(BuildContext context, Map<String, dynamic> volunteer) {
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Aprovar Voluntário',
          style: TextStyle(color: context.colors.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Você está prestes a aprovar:'),
            const SizedBox(height: 8),
            Text(
              volunteer['name'] ?? 'Nome não informado',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
                hintText: 'Adicione comentários sobre a aprovação...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _approveVolunteer(context, volunteer, notesController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Aprovar'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, Map<String, dynamic> volunteer) {
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Rejeitar Voluntário',
          style: TextStyle(color: context.colors.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Você está prestes a rejeitar:'),
            const SizedBox(height: 8),
            Text(
              volunteer['name'] ?? 'Nome não informado',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Motivo da rejeição',
                hintText: 'Explique o motivo da rejeição...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _rejectVolunteer(context, volunteer, notesController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveVolunteer(BuildContext context, Map<String, dynamic> volunteer, String notes) async {
    try {
      // Verificar se é voluntário de invite (precisa escolher função)
      if (volunteer['source'] == 'invite') {
        // Para invites, mostrar dialog para escolher função
        await _showFunctionSelectionDialog(context, volunteer, notes);
        return;
      }
      
      // Para formulários, aprovar diretamente
      final success = await controller!.approveVolunteer(
        volunteer['id'],
        notes: notes.isNotEmpty ? notes : null,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${volunteer['name']} foi aprovado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao aprovar voluntário. Tente novamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectVolunteer(BuildContext context, Map<String, dynamic> volunteer, String notes) async {
    try {
      final success = await controller!.rejectVolunteer(
        volunteer['id'],
        notes: notes.isNotEmpty ? notes : null,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${volunteer['name']} foi rejeitado.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao rejeitar voluntário. Tente novamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Data não informada';
    
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return 'Data inválida';
    }
  }

  /// Mostra dialog para seleção de função para voluntários de invite
  Future<void> _showFunctionSelectionDialog(
    BuildContext context, 
    Map<String, dynamic> volunteer,
    String? notes
  ) async {
    debugPrint('🎯 [FunctionDialog] Iniciando dialog de seleção de função...');
    debugPrint('   - Volunteer ID: ${volunteer['id']}');
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ministério não encontrado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    debugPrint('🔍 [FunctionDialog] Buscando funções do ministério: $ministryId');
    // Buscar funções do ministério
    final functions = await controller!.getMinistryFunctions(ministryId);
    debugPrint('🔍 [FunctionDialog] Funções encontradas: ${functions.length}');
    debugPrint('🔍 [FunctionDialog] Primeira função (raw): ${functions.isNotEmpty ? functions.first : 'Nenhuma'}');

    if (functions.isEmpty) {
      debugPrint('❌ [FunctionDialog] Nenhuma função disponível');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma função disponível para este ministério'),
          backgroundColor: Colors.red,
        ),
      );
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
              }),
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
                final success = await controller!.approveVolunteer(
                  volunteer['id'], 
                  functionIds: selectedFunctionIds,
                  notes: notes,
                );
                
                debugPrint('🎯 [FunctionDialog] Resultado da aprovação: $success');
                if (success) {
                  final functionNames = selectedFunctionNames.join(', ');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Voluntário aprovado como: $functionNames!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro ao aprovar voluntário'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } : null,
              child: const Text('Aprovar'),
            ),
          ],
        ),
      ),
    );
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
    debugPrint('🔍 [getSourceText] Source recebido: "$source" (tipo: ${source.runtimeType})');
    
    switch (source) {
      case 'invite':
        return 'Código de Convite';
      case 'form':
        return 'Formulário Online';
      case 'manual':
        return 'Cadastro Manual';
      default:
        debugPrint('⚠️ [getSourceText] Source não reconhecido: "$source"');
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
