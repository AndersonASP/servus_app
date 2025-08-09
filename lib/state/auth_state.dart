import 'package:flutter/material.dart';
import 'package:servus_app/core/auth/services/auth_service.dart';
import 'package:servus_app/core/enums/user_role.dart';
import 'package:servus_app/core/models/usuario_logado.dart';
import 'package:servus_app/services/local_storage_service.dart';

class AuthState extends ChangeNotifier {
  UsuarioLogado? _usuario;

  UsuarioLogado? get usuario => _usuario;

  bool get isAdmin => _usuario?.role == UserRole.admin;
  bool get isLider => _usuario?.role == UserRole.leader;
  bool get isVoluntario => _usuario?.role == UserRole.volunteer;

  void login(UsuarioLogado usuario) async {
    _usuario = usuario;
    await LocalStorageService.salvarUsuario(usuario);
    notifyListeners();
  }

  Future<void> logoutCompleto() async {
    try {
      await AuthService().logout();
      _usuario = null;
      await LocalStorageService.limparDados();
    } catch (_) {
      _usuario = null;
      await LocalStorageService.limparDados();
    }
    notifyListeners();
  }

  void selecionarPapel(UserRole papel) {
    if (_usuario != null) {
      _usuario = _usuario!.copyWith(papelSelecionado: papel);
      notifyListeners();
    }
  }

  Future<void> carregarUsuarioDoLocalStorage() async {
    final usuario = await LocalStorageService.carregarUsuario();
    if (usuario != null) {
      _usuario = usuario;
      notifyListeners();
    }
  }
}
