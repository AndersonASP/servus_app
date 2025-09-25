class Address {
  final String? cep;
  final String? rua;
  final String? numero;
  final String? bairro;
  final String? cidade;
  final String? estado;

  Address({
    this.cep,
    this.rua,
    this.numero,
    this.bairro,
    this.cidade,
    this.estado,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      cep: json['cep'],
      rua: json['rua'],
      numero: json['numero'],
      bairro: json['bairro'],
      cidade: json['cidade'],
      estado: json['estado'],
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
    };
  }
}

class BranchBasic {
  final String id;
  final String name;
  final String? address;

  BranchBasic({
    required this.id,
    required this.name,
    this.address,
  });

  factory BranchBasic.fromJson(Map<String, dynamic> json) {
    return BranchBasic(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
    };
  }
}

class MinistryBasic {
  final String id;
  final String name;
  final String? description;

  MinistryBasic({
    required this.id,
    required this.name,
    this.description,
  });

  factory MinistryBasic.fromJson(Map<String, dynamic> json) {
    return MinistryBasic(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}

class MembershipResponse {
  final String id;
  final String role;
  final bool isActive;
  final BranchBasic? branch;
  final MinistryBasic? ministry;
  final DateTime createdAt;
  final DateTime updatedAt;

  MembershipResponse({
    required this.id,
    required this.role,
    required this.isActive,
    this.branch,
    this.ministry,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MembershipResponse.fromJson(Map<String, dynamic> json) {
    return MembershipResponse(
      id: json['id'] ?? '',
      role: json['role'] ?? '',
      isActive: json['isActive'] ?? false,
      branch: json['branch'] != null ? BranchBasic.fromJson(json['branch']) : null,
      ministry: json['ministry'] != null ? MinistryBasic.fromJson(json['ministry']) : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'isActive': isActive,
      'branch': branch?.toJson(),
      'ministry': ministry?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class Member {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? birthDate;
  final String? bio;
  final List<String>? skills;
  final String? availability;
  final Address? address;
  final String? picture;
  final bool isActive;
  final bool profileCompleted;
  final String role;
  final String? tenantId; // ObjectId como string
  final String? branchId;
  final List<MembershipResponse> memberships;
  final DateTime createdAt;
  final DateTime updatedAt;

  Member({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.birthDate,
    this.bio,
    this.skills,
    this.availability,
    this.address,
    this.picture,
    required this.isActive,
    required this.profileCompleted,
    required this.role,
    this.tenantId,
    this.branchId,
    required this.memberships,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      birthDate: json['birthDate'],
      bio: json['bio'],
      skills: json['skills'] != null ? List<String>.from(json['skills']) : null,
      availability: json['availability'],
      address: json['address'] != null ? Address.fromJson(json['address']) : null,
      picture: json['picture'],
      isActive: json['isActive'] ?? false,
      profileCompleted: json['profileCompleted'] ?? false,
      role: json['role'] ?? '',
      tenantId: json['tenantId'],
      branchId: json['branchId'],
      memberships: json['memberships'] != null 
          ? List<MembershipResponse>.from(json['memberships'].map((x) => MembershipResponse.fromJson(x)))
          : [],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'birthDate': birthDate,
      'bio': bio,
      'skills': skills,
      'availability': availability,
      'address': address?.toJson(),
      'picture': picture,
      'isActive': isActive,
      'profileCompleted': profileCompleted,
      'role': role,
      'tenantId': tenantId,
      'branchId': branchId,
      'memberships': memberships.map((x) => x.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class MemberFilter {
  final String? search;
  final String? branchId;
  final String? ministryId;
  final String? role;
  final bool? isActive;
  final int? page;
  final int? limit;

  MemberFilter({
    this.search,
    this.branchId,
    this.ministryId,
    this.role,
    this.isActive,
    this.page,
    this.limit,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (search != null && search!.isNotEmpty) data['search'] = search;
    if (branchId != null && branchId!.isNotEmpty) data['branchId'] = branchId;
    if (ministryId != null && ministryId!.isNotEmpty) data['ministryId'] = ministryId;
    if (role != null && role!.isNotEmpty) data['role'] = role;
    if (isActive != null) data['isActive'] = isActive;
    if (page != null && page! > 0) data['page'] = page.toString();
    if (limit != null && limit! > 0) data['limit'] = limit.toString();
    return data;
  }
}

class MembershipAssignment {
  final String role;
  final String? branchId;
  final String? ministryId;
  final bool? isActive;
  final List<String> functionIds; // IDs das funções aprovadas

  MembershipAssignment({
    required this.role,
    this.branchId,
    this.ministryId,
    this.isActive,
    this.functionIds = const [],
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'role': role,
    };
    
    if (branchId != null) data['branchId'] = branchId;
    if (ministryId != null) data['ministryId'] = ministryId;
    if (isActive != null) data['isActive'] = isActive;
    if (functionIds.isNotEmpty) data['functionIds'] = functionIds;
    
    return data;
  }
}

class CreateMemberRequest {
  final String name;
  final String? email;
  final String? phone;
  final String? birthDate;
  final String? bio;
  final List<String>? skills;
  final String? availability;
  final Address? address;
  final List<MembershipAssignment> memberships;
  final String? password;

  CreateMemberRequest({
    required this.name,
    this.email,
    this.phone,
    this.birthDate,
    this.bio,
    this.skills,
    this.availability,
    this.address,
    required this.memberships,
    this.password,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'memberships': memberships.map((x) => x.toJson()).toList(),
    };
    
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;
    if (birthDate != null) data['birthDate'] = birthDate;
    if (bio != null) data['bio'] = bio;
    if (skills != null) data['skills'] = skills;
    if (availability != null) data['availability'] = availability;
    if (address != null) data['address'] = address!.toJson();
    if (password != null) data['password'] = password;
    
    return data;
  }
}

class UpdateMemberRequest {
  final String? name;
  final String? email;
  final String? phone;
  final String? birthDate;
  final String? bio;
  final List<String>? skills;
  final String? availability;
  final Address? address;
  final String? branchId;
  final String? ministryId;
  final String? role;
  final String? password;

  UpdateMemberRequest({
    this.name,
    this.email,
    this.phone,
    this.birthDate,
    this.bio,
    this.skills,
    this.availability,
    this.address,
    this.branchId,
    this.ministryId,
    this.role,
    this.password,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;
    if (birthDate != null) data['birthDate'] = birthDate;
    if (bio != null) data['bio'] = bio;
    if (skills != null) data['skills'] = skills;
    if (availability != null) data['availability'] = availability;
    if (address != null) data['address'] = address!.toJson();
    if (branchId != null) data['branchId'] = branchId;
    if (ministryId != null) data['ministryId'] = ministryId;
    if (role != null) data['role'] = role;
    if (password != null) data['password'] = password;
    
    return data;
  }
}

class MembersResponse {
  final List<Member> members;
  final int total;

  MembersResponse({
    required this.members,
    required this.total,
  });

  factory MembersResponse.fromJson(Map<String, dynamic> json) {
    List<Member> members = [];
    
    
    if (json['members'] != null) {
      if (json['members'] is List) {
        try {
          members = List<Member>.from(json['members'].map((x) => Member.fromJson(x)));
        } catch (e) {
          members = [];
        }
      } else {
        members = [];
      }
    } else {
    }
    
    return MembersResponse(
      members: members,
      total: json['total'] ?? 0,
    );
  }
}
