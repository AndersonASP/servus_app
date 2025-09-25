import 'package:flutter/material.dart';
import 'package:servus_app/core/models/form_submission.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/services/custom_form_service.dart';

class FormSubmissionsScreen extends StatefulWidget {
  final String formId;
  final String formTitle;

  const FormSubmissionsScreen({
    super.key,
    required this.formId,
    required this.formTitle,
  });

  @override
  State<FormSubmissionsScreen> createState() => _FormSubmissionsScreenState();
}

class _FormSubmissionsScreenState extends State<FormSubmissionsScreen> {
  final CustomFormService _formService = CustomFormService();
  List<FormSubmission> _submissions = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _formService.getFormSubmissions(
        formId: widget.formId,
        status: _selectedStatus == 'all' ? null : _selectedStatus,
      );
      
      setState(() {
        _submissions = result['submissions'] ?? [];
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar submissões: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _reviewSubmission(FormSubmission submission, String status) async {
    try {
      await _formService.reviewSubmission(
        submission.id,
        status,
        null, // reviewNotes
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submissão ${status == 'approved' ? 'aprovada' : 'rejeitada'} com sucesso!'),
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
        ),
      );
      
      _loadSubmissions(); // Recarregar lista
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao revisar submissão: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _bulkReview(List<FormSubmission> submissions, String status) async {
    try {
      final submissionIds = submissions.map((s) => s.id).toList();
      
      await _formService.bulkReviewSubmissions(
        submissionIds: submissionIds,
        status: status,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${submissions.length} submissões ${status == 'approved' ? 'aprovadas' : 'rejeitadas'} com sucesso!'),
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
        ),
      );
      
      _loadSubmissions(); // Recarregar lista
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao revisar submissões: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'Submissões',
          style: TextStyle(
            color: context.colors.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: context.colors.onSurface, // 🎨 Cor visível para ícones
        elevation: 0, // 🎨 Sem sombra
        surfaceTintColor: Colors.transparent, // 🎨 Sem tint
        scrolledUnderElevation: 0, // 🎨 Sem elevação ao rolar
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: context.colors.onSurface, // 🎨 Cor visível
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.filter_list,
              color: context.colors.onSurface, // 🎨 Cor visível
            ),
            onSelected: (status) {
              setState(() {
                _selectedStatus = status;
              });
              _loadSubmissions();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Todas')),
              const PopupMenuItem(value: 'pending', child: Text('Pendentes')),
              const PopupMenuItem(value: 'approved', child: Text('Aprovadas')),
              const PopupMenuItem(value: 'rejected', child: Text('Rejeitadas')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: context.colors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: context.colors.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSubmissions,
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              : _submissions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 80,
                            color: context.colors.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma submissão encontrada.',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: context.colors.onSurface.withOpacity(0.6),
                                ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Filtros e ações em lote
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Expanded(
                              //   child: Text(
                              //     '${_submissions.length} submissões encontradas',
                              //     style: Theme.of(context).textTheme.titleMedium,
                              //   ),
                              // ),
                              if (_submissions.any((s) => s.status == FormSubmissionStatus.pending))
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        final pendingSubmissions = _submissions
                                            .where((s) => s.status == FormSubmissionStatus.pending)
                                            .toList();
                                        _bulkReview(pendingSubmissions, FormSubmissionStatus.approved);
                                      },
                                      icon: const Icon(Icons.check),
                                      label: const Text('Aprovar Todas'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        final pendingSubmissions = _submissions
                                            .where((s) => s.status == FormSubmissionStatus.pending)
                                            .toList();
                                        _bulkReview(pendingSubmissions, FormSubmissionStatus.rejected);
                                      },
                                      icon: const Icon(Icons.close),
                                      label: const Text('Rejeitar Todas'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: context.colors.error,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        // Lista de submissões
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _submissions.length,
                            itemBuilder: (context, index) {
                              final submission = _submissions[index];
                              return _buildSubmissionCard(submission);
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildSubmissionCard(FormSubmission submission) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (submission.status) {
      case FormSubmissionStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Pendente';
        break;
      case FormSubmissionStatus.approved:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Aprovada';
        break;
      case FormSubmissionStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejeitada';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Desconhecido';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        submission.volunteerName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.colors.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        submission.email,
                        style: TextStyle(
                          color: context.colors.onSurface.withOpacity(0.7),
                        ),
                      ),
                      if (submission.phone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          submission.phone,
                          style: TextStyle(
                            color: context.colors.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (submission.preferredMinistry != null) ...[
              Text(
                'Ministério: ${submission.preferredMinistry}',
                style: TextStyle(
                  color: context.colors.onSurface.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              'Função: ${submission.preferredRole}',
              style: TextStyle(
                color: context.colors.onSurface.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            // Data de submissão
            Text(
              'Submetido em: ${_formatDate(submission.createdAt)}',
              style: TextStyle(
                color: context.colors.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Botões de ação centralizados
            if (submission.status == FormSubmissionStatus.pending) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center, // 🎨 Centralizar botões
                children: [
                  TextButton.icon(
                    onPressed: () => _reviewSubmission(submission, FormSubmissionStatus.approved),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Aprovar'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8), // 🎨 Espaçamento maior
                  TextButton.icon(
                    onPressed: () => _reviewSubmission(submission, FormSubmissionStatus.rejected),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Rejeitar'),
                    style: TextButton.styleFrom(
                      foregroundColor: context.colors.error,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
