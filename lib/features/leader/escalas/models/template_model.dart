import 'package:uuid/uuid.dart';

class FuncaoEscala {
  final String id;

  final String nome; // Nome da função (para exibição)
  final String ministerioId;
  final int quantidade;

  FuncaoEscala({
    String? id,

    required this.nome,
    required this.ministerioId,
    required this.quantidade,
  }) : id = id ?? const Uuid().v4();

  FuncaoEscala copyWith({
    String? id,
    String? nome,
    String? ministerioId,
    int? quantidade,
  }) {
    return FuncaoEscala(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      ministerioId: ministerioId ?? this.ministerioId,
      quantidade: quantidade ?? this.quantidade,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'ministerioId': ministerioId,
      'quantidade': quantidade,
    };
  }

  factory FuncaoEscala.fromMap(Map<String, dynamic> map) {
    return FuncaoEscala(
      id: map['id'],
      nome: map['nome'],
      ministerioId: map['ministerioId'],
      quantidade: map['quantidade'],
    );
  }
}

class TemplateModel {
  final String id;
  final String nome;
  final List<FuncaoEscala> funcoes;
  final String? observacoes;

  TemplateModel({
    String? id,
    required this.nome,
    required this.funcoes,
    this.observacoes,
  }) : id = id ?? const Uuid().v4();

  TemplateModel copyWith({
    String? id,
    String? nome,
    List<FuncaoEscala>? funcoes,
    String? observacoes,
  }) {
    return TemplateModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      funcoes: funcoes ?? this.funcoes,
      observacoes: observacoes ?? this.observacoes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'funcoes': funcoes.map((f) => f.toMap()).toList(),
      'observacoes': observacoes,
    };
  }

  factory TemplateModel.fromMap(Map<String, dynamic> map) {
    return TemplateModel(
      id: map['id'],
      nome: map['nome'],
      funcoes: List<FuncaoEscala>.from(
        map['funcoes']?.map((f) => FuncaoEscala.fromMap(f)) ?? [],
      ),
      observacoes: map['observacoes'],
    );
  }
}