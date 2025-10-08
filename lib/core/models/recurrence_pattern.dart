/// Enum que define os tipos de recorrência disponíveis
enum RecurrenceType {
  /// Sem recorrência - bloqueio único
  none,
  
  /// Recorrência semanal - repete toda semana no mesmo dia
  weekly,
  
  /// Recorrência quinzenal - repete a cada 15 dias
  biweekly,
  
  /// Recorrência mensal - repete todo mês no mesmo dia
  monthly,
  
  /// Recorrência personalizada - intervalo customizado
  custom,
}

/// Classe que representa um padrão de recorrência para bloqueios
class RecurrencePattern {
  /// Tipo de recorrência
  final RecurrenceType type;
  
  /// Dia da semana (0-6, onde 0 = domingo, 6 = sábado)
  /// Usado apenas para recorrência semanal
  final int? dayOfWeek;
  
  /// Dia do mês (1-31)
  /// Usado apenas para recorrência mensal tradicional
  final int? dayOfMonth;
  
  /// Semana do mês (1-4)
  /// Usado para recorrência mensal inteligente (ex: primeira sexta do mês)
  final int? weekOfMonth;
  
  /// Intervalo personalizado (ex: a cada 3 semanas)
  /// Usado apenas para recorrência customizada
  final int? interval;
  
  /// Unidade do intervalo ('weeks' ou 'months')
  /// Usado apenas para recorrência customizada
  final String? unit;
  
  /// Data limite para a recorrência (opcional)
  final DateTime? endDate;
  
  /// Número máximo de ocorrências (opcional)
  final int? maxOccurrences;

  const RecurrencePattern({
    required this.type,
    this.dayOfWeek,
    this.dayOfMonth,
    this.weekOfMonth,
    this.interval,
    this.unit,
    this.endDate,
    this.maxOccurrences,
  });

  /// Converte o padrão para JSON
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'dayOfWeek': dayOfWeek,
    'dayOfMonth': dayOfMonth,
    'weekOfMonth': weekOfMonth,
    'interval': interval,
    'unit': unit,
    'endDate': endDate?.toIso8601String(),
    'maxOccurrences': maxOccurrences,
  };

  /// Cria um padrão a partir de JSON
  factory RecurrencePattern.fromJson(Map<String, dynamic> json) => RecurrencePattern(
    type: RecurrenceType.values.firstWhere((e) => e.name == json['type']),
    dayOfWeek: json['dayOfWeek'],
    dayOfMonth: json['dayOfMonth'],
    weekOfMonth: json['weekOfMonth'],
    interval: json['interval'],
    unit: json['unit'],
    endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    maxOccurrences: json['maxOccurrences'],
  );

  /// Cria uma cópia do padrão com novos valores
  RecurrencePattern copyWith({
    RecurrenceType? type,
    int? dayOfWeek,
    int? dayOfMonth,
    int? weekOfMonth,
    int? interval,
    String? unit,
    DateTime? endDate,
    int? maxOccurrences,
  }) => RecurrencePattern(
    type: type ?? this.type,
    dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    dayOfMonth: dayOfMonth ?? this.dayOfMonth,
    weekOfMonth: weekOfMonth ?? this.weekOfMonth,
    interval: interval ?? this.interval,
    unit: unit ?? this.unit,
    endDate: endDate ?? this.endDate,
    maxOccurrences: maxOccurrences ?? this.maxOccurrences,
  );

  @override
  String toString() {
    switch (type) {
      case RecurrenceType.none:
        return 'Sem recorrência';
      case RecurrenceType.weekly:
        return 'Semanal (${_getDayOfWeekName(dayOfWeek ?? 0)})';
      case RecurrenceType.biweekly:
        return 'Quinzenal';
      case RecurrenceType.monthly:
        if (weekOfMonth != null) {
          final weekNames = ['primeira', 'segunda', 'terceira', 'quarta'];
          final weekName = weekNames[weekOfMonth! - 1];
          final dayName = _getDayOfWeekName(dayOfWeek ?? 0);
          return 'Mensal ($weekName $dayName do mês)';
        }
        return 'Mensal (dia $dayOfMonth)';
      case RecurrenceType.custom:
        return 'Personalizado (a cada $interval ${unit == 'weeks' ? 'semanas' : 'meses'})';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurrencePattern &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          dayOfWeek == other.dayOfWeek &&
          dayOfMonth == other.dayOfMonth &&
          weekOfMonth == other.weekOfMonth &&
          interval == other.interval &&
          unit == other.unit &&
          endDate == other.endDate &&
          maxOccurrences == other.maxOccurrences;

  @override
  int get hashCode =>
      type.hashCode ^
      dayOfWeek.hashCode ^
      dayOfMonth.hashCode ^
      weekOfMonth.hashCode ^
      interval.hashCode ^
      unit.hashCode ^
      endDate.hashCode ^
      maxOccurrences.hashCode;

  /// Retorna o nome do dia da semana
  String _getDayOfWeekName(int day) {
    const days = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
    return days[day];
  }
}
