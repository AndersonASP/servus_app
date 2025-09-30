import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:servus_app/core/constants/env.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/core/widgets/shimmer_widget.dart';
import 'package:servus_app/core/models/custom_form.dart';
import 'package:servus_app/services/custom_form_service.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';

class FormsListScreen extends StatefulWidget {
  const FormsListScreen({super.key});

  @override
  State<FormsListScreen> createState() => _FormsListScreenState();
}

class _FormsListScreenState extends State<FormsListScreen> {
  final CustomFormService _formService = CustomFormService();
  List<CustomForm> _forms = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadForms();
    
    // Verifica se há parâmetro de refresh na URL no initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final uri = Uri.parse(ModalRoute.of(context)?.settings.name ?? '');
        if (uri.queryParameters['refresh'] == 'true') {
          _loadForms(refresh: true);
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Verifica se há parâmetro de refresh na URL
    final uri = Uri.parse(ModalRoute.of(context)?.settings.name ?? '');
    if (uri.queryParameters['refresh'] == 'true') {
      // Recarrega a lista quando vem da criação
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadForms(refresh: true);
        }
      });
    }
  }

  @override
  void didUpdateWidget(FormsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Verifica se há parâmetro de refresh na URL quando o widget é atualizado
    final uri = Uri.parse(ModalRoute.of(context)?.settings.name ?? '');
    if (uri.queryParameters['refresh'] == 'true') {
      // Recarrega a lista quando volta da criação
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadForms(refresh: true);
        }
      });
    }
  }

  Future<void> _loadForms({bool refresh = false}) async {
    
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _forms.clear();
      });
    }

    if (!_hasMore) {
      return;
    }

    try {
      setState(() => _isLoading = true);

      
      final result = await _formService.getTenantForms(
        page: _currentPage,
        limit: 20,
      );

      
      final newForms = result['forms'] as List<CustomForm>;
      final pagination = result['pagination'] as Map<String, dynamic>;
      

      setState(() {
        if (refresh) {
          _forms = newForms;
        } else {
          _forms.addAll(newForms);
        }
        _currentPage++;
        _hasMore = _currentPage <= (pagination['pages'] ?? 1);
        _isLoading = false;
        
      });
    } catch (e) {
      
      setState(() => _isLoading = false);
      if (mounted) {
        showError(context, 'Erro ao carregar formulários: $e', title: 'Erro');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verifica se há parâmetro de refresh na URL a cada build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final uri = Uri.parse(ModalRoute.of(context)?.settings.name ?? '');
        if (uri.queryParameters['refresh'] == 'true') {
          _loadForms(refresh: true);
        }
      }
    });
    
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
          onPressed: () => context.go('/leader/dashboard'),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            'Formulários',
            style: context.textStyles.titleLarge?.copyWith(
              color: context.colors.onSurface,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadForms(refresh: true),
        child: _isLoading && _forms.isEmpty
            ? const ShimmerList(
                itemCount: 6,
                itemHeight: 120,
              )
            : _forms.isEmpty
                ? _buildEmptyState()
                : _buildFormsList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/forms/create'),
        backgroundColor: context.colors.primary,
        foregroundColor: context.colors.onPrimary,
        tooltip: 'Criar Formulário',
        icon: const Icon(Icons.add),
        label: const Text('Criar'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: context.colors.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum formulário encontrado',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie seu primeiro formulário para começar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _forms.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _forms.length) {
          return _buildLoadMoreButton();
        }

        final form = _forms[index];
        return _buildFormCard(form);
      },
    );
  }

  Widget _buildFormCard(CustomForm form) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => context.push('/forms/${form.id}/details'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      form.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: form.isActive ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      form.isActive ? 'Ativo' : 'Inativo',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (form.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  form.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatChip(
                    Icons.assignment,
                    '${form.submissionCount} submissões',
                    context.colors.primary,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    Icons.check_circle,
                    '${form.approvedCount} aprovadas',
                    Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    Icons.settings,
                    '${form.fields.length} campos',
                    context.colors.outline,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.public,
                    size: 16,
                    color: form.isPublic ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    form.isPublic ? 'Público' : 'Privado',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: form.isPublic ? Colors.green : Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _shareForm(form),
                    icon: const Icon(Icons.share, size: 16),
                    tooltip: 'Compartilhar',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Criado em ${_formatDate(form.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  Widget _buildLoadMoreButton() {
    if (!_hasMore) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: () => _loadForms(),
                child: const Text('Carregar Mais'),
              ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _shareForm(CustomForm form) {
    final publicUrl = '${Env.baseUrl}/forms/public/${form.id}';
    final message = '''
📋 *${form.title}*

${form.description.isNotEmpty ? form.description : 'Formulário de cadastro de voluntários'}

🔗 Acesse o formulário: $publicUrl

📱 Ou escaneie o QR Code para acessar diretamente pelo celular.
''';

    Share.share(
      message,
      subject: 'Formulário: ${form.title}',
    );
  }
}
