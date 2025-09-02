import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/auth/services/auth_service.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/core/utils/role_util.dart';
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

      // Converte para UsuarioLogado
      final usuario = _authService.convertToUsuarioLogado(loginResponse);

      // Atualiza estado global
      auth.login(usuario);

      // 🆕 CORREÇÃO: Após login bem-sucedido, determina dashboard usando claims do JWT
      print('✅ Login realizado com sucesso. Determinando dashboard...');
      
      // Determina o dashboard usando a mesma lógica do SplashController
      if (context.mounted) {
        final dashboardRoute = await _determinarDashboardRouteComClaims(usuario);
        print('🎯 Redirecionando para: $dashboardRoute');
        context.go(dashboardRoute);
      }
    } catch (e) {
      showServusSnack(context, message: e.toString().replaceAll('Exception: ', ''), type: ServusSnackType.error);
    } finally {
      setLoading(false);
    }
  }

  Future<void> fazerLoginComGoogle(BuildContext context, {String? tenantId}) async {
    final auth = Provider.of<AuthState>(context, listen: false);

    setLoading(true);

    try {
      final loginResponse = await _authService.loginComGoogle(tenantId: tenantId);

      // Converte para UsuarioLogado
      final usuario = _authService.convertToUsuarioLogado(loginResponse);

      auth.login(usuario);

      // 🆕 CORREÇÃO: Após login bem-sucedido, vai direto para o dashboard
      print('✅ Login com Google realizado com sucesso. Redirecionando para dashboard...');
      
      // Determina o dashboard usando a mesma lógica do SplashController
      if (context.mounted) {
        final dashboardRoute = await _determinarDashboardRouteComClaims(usuario);
        print('🎯 Redirecionando para: $dashboardRoute');
        context.go(dashboardRoute);
      }
    } catch (e) {
      showServusSnack(context, message: e.toString().replaceAll('Exception: ', ''), type: ServusSnackType.error);
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

  /// 🆕 Determina a rota do dashboard usando claims do JWT (mesma lógica do SplashController)
  Future<String> _determinarDashboardRouteComClaims(UsuarioLogado usuario) async {
    try {
      print('🔍 Determinando dashboard usando claims do JWT...');
      
      // 🆕 PRIMEIRO: Tenta extrair claims diretamente do JWT atual
      final accessToken = await TokenService.getAccessToken();
      print('🔐 Access token encontrado: ${accessToken != null ? "SIM" : "NÃO"}');
      if (accessToken != null) {
        print('🔐 JWT encontrado, extraindo claims diretamente...');
        await TokenService.extractSecurityClaims(accessToken);
      }
      
      // 🆕 SEGUNDO: Carrega claims de segurança (do JWT ou cache)
      print('📥 Carregando claims de segurança...');
      await TokenService.loadSecurityClaims();
      
      // 🆕 TERCEIRO: Usa role do JWT (mais seguro e atualizado)
      final userRole = TokenService.userRole;
      final membershipRole = TokenService.membershipRole;
      
      print('📋 Claims de segurança carregados:');
      print('   - User Role: $userRole');
      print('   - Membership Role: $membershipRole');
      
      // 🆕 CORREÇÃO: Para ServusAdmin, sempre usa userRole
      String? roleFinal;
      if (userRole == 'servus_admin') {
        roleFinal = userRole; // ServusAdmin sempre usa seu role global
        print('🎯 ServusAdmin detectado - usando role global: $roleFinal');
      } else {
        // Para outros usuários, membership role tem prioridade sobre user role
        roleFinal = membershipRole ?? userRole;
        print('🎯 Role final para roteamento: $roleFinal');
      }
      
      if (roleFinal != null) {
        print('🎯 Role final para roteamento: $roleFinal');
        
        // Mapeia o role para rota do dashboard
        final dashboardRoute = _mapearRoleParaDashboard(roleFinal);
        print('🎭 Role mapeado para dashboard: $dashboardRoute');
        return dashboardRoute;
      } else {
        print('⚠️ Nenhum role encontrado, usando fallback para volunteer');
        return '/volunteer/dashboard';
      }
      
    } catch (e) {
      print('❌ Erro ao determinar dashboard por claims: $e');
      print('🔄 Fallback: usando role do usuário local...');
      
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
        print('⚠️ Role desconhecido: $role, usando volunteer como padrão');
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
      default:
        return '/volunteer/dashboard'; // Fallback
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
