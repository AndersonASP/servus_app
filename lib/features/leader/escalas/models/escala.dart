import 'package:servus_app/features/leader/escalas/models/escala_status.dart';
import 'package:servus_app/features/leader/escalas/models/funcao_preenchida.dart';

class Escala {
  final String id;
  final String eventoId;
  final String eventoNome;
  final DateTime eventoData;
  final List<FuncaoPreenchida> funcoes;
  final EscalaStatus status;
  final DateTime? dataPublicacao;
  final bool temTemplate;
  bool? selecionadaParaPublicar;

  Escala({
    required this.id,
    required this.eventoId,
    required this.eventoNome,
    required this.eventoData,
    required this.funcoes,
    required this.status,
    this.dataPublicacao,
    required this.temTemplate,
    this.selecionadaParaPublicar,
  });

  bool get completa {
    if (funcoes.isEmpty) return false;
    return funcoes.every((f) => f.preenchida);
  }

  int get funcoesPreenchidas => funcoes.where((f) => f.preenchida).length;

  int get totalFuncoes => funcoes.length;

  double get percentualCompleto {
    if (totalFuncoes == 0) return 0.0;
    return funcoesPreenchidas / totalFuncoes;
  }

  bool get isPronto => status == EscalaStatus.pronto;

  bool get isPublicado => status == EscalaStatus.publicado;

  Escala copyWith({
    String? id,
    String? eventoId,
    String? eventoNome,
    DateTime? eventoData,
    List<FuncaoPreenchida>? funcoes,
    EscalaStatus? status,
    DateTime? dataPublicacao,
    bool? temTemplate,
    bool? selecionadaParaPublicar,
    bool? clearSelecionadaParaPublicar,
  }) {
    return Escala(
      id: id ?? this.id,
      eventoId: eventoId ?? this.eventoId,
      eventoNome: eventoNome ?? this.eventoNome,
      eventoData: eventoData ?? this.eventoData,
      funcoes: funcoes ?? this.funcoes,
      status: status ?? this.status,
      dataPublicacao: dataPublicacao ?? this.dataPublicacao,
      temTemplate: temTemplate ?? this.temTemplate,
      selecionadaParaPublicar: clearSelecionadaParaPublicar == true
          ? null
          : (selecionadaParaPublicar ?? this.selecionadaParaPublicar),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventoId': eventoId,
      'eventoNome': eventoNome,
      'eventoData': eventoData.toIso8601String(),
      'funcoes': funcoes.map((f) => f.toJson()).toList(),
      'status': status.name,
      'dataPublicacao': dataPublicacao?.toIso8601String(),
      'temTemplate': temTemplate,
      'selecionadaParaPublicar': selecionadaParaPublicar,
    };
  }

  factory Escala.fromJson(Map<String, dynamic> json) {
    return Escala(
      id: json['id'] as String,
      eventoId: json['eventoId'] as String,
      eventoNome: json['eventoNome'] as String,
      eventoData: DateTime.parse(json['eventoData'] as String),
      funcoes: (json['funcoes'] as List<dynamic>?)
              ?.map((f) => FuncaoPreenchida.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      status: EscalaStatus.fromString(json['status'] as String?) ?? EscalaStatus.rascunho,
      dataPublicacao: json['dataPublicacao'] != null
          ? DateTime.parse(json['dataPublicacao'] as String)
          : null,
      temTemplate: json['temTemplate'] as bool? ?? false,
      selecionadaParaPublicar: json['selecionadaParaPublicar'] as bool?,
    );
  }
}
