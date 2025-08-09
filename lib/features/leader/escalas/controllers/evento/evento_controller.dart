import 'package:flutter/material.dart';
import '../../models/evento_model.dart';

class EventoController extends ChangeNotifier {
  final List<EventoModel> _eventos = [];

  List<EventoModel> get todos => List.unmodifiable(_eventos);

  // Adiciona novo evento
  void adicionarEvento(EventoModel evento) {
    _eventos.add(evento);
    notifyListeners();
  }

  // Atualiza um evento existente
  void atualizarEvento(EventoModel eventoAtualizado) {
    final index = _eventos.indexWhere((e) => e.id == eventoAtualizado.id);
    if (index != -1) {
      _eventos[index] = eventoAtualizado;
      notifyListeners();
    }
  }

  // Remove um evento
  void removerEvento(String id) {
    _eventos.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // Filtrar eventos por ministério
  List<EventoModel> filtrarPorMinisterio(String ministerioId) {
    return _eventos.where((e) => e.ministerioId == ministerioId).toList();
  }

  // Listar apenas eventos futuros
  List<EventoModel> get eventosFuturos {
    return _eventos.where((e) => e.dataHora.isAfter(DateTime.now())).toList();
  }

  // Buscar evento por ID
  EventoModel? buscarPorId(String id) {
    try {
      return _eventos.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  // Limpa tudo (útil para testes)
  void limparEventos() {
    _eventos.clear();
    notifyListeners();
  }
}