import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:servus_app/core/constants/env.dart';
import 'package:servus_app/core/models/custom_form.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/services/custom_form_service.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';

class FormDetailsScreen extends StatefulWidget {
  final String formId;

  const FormDetailsScreen({
    super.key,
    required this.formId,
  });

  @override
  State<FormDetailsScreen> createState() => _FormDetailsScreenState();
}

class _FormDetailsScreenState extends State<FormDetailsScreen> {
  final CustomFormService _formService = CustomFormService();
  CustomForm? _form;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  Future<void> _loadForm() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final form = await _formService.getFormById(widget.formId);
      setState(() {
        _form = form;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar formulário: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _shareForm() {
    if (_form == null) return;

    final publicUrl = '${Env.baseUrl}/forms/public/${_form!.id}';
    final message = '''
📋 *${_form!.title}*

${_form!.description.isNotEmpty ? _form!.description : 'Formulário de cadastro de voluntários'}

🔗 Acesse o formulário: $publicUrl

📱 Ou escaneie o QR Code abaixo para acessar diretamente pelo celular.
''';

    Share.share(
      message,
      subject: 'Formulário: ${_form!.title}',
    );
  }

  void _copyLink() {
    if (_form == null) return;

    final publicUrl = '${Env.baseUrl}/forms/public/${_form!.id}';
    Clipboard.setData(ClipboardData(text: publicUrl));
    
    if (mounted) {
      showSuccess(context, 'Link copiado para a área de transferência!', title: 'Sucesso');
    }
  }

  void _showQRCode() {
    if (_form == null) return;

    final publicUrl = '${Env.baseUrl}/forms/public/${_form!.id}';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR Code - ${_form!.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  // Aqui você pode integrar uma biblioteca de QR Code como qr_flutter
                  // Por enquanto, vamos mostrar o link
                  Icon(
                    Icons.qr_code,
                    size: 100,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'QR Code para:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    publicUrl,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Escaneie este QR Code para acessar o formulário diretamente',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _copyLink();
            },
            child: const Text('Copiar Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/leader/forms'),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            'Detalhes do Formulário',
            style: context.textStyles.titleLarge?.copyWith(
              color: context.colors.onSurface,
            ),
          ),
        ),
        actions: [
          if (_form != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'share':
                    _shareForm();
                    break;
                  case 'copy':
                    _copyLink();
                    break;
                  case 'qr':
                    _showQRCode();
                    break;
                  case 'submissions':
                    context.push('/forms/${_form!.id}/submissions?title=${Uri.encodeComponent(_form!.title)}');
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share),
                      SizedBox(width: 8),
                      Text('Compartilhar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'copy',
                  child: Row(
                    children: [
                      Icon(Icons.copy),
                      SizedBox(width: 8),
                      Text('Copiar Link'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'qr',
                  child: Row(
                    children: [
                      Icon(Icons.qr_code),
                      SizedBox(width: 8),
                      Text('QR Code'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'submissions',
                  child: Row(
                    children: [
                      Icon(Icons.assignment),
                      SizedBox(width: 8),
                      Text('Ver Submissões'),
                    ],
                  ),
                ),
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
                        onPressed: _loadForm,
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              : _form == null
                  ? const Center(child: Text('Formulário não encontrado'))
                  : _buildFormDetails(),
      floatingActionButton: _form != null
          ? FloatingActionButton.extended(
              onPressed: _shareForm,
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
              icon: const Icon(Icons.share),
              label: const Text('Compartilhar'),
            )
          : null,
    );
  }

  Widget _buildFormDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card principal com informações do formulário
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _form!.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colors.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _form!.isActive ? Colors.green : Colors.grey,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _form!.isActive ? 'Ativo' : 'Inativo',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_form!.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _form!.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.colors.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatChip(
                        Icons.public,
                        _form!.isPublic ? 'Público' : 'Privado',
                        _form!.isPublic ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        Icons.assignment,
                        '${_form!.submissionCount} submissões',
                        context.colors.primary,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        Icons.check_circle,
                        '${_form!.approvedCount} aprovadas',
                        Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Card de compartilhamento
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Compartilhar Formulário',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Compartilhe este formulário para que outras pessoas possam preenchê-lo',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _shareForm,
                          icon: const Icon(Icons.share),
                          label: const Text('Compartilhar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colors.primary,
                            foregroundColor: context.colors.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _copyLink,
                          icon: const Icon(Icons.copy),
                          label: const Text('Copiar Link'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showQRCode,
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Mostrar QR Code'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Card de configurações
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configurações',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingRow(
                    'Múltiplas Submissões',
                    _form!.settings.allowMultipleSubmissions ? 'Permitido' : 'Não permitido',
                    _form!.settings.allowMultipleSubmissions ? Colors.green : Colors.orange,
                  ),
                  _buildSettingRow(
                    'Requer Aprovação',
                    _form!.settings.requireApproval ? 'Sim' : 'Não',
                    _form!.settings.requireApproval ? Colors.orange : Colors.green,
                  ),
                  _buildSettingRow(
                    'Mostrar Progresso',
                    _form!.settings.showProgress ? 'Sim' : 'Não',
                    _form!.settings.showProgress ? Colors.green : Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Card de campos
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Campos do Formulário',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_form!.fields.length} campos configurados',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._form!.fields.map((field) => _buildFieldItem(field)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Card de ministérios
          if (_form!.availableMinistries.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ministérios Disponíveis',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_form!.availableMinistries.length} ministérios disponíveis',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _form!.availableMinistries.map((ministry) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: context.colors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: context.colors.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            ministry,
                            style: TextStyle(
                              color: context.colors.primary,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurface,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldItem(CustomFormField field) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.colors.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getFieldIcon(field.type),
            size: 16,
            color: context.colors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              field.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: context.colors.onSurface,
              ),
            ),
          ),
          if (field.required)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Obrigatório',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getFieldIcon(String type) {
    switch (type) {
      case FormFieldType.text:
        return Icons.text_fields;
      case FormFieldType.email:
        return Icons.email;
      case FormFieldType.phone:
        return Icons.phone;
      case FormFieldType.select:
        return Icons.arrow_drop_down;
      case FormFieldType.multiselect:
        return Icons.checklist;
      case FormFieldType.textarea:
        return Icons.notes;
      case FormFieldType.date:
        return Icons.calendar_today;
      case FormFieldType.number:
        return Icons.numbers;
      case FormFieldType.checkbox:
        return Icons.check_box;
      default:
        return Icons.text_fields;
    }
  }
}
