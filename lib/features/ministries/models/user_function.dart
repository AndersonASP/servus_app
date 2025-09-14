enum UserFunctionStatus {
  pending,
  approved,
  rejected,
}

class UserFunction {
  final String id;
  final String userId;
  final String ministryId;
  final String functionId;
  final UserFunctionStatus status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? notes;
  final String tenantId;
  final String? branchId;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Dados populados
  final UserFunctionUser? user;
  final UserFunctionMinistry? ministry;
  final UserFunctionFunction? function;
  final UserFunctionUser? approvedByUser;

  UserFunction({
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

  factory UserFunction.fromJson(Map<String, dynamic> json) {
    return UserFunction(
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
      user: json['user'] != null ? UserFunctionUser.fromJson(json['user']) : null,
      ministry: json['ministry'] != null ? UserFunctionMinistry.fromJson(json['ministry']) : null,
      function: json['function'] != null ? UserFunctionFunction.fromJson(json['function']) : null,
      approvedByUser: json['approvedByUser'] != null ? UserFunctionUser.fromJson(json['approvedByUser']) : null,
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

  static UserFunctionStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return UserFunctionStatus.pending;
      case 'approved':
        return UserFunctionStatus.approved;
      case 'rejected':
        return UserFunctionStatus.rejected;
      default:
        return UserFunctionStatus.pending;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case UserFunctionStatus.pending:
        return 'Pendente';
      case UserFunctionStatus.approved:
        return 'Aprovado';
      case UserFunctionStatus.rejected:
        return 'Rejeitado';
    }
  }

  bool get isApproved => status == UserFunctionStatus.approved;
  bool get isPending => status == UserFunctionStatus.pending;
  bool get isRejected => status == UserFunctionStatus.rejected;
}

class UserFunctionUser {
  final String id;
  final String name;
  final String email;

  UserFunctionUser({
    required this.id,
    required this.name,
    required this.email,
  });

  factory UserFunctionUser.fromJson(Map<String, dynamic> json) {
    return UserFunctionUser(
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

class UserFunctionMinistry {
  final String id;
  final String name;

  UserFunctionMinistry({
    required this.id,
    required this.name,
  });

  factory UserFunctionMinistry.fromJson(Map<String, dynamic> json) {
    return UserFunctionMinistry(
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

class UserFunctionFunction {
  final String id;
  final String name;
  final String? description;

  UserFunctionFunction({
    required this.id,
    required this.name,
    this.description,
  });

  factory UserFunctionFunction.fromJson(Map<String, dynamic> json) {
    return UserFunctionFunction(
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
