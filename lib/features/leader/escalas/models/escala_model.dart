import 'package:uuid/uuid.dart';

class Escalado {
  final String funcaoId;        // ID da função do template
      // ID da função do catálogo
  final String voluntarioId;    // ID do voluntário escolhido

  Escalado({
    required this.funcaoId,

    required this.voluntarioId,
  });

  Map<String, dynamic> toMap() {
    return {
      'funcaoId': funcaoId,

      'voluntarioId': voluntarioId,
    };
  }

  factory Escalado.fromMap(Map<String, dynamic> map) {
          return Escalado(
        funcaoId: map['funcaoId'] ?? map['id'], // Fallback para compatibilidade
        voluntarioId: map['voluntarioId'],
      );
  }
}

enum StatusEscala {
  rascunho,
  publicada,
}

class EscalaModel {
  final String id;
  final String eventoId;
  final String? templateId;
  final List<Escalado> escalados;
  final StatusEscala status;
  final DateTime criadaEm;

  EscalaModel({
    String? id,
    required this.eventoId,
    this.templateId,
    required this.escalados,
    this.status = StatusEscala.rascunho,
    DateTime? criadaEm,
  })  : id = id ?? const Uuid().v4(),
        criadaEm = criadaEm ?? DateTime.now();

  EscalaModel copyWith({
    String? id,
    String? eventoId,
    String? templateId,
    List<Escalado>? escalados,
    StatusEscala? status,
    DateTime? criadaEm,
  }) {
    return EscalaModel(
      id: id ?? this.id,
      eventoId: eventoId ?? this.eventoId,
      templateId: templateId ?? this.templateId,
      escalados: escalados ?? this.escalados,
      status: status ?? this.status,
      criadaEm: criadaEm ?? this.criadaEm,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventoId': eventoId,
      'templateId': templateId,
      'escalados': escalados.map((e) => e.toMap()).toList(),
      'status': status.name,
      'criadaEm': criadaEm.toIso8601String(),
    };
  }

  factory EscalaModel.fromMap(Map<String, dynamic> map) {
    return EscalaModel(
      id: map['id'],
      eventoId: map['eventoId'],
      templateId: map['templateId'],
      escalados: List<Escalado>.from(
        map['escalados']?.map((e) => Escalado.fromMap(e)) ?? [],
      ),
      status: StatusEscala.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => StatusEscala.rascunho,
      ),
      criadaEm: DateTime.parse(map['criadaEm']),
    );
  }
}