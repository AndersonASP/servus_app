class VoluntarioModel {
  final String id;
  final String nome;
  final List<String> ministerios; // Agora é uma lista!
  final List<String> funcoes;     // Também pode estar em várias funções
  final bool ativo;

  VoluntarioModel({
    required this.id,
    required this.nome,
    this.ministerios = const [],
    this.funcoes = const [],
    this.ativo = true,
  });

  VoluntarioModel copyWith({
    String? id,
    String? nome,
    List<String>? ministerios,
    List<String>? funcoes,
    bool? ativo,
  }) {
    return VoluntarioModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      ministerios: ministerios ?? this.ministerios,
      funcoes: funcoes ?? this.funcoes,
      ativo: ativo ?? this.ativo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'ministerios': ministerios,
      'funcoes': funcoes,
      'ativo': ativo,
    };
  }

  factory VoluntarioModel.fromMap(Map<String, dynamic> map) {
    return VoluntarioModel(
      id: map['id'],
      nome: map['nome'],
      ministerios: List<String>.from(map['ministerios'] ?? []),
      funcoes: List<String>.from(map['funcoes'] ?? []),
      ativo: map['ativo'] ?? true,
    );
  }
}