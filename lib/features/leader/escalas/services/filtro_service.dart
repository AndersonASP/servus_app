enum FiltroEscala {
  proximos7Dias,
  proximos30Dias,
  mesAtual,
  proximoMes,
  proximos3Meses,
  todos;

  static (DateTime?, DateTime?) obterRangeFiltro(FiltroEscala filtro) {
    final agora = DateTime.now();
    final inicioHoje = DateTime(agora.year, agora.month, agora.day);

    switch (filtro) {
      case FiltroEscala.proximos7Dias:
        return (inicioHoje, inicioHoje.add(const Duration(days: 7)));

      case FiltroEscala.proximos30Dias:
        return (inicioHoje, inicioHoje.add(const Duration(days: 30)));

      case FiltroEscala.mesAtual:
        final inicioMes = DateTime(agora.year, agora.month, 1);
        final fimMes = DateTime(agora.year, agora.month + 1, 0, 23, 59, 59);
        return (inicioMes, fimMes);

      case FiltroEscala.proximoMes:
        final proximoMes = DateTime(agora.year, agora.month + 1, 1);
        final fimProximoMes =
            DateTime(proximoMes.year, proximoMes.month + 1, 0, 23, 59, 59);
        return (proximoMes, fimProximoMes);

      case FiltroEscala.proximos3Meses:
        return (inicioHoje, inicioHoje.add(const Duration(days: 90)));

      case FiltroEscala.todos:
        return (null, null);
    }
  }

  static String obterLabel(FiltroEscala filtro) {
    switch (filtro) {
      case FiltroEscala.proximos7Dias:
        return 'Próximos 7 dias';
      case FiltroEscala.proximos30Dias:
        return 'Próximos 30 dias';
      case FiltroEscala.mesAtual:
        return 'Este mês';
      case FiltroEscala.proximoMes:
        return 'Próximo mês';
      case FiltroEscala.proximos3Meses:
        return 'Próximos 3 meses';
      case FiltroEscala.todos:
        return 'Todos';
    }
  }

  String get label => obterLabel(this);
}
