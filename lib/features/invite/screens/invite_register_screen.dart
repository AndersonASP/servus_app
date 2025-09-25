import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/core/models/invite_code.dart';
import 'package:servus_app/services/invite_code_service.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';

class InviteRegisterScreen extends StatefulWidget {
  final String code;
  final String ministryName;
  final String ministryId;

  const InviteRegisterScreen({
    super.key,
    required this.code,
    required this.ministryName,
    required this.ministryId,
  });

  @override
  State<InviteRegisterScreen> createState() => _InviteRegisterScreenState();
}

class _InviteRegisterScreenState extends State<InviteRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final InviteCodeService _inviteCodeService = InviteCodeService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    
    // Adicionar listener para atualizar o indicador de força da senha
    _passwordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      showError(context, 'As senhas não coincidem');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Preparar dados de registro
      final registrationData = InviteRegistrationData(
        code: widget.code,
        name: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        phone: _phoneController.text.replaceAll(RegExp(r'[^\d]'), ''), // Remove formatação
        password: _passwordController.text,
      );

      print('📝 Dados de registro:');
      print('   - Código: ${registrationData.code}');
      print('   - Nome: ${registrationData.name}');
      print('   - Email: ${registrationData.email}');
      print('   - Telefone: ${registrationData.phone}');
      print('   - Senha: ${registrationData.password.length} caracteres');

      final result = await _inviteCodeService.registerWithInviteCode(registrationData);
      
      print('✅ Registro bem-sucedido: $result');

    if (mounted) {
      // Verificar se o usuário está pendente de aprovação
      if (result['status'] == 'pending_approval') {
        print('⏳ Usuário criado e está pendente de aprovação');
        
        // Mostrar dialog de status pendente
        _showPendingApprovalDialog(result);
      } else {
        // Registro normal (não deveria acontecer com código de convite)
        showSuccess(context, 'Conta criada com sucesso!');
        
        // Navegar para tela de sucesso
        context.pushReplacement('/invite/success', extra: {
          'ministryName': widget.ministryName,
          'userName': _nameController.text.trim(),
        });
      }
    }
    } catch (e) {
      print('❌ Erro no registro: $e');
      
      if (mounted) {
        String errorMessage = 'Erro ao criar conta';
        
        if (e.toString().contains('Email já está em uso')) {
          errorMessage = 'Este email já está sendo usado. Tente fazer login ou use outro email.';
        } else if (e.toString().contains('Código de convite inválido')) {
          errorMessage = 'Código de convite inválido ou expirado. Verifique o código e tente novamente.';
        } else if (e.toString().contains('conexão')) {
          errorMessage = 'Problema de conexão. Verifique sua internet e tente novamente.';
        } else if (e.toString().contains('senha')) {
          errorMessage = 'Senha não atende aos critérios de segurança.';
        } else {
          errorMessage = 'Erro ao criar conta: ${e.toString()}';
        }
        
        showError(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Mostra dialog de status pendente de aprovação
  void _showPendingApprovalDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.schedule,
              color: Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aguardando Aprovação',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurface,
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
              'Sua conta foi criada com sucesso!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
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
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Status: Pendente',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Você foi vinculado ao ministério ${widget.ministryName}\n'
                    '• O líder do ministério precisa aprovar sua participação\n'
                    '• Você receberá um email quando for aprovado\n'
                    '• Enquanto isso, você pode fazer login normalmente',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.colors.onSurface.withOpacity(0.8),
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
            onPressed: () {
              Navigator.of(context).pop();
              // Navegar para login
              context.pushReplacement('/login');
            },
            child: Text(
              'Fazer Login',
              style: TextStyle(
                color: context.colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }


  /// Constrói o indicador de força da senha
  Widget _buildPasswordStrengthIndicator() {
    final password = _passwordController.text;
    final strength = _calculatePasswordStrength(password);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Força da senha: ',
              style: TextStyle(
                fontSize: 12,
                color: context.colors.onSurface.withOpacity(0.7),
              ),
            ),
            Text(
              strength.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: strength.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: context.colors.surfaceContainerHighest,
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: strength.strength,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: strength.color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Calcula a força da senha
  PasswordStrength _calculatePasswordStrength(String password) {
    if (password.isEmpty) {
      return PasswordStrength('Muito fraca', 0.0, Colors.red);
    }
    
    int score = 0;
    
    // Comprimento
    if (password.length >= 8) score += 1;
    if (password.length >= 12) score += 1;
    
    // Tipos de caracteres
    if (RegExp(r'[a-z]').hasMatch(password)) score += 1;
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 1;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 1;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score += 1;
    
    // Penalidade por espaços
    if (password.contains(' ')) score -= 1;
    
    score = score.clamp(0, 6);
    
    if (score <= 2) {
      return PasswordStrength('Muito fraca', 0.2, Colors.red);
    } else if (score <= 3) {
      return PasswordStrength('Fraca', 0.4, Colors.orange);
    } else if (score <= 4) {
      return PasswordStrength('Média', 0.6, Colors.yellow[700]!);
    } else if (score <= 5) {
      return PasswordStrength('Forte', 0.8, Colors.lightGreen);
    } else {
      return PasswordStrength('Muito forte', 1.0, Colors.green);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Criar Conta'),
        backgroundColor: context.colors.primaryContainer,
        foregroundColor: context.colors.onPrimaryContainer,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header com contexto do ministério
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.colors.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.church,
                        size: 48,
                        color: context.colors.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Você está se cadastrando para o ministério:',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.colors.onPrimaryContainer.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.ministryName.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: context.colors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Código: ${widget.code}',
                          style: TextStyle(
                            color: context.colors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Campo Nome
                Text(
                  'Nome Completo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Digite seu nome completo',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nome é obrigatório';
                    }
                    if (value.trim().length < 2) {
                      return 'Nome deve ter pelo menos 2 caracteres';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Campo Email
                Text(
                  'Email',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Digite seu email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email é obrigatório';
                    }
                    
                    final email = value.trim().toLowerCase();
                    
                    // Validação mais robusta de email
                    final emailRegex = RegExp(r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$');
                    
                    if (!emailRegex.hasMatch(email)) {
                      return 'Digite um email válido (ex: usuario@exemplo.com)';
                    }
                    
                    // Verificar se não tem espaços
                    if (email.contains(' ')) {
                      return 'Email não pode conter espaços';
                    }
                    
                    // Verificar se não tem caracteres duplicados suspeitos
                    if (email.contains('..') || email.contains('@@')) {
                      return 'Email contém caracteres inválidos';
                    }
                    
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Campo Telefone
                Text(
                  'Telefone',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                    PhoneNumberFormatter(),
                  ],
                  decoration: InputDecoration(
                    hintText: '(99) 99999-9999',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Telefone é obrigatório';
                    }
                    
                    // Remove formatação para validar apenas números
                    final phoneNumbers = value.replaceAll(RegExp(r'[^\d]'), '');
                    
                    if (phoneNumbers.length < 10) {
                      return 'Telefone deve ter pelo menos 10 dígitos';
                    }
                    
                    if (phoneNumbers.length > 11) {
                      return 'Telefone deve ter no máximo 11 dígitos';
                    }
                    
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Campo Senha
                Text(
                  'Senha',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Digite sua senha',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Senha é obrigatória';
                    }
                    
                    if (value.length < 8) {
                      return 'Senha deve ter pelo menos 8 caracteres';
                    }
                    
                    if (value.length > 50) {
                      return 'Senha deve ter no máximo 50 caracteres';
                    }
                    
                    // Verificar se tem pelo menos uma letra minúscula
                    if (!RegExp(r'[a-z]').hasMatch(value)) {
                      return 'Senha deve conter pelo menos uma letra minúscula';
                    }
                    
                    // Verificar se tem pelo menos uma letra maiúscula
                    if (!RegExp(r'[A-Z]').hasMatch(value)) {
                      return 'Senha deve conter pelo menos uma letra maiúscula';
                    }
                    
                    // Verificar se tem pelo menos um número
                    if (!RegExp(r'[0-9]').hasMatch(value)) {
                      return 'Senha deve conter pelo menos um número';
                    }
                    
                    // Verificar se tem pelo menos um caractere especial
                    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                      return 'Senha deve conter pelo menos um caractere especial (!@#\$%^&*)';
                    }
                    
                    // Verificar se não tem espaços
                    if (value.contains(' ')) {
                      return 'Senha não pode conter espaços';
                    }
                    
                    return null;
                  },
                ),
                
                // Indicador de força da senha
                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildPasswordStrengthIndicator(),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 20),

                // Campo Confirmar Senha
                Text(
                  'Confirmar Senha',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Confirme sua senha',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirmação de senha é obrigatória';
                    }
                    
                    if (value != _passwordController.text) {
                      return 'As senhas não coincidem';
                    }
                    
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Botão de criar conta
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
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
                          'Criar Conta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),

                const SizedBox(height: 24),

                // Informações sobre o processo
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
                            'O que acontece depois?',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: context.colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Sua conta será criada automaticamente\n'
                        '• Você será vinculado ao ministério ${widget.ministryName}\n'
                        '• Suas funções serão definidas pelo líder\n'
                        '• Você receberá um email de boas-vindas',
                        style: TextStyle(
                          color: context.colors.onSurface.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Link para voltar
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    'Voltar',
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
      ),
    );
  }
}

/// Classe para representar a força da senha
class PasswordStrength {
  final String label;
  final double strength;
  final Color color;

  PasswordStrength(this.label, this.strength, this.color);
}

/// Formatter para máscara de telefone brasileiro
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    // Se está vazio, retorna como está
    if (text.isEmpty) {
      return newValue;
    }
    
    // Remove todos os caracteres não numéricos
    final numbers = text.replaceAll(RegExp(r'[^\d]'), '');
    
    // Limita a 11 dígitos
    final limitedNumbers = numbers.length > 11 
        ? numbers.substring(0, 11) 
        : numbers;
    
    String formatted = '';
    
    if (limitedNumbers.length <= 2) {
      // Apenas DDD: (11
      formatted = '($limitedNumbers';
    } else if (limitedNumbers.length <= 6) {
      // DDD + início do número: (11) 9999
      formatted = '(${limitedNumbers.substring(0, 2)}) ${limitedNumbers.substring(2)}';
    } else if (limitedNumbers.length <= 10) {
      // Telefone fixo: (11) 9999-9999
      formatted = '(${limitedNumbers.substring(0, 2)}) ${limitedNumbers.substring(2, 6)}-${limitedNumbers.substring(6)}';
    } else {
      // Celular: (11) 99999-9999
      formatted = '(${limitedNumbers.substring(0, 2)}) ${limitedNumbers.substring(2, 7)}-${limitedNumbers.substring(7)}';
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}