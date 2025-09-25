import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/services/invite_code_service.dart';
import 'package:servus_app/core/error/error_handler_service.dart';

class InviteCodeScreen extends StatefulWidget {
  const InviteCodeScreen({super.key});

  @override
  State<InviteCodeScreen> createState() => _InviteCodeScreenState();
}

class _InviteCodeScreenState extends State<InviteCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  final InviteCodeService _inviteCodeService = InviteCodeService();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _validateCode() async {
    if (_codeController.text.trim().isEmpty) {
      ErrorHandlerService().handleValidationError(
        context, 
        'Por favor, digite o código de convite que você recebeu.',
        title: 'Código Obrigatório',
      );
      return;
    }

    if (_codeController.text.trim().length != 4) {
      ErrorHandlerService().handleValidationError(
        context, 
        'O código de convite deve ter exatamente 4 caracteres.',
        title: 'Código Inválido',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final validation = await _inviteCodeService.validateInviteCode(
        _codeController.text.trim(),
      );

      if (validation.isValid) {
        // Navegar para tela de cadastro
        context.push('/invite/register', extra: {
          'code': _codeController.text.trim().toUpperCase(),
          'ministryName': validation.ministryName ?? 'Ministério',
          'ministryId': validation.ministryId,
        });
      } else {
        ErrorHandlerService().handleValidationError(
          context, 
          validation.message ?? 'Este código de convite não é válido ou já expirou.',
          title: 'Código Inválido',
        );
      }
    } catch (e) {
      ErrorHandlerService().handleError(
        context, 
        e,
        customMessage: 'Não foi possível validar o código. Verifique sua conexão e tente novamente.',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Código de Convite'),
        backgroundColor: context.colors.primaryContainer,
        foregroundColor: context.colors.onPrimaryContainer,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      size: 64,
                      color: context.colors.onPrimary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Você foi convidado!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Digite o código de convite para entrar no ministério',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.colors.onPrimaryContainer.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Campo de código
              Text(
                'Código de Convite',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _codeController,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
                inputFormatters: [
                  UpperCaseTextFormatter(),
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                ],
                decoration: InputDecoration(
                  hintText: 'A1B2',
                  hintStyle: TextStyle(
                    color: context.colors.onSurface.withOpacity(0.5),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.colors.outline.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.colors.outline.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.colors.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: context.colors.surface,
                  counterText: '',
                ),
                onChanged: (value) {
                  if (value.length == 4) {
                    _validateCode();
                  }
                },
              ),

              const SizedBox(height: 24),

              // Botão de continuar
              ElevatedButton(
                onPressed: _isLoading ? null : _validateCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                    : const Text(
                        'Continuar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),

              const SizedBox(height: 24),

              // Informações adicionais
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
                      '• Digite o código de 4 caracteres fornecido pelo líder do ministério\n'
                      '• Após validar, você será direcionado para criar sua conta\n'
                      '• Sua conta será automaticamente vinculada ao ministério',
                      style: TextStyle(
                        color: context.colors.onSurface.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Link para login
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  'Já tem uma conta? Faça login',
                  style: TextStyle(
                    color: context.colors.primary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
