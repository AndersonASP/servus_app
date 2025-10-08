/// Modelo que representa as configurações de bloqueio para um ministério
class BlockConfiguration {
  /// ID do ministério
  final String ministryId;
  
  /// Nome do ministério
  final String ministryName;
  
  /// Limite máximo de dias bloqueados por voluntário
  final int maxBlockedDays;
  
  /// Se a configuração está ativa
  final bool isActive;
  
  /// Data de criação da configuração
  final DateTime createdAt;
  
  /// Data da última atualização
  final DateTime updatedAt;
  
  /// ID do usuário que criou/atualizou a configuração
  final String updatedBy;

  const BlockConfiguration({
    required this.ministryId,
    required this.ministryName,
    required this.maxBlockedDays,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedBy,
  });

  /// Converte para JSON
  Map<String, dynamic> toJson() => {
    'ministryId': ministryId,
    'ministryName': ministryName,
    'maxBlockedDays': maxBlockedDays,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'updatedBy': updatedBy,
  };

  /// Cria a partir de JSON
  factory BlockConfiguration.fromJson(Map<String, dynamic> json) => BlockConfiguration(
    ministryId: json['ministryId'],
    ministryName: json['ministryName'],
    maxBlockedDays: json['maxBlockedDays'],
    isActive: json['isActive'] ?? true,
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    updatedBy: json['updatedBy'],
  );

  /// Cria uma cópia com novos valores
  BlockConfiguration copyWith({
    String? ministryId,
    String? ministryName,
    int? maxBlockedDays,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedBy,
  }) => BlockConfiguration(
    ministryId: ministryId ?? this.ministryId,
    ministryName: ministryName ?? this.ministryName,
    maxBlockedDays: maxBlockedDays ?? this.maxBlockedDays,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
  );

  @override
  String toString() {
    return 'BlockConfiguration(ministryId: $ministryId, ministryName: $ministryName, maxBlockedDays: $maxBlockedDays, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockConfiguration &&
          runtimeType == other.runtimeType &&
          ministryId == other.ministryId &&
          ministryName == other.ministryName &&
          maxBlockedDays == other.maxBlockedDays &&
          isActive == other.isActive &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          updatedBy == other.updatedBy;

  @override
  int get hashCode =>
      ministryId.hashCode ^
      ministryName.hashCode ^
      maxBlockedDays.hashCode ^
      isActive.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      updatedBy.hashCode;
}

/// Configuração padrão para novos ministérios
class DefaultBlockConfiguration {
  static const int defaultMaxBlockedDays = 10;
  static const bool defaultIsActive = true;
  
  /// Cria uma configuração padrão para um ministério
  static BlockConfiguration createDefault({
    required String ministryId,
    required String ministryName,
    required String updatedBy,
  }) {
    final now = DateTime.now();
    return BlockConfiguration(
      ministryId: ministryId,
      ministryName: ministryName,
      maxBlockedDays: defaultMaxBlockedDays,
      isActive: defaultIsActive,
      createdAt: now,
      updatedAt: now,
      updatedBy: updatedBy,
    );
  }
}
