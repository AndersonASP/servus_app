import 'package:intl/intl.dart';
import 'package:servus_app/features/leader/escalas/models/escala.dart';
import 'package:servus_app/features/leader/escalas/models/escala_status.dart';

class MesAgrupado {
  final int mes;
  final int ano;
  final List<Escala> escalas;

  MesAgrupado({
    required this.mes,
    required this.ano,
    required this.escalas,
  });

  String get nomeFormatado {
    final date = DateTime(ano, mes, 1);
    final formatter = DateFormat('MMMM yyyy', 'pt_BR');
    return formatter.format(date);
  }

  String get nomeAbreviado {
    final date = DateTime(ano, mes, 1);
    final formatter = DateFormat('MMM/yy', 'pt_BR');
    return formatter.format(date);
  }

  int get totalEventos => escalas.length;

  int get rascunhos =>
      escalas.where((e) => e.status == EscalaStatus.rascunho).length;

  int get prontos =>
      escalas.where((e) => e.status == EscalaStatus.pronto).length;

  int get publicados =>
      escalas.where((e) => e.status == EscalaStatus.publicado).length;

  int get pendentes => totalEventos - publicados;

  bool get temEventosProntos => prontos > 0;

  bool get todosPublicados => publicados == totalEventos && totalEventos > 0;

  DateTime get dataInicio => DateTime(ano, mes, 1);

  DateTime get dataFim {
    final ultimoDia = DateTime(ano, mes + 1, 0);
    return DateTime(ano, mes, ultimoDia.day, 23, 59, 59);
  }

  static List<MesAgrupado> agruparPorMes(List<Escala> escalas) {
    final Map<String, List<Escala>> agrupados = {};

    for (final escala in escalas) {
      final chave = '${escala.eventoData.year}-${escala.eventoData.month}';
      agrupados.putIfAbsent(chave, () => []).add(escala);
    }

    final List<MesAgrupado> meses = [];
    for (final entry in agrupados.entries) {
      final partes = entry.key.split('-');
      final ano = int.parse(partes[0]);
      final mes = int.parse(partes[1]);
      
      // Ordenar escalas por data
      final escalasOrdenadas = List<Escala>.from(entry.value)
        ..sort((a, b) => a.eventoData.compareTo(b.eventoData));

      meses.add(MesAgrupado(
        mes: mes,
        ano: ano,
        escalas: escalasOrdenadas,
      ));
    }

    // Ordenar cronologicamente
    meses.sort((a, b) {
      final dataA = DateTime(a.ano, a.mes);
      final dataB = DateTime(b.ano, b.mes);
      return dataA.compareTo(dataB);
    });

    return meses;
  }
}
