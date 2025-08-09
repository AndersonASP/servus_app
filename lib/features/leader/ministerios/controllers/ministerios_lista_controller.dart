import 'package:flutter/material.dart';

class Ministerio {
  final String id;
  final String nome;
  bool ativo;

  Ministerio({required this.id, required this.nome, required this.ativo});
}

class MinisterioListController extends ChangeNotifier {
  bool isLoading = false;
  List<Ministerio> ministerios = [];

  Future<void> carregarMinisterios() async {
    isLoading = true;
    notifyListeners();

    // Simula carregamento (substituir pelo service real)
    await Future.delayed(const Duration(seconds: 1));
    ministerios = [
      Ministerio(id: '1', nome: 'Louvor', ativo: true),
      Ministerio(id: '2', nome: 'Mídia', ativo: true),
      Ministerio(id: '3', nome: 'Acolhimento', ativo: false),
    ];

    isLoading = false;
    notifyListeners();
  }

  void alterarStatus(String id, bool ativo) {
    final index = ministerios.indexWhere((m) => m.id == id);
    if (index != -1) {
      ministerios[index].ativo = ativo;
      notifyListeners();
      // Aqui você pode chamar seu service/repository para persistir
      print("Ministério $id agora está ${ativo ? 'Ativo' : 'Inativo'}");
    }
  }
}