class MinistryFunction {
  final String functionId;
  final String name;
  final String slug;
  final String? category;
  final String? description;
  final bool isActive;
  final int? defaultSlots;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  MinistryFunction({
    required this.functionId,
    required this.name,
    required this.slug,
    this.category,
    this.description,
    required this.isActive,
    this.defaultSlots,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MinistryFunction.fromJson(Map<String, dynamic> json) {
    return MinistryFunction(
      functionId: json['functionId'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      category: json['category'],
      description: json['description'],
      isActive: json['isActive'] ?? false,
      defaultSlots: json['defaultSlots'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'functionId': functionId,
      'name': name,
      'slug': slug,
      'category': category,
      'description': description,
      'isActive': isActive,
      'defaultSlots': defaultSlots,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  MinistryFunction copyWith({
    String? functionId,
    String? name,
    String? slug,
    String? category,
    String? description,
    bool? isActive,
    int? defaultSlots,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MinistryFunction(
      functionId: functionId ?? this.functionId,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      category: category ?? this.category,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      defaultSlots: defaultSlots ?? this.defaultSlots,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BulkUpsertResponse {
  final List<MinistryFunction> created;
  final List<MinistryFunction> linked;
  final List<MinistryFunction> alreadyLinked;
  final List<FunctionSuggestion> suggestions;

  BulkUpsertResponse({
    required this.created,
    required this.linked,
    required this.alreadyLinked,
    required this.suggestions,
  });

  factory BulkUpsertResponse.fromJson(Map<String, dynamic> json) {
    return BulkUpsertResponse(
      created: (json['created'] as List<dynamic>?)
          ?.map((item) => MinistryFunction.fromJson(item))
          .toList() ?? [],
      linked: (json['linked'] as List<dynamic>?)
          ?.map((item) => MinistryFunction.fromJson(item))
          .toList() ?? [],
      alreadyLinked: (json['alreadyLinked'] as List<dynamic>?)
          ?.map((item) => MinistryFunction.fromJson(item))
          .toList() ?? [],
      suggestions: (json['suggestions'] as List<dynamic>?)
          ?.map((item) => FunctionSuggestion.fromJson(item))
          .toList() ?? [],
    );
  }
}

class FunctionSuggestion {
  final String name;
  final String suggested;
  final String reason;

  FunctionSuggestion({
    required this.name,
    required this.suggested,
    required this.reason,
  });

  factory FunctionSuggestion.fromJson(Map<String, dynamic> json) {
    return FunctionSuggestion(
      name: json['name'] ?? '',
      suggested: json['suggested'] ?? '',
      reason: json['reason'] ?? '',
    );
  }
}
