import 'package:flutter/material.dart';
import 'package:servus_app/features/leader/escalas/models/escala_model.dart';

class EscalaController extends ChangeNotifier {
  final List<EscalaModel> _escalas = [];

  List<EscalaModel> get todas => List.unmodifiable(_escalas);

  void adicionar(EscalaModel escala) {
    _escalas.add(escala);
    notifyListeners();
  }

  void atualizar(EscalaModel escalaAtualizada) {
    final index = _escalas.indexWhere((e) => e.id == escalaAtualizada.id);
    if (index != -1) {
      _escalas[index] = escalaAtualizada;
      notifyListeners();
    }
  }

  void remover(String id) {
    _escalas.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void publicarEscala(String id) {
    final index = _escalas.indexWhere((e) => e.id == id);
    if (index != -1) {
      _escalas[index] = _escalas[index].copyWith(status: StatusEscala.publicada);
      notifyListeners();
    }
  }

  List<EscalaModel> listarPorEvento(String eventoId) {
    return _escalas.where((e) => e.eventoId == eventoId).toList();
  }

  EscalaModel? buscarPorId(String id) {
    try {
      return _escalas.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  void limparTudo() {
    _escalas.clear();
    notifyListeners();
  }
}