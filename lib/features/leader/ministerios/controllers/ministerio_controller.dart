import 'package:flutter/material.dart';

class MinisterioController extends ChangeNotifier {
  final TextEditingController nomeController = TextEditingController();
  bool ativo = true;
  bool moduloLouvorAtivo = false; // NOVO TOGGLE
  bool isSaving = false;

  void toggleAtivo(bool value) {
    ativo = value;
    notifyListeners();
  }

  void toggleModuloLouvor(bool value) {
    moduloLouvorAtivo = value;
    notifyListeners();
  }

  Future<void> salvarMinisterio() async {
    if (nomeController.text.trim().isEmpty) return;

    isSaving = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    print('Salvando ministério: ${nomeController.text}');
    print('Ativo: $ativo');
    print('Módulo Louvor Ativo: $moduloLouvorAtivo');

    isSaving = false;
    notifyListeners();
  }

  @override
  void dispose() {
    nomeController.dispose();
    super.dispose();
  }
}