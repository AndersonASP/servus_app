import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/auth/services/auth_service.dart';
import 'package:servus_app/core/auth/services/token_service.dart';

import 'package:servus_app/shared/widgets/servus_snackbar.dart';
import 'package:servus_app/core/enums/user_role.dart';
import 'package:servus_app/core/models/usuario_logado.dart';
import 'package:servus_app/state/auth_state.dart';

class LoginController extends ChangeNotifier {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool rememberMe = false;
  bool isPasswordVisible = false;
  bool isLoading = false;

  final AuthService _authService = AuthService();

  Future<void> fazerLogin(
      String email, String senha, BuildContext context, {String? tenantId}) async {
    
    final auth = Provider.of<AuthState>(context, listen: false);

    if (email.isEmpty || senha.isEmpty) {
      showServusSnack(context, message: 'Informe e-mail e senha', type: ServusSnackType.error);
      return;
    }

    setLoading(true);

    try {
      final loginResponse = await _authService.loginComEmailESenha(
        email: email, 
        senha: senha,
        tenantId: tenantId,
      );

      // 🆕 CORREÇÃO: Primeiro extrai e carrega claims do JWT
      await TokenService.extractSecurityClaims(loginResponse.accessToken);
      await TokenService.loadSecurityClaims();
      
      // Converte para UsuarioLogado com dados atualizados
      final usuario = _authService.convertToUsuarioLogado(loginResponse);

      // 🆕 CORREÇÃO: Atualiza o usuário com dados corretos dos claims
      final usuarioAtualizado = await _atualizarUsuarioComClaims(usuario);
      
      // Atualiza estado global com dados corretos
      auth.login(usuarioAtualizado);

      // Determina o dashboard usando claims atualizados
      
      if (context.mounted) {
        final dashboardRoute = await _determinarDashboardRouteComClaims(usuarioAtualizado);
        // Usa post frame callback para evitar problemas de navegação durante dispose
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.go(dashboardRoute);
          }
        });
      }
    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      
      // Tratamento específico para usuários pendentes
      if (errorMessage.contains('aguardando aprovação') || errorMessage.contains('aprovação do líder')) {
        _showPendingApprovalDialog(context, errorMessage);
      } else {
        showServusSnack(context, message: errorMessage, type: ServusSnackType.error);
      }
    } finally {
      setLoading(false);
    }
  }

  Future<void> fazerLoginComGoogle(BuildContext context, {String? tenantId}) async {
    final auth = Provider.of<AuthState>(context, listen: false);

    setLoading(true);

    try {
      final loginResponse = await _authService.loginComGoogle(tenantId: tenantId);

      // 🆕 CORREÇÃO: Primeiro extrai e carrega claims do JWT
      await TokenService.extractSecurityClaims(loginResponse.accessToken);
      await TokenService.loadSecurityClaims();
      
      // Converte para UsuarioLogado com dados atualizados
      final usuario = _authService.convertToUsuarioLogado(loginResponse);

      // 🆕 CORREÇÃO: Atualiza o usuário com dados corretos dos claims
      final usuarioAtualizado = await _atualizarUsuarioComClaims(usuario);
      
      // Atualiza estado global com dados corretos
      auth.login(usuarioAtualizado);

      // Determina o dashboard usando claims atualizados
      
      if (context.mounted) {
        final dashboardRoute = await _determinarDashboardRouteComClaims(usuarioAtualizado);
        // Usa post frame callback para evitar problemas de navegação durante dispose
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.go(dashboardRoute);
          }
        });
      }
    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      
      // Tratamento específico para usuários pendentes
      if (errorMessage.contains('aguardando aprovação') || errorMessage.contains('aprovação do líder')) {
        _showPendingApprovalDialog(context, errorMessage);
      } else {
        showServusSnack(context, message: errorMessage, type: ServusSnackType.error);
      }
    } finally {
      setLoading(false);
    }
  }



  void toggleRememberMe(bool? value) {
    rememberMe = value ?? false;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    notifyListeners();
  }

  void setLoading(bool loading) {
    isLoading = loading;
    notifyListeners();
  }

  /// 🆕 Atualiza o usuário com dados corretos dos claims do JWT
  Future<UsuarioLogado> _atualizarUsuarioComClaims(UsuarioLogado usuario) async {
    try {
      print('🔍 [LoginController] ===== ATUALIZANDO USUÁRIO COM CLAIMS =====');
      print('🔍 [LoginController] Usuário antes da atualização:');
      print('   - Role: ${usuario.role}');
      print('   - PrimaryMinistryId: ${usuario.primaryMinistryId}');
      print('   - PrimaryMinistryName: ${usuario.primaryMinistryName}');
      print('   - TenantId: ${usuario.tenantId}');
      print('   - BranchId: ${usuario.branchId}');
      
      // Obtém dados atualizados dos claims
      final userRole = TokenService.userRole;
      final membershipRole = TokenService.membershipRole;
      final tenantId = TokenService.tenantId;
      final branchId = TokenService.branchId;
      
      print('🔍 [LoginController] Dados dos claims:');
      print('   - UserRole: $userRole');
      print('   - MembershipRole: $membershipRole');
      print('   - TenantId: $tenantId');
      print('   - BranchId: $branchId');
      
      // Determina o role final (mesma lógica do roteamento)
      String? roleFinal;
      if (userRole == 'servus_admin') {
        roleFinal = userRole; // ServusAdmin sempre usa seu role global
      } else {
        // Para outros usuários, membership role tem prioridade sobre user role
        roleFinal = membershipRole ?? userRole;
      }
      
      // Mapeia o role para enum
      final roleEnum = _mapearRoleParaEnum(roleFinal);
      
      print('🔍 [LoginController] Role final determinado: $roleFinal -> $roleEnum');
      
      // 🆕 CORREÇÃO: Preservar TODOS os dados do usuário, incluindo primaryMinistryId
      final usuarioAtualizado = usuario.copyWith(
        papeis: roleEnum,
        papelSelecionado: roleEnum,
        tenantId: tenantId,
        branchId: branchId,
        // 🆕 IMPORTANTE: Preservar os dados do ministério principal
        primaryMinistryId: usuario.primaryMinistryId,
        primaryMinistryName: usuario.primaryMinistryName,
      );
      
      print('🔍 [LoginController] Usuário após atualização:');
      print('   - Role: ${usuarioAtualizado.role}');
      print('   - PrimaryMinistryId: ${usuarioAtualizado.primaryMinistryId}');
      print('   - PrimaryMinistryName: ${usuarioAtualizado.primaryMinistryName}');
      print('   - TenantId: ${usuarioAtualizado.tenantId}');
      print('   - BranchId: ${usuarioAtualizado.branchId}');
      print('🔍 [LoginController] ===== FIM DA ATUALIZAÇÃO COM CLAIMS =====');
      
      return usuarioAtualizado;
      
    } catch (e) {
      print('❌ [LoginController] Erro ao atualizar usuário com claims: $e');
      return usuario;
    }
  }

  /// 🆕 Mapeia role string para enum
  UserRole _mapearRoleParaEnum(String? role) {
    switch (role?.toLowerCase()) {
      case 'servus_admin':
        return UserRole.servus_admin;
      case 'tenant_admin':
        return UserRole.tenant_admin;
      case 'branch_admin':
        return UserRole.branch_admin;
      case 'leader':
        return UserRole.leader;
      case 'volunteer':
        return UserRole.volunteer;
      default:
        return UserRole.volunteer;
    }
  }

  /// 🆕 Determina a rota do dashboard usando claims do JWT (mesma lógica do SplashController)
  Future<String> _determinarDashboardRouteComClaims(UsuarioLogado usuario) async {
    try {
      
      // 🆕 PRIMEIRO: Tenta extrair claims diretamente do JWT atual
      final accessToken = await TokenService.getAccessToken();
      if (accessToken != null) {
        await TokenService.extractSecurityClaims(accessToken);
      }
      
      // 🆕 SEGUNDO: Carrega claims de segurança (do JWT ou cache)
      await TokenService.loadSecurityClaims();
      
      // 🆕 TERCEIRO: Usa role do JWT (mais seguro e atualizado)
      final userRole = TokenService.userRole;
      final membershipRole = TokenService.membershipRole;
      
      
      // 🆕 CORREÇÃO: Para ServusAdmin, sempre usa userRole
      String? roleFinal;
      if (userRole == 'servus_admin') {
        roleFinal = userRole; // ServusAdmin sempre usa seu role global
      } else {
        // Para outros usuários, membership role tem prioridade sobre user role
        roleFinal = membershipRole ?? userRole;
      }
      
      if (roleFinal != null) {
        
        // Mapeia o role para rota do dashboard
        final dashboardRoute = _mapearRoleParaDashboard(roleFinal);
        return dashboardRoute;
      } else {
        return '/volunteer/dashboard';
      }
      
    } catch (e) {
      
      // Fallback: usa o role do usuário logado
      return _determinarDashboardRoute(usuario.role);
    }
  }

  /// 🆕 Mapeia role string para rota do dashboard
  String _mapearRoleParaDashboard(String role) {
    switch (role.toLowerCase()) {
      case 'servus_admin':
      case 'tenant_admin':
      case 'branch_admin':
      case 'leader':
        return '/leader/dashboard';
      case 'volunteer':
        return '/volunteer/dashboard';
      default:
        return '/volunteer/dashboard';
    }
  }

  /// 🆕 Determina a rota do dashboard baseada no role do usuário (fallback)
  String _determinarDashboardRoute(UserRole role) {
    switch (role) {
      case UserRole.servus_admin:
      case UserRole.tenant_admin:
      case UserRole.branch_admin:
      case UserRole.leader:
        return '/leader/dashboard';
      case UserRole.volunteer:
        return '/volunteer/dashboard';
    }
  }

  /// Mostra dialog específico para usuários pendentes de aprovação
  void _showPendingApprovalDialog(BuildContext context, String message) {
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
                  color: Theme.of(context).colorScheme.onSurface,
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
                color: Theme.of(context).colorScheme.onSurface,
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
                    '• O líder do ministério precisa aprovar sua participação\n'
                    '• Você receberá um email quando for aprovado\n'
                    '• Entre em contato com o líder se necessário',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
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
              'Entendi',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
