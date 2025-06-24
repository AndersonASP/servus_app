import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  void login() {
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  // Você pode adicionar outras coisas aqui, como:
  // String _usuario = 'Anderson';
  // ThemeMode _modoTema = ThemeMode.system;
}
