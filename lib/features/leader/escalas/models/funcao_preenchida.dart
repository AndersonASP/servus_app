class FuncaoPreenchida {
  final String funcaoId;
  final String funcaoNome;
  final String? voluntarioId;
  final String? voluntarioNome;

  FuncaoPreenchida({
    required this.funcaoId,
    required this.funcaoNome,
    this.voluntarioId,
    this.voluntarioNome,
  });

  bool get preenchida => voluntarioId != null && voluntarioId!.isNotEmpty;

  FuncaoPreenchida copyWith({
    String? funcaoId,
    String? funcaoNome,
    String? voluntarioId,
    String? voluntarioNome,
    bool? clearVoluntario,
  }) {
    return FuncaoPreenchida(
      funcaoId: funcaoId ?? this.funcaoId,
      funcaoNome: funcaoNome ?? this.funcaoNome,
      voluntarioId: clearVoluntario == true
          ? null
          : (voluntarioId ?? this.voluntarioId),
      voluntarioNome: clearVoluntario == true
          ? null
          : (voluntarioNome ?? this.voluntarioNome),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'funcaoId': funcaoId,
      'funcaoNome': funcaoNome,
      'voluntarioId': voluntarioId,
      'voluntarioNome': voluntarioNome,
    };
  }

  factory FuncaoPreenchida.fromJson(Map<String, dynamic> json) {
    return FuncaoPreenchida(
      funcaoId: json['funcaoId'] as String,
      funcaoNome: json['funcaoNome'] as String,
      voluntarioId: json['voluntarioId'] as String?,
      voluntarioNome: json['voluntarioNome'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FuncaoPreenchida &&
          runtimeType == other.runtimeType &&
          funcaoId == other.funcaoId &&
          voluntarioId == other.voluntarioId;

  @override
  int get hashCode => funcaoId.hashCode ^ voluntarioId.hashCode;
}
