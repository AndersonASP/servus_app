class Branch {
  final String id;
  final String branchId;
  final String name;
  final String? description;
  final BranchAddress? endereco;
  final String? telefone;
  final String? email;
  final String? whatsappOficial;
  final List<CultoDay>? diasCulto;
  final List<EventoPadrao>? eventosPadrao;
  final List<String>? modulosAtivos;
  final String? logoUrl;
  final String? corTema;
  final String? idioma;
  final String? timezone;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Branch({
    required this.id,
    required this.branchId,
    required this.name,
    this.description,
    this.endereco,
    this.telefone,
    this.email,
    this.whatsappOficial,
    this.diasCulto,
    this.eventosPadrao,
    this.modulosAtivos,
    this.logoUrl,
    this.corTema,
    this.idioma,
    this.timezone,
    required this.isActive,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] ?? '',
      branchId: json['branchId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      endereco: json['endereco'] != null 
          ? BranchAddress.fromJson(json['endereco']) 
          : null,
      telefone: json['telefone'],
      email: json['email'],
      whatsappOficial: json['whatsappOficial'],
      diasCulto: json['diasCulto'] != null
          ? (json['diasCulto'] as List)
              .map((e) => CultoDay.fromJson(e))
              .toList()
          : null,
      eventosPadrao: json['eventosPadrao'] != null
          ? (json['eventosPadrao'] as List)
              .map((e) => EventoPadrao.fromJson(e))
              .toList()
          : null,
      modulosAtivos: json['modulosAtivos'] != null
          ? List<String>.from(json['modulosAtivos'])
          : null,
      logoUrl: json['logoUrl'],
      corTema: json['corTema'],
      idioma: json['idioma'],
      timezone: json['timezone'],
      isActive: json['isActive'] ?? true,
      createdBy: json['createdBy'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branchId': branchId,
      'name': name,
      'description': description,
      'endereco': endereco?.toJson(),
      'telefone': telefone,
      'email': email,
      'whatsappOficial': whatsappOficial,
      'diasCulto': diasCulto?.map((e) => e.toJson()).toList(),
      'eventosPadrao': eventosPadrao?.map((e) => e.toJson()).toList(),
      'modulosAtivos': modulosAtivos,
      'logoUrl': logoUrl,
      'corTema': corTema,
      'idioma': idioma,
      'timezone': timezone,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Branch copyWith({
    String? id,
    String? branchId,
    String? name,
    String? description,
    BranchAddress? endereco,
    String? telefone,
    String? email,
    String? whatsappOficial,
    List<CultoDay>? diasCulto,
    List<EventoPadrao>? eventosPadrao,
    List<String>? modulosAtivos,
    String? logoUrl,
    String? corTema,
    String? idioma,
    String? timezone,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Branch(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      name: name ?? this.name,
      description: description ?? this.description,
      endereco: endereco ?? this.endereco,
      telefone: telefone ?? this.telefone,
      email: email ?? this.email,
      whatsappOficial: whatsappOficial ?? this.whatsappOficial,
      diasCulto: diasCulto ?? this.diasCulto,
      eventosPadrao: eventosPadrao ?? this.eventosPadrao,
      modulosAtivos: modulosAtivos ?? this.modulosAtivos,
      logoUrl: logoUrl ?? this.logoUrl,
      corTema: corTema ?? this.corTema,
      idioma: idioma ?? this.idioma,
      timezone: timezone ?? this.timezone,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BranchAddress {
  final String? cep;
  final String? rua;
  final String? numero;
  final String? bairro;
  final String? cidade;
  final String? estado;
  final String? complemento;

  BranchAddress({
    this.cep,
    this.rua,
    this.numero,
    this.bairro,
    this.cidade,
    this.estado,
    this.complemento,
  });

  factory BranchAddress.fromJson(Map<String, dynamic> json) {
    return BranchAddress(
      cep: json['cep'],
      rua: json['rua'],
      numero: json['numero'],
      bairro: json['bairro'],
      cidade: json['cidade'],
      estado: json['estado'],
      complemento: json['complemento'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cep': cep,
      'rua': rua,
      'numero': numero,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
      'complemento': complemento,
    };
  }

  String get fullAddress {
    final parts = <String>[];
    if (rua != null && rua!.isNotEmpty) parts.add(rua!);
    if (numero != null && numero!.isNotEmpty) parts.add(numero!);
    if (bairro != null && bairro!.isNotEmpty) parts.add(bairro!);
    if (cidade != null && cidade!.isNotEmpty) parts.add(cidade!);
    if (estado != null && estado!.isNotEmpty) parts.add(estado!);
    return parts.join(', ');
  }
}

class CultoDay {
  final String dia;
  final List<String> horarios;

  CultoDay({
    required this.dia,
    required this.horarios,
  });

  factory CultoDay.fromJson(Map<String, dynamic> json) {
    return CultoDay(
      dia: json['dia'] ?? '',
      horarios: List<String>.from(json['horarios'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dia': dia,
      'horarios': horarios,
    };
  }
}

class EventoPadrao {
  final String nome;
  final String dia;
  final List<String> horarios;
  final String? tipo;

  EventoPadrao({
    required this.nome,
    required this.dia,
    required this.horarios,
    this.tipo,
  });

  factory EventoPadrao.fromJson(Map<String, dynamic> json) {
    return EventoPadrao(
      nome: json['nome'] ?? '',
      dia: json['dia'] ?? '',
      horarios: List<String>.from(json['horarios'] ?? []),
      tipo: json['tipo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'dia': dia,
      'horarios': horarios,
      'tipo': tipo,
    };
  }
}

class BranchListResponse {
  final List<Branch> branches;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  BranchListResponse({
    required this.branches,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory BranchListResponse.fromJson(Map<String, dynamic> json) {
    return BranchListResponse(
      branches: (json['branches'] as List)
          .map((e) => Branch.fromJson(e))
          .toList(),
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      totalPages: json['totalPages'] ?? 0,
    );
  }
}

class BranchFilter {
  final String? search;
  final String? cidade;
  final String? estado;
  final bool? isActive;
  final int page;
  final int limit;
  final String sortBy;
  final String sortOrder;

  BranchFilter({
    this.search,
    this.cidade,
    this.estado,
    this.isActive,
    this.page = 1,
    this.limit = 10,
    this.sortBy = 'name',
    this.sortOrder = 'asc',
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'page': page.toString(),
      'limit': limit.toString(),
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };

    if (search != null && search!.isNotEmpty) data['search'] = search;
    if (cidade != null && cidade!.isNotEmpty) data['cidade'] = cidade;
    if (estado != null && estado!.isNotEmpty) data['estado'] = estado;
    if (isActive != null) data['isActive'] = isActive.toString();

    return data;
  }
}
