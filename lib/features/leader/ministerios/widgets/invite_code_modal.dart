import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/core/models/invite_code.dart';
import 'package:servus_app/services/invite_code_service.dart';
import 'package:servus_app/services/deep_link_service.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';

class InviteCodeModal extends StatefulWidget {
  final String ministryId;
  final String ministryName;

  const InviteCodeModal({
    super.key,
    required this.ministryId,
    required this.ministryName,
  });

  @override
  State<InviteCodeModal> createState() => _InviteCodeModalState();
}

class _InviteCodeModalState extends State<InviteCodeModal> with TickerProviderStateMixin {
  final InviteCodeService _inviteCodeService = InviteCodeService();
  final DeepLinkService _deepLinkService = DeepLinkService();
  InviteCode? _currentInviteCode;
  bool _isLoading = false;
  bool _isGenerating = false;
  
  // Controllers para animações
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

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
    
    _loadCurrentInviteCode();
    
    // Iniciar animação após um pequeno delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  Future<void> _loadCurrentInviteCode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final codes = await _inviteCodeService.getMinistryInviteCodes(widget.ministryId);
      if (codes.isNotEmpty) {
        // Buscar o código ativo mais recente
        final activeCode = codes.firstWhere(
          (code) => code.isActive,
          orElse: () => codes.first,
        );
        setState(() {
          _currentInviteCode = activeCode;
        });
      }
    } catch (e) {
      showError(context, 'Erro ao carregar código: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateNewCode() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final newCode = await _inviteCodeService.createMinistryInviteCode(
        widget.ministryId,
        regenerate: true,
      );
      
      setState(() {
        _currentInviteCode = newCode;
      });
      
      showSuccess(context, 'Novo código gerado com sucesso!');
    } catch (e) {
      showError(context, 'Erro ao gerar código: $e');
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _shareInviteCode() async {
    if (_currentInviteCode == null) return;

    // Gerar links usando o DeepLinkService
    final inviteLink = _deepLinkService.generateInviteLink(
      _currentInviteCode!.code,
      widget.ministryName,
    );
    final httpLink = _deepLinkService.generateHttpInviteLink(
      _currentInviteCode!.code,
      widget.ministryName,
    );

    final message = 'Olá! Você foi convidado para participar do ministério *${widget.ministryName}* no Servus App.\n\n'
        'Para entrar, baixe o app e use o código: *${_currentInviteCode!.code}*\n\n'
        'Ou clique no link: $inviteLink\n\n'
        'Link alternativo: $httpLink';

    await Share.share(
      message,
      subject: 'Convite para o Ministério ${widget.ministryName}',
    );
  }

  void _copyCodeToClipboard() {
    if (_currentInviteCode == null) return;
    
    Clipboard.setData(ClipboardData(text: _currentInviteCode!.code));
    showSuccess(context, 'Código copiado para a área de transferência!');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.8; // 80% da altura da tela
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Dialog(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(
                  maxHeight: maxHeight,
                  maxWidth: 400,
                ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.colors.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.card_giftcard, color: context.colors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Código de Convite',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: context.colors.onPrimaryContainer),
                  ),
                ],
              ),
            ),

            // Conteúdo com scroll
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildContent(),
              ),
            ),

            // Botões
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: _buildActionButtons(),
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

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentInviteCode == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.code_off,
            size: 64,
            color: context.colors.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum código de convite',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gere um código para convidar novos membros',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Código atual
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.colors.primary.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                'Código Atual',
                style: TextStyle(
                  color: context.colors.onSurface.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentInviteCode!.code,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.primary,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _copyCodeToClipboard,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.colors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: context.colors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.copy,
                        color: context.colors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Ministério: ${widget.ministryName}',
                style: TextStyle(
                  color: context.colors.onSurface.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Estatísticas
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Usos',
                _currentInviteCode!.usageCount.toString(),
                Icons.people,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Status',
                _currentInviteCode!.isActive ? 'Ativo' : 'Inativo',
                _currentInviteCode!.isActive ? Icons.check_circle : Icons.cancel,
                color: _currentInviteCode!.isActive ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Informações sobre o código
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.colors.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: context.colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Como funciona?',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.colors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '• Compartilhe o código com novos membros\n'
                '• Eles usarão o código para se cadastrar\n'
                '• Serão automaticamente vinculados ao ministério\n'
                '• Você pode regenerar o código a qualquer momento',
                style: TextStyle(
                  color: context.colors.onSurface.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.colors.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: color ?? context.colors.primary,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color ?? context.colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: context.colors.onSurface.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Se a largura for menor que 300px, usar layout vertical
        if (constraints.maxWidth < 300) {
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _currentInviteCode == null ? null : _shareInviteCode,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colors.primary,
                    side: BorderSide(color: context.colors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Compartilhar'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _generateNewCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: context.colors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isGenerating
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Gerar'),
                ),
              ),
            ],
          );
        }
        
        // Layout horizontal para telas maiores
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _currentInviteCode == null ? null : _shareInviteCode,
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.colors.primary,
                  side: BorderSide(color: context.colors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Compartilhar'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generateNewCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isGenerating
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Gerar'),
              ),
            ),
          ],
        );
      },
    );
  }
}