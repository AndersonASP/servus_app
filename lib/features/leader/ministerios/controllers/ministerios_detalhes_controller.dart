import 'package:flutter/material.dart';

class MinisterioDetalhesController extends ChangeNotifier {
  final String ministerioId;

  bool isLoading = false;
  String nomeMinisterio = '';
  String igreja = '';
  int totalMembros = 0;
  int limiteMembros = 10;

  MinisterioDetalhesController({required this.ministerioId});

  Future<void> carregarDados() async {
    isLoading = true;
    notifyListeners();

    // TODO: Substituir por chamada real à API
    await Future.delayed(const Duration(seconds: 1));

    // Dados mockados
    nomeMinisterio = "Ministério de Louvor";
    igreja = "Igreja Oceano da Graça";
    totalMembros = 5;

    isLoading = false;
    notifyListeners();
  }
}