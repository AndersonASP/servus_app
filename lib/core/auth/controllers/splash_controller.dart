import 'package:flutter/material.dart';
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
    
    // Verifica se já viu a tela de welcome
    final jaViuWelcome = await _verificarSeViuWelcome();
    if (!jaViuWelcome) {
      _navigateSafely('/welcome');
      return;
    }

    // Verifica se há tokens válidos
    final temTokens = await _verificarTokens();
    if (!temTokens) {
      _navigateSafely('/login');
      return;
    }

    // Tenta renovar o token se necessário
    final tokenValido = await _verificarErenovarToken(context);
    if (!tokenValido) {
      await _limparDados();
      _navigateSafely('/login');
      return;
    }

    // Verifica se há dados do usuário
    final temUsuario = await LocalStorageService.temUsuarioSalvo();
    if (!temUsuario) {
      _navigateSafely('/login');
      return;
    }

    // Redireciona baseado no role
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
      return false;
    }
  }

  Future<void> _redirecionarPorRole() async {
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
        
        // Mapeia o role para enum
        final papel = _mapearRoleParaEnum(roleFinal);
        
        switch (papel) {
          case UserRole.servus_admin:
          case UserRole.tenant_admin:
          case UserRole.branch_admin:
          case UserRole.leader:
            _navigateSafely('/leader/dashboard');
            break;
          case UserRole.volunteer:
            _navigateSafely('/volunteer/dashboard');
            break;
        }
      } else {
        _navigateSafely('/choose-role');
      }
      
    } catch (e) {
      
      // 🆕 FALLBACK: Se falhar, usa storage local
      await _redirecionarPorRoleFallback();
    }
  }

  /// 🆕 Fallback para roteamento usando storage local
  Future<void> _redirecionarPorRoleFallback() async {
    try {
      final infoBasica = await LocalStorageService.getInfoBasica();
      final role = infoBasica['role'];
      
      
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
            _navigateSafely('/leader/dashboard');
            break;
          case UserRole.volunteer:
            _navigateSafely('/volunteer/dashboard');
            break;
        }
      } else {
        _navigateSafely('/choose-role');
      }
    } catch (e) {
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
