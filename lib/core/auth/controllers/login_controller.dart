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
    print('🎯 [LOGIN_CONTROLLER] Iniciando processo de login...');
    print('📧 [LOGIN_CONTROLLER] Email recebido: $email');
    print('🔑 [LOGIN_CONTROLLER] Senha recebida: ${senha.isNotEmpty ? '***' : 'VAZIA'}');
    print('🏢 [LOGIN_CONTROLLER] TenantId: $tenantId');
    
    final auth = Provider.of<AuthState>(context, listen: false);

    if (email.isEmpty || senha.isEmpty) {
      print('❌ [LOGIN_CONTROLLER] Email ou senha vazios');
      showServusSnack(context, message: 'Informe e-mail e senha', type: ServusSnackType.error);
      return;
    }

    print('⏳ [LOGIN_CONTROLLER] Definindo loading como true...');
    setLoading(true);

    try {
      print('🚀 [LOGIN_CONTROLLER] Chamando AuthService.loginComEmailESenha...');
      final loginResponse = await _authService.loginComEmailESenha(
        email: email, 
        senha: senha,
        tenantId: tenantId,
      );
      print('✅ [LOGIN_CONTROLLER] LoginResponse recebido com sucesso');

      // 🆕 CORREÇÃO: Primeiro extrai e carrega claims do JWT
      print('🔐 [LOGIN_CONTROLLER] Extraindo claims do JWT...');
      await TokenService.extractSecurityClaims(loginResponse.accessToken);
      await TokenService.loadSecurityClaims();
      print('✅ [LOGIN_CONTROLLER] Claims extraídos com sucesso');
      
      // Converte para UsuarioLogado com dados atualizados
      print('🔄 [LOGIN_CONTROLLER] Convertendo LoginResponse para UsuarioLogado...');
      final usuario = _authService.convertToUsuarioLogado(loginResponse);
      print('✅ [LOGIN_CONTROLLER] UsuarioLogado criado: ${usuario.nome} (${usuario.email})');

      // 🆕 CORREÇÃO: Atualiza o usuário com dados corretos dos claims
      print('🔄 [LOGIN_CONTROLLER] Atualizando usuário com claims...');
      final usuarioAtualizado = await _atualizarUsuarioComClaims(usuario);
      print('✅ [LOGIN_CONTROLLER] Usuário atualizado com claims');
      
      // Atualiza estado global com dados corretos
      print('🔄 [LOGIN_CONTROLLER] Atualizando estado global...');
      auth.login(usuarioAtualizado);
      print('✅ [LOGIN_CONTROLLER] Estado global atualizado');

      // Determina o dashboard usando claims atualizados
      print('🎯 [LOGIN_CONTROLLER] Determinando dashboard com claims atualizados...');
      
      if (context.mounted) {
        final dashboardRoute = await _determinarDashboardRouteComClaims(usuarioAtualizado);
        print('🎯 [LOGIN_CONTROLLER] Redirecionando para: $dashboardRoute');
        // Usa post frame callback para evitar problemas de navegação durante dispose
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            print('🚀 [LOGIN_CONTROLLER] Executando navegação para: $dashboardRoute');
            context.go(dashboardRoute);
          }
        });
      }
    } catch (e) {
      print('❌ [LOGIN_CONTROLLER] Erro durante login: $e');
      showServusSnack(context, message: e.toString().replaceAll('Exception: ', ''), type: ServusSnackType.error);
    } finally {
      print('⏳ [LOGIN_CONTROLLER] Definindo loading como false...');
      setLoading(false);
    }
  }

  Future<void> fazerLoginComGoogle(BuildContext context, {String? tenantId}) async {
    final auth = Provider.of<AuthState>(context, listen: false);

    setLoading(true);

    try {
      final loginResponse = await _authService.loginComGoogle(tenantId: tenantId);

      // 🆕 CORREÇÃO: Primeiro extrai e carrega claims do JWT
      // print('✅ Login com Google realizado com sucesso. Extraindo claims do JWT...');
      await TokenService.extractSecurityClaims(loginResponse.accessToken);
      await TokenService.loadSecurityClaims();
      
      // Converte para UsuarioLogado com dados atualizados
      final usuario = _authService.convertToUsuarioLogado(loginResponse);

      // 🆕 CORREÇÃO: Atualiza o usuário com dados corretos dos claims
      final usuarioAtualizado = await _atualizarUsuarioComClaims(usuario);
      
      // Atualiza estado global com dados corretos
      auth.login(usuarioAtualizado);

      // Determina o dashboard usando claims atualizados
      // print('🎯 Determinando dashboard com claims atualizados...');
      
      if (context.mounted) {
        final dashboardRoute = await _determinarDashboardRouteComClaims(usuarioAtualizado);
        // print('🎯 Redirecionando para: $dashboardRoute');
        // Usa post frame callback para evitar problemas de navegação durante dispose
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.go(dashboardRoute);
          }
        });
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

  /// 🆕 Atualiza o usuário com dados corretos dos claims do JWT
  Future<UsuarioLogado> _atualizarUsuarioComClaims(UsuarioLogado usuario) async {
    try {
      // print('🔄 Atualizando usuário com claims do JWT...');
      
      // Obtém dados atualizados dos claims
      final userRole = TokenService.userRole;
      final membershipRole = TokenService.membershipRole;
      final tenantId = TokenService.tenantId;
      final branchId = TokenService.branchId;
      
      // print('📋 Claims disponíveis:');
      // print('   - User Role: $userRole');
      // print('   - Membership Role: $membershipRole');
      // print('   - Tenant ID: $tenantId');
      // print('   - Branch ID: $branchId');
      
      // Determina o role final (mesma lógica do roteamento)
      String? roleFinal;
      if (userRole == 'servus_admin') {
        roleFinal = userRole; // ServusAdmin sempre usa seu role global
        // print('🎯 ServusAdmin detectado - usando role global: $roleFinal');
      } else {
        // Para outros usuários, membership role tem prioridade sobre user role
        roleFinal = membershipRole ?? userRole;
        // print('🎯 Role final para usuário: $roleFinal');
      }
      
      // Mapeia o role para enum
      final roleEnum = _mapearRoleParaEnum(roleFinal);
      // print('🎭 Role mapeado para enum: $roleEnum');
      
      // Retorna usuário atualizado com dados corretos
      return usuario.copyWith(
        papeis: roleEnum,
        papelSelecionado: roleEnum,
        tenantId: tenantId,
        branchId: branchId,
      );
      
    } catch (e) {
      // print('❌ Erro ao atualizar usuário com claims: $e');
      // print('🔄 Retornando usuário original...');
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
        // print('⚠️ Role desconhecido: $role, usando volunteer como padrão');
        return UserRole.volunteer;
    }
  }

  /// 🆕 Determina a rota do dashboard usando claims do JWT (mesma lógica do SplashController)
  Future<String> _determinarDashboardRouteComClaims(UsuarioLogado usuario) async {
    try {
      // print('🔍 Determinando dashboard usando claims do JWT...');
      
      // 🆕 PRIMEIRO: Tenta extrair claims diretamente do JWT atual
      final accessToken = await TokenService.getAccessToken();
      // print('🔐 Access token encontrado: ${accessToken != null ? "SIM" : "NÃO"}');
      if (accessToken != null) {
        // print('🔐 JWT encontrado, extraindo claims diretamente...');
        await TokenService.extractSecurityClaims(accessToken);
      }
      
      // 🆕 SEGUNDO: Carrega claims de segurança (do JWT ou cache)
      // print('📥 Carregando claims de segurança...');
      await TokenService.loadSecurityClaims();
      
      // 🆕 TERCEIRO: Usa role do JWT (mais seguro e atualizado)
      final userRole = TokenService.userRole;
      final membershipRole = TokenService.membershipRole;
      
      // print('📋 Claims de segurança carregados:');
      // print('   - User Role: $userRole');
      // print('   - Membership Role: $membershipRole');
      
      // 🆕 CORREÇÃO: Para ServusAdmin, sempre usa userRole
      String? roleFinal;
      if (userRole == 'servus_admin') {
        roleFinal = userRole; // ServusAdmin sempre usa seu role global
        // print('🎯 ServusAdmin detectado - usando role global: $roleFinal');
      } else {
        // Para outros usuários, membership role tem prioridade sobre user role
        roleFinal = membershipRole ?? userRole;
        // print('🎯 Role final para roteamento: $roleFinal');
      }
      
      if (roleFinal != null) {
        // print('🎯 Role final para roteamento: $roleFinal');
        
        // Mapeia o role para rota do dashboard
        final dashboardRoute = _mapearRoleParaDashboard(roleFinal);
        // print('🎭 Role mapeado para dashboard: $dashboardRoute');
        return dashboardRoute;
      } else {
        // print('⚠️ Nenhum role encontrado, usando fallback para volunteer');
        return '/volunteer/dashboard';
      }
      
    } catch (e) {
      // print('❌ Erro ao determinar dashboard por claims: $e');
      // print('🔄 Fallback: usando role do usuário local...');
      
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
        // print('⚠️ Role desconhecido: $role, usando volunteer como padrão');
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

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
