import 'package:servus_app/core/models/recurrence_pattern.dart';

/// Serviço responsável por gerar datas baseadas em padrões de recorrência
class RecurrenceService {
  
  /// Calcula qual semana do mês uma data está (1-4)
  static int getWeekOfMonth(DateTime date) {
    final dayOfMonth = date.day;
    
    // Calcular quantas semanas completas passaram + 1
    return ((dayOfMonth - 1) / 7).floor() + 1;
  }
  /// Gera uma série de datas baseada no padrão de recorrência
  /// 
  /// [startDate] - Data inicial do bloqueio
  /// [pattern] - Padrão de recorrência
  /// [maxDates] - Número máximo de datas a gerar (padrão: 12)
  /// [endDate] - Data limite opcional para parar a geração
  static List<DateTime> generateDateSeries(
    DateTime startDate,
    RecurrencePattern pattern, {
    int maxDates = 12,
    DateTime? endDate,
  }) {
    print('🔍 [RecurrenceService] ===== GERANDO SÉRIE DE DATAS =====');
    print('🔍 [RecurrenceService] Data inicial: ${startDate.day}/${startDate.month}/${startDate.year}');
    print('🔍 [RecurrenceService] Padrão: ${pattern.toString()}');
    print('🔍 [RecurrenceService] Tipo: ${pattern.type}');
    print('🔍 [RecurrenceService] MaxDates: $maxDates');
    
    if (pattern.type == RecurrenceType.none) {
      print('🔍 [RecurrenceService] Tipo NONE - retornando apenas data inicial');
      return [startDate];
    }

    final dates = <DateTime>[];
    DateTime currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    
    for (int i = 0; i < maxDates; i++) {
      // Verificar se atingiu a data limite
      if (endDate != null && currentDate.isAfter(endDate)) {
        print('🔍 [RecurrenceService] Atingiu data limite: $endDate');
        break;
      }
      
      // Verificar se atingiu o número máximo de ocorrências
      if (pattern.maxOccurrences != null && i >= pattern.maxOccurrences!) {
        print('🔍 [RecurrenceService] Atingiu máximo de ocorrências: ${pattern.maxOccurrences}');
        break;
      }
      
      print('🔍 [RecurrenceService] Adicionando data ${i + 1}: ${currentDate.day}/${currentDate.month}/${currentDate.year}');
      dates.add(DateTime(currentDate.year, currentDate.month, currentDate.day));
      currentDate = _getNextOccurrence(currentDate, pattern);
    }
    
    print('🔍 [RecurrenceService] Total de datas geradas: ${dates.length}');
    return dates;
  }

  /// Calcula a próxima ocorrência baseada no padrão de recorrência
  static DateTime _getNextOccurrence(DateTime currentDate, RecurrencePattern pattern) {
    print('🔍 [RecurrenceService] _getNextOccurrence - Data atual: ${currentDate.day}/${currentDate.month}/${currentDate.year}');
    print('🔍 [RecurrenceService] _getNextOccurrence - Padrão: ${pattern.type}');
    
    final nextDate = DateTime(currentDate.year, currentDate.month, currentDate.day);
    
    switch (pattern.type) {
      case RecurrenceType.weekly:
        print('🔍 [RecurrenceService] Calculando próxima ocorrência SEMANAL');
        return nextDate.add(const Duration(days: 7));
        
      case RecurrenceType.biweekly:
        print('🔍 [RecurrenceService] Calculando próxima ocorrência QUINZENAL');
        return nextDate.add(const Duration(days: 14));
        
      case RecurrenceType.monthly:
        if (pattern.weekOfMonth != null) {
          print('🔍 [RecurrenceService] Calculando próxima ocorrência MENSAL INTELIGENTE');
          print('🔍 [RecurrenceService] WeekOfMonth: ${pattern.weekOfMonth}, DayOfWeek: ${pattern.dayOfWeek}');
          return _getNextMonthlyByWeekday(currentDate, pattern);
        } else {
          print('🔍 [RecurrenceService] Calculando próxima ocorrência MENSAL TRADICIONAL');
          return _getNextMonthlyByDay(currentDate, pattern);
        }
        
      case RecurrenceType.custom:
        if (pattern.unit == 'weeks') {
          final weeks = pattern.interval ?? 1;
          print('🔍 [RecurrenceService] Calculando próxima ocorrência CUSTOMIZADA ($weeks semanas)');
          return nextDate.add(Duration(days: 7 * weeks));
        } else if (pattern.unit == 'months') {
          final months = pattern.interval ?? 1;
          print('🔍 [RecurrenceService] Calculando próxima ocorrência CUSTOMIZADA ($months meses)');
          int nextMonth = nextDate.month + months;
          int nextYear = nextDate.year;
          
          while (nextMonth > 12) {
            nextMonth -= 12;
            nextYear++;
          }
          
          // Garantir que o dia existe no próximo mês
          int day = nextDate.day;
          if (day > 28) {
            final daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
            if (day > daysInNextMonth) {
              day = daysInNextMonth;
            }
          }
          
          return DateTime(nextYear, nextMonth, day);
        }
        return nextDate;
        
      case RecurrenceType.none:
        print('🔍 [RecurrenceService] Tipo NONE - retornando data atual');
        return nextDate;
    }
  }

  /// Calcula a próxima ocorrência para recorrência mensal tradicional
  static DateTime _getNextMonthlyByDay(DateTime currentDate, RecurrencePattern pattern) {
    // Usar dayOfMonth se definido, senão usar o dia da data atual
    final targetDay = pattern.dayOfMonth ?? currentDate.day;
    final nextDate = DateTime(currentDate.year, currentDate.month, targetDay);
    
    print('🔍 [RecurrenceService] _getNextMonthlyByDay - targetDay: $targetDay');
    print('🔍 [RecurrenceService] _getNextMonthlyByDay - currentDate: ${currentDate.day}/${currentDate.month}/${currentDate.year}');
    
    // Adicionar um mês, lidando com meses com diferentes números de dias
    int nextMonth = nextDate.month + 1;
    int nextYear = nextDate.year;
    
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear++;
    }
    
    // Garantir que o dia existe no próximo mês
    int day = targetDay;
    if (day > 28) {
      // Verificar se o dia existe no próximo mês
      final daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
      if (day > daysInNextMonth) {
        day = daysInNextMonth;
        print('🔍 [RecurrenceService] Ajustando dia de $targetDay para $day (mês tem $daysInNextMonth dias)');
      }
    }
    
    final result = DateTime(nextYear, nextMonth, day);
    print('🔍 [RecurrenceService] _getNextMonthlyByDay - resultado: ${result.day}/${result.month}/${result.year}');
    return result;
  }

  /// Calcula a próxima ocorrência para recorrência mensal inteligente
  static DateTime _getNextMonthlyByWeekday(DateTime currentDate, RecurrencePattern pattern) {
    final targetWeekday = pattern.dayOfWeek ?? currentDate.weekday;
    final targetWeek = pattern.weekOfMonth ?? 1;
    
    // Ir para o próximo mês
    int nextMonth = currentDate.month + 1;
    int nextYear = currentDate.year;
    
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear++;
    }
    
    // Encontrar a primeira ocorrência do dia da semana no próximo mês
    final firstDayOfMonth = DateTime(nextYear, nextMonth, 1);
    final firstWeekday = firstDayOfMonth.weekday;
    
    // Calcular quantos dias adicionar para chegar ao dia da semana desejado
    int daysToAdd = (targetWeekday - firstWeekday) % 7;
    if (daysToAdd < 0) daysToAdd += 7;
    
    // Calcular a data da semana desejada
    int targetDay = 1 + daysToAdd + (targetWeek - 1) * 7;
    
    // Verificar se o dia existe no mês
    final daysInMonth = DateTime(nextYear, nextMonth + 1, 0).day;
    if (targetDay > daysInMonth) {
      // Se não existe, usar o último dia do mês que seja o dia da semana desejado
      final lastDayOfMonth = DateTime(nextYear, nextMonth, daysInMonth);
      final lastWeekday = lastDayOfMonth.weekday;
      daysToAdd = (lastWeekday - targetWeekday) % 7;
      if (daysToAdd < 0) daysToAdd += 7;
      targetDay = daysInMonth - daysToAdd;
    }
    
    return DateTime(nextYear, nextMonth, targetDay);
  }

  /// Verifica se uma data específica corresponde ao padrão de recorrência
  static bool matchesPattern(DateTime date, RecurrencePattern pattern, DateTime startDate) {
    switch (pattern.type) {
      case RecurrenceType.weekly:
        return date.weekday == (pattern.dayOfWeek ?? startDate.weekday);
        
      case RecurrenceType.biweekly:
        final daysDiff = date.difference(startDate).inDays;
        return daysDiff % 14 == 0;
        
      case RecurrenceType.monthly:
        return date.day == (pattern.dayOfMonth ?? startDate.day);
        
      case RecurrenceType.custom:
        return _matchesCustomPattern(date, pattern, startDate);
        
      case RecurrenceType.none:
        return date.isAtSameMomentAs(startDate);
    }
  }

  /// Verifica se uma data corresponde ao padrão personalizado
  static bool _matchesCustomPattern(DateTime date, RecurrencePattern pattern, DateTime startDate) {
    if (pattern.unit == 'weeks') {
      final weeks = pattern.interval ?? 1;
      final daysDiff = date.difference(startDate).inDays;
      return daysDiff % (7 * weeks) == 0;
    } else if (pattern.unit == 'months') {
      final months = pattern.interval ?? 1;
      final monthsDiff = (date.year - startDate.year) * 12 + (date.month - startDate.month);
      return monthsDiff % months == 0 && date.day == startDate.day;
    }
    return false;
  }

  /// Valida se o padrão de recorrência é válido
  static String? validatePattern(RecurrencePattern pattern) {
    switch (pattern.type) {
      case RecurrenceType.weekly:
        if (pattern.dayOfWeek == null) {
          return 'Dia da semana é obrigatório para recorrência semanal';
        }
        if (pattern.dayOfWeek! < 0 || pattern.dayOfWeek! > 6) {
          return 'Dia da semana deve estar entre 0 (domingo) e 6 (sábado)';
        }
        break;
        
      case RecurrenceType.monthly:
        // Para recorrência mensal, se dayOfMonth não estiver definido, usar o dia da data inicial
        if (pattern.dayOfMonth == null) {
          print('🔍 [RecurrenceService] dayOfMonth não definido para recorrência mensal');
          // Não retornar erro - será definido automaticamente
        } else if (pattern.dayOfMonth! < 1 || pattern.dayOfMonth! > 31) {
          return 'Dia do mês deve estar entre 1 e 31';
        }
        break;
        
      case RecurrenceType.custom:
        if (pattern.interval == null || pattern.interval! < 1) {
          return 'Intervalo deve ser maior que zero para recorrência personalizada';
        }
        if (pattern.unit == null || !['weeks', 'months'].contains(pattern.unit)) {
          return 'Unidade deve ser "weeks" ou "months" para recorrência personalizada';
        }
        break;
        
      case RecurrenceType.biweekly:
      case RecurrenceType.none:
        // Não precisam de validação adicional
        break;
    }
    
    // Validar data limite
    if (pattern.endDate != null && pattern.maxOccurrences != null) {
      return 'Não é possível definir data limite e número máximo de ocorrências ao mesmo tempo';
    }
    
    return null; // Padrão válido
  }

  /// Retorna uma descrição legível do padrão de recorrência
  static String getPatternDescription(RecurrencePattern pattern) {
    switch (pattern.type) {
      case RecurrenceType.none:
        return 'Sem recorrência';
        
      case RecurrenceType.weekly:
        final dayName = _getDayOfWeekName(pattern.dayOfWeek ?? 0);
        return 'Toda $dayName';
        
      case RecurrenceType.biweekly:
        return 'A cada 15 dias';
        
      case RecurrenceType.monthly:
        return 'Todo dia ${pattern.dayOfMonth} do mês';
        
      case RecurrenceType.custom:
        final interval = pattern.interval ?? 1;
        final unit = pattern.unit == 'weeks' ? 'semana' : 'mês';
        final unitPlural = interval > 1 ? (pattern.unit == 'weeks' ? 'semanas' : 'meses') : unit;
        return 'A cada $interval $unitPlural';
    }
  }

  /// Retorna o nome do dia da semana
  static String _getDayOfWeekName(int day) {
    const days = ['Domingo', 'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado'];
    return days[day];
  }

  /// Gera um preview das próximas datas que serão bloqueadas
  static List<DateTime> generatePreview(
    DateTime startDate,
    RecurrencePattern pattern, {
    int previewCount = 6,
  }) {
    return generateDateSeries(
      startDate,
      pattern,
      maxDates: previewCount,
    );
  }

  /// Calcula quantas ocorrências serão geradas até uma data limite
  static int calculateOccurrenceCount(
    DateTime startDate,
    RecurrencePattern pattern,
    DateTime endDate,
  ) {
    final dates = generateDateSeries(
      startDate,
      pattern,
      maxDates: 1000, // Número alto para garantir que capture todas
      endDate: endDate,
    );
    
    return dates.length;
  }
}
