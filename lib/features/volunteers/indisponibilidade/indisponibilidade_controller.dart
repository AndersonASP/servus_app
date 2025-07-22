import 'package:flutter/material.dart';

class IndisponibilidadeController extends ChangeNotifier {
  List<DateTime> selectedDays = [];
  DateTime focusedDay = DateTime.now();
  int maxDiasIndisponiveis = 5;

  void toggleDay(DateTime day) {
    if (selectedDays.any((d) => isSameDay(d, day))) {
      selectedDays.removeWhere((d) => isSameDay(d, day));
    } else {
      selectedDays.add(day);
    }
    notifyListeners();
  }

  void setFocusedDay(DateTime day) {
    focusedDay = day;
    notifyListeners();
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void salvarIndisponibilidade() {
    // Implementar lógica de salvar, se necessário
    print("Dias indisponíveis: $selectedDays");
  }
}