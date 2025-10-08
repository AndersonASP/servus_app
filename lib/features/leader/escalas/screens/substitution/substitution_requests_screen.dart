import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/escalas/controllers/substitution_controller.dart';
import 'package:servus_app/features/leader/escalas/models/substitution_request_model.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';

class SubstitutionRequestsScreen extends StatefulWidget {
  const SubstitutionRequestsScreen({super.key});

  @override
  State<SubstitutionRequestsScreen> createState() => _SubstitutionRequestsScreenState();
}

class _SubstitutionRequestsScreenState extends State<SubstitutionRequestsScreen>
    with SingleTickerProviderStateMixin {
  late final SubstitutionController _controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = context.read<SubstitutionController>();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _controller.loadPendingRequests(tenantId: '507f1f77bcf86cd799439011'), // TODO: Obter do contexto
      _controller.loadSentRequests(tenantId: '507f1f77bcf86cd799439011'),
    ]);
  }

  Future<void> _respondToRequest(SubstitutionRequest request, String response) async {
    String? rejectionReason;
    
    if (response == 'rejected') {
      rejectionReason = await _showRejectionReasonDialog();
      if (rejectionReason == null) return;
    }

    final success = await _controller.respondToSwapRequest(
      tenantId: '507f1f77bcf86cd799439011', // TODO: Obter do contexto
      swapRequestId: request.id,
      response: response,
      rejectionReason: rejectionReason,
    );

    if (success) {
      showSuccess(
        context,
        response == 'accepted' ? 'Solicitação aceita!' : 'Solicitação rejeitada.',
      );
    } else {
      showError(context, _controller.errorMessage ?? 'Erro ao responder solicitação');
    }
  }

  Future<void> _cancelRequest(SubstitutionRequest request) async {
    final confirmed = await _showCancelConfirmationDialog(request);
    if (!confirmed) return;

    final success = await _controller.cancelSwapRequest(
      tenantId: '507f1f77bcf86cd799439011', // TODO: Obter do contexto
      swapRequestId: request.id,
    );

    if (success) {
      showSuccess(context, 'Solicitação cancelada!');
    } else {
      showError(context, _controller.errorMessage ?? 'Erro ao cancelar solicitação');
    }
  }

  Future<String?> _showRejectionReasonDialog() async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Motivo da Rejeição'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Digite o motivo para rejeitar esta solicitação',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showCancelConfirmationDialog(SubstitutionRequest request) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Solicitação'),
        content: Text('Tem certeza que deseja cancelar esta solicitação de troca?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sim'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitações de Troca'),
        backgroundColor: context.theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox),
                  const SizedBox(width: 8),
                  Text('Recebidas (${_controller.pendingRequestsCount})'),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send),
                  SizedBox(width: 8),
                  Text('Enviadas'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Consumer<SubstitutionController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Solicitações recebidas
              _buildPendingRequestsList(),
              // Solicitações enviadas
              _buildSentRequestsList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPendingRequestsList() {
    if (_controller.pendingRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Nenhuma solicitação pendente'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _controller.pendingRequests.length,
      itemBuilder: (context, index) {
        final request = _controller.pendingRequests[index];
        return _buildRequestCard(request, isPending: true);
      },
    );
  }

  Widget _buildSentRequestsList() {
    if (_controller.sentRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Nenhuma solicitação enviada'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _controller.sentRequests.length,
      itemBuilder: (context, index) {
        final request = _controller.sentRequests[index];
        return _buildRequestCard(request, isPending: false);
      },
    );
  }

  Widget _buildRequestCard(SubstitutionRequest request, {required bool isPending}) {
    final isExpired = request.isExpired;
    final statusColor = _getStatusColor(request.status);
    final statusText = _getStatusText(request.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                if (isExpired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Text(
                      'EXPIRADA',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Informações da solicitação
            Text(
              'Motivo: ${request.reason}',
              style: context.textStyles.bodyMedium,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Criada em: ${_formatDate(request.createdAt)}',
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            
            if (request.expiresAt.isAfter(DateTime.now()))
              Text(
                'Expira em: ${_formatDate(request.expiresAt)}',
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            
            if (request.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  'Motivo da rejeição: ${request.rejectionReason}',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: Colors.red,
                  ),
                ),
              ),
            ],
            
            // Ações
            if (isPending && request.isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _respondToRequest(request, 'accepted'),
                      icon: const Icon(Icons.check),
                      label: const Text('Aceitar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _respondToRequest(request, 'rejected'),
                      icon: const Icon(Icons.close),
                      label: const Text('Rejeitar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (!isPending && request.status == SubstitutionRequestStatus.pending) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _cancelRequest(request),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancelar Solicitação'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(SubstitutionRequestStatus status) {
    switch (status) {
      case SubstitutionRequestStatus.pending:
        return Colors.blue;
      case SubstitutionRequestStatus.accepted:
        return Colors.green;
      case SubstitutionRequestStatus.rejected:
        return Colors.red;
      case SubstitutionRequestStatus.cancelled:
        return Colors.orange;
      case SubstitutionRequestStatus.expired:
        return Colors.grey;
    }
  }

  String _getStatusText(SubstitutionRequestStatus status) {
    switch (status) {
      case SubstitutionRequestStatus.pending:
        return 'PENDENTE';
      case SubstitutionRequestStatus.accepted:
        return 'ACEITA';
      case SubstitutionRequestStatus.rejected:
        return 'REJEITADA';
      case SubstitutionRequestStatus.cancelled:
        return 'CANCELADA';
      case SubstitutionRequestStatus.expired:
        return 'EXPIRADA';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
