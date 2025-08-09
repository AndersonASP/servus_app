import 'package:flutter/material.dart';

class BloqueioIndisponibilidade {
  final DateTime data;
  final String motivo;
  final List<String> ministerios;

  BloqueioIndisponibilidade({
    required this.data,
    required this.motivo,
    required this.ministerios,
  });
}

class IndisponibilidadeController extends ChangeNotifier {
  final List<BloqueioIndisponibilidade> bloqueios = [];
  DateTime focusedDay = DateTime.now();
  final int maxDiasIndisponiveis = 5;

  final List<String> ministeriosDoVoluntario = [
    'Louvor',
    'Recepção',
    'Filmagem e transmissão'
  ];

  // Define o dia em foco (exibido no calendário)
  void setFocusedDay(DateTime day, {bool notify = true}) {
    focusedDay = day;
    if (notify) notifyListeners();
  }

  void abrirTelaDeBloqueio(BuildContext context, DateTime dia) {
    final bloqueio = getBloqueio(dia);
    Navigator.pushNamed(
      context,
      '/bloqueio',
      arguments: {
        'dia': dia,
        'bloqueioExistente': bloqueio,
        'controller': this,
      },
    );
  }

  // Verifica se duas datas são o mesmo dia (sem considerar hora)
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Verifica se o dia está bloqueado
  bool isDiaBloqueado(DateTime day) {
    return bloqueios.any((b) => isSameDay(b.data, day));
  }

  // Retorna o bloqueio correspondente ao dia (ou null se não existir)
  BloqueioIndisponibilidade? getBloqueio(DateTime day) {
    try {
      return bloqueios.firstWhere((b) => isSameDay(b.data, day));
    } catch (_) {
      return null;
    }
  }

  // Registra ou atualiza um bloqueio no dia
  void registrarBloqueio({
    required DateTime dia,
    required String motivo,
    required List<String> ministerios,
  }) {
    final dataAjustada = DateTime(dia.year, dia.month, dia.day);
    print(
        "Registrando bloqueio: $dia, Motivo: $motivo, Ministérios: ${ministerios.join(', ')}");
    if (bloqueios.length >= maxDiasIndisponiveis && !isDiaBloqueado(dia)) {
      return;
    }

    bloqueios.removeWhere((b) => isSameDay(b.data, dataAjustada));
    bloqueios.add(BloqueioIndisponibilidade(
      data: dataAjustada,
      motivo: motivo,
      ministerios: ministerios,
    ));

    notifyListeners();
  }

  // Remove o bloqueio de um dia
  void removerBloqueio(DateTime day) {
    bloqueios.removeWhere((b) => isSameDay(b.data, day));
    notifyListeners();
  }

  // Exportar ou salvar os bloqueios (mock)
  void salvarIndisponibilidade() {
    for (var b in bloqueios) {
      debugPrint(
          "Bloqueio: ${b.data} | Motivo: ${b.motivo} | Ministérios: ${b.ministerios.join(', ')}");
    }
  }

  // Lista de dias bloqueados (útil para o calendário)
  List<DateTime> get diasBloqueados => bloqueios.map((b) => b.data).toList();
}
