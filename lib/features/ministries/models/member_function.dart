enum MemberFunctionStatus {
  pending,
  approved,
  rejected,
}

class MemberFunction {
  final String id;
  final String userId;
  final String ministryId;
  final String functionId;
  final MemberFunctionStatus status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? notes;
  final String tenantId;
  final String? branchId;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Dados populados
  final MemberFunctionUser? user;
  final MemberFunctionMinistry? ministry;
  final MemberFunctionFunction? function;
  final MemberFunctionUser? approvedByUser;

  MemberFunction({
    required this.id,
    required this.userId,
    required this.ministryId,
    required this.functionId,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.notes,
    required this.tenantId,
    this.branchId,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.ministry,
    this.function,
    this.approvedByUser,
  });

  factory MemberFunction.fromJson(Map<String, dynamic> json) {
    return MemberFunction(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      ministryId: json['ministryId'] ?? '',
      functionId: json['functionId'] ?? '',
      status: _parseStatus(json['status']),
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      notes: json['notes'],
      tenantId: json['tenantId'] ?? '',
      branchId: json['branchId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      user: json['user'] != null ? MemberFunctionUser.fromJson(json['user']) : null,
      ministry: json['ministry'] != null ? MemberFunctionMinistry.fromJson(json['ministry']) : null,
      function: json['function'] != null ? MemberFunctionFunction.fromJson(json['function']) : null,
      approvedByUser: json['approvedByUser'] != null ? MemberFunctionUser.fromJson(json['approvedByUser']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'ministryId': ministryId,
      'functionId': functionId,
      'status': status.name,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'notes': notes,
      'tenantId': tenantId,
      'branchId': branchId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'user': user?.toJson(),
      'ministry': ministry?.toJson(),
      'function': function?.toJson(),
      'approvedByUser': approvedByUser?.toJson(),
    };
  }

  static MemberFunctionStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return MemberFunctionStatus.pending;
      case 'approved':
      case 'aprovado': // ✅ Suporte ao status em português do backend
        return MemberFunctionStatus.approved;
      case 'rejected':
      case 'rejeitado': // ✅ Suporte ao status em português do backend
        return MemberFunctionStatus.rejected;
      default:
        return MemberFunctionStatus.pending;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case MemberFunctionStatus.pending:
        return 'Pendente';
      case MemberFunctionStatus.approved:
        return 'Aprovado';
      case MemberFunctionStatus.rejected:
        return 'Rejeitado';
    }
  }

  bool get isApproved => status == MemberFunctionStatus.approved;
  bool get isPending => status == MemberFunctionStatus.pending;
  bool get isRejected => status == MemberFunctionStatus.rejected;
}

class MemberFunctionUser {
  final String id;
  final String name;
  final String email;

  MemberFunctionUser({
    required this.id,
    required this.name,
    required this.email,
  });

  factory MemberFunctionUser.fromJson(Map<String, dynamic> json) {
    return MemberFunctionUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}

class MemberFunctionMinistry {
  final String id;
  final String name;

  MemberFunctionMinistry({
    required this.id,
    required this.name,
  });

  factory MemberFunctionMinistry.fromJson(Map<String, dynamic> json) {
    return MemberFunctionMinistry(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class MemberFunctionFunction {
  final String id;
  final String name;
  final String? description;

  MemberFunctionFunction({
    required this.id,
    required this.name,
    this.description,
  });

  factory MemberFunctionFunction.fromJson(Map<String, dynamic> json) {
    return MemberFunctionFunction(
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
