class CreateMinistryDto {
  final String name;
  final String? description;
  final List<String>? ministryFunctions;
  final bool isActive;

  CreateMinistryDto({
    required this.name,
    this.description,
    this.ministryFunctions,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      if (ministryFunctions != null) 'ministryFunctions': ministryFunctions,
      'isActive': isActive,
    };
  }
}

class UpdateMinistryDto {
  final String? name;
  final String? description;
  final List<String>? ministryFunctions;
  final bool? isActive;

  UpdateMinistryDto({
    this.name,
    this.description,
    this.ministryFunctions,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (ministryFunctions != null) data['ministryFunctions'] = ministryFunctions;
    if (isActive != null) data['isActive'] = isActive;
    return data;
  }
}

class ListMinistryDto {
  final int? page;
  final int? limit;
  final String? search;
  final bool? isActive;

  ListMinistryDto({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (page != null) data['page'] = page;
    if (limit != null) data['limit'] = limit;
    if (search != null) data['search'] = search;
    if (isActive != null) data['isActive'] = isActive;
    return data;
  }
}

class MinistryResponse {
  final String id;
  final String name;
  final String? description;
  final List<String> ministryFunctions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  MinistryResponse({
    required this.id,
    required this.name,
    this.description,
    required this.ministryFunctions,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MinistryResponse.fromJson(Map<String, dynamic> json) {
    return MinistryResponse(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      ministryFunctions: List<String>.from(json['ministryFunctions'] ?? []),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class MinistryListResponse {
  final List<MinistryResponse> items;
  final int total;
  final int page;
  final int limit;
  final int pages;

  MinistryListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.pages,
  });

  factory MinistryListResponse.fromJson(Map<String, dynamic> json) {
    return MinistryListResponse(
      items: (json['items'] as List?)
          ?.map((item) => MinistryResponse.fromJson(item))
          .toList() ?? [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      pages: json['pages'] ?? 1,
    );
  }
} 