import 'package:flutter/material.dart';
import 'package:servus_app/core/auth/services/auth_service.dart';
import 'package:servus_app/core/enums/user_role.dart';
import 'package:servus_app/core/models/usuario_logado.dart';
import 'package:servus_app/services/local_storage_service.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/services/auth_integration_service.dart';

class AuthState extends ChangeNotifier {
  UsuarioLogado? _usuario;
  bool _isLoading = false;

  UsuarioLogado? get usuario => _usuario;
  bool get isLoading => _isLoading;

  bool get isAuthenticated => _usuario != null;
  bool get isAdmin => _usuario?.role == UserRole.servus_admin || _usuario?.role == UserRole.tenant_admin || _usuario?.role == UserRole.branch_admin;
  bool get isLider => _usuario?.role == UserRole.leader;
  bool get isVoluntario => _usuario?.role == UserRole.volunteer;

  void login(UsuarioLogado usuario) async {
    _usuario = usuario;
    await LocalStorageService.salvarUsuario(usuario);
    
    // Integrar contexto de autenticação
    AuthIntegrationService.instance.integrateWithUsuarioLogado(usuario);
    
    notifyListeners();
  }

  Future<void> logoutCompleto() async {
    try {
      setLoading(true);
      await AuthService().logout();
      _usuario = null;
      await LocalStorageService.limparDados();
      await TokenService.clearAll();
      
      // Limpar contexto de autenticação
      AuthIntegrationService.instance.integrateWithUsuarioLogado(null);
    } catch (_) {
      _usuario = null;
      await LocalStorageService.limparDados();
      await TokenService.clearAll();
      
      // Limpar contexto de autenticação mesmo em caso de erro
      AuthIntegrationService.instance.integrateWithUsuarioLogado(null);
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  void selecionarPapel(UserRole papel) {
    if (_usuario != null) {
      _usuario = _usuario!.copyWith(papelSelecionado: papel);
      notifyListeners();
    }
  }

  Future<void> carregarUsuarioDoLocalStorage() async {
    try {
      setLoading(true);
      
      final usuario = await LocalStorageService.carregarUsuario();
      
      if (usuario != null) {
        
        _usuario = usuario;
        
        // Integrar contexto de autenticação
        AuthIntegrationService.instance.integrateWithUsuarioLogado(usuario);
        
        notifyListeners();
      } else {
      }
    } finally {
      setLoading(false);
    }
  }

  Future<void> renovarToken(BuildContext context) async {
    try {
      setLoading(true);
      final success = await AuthService().renovarToken(context);
      if (!success) {
        // Se não conseguiu renovar, faz logout
        await logoutCompleto();
      }
    } finally {
      setLoading(false);
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Verifica se o token está expirado e renova se necessário
  Future<bool> verificarToken(BuildContext context) async {
    if (await TokenService.isTokenExpired()) {
      await renovarToken(context);
      return false;
    }
    return true;
  }

  /// Obtém o contexto atual do usuário
  Future<void> atualizarContexto(BuildContext context) async {
    try {
      setLoading(true);
      final loginResponse = await AuthService().getUserContext();
      if (loginResponse != null) {
        final usuario = AuthService().convertToUsuarioLogado(loginResponse);
        _usuario = usuario;
        await LocalStorageService.salvarUsuario(usuario);
        
        // Integrar contexto de autenticação
        AuthIntegrationService.instance.integrateWithUsuarioLogado(usuario);
        
        notifyListeners();
      }
    } finally {
      setLoading(false);
    }
  }
}
