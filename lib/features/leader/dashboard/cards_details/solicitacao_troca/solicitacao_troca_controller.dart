import 'package:flutter/material.dart';

class SolicitacaoTroca {
  final String voluntario;
  final String substituto;
  final String escala;
  final String motivo;
  String status; // 'pendente', 'aceito', 'recusado'

  SolicitacaoTroca({
    required this.voluntario,
    required this.substituto,
    required this.escala,
    required this.motivo,
    this.status = 'pendente',
  });
}

class SolicitacoesTrocaController extends ChangeNotifier {
  final List<SolicitacaoTroca> solicitacoes = [
    SolicitacaoTroca(
      voluntario: 'Anderson Alves',
      substituto: 'Carlos Pereira',
      escala: 'Culto de Domingo - 28/07',
      motivo: 'Viagem marcada com antecedência',
    ),
    SolicitacaoTroca(
      voluntario: 'Samila Costa',
      substituto: 'Mariana Souza',
      escala: 'Quarta da Graça - 24/07',
      motivo: 'Compromisso familiar',
    ),
    SolicitacaoTroca(
      voluntario: 'Lucas Lima',
      substituto: 'João Silva',
      escala: 'Culto de Jovens - 26/07',
      motivo: 'Trabalho no horário',
    ),
  ];

  void aprovar(int index) {
    solicitacoes[index].status = 'aceito';
    notifyListeners();
  }

  void recusar(int index) {
    solicitacoes[index].status = 'recusado';
    notifyListeners();
  }
}