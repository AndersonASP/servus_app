import 'package:flutter/material.dart';

class EscalaDetalhesController extends ChangeNotifier {
  final TextEditingController trocaVoluntarioController = TextEditingController();

  /// Lista de participantes mockada (futuramente virá da API)
  final List<Map<String, dynamic>> participantes = [
    {'nome': 'Anderson Alves', 'imagem': 'https://randomuser.me/api/portraits/men/1.jpg', 'funcao': 'Baixista', 'confirmado': true},
    {'nome': 'Samila Costa', 'imagem': 'https://randomuser.me/api/portraits/women/2.jpg', 'funcao': 'Baterista', 'confirmado': false},
    {'nome': 'Lucas Lima', 'imagem': 'https://randomuser.me/api/portraits/men/3.jpg', 'funcao': 'Guitarrista', 'confirmado': true},
    {'nome': 'Juliana Rocha', 'imagem': 'https://randomuser.me/api/portraits/women/8.jpg', 'funcao': 'Ministra de louvor', 'confirmado': true},
  ];

  /// Validação do campo de troca
  bool get isValidTroca => trocaVoluntarioController.text.trim().isNotEmpty;

  String get voluntarioSelecionado => trocaVoluntarioController.text.trim();

  void clearTroca() {
    trocaVoluntarioController.clear();
    notifyListeners();
  }

  void disposeController() {
    trocaVoluntarioController.dispose();
    super.dispose();
  }
}