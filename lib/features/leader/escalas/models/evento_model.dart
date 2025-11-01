import 'package:uuid/uuid.dart';

enum RecorrenciaTipo {
  nenhum,
  diario,
  semanal,
  mensal,
}

class EventoModel {
  final String id;
  final String nome;
  final DateTime dataHora; // usado para eventos únicos ou primeira instância
  final String ministerioId;
  final bool isOrdinary;
  final String? templateId;

  final bool recorrente;
  final RecorrenciaTipo tipoRecorrencia;

  final int? diaSemana; // 0 = domingo, 6 = sábado (para recorrentes)
  final int? semanaDoMes; // 1 = primeira, 2 = segunda... usado em mensal
  final String? eventoPaiId; // caso seja uma exceção de um evento pai
  final DateTime? dataLimiteRecorrencia; // data limite para recorrências

  final String? observacoes;
  final String? createdBy; // ID do usuário que criou o evento
  final bool isGlobal; // true se for evento global (criado por admin)

  EventoModel({
    String? id,
    required this.nome,
    required this.dataHora,
    required this.ministerioId,
    this.isOrdinary = false,
    this.templateId,
    this.recorrente = false,
    this.tipoRecorrencia = RecorrenciaTipo.nenhum,
    this.diaSemana,
    this.semanaDoMes,
    this.eventoPaiId,
    this.dataLimiteRecorrencia,
    this.observacoes,
    this.createdBy,
    this.isGlobal = false,
  }) : id = id ?? const Uuid().v4();

  EventoModel copyWith({
    String? id,
    String? nome,
    DateTime? dataHora,
    String? ministerioId,
    bool? isOrdinary,
    String? templateId,
    bool? recorrente,
    RecorrenciaTipo? tipoRecorrencia,
    int? diaSemana,
    int? semanaDoMes,
    String? eventoPaiId,
    DateTime? dataLimiteRecorrencia,
    String? observacoes,
    String? createdBy,
    bool? isGlobal,
  }) {
    return EventoModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      dataHora: dataHora ?? this.dataHora,
      ministerioId: ministerioId ?? this.ministerioId,
      isOrdinary: isOrdinary ?? this.isOrdinary,
      templateId: templateId ?? this.templateId,
      recorrente: recorrente ?? this.recorrente,
      tipoRecorrencia: tipoRecorrencia ?? this.tipoRecorrencia,
      diaSemana: diaSemana ?? this.diaSemana,
      semanaDoMes: semanaDoMes ?? this.semanaDoMes,
      eventoPaiId: eventoPaiId ?? this.eventoPaiId,
      dataLimiteRecorrencia: dataLimiteRecorrencia ?? this.dataLimiteRecorrencia,
      observacoes: observacoes ?? this.observacoes,
      createdBy: createdBy ?? this.createdBy,
      isGlobal: isGlobal ?? this.isGlobal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'dataHora': dataHora.toIso8601String(),
      'ministerioId': ministerioId,
      'isOrdinary': isOrdinary,
      'templateId': templateId,
      'recorrente': recorrente,
      'tipoRecorrencia': tipoRecorrencia.name,
      'diaSemana': diaSemana,
      'semanaDoMes': semanaDoMes,
      'eventoPaiId': eventoPaiId,
      'dataLimiteRecorrencia': dataLimiteRecorrencia?.toIso8601String(),
      'observacoes': observacoes,
      'createdBy': createdBy,
      'isGlobal': isGlobal,
    };
  }

  factory EventoModel.fromMap(Map<String, dynamic> map) {
    return EventoModel(
      id: map['id'],
      nome: map['nome'],
      dataHora: DateTime.parse(map['dataHora']),
      ministerioId: map['ministerioId'],
      isOrdinary: map['isOrdinary'] ?? false,
      templateId: map['templateId'],
      recorrente: map['recorrente'] ?? false,
      tipoRecorrencia: RecorrenciaTipo.values.firstWhere(
        (e) => e.name == map['tipoRecorrencia'],
        orElse: () => RecorrenciaTipo.nenhum,
      ),
      diaSemana: map['diaSemana'],
      semanaDoMes: map['semanaDoMes'],
      eventoPaiId: map['eventoPaiId'],
      dataLimiteRecorrencia: map['dataLimiteRecorrencia'] != null 
          ? DateTime.parse(map['dataLimiteRecorrencia']) 
          : null,
      observacoes: map['observacoes'],
      createdBy: map['createdBy']?.toString(),
      isGlobal: map['isGlobal'] ?? false,
    );
  }
}