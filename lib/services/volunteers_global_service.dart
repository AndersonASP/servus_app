import 'package:flutter/material.dart';
import 'package:servus_app/features/leader/volunteers/controllers/volunteers_controller.dart';
import 'package:servus_app/state/auth_state.dart';

/// Serviço global para gerenciar o estado dos voluntários
/// Garante que todas as telas compartilhem a mesma instância do controller
class VolunteersGlobalService extends ChangeNotifier {
  static VolunteersGlobalService? _instance;
  VolunteersController? _controller;
  AuthState? _auth;

  VolunteersGlobalService._();

  static VolunteersGlobalService get instance {
    _instance ??= VolunteersGlobalService._();
    return _instance!;
  }

  /// Inicializa o serviço com o AuthState
  void initialize(AuthState auth) {
    if (_controller != null) {
      // Se já existe um controller, apenas atualiza o auth se necessário
      if (_auth != auth) {
        _auth = auth;
        _controller!.dispose();
        _controller = VolunteersController(auth: auth);
        _controller!.init();
        notifyListeners();
      }
      return;
    }

    _auth = auth;
    _controller = VolunteersController(auth: auth);
    _controller!.init();
    notifyListeners();
  }

  /// Obtém o controller atual
  VolunteersController? get controller => _controller;

  /// Verifica se o serviço está inicializado
  bool get isInitialized => _controller != null;

  /// Força atualização dos dados
  Future<void> refresh() async {
    if (_controller != null) {
      await _controller!.refreshVolunteers();
      notifyListeners();
    }
  }

  /// Limpa o serviço
  void dispose() {
    _controller?.dispose();
    _controller = null;
    _auth = null;
    notifyListeners();
  }
}
