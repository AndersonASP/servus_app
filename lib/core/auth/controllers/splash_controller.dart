import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:servus_app/core/auth/services/auth_service.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/core/enums/user_role.dart';
import 'package:servus_app/services/local_storage_service.dart';

class SplashController {
  final AnimationController animationController;
  final void Function(String route) onNavigate;
  final BuildContext? context;

  late final Animation<double> circleScale;
  late final Animation<double> logoTop;
  late final Animation<double> logoOpacity;
  late final Animation<double> textOpacity;

  SplashController({
    required TickerProvider vsync,
    required this.onNavigate,
    this.context,
  }) : animationController = AnimationController(
          vsync: vsync,
          duration: const Duration(milliseconds: 3000),
        );

  /// Navegação segura que evita problemas durante dispose
  void _navigateSafely(String route) {
    if (context != null && context!.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context != null && context!.mounted) {
          onNavigate(route);
        }
      });
    } else {
      onNavigate(route);
    }
  }

  void start(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    );

    circleScale = Tween<double>(begin: 0.0, end: 8.0).animate(curved);

    logoTop = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: -150, end: 0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: -20)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -20, end: -10)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
    ]).animate(curved);

    logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeIn),
      ),
    );

    textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
      ),
    );

    animationController.forward();
    Future.delayed(const Duration(milliseconds: 3200), () => _decidirRota(context));
  }

  Future<void> _decidirRota(BuildContext context) async {
    // print('🚀 Iniciando decisão de rota...');
    
    // Verifica se já viu a tela de welcome
    final jaViuWelcome = await _verificarSeViuWelcome();
    // print('📋 Já viu welcome: $jaViuWelcome');
    if (!jaViuWelcome) {
      // print('🔄 Redirecionando para welcome');
      _navigateSafely('/welcome');
      return;
    }

    // Verifica se há tokens válidos
    final temTokens = await _verificarTokens();
    // print('🔑 Tem tokens: $temTokens');
    if (!temTokens) {
      // print('🔄 Redirecionando para login (sem tokens)');
      _navigateSafely('/login');
      return;
    }

    // Tenta renovar o token se necessário
    final tokenValido = await _verificarErenovarToken(context);
    // print('✅ Token válido: $tokenValido');
    if (!tokenValido) {
      // print('🔄 Token inválido, limpando dados e redirecionando para login');
      await _limparDados();
      _navigateSafely('/login');
      return;
    }

    // Verifica se há dados do usuário
    final temUsuario = await LocalStorageService.temUsuarioSalvo();
    // print('👤 Tem usuário salvo: $temUsuario');
    if (!temUsuario) {
      // print('🔄 Redirecionando para login (sem usuário salvo)');
      _navigateSafely('/login');
      return;
    }

    // Redireciona baseado no role
    // print('🎯 Redirecionando por role...');
    await _redirecionarPorRole();
  }

  Future<bool> _verificarSeViuWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('viu_welcome') ?? false;
  }

  Future<bool> _verificarTokens() async {
    final accessToken = await TokenService.getAccessToken();
    final refreshToken = await TokenService.getRefreshToken();
    
    return accessToken != null && refreshToken != null;
  }

  Future<bool> _verificarErenovarToken(BuildContext context) async {
    try {
      // Se o token está expirado, tenta renovar
      if (await TokenService.isTokenExpired()) {
        final authService = AuthService();
        return await authService.renovarToken(context);
      }
      
      // Se o token expira em breve, renova preventivamente
      if (await TokenService.isTokenExpiringSoon()) {
        final authService = AuthService();
        return await authService.renovarToken(context);
      }
      
      return true;
    } catch (e) {
      // print('❌ Erro ao verificar/renovar token: $e');
      return false;
    }
  }

  Future<void> _redirecionarPorRole() async {
    try {
      // print('🔍 Decidindo rota baseada no role...');
      
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
        
        // Mapeia o role para enum
        final papel = _mapearRoleParaEnum(roleFinal);
        // print('🎭 Role mapeado para enum: $papel');
        
        switch (papel) {
          case UserRole.servus_admin:
          case UserRole.tenant_admin:
          case UserRole.branch_admin:
          case UserRole.leader:
            // print('👑 Redirecionando para dashboard de líder: /leader/dashboard');
            _navigateSafely('/leader/dashboard');
            break;
          case UserRole.volunteer:
            // print('👤 Redirecionando para dashboard de voluntário: /volunteer/dashboard');
            _navigateSafely('/volunteer/dashboard');
            break;
        }
      } else {
        // print('⚠️ Nenhum role encontrado, redirecionando para escolha de role');
        _navigateSafely('/choose-role');
      }
      
    } catch (e) {
      // print('❌ Erro ao decidir rota por role: $e');
      // print('🔄 Fallback: usando storage local...');
      
      // 🆕 FALLBACK: Se falhar, usa storage local
      await _redirecionarPorRoleFallback();
    }
  }

  /// 🆕 Fallback para roteamento usando storage local
  Future<void> _redirecionarPorRoleFallback() async {
    try {
      final infoBasica = await LocalStorageService.getInfoBasica();
      final role = infoBasica['role'];
      
      // print('🔄 Fallback - Role do storage local: $role');
      
      if (role != null) {
        final papel = UserRole.values.firstWhere(
          (e) => e.name == role,
          orElse: () => UserRole.volunteer,
        );

        switch (papel) {
          case UserRole.servus_admin:
          case UserRole.tenant_admin:
          case UserRole.branch_admin:
          case UserRole.leader:
            // print('👑 Fallback - Redirecionando para dashboard de líder');
            _navigateSafely('/leader/dashboard');
            break;
          case UserRole.volunteer:
            // print('👤 Fallback - Redirecionando para dashboard de voluntário');
            _navigateSafely('/volunteer/dashboard');
            break;
        }
      } else {
        // print('⚠️ Fallback - Nenhum role encontrado, redirecionando para escolha');
        _navigateSafely('/choose-role');
      }
    } catch (e) {
      // print('❌ Erro no fallback de roteamento: $e');
      onNavigate('/choose-role');
    }
  }

  /// 🆕 Mapeia role string para enum UserRole
  UserRole _mapearRoleParaEnum(String role) {
    switch (role.toLowerCase()) {
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

  Future<void> _limparDados() async {
    await TokenService.clearAll();
    await LocalStorageService.limparDados();
  }

  void dispose() {
    animationController.dispose();
  }
}
