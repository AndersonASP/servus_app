class InviteCode {
  final String code;
  final String ministryId;
  final String ministryName;
  final String tenantId;
  final String? branchId;
  final String? branchName;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int usageCount;
  final bool isActive;

  InviteCode({
    required this.code,
    required this.ministryId,
    required this.ministryName,
    required this.tenantId,
    this.branchId,
    this.branchName,
    required this.createdBy,
    required this.createdAt,
    this.expiresAt,
    required this.usageCount,
    required this.isActive,
  });

  factory InviteCode.fromMap(Map<String, dynamic> map) {
    return InviteCode(
      code: map['code'] ?? '',
      ministryId: map['ministryId'] ?? '',
      ministryName: map['ministryName'] ?? '',
      tenantId: map['tenantId'] ?? '',
      branchId: map['branchId'],
      branchName: map['branchName'],
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      expiresAt: map['expiresAt'] != null ? DateTime.parse(map['expiresAt']) : null,
      usageCount: map['usageCount'] ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'ministryId': ministryId,
      'ministryName': ministryName,
      'tenantId': tenantId,
      'branchId': branchId,
      'branchName': branchName,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'usageCount': usageCount,
      'isActive': isActive,
    };
  }
}

class InviteCodeValidation {
  final bool isValid;
  final String? ministryId;
  final String? ministryName;
  final String? tenantId;
  final String? branchId;
  final String? branchName;
  final DateTime? expiresAt;
  final String? message;

  InviteCodeValidation({
    required this.isValid,
    this.ministryId,
    this.ministryName,
    this.tenantId,
    this.branchId,
    this.branchName,
    this.expiresAt,
    this.message,
  });

  factory InviteCodeValidation.fromMap(Map<String, dynamic> map) {
    
    // Extrair apenas o ID do objeto ministryId
    String? extractedMinistryId;
    if (map['ministryId'] != null) {
      if (map['ministryId'] is String) {
        // Se já é string, verificar se contém ObjectId
        final ministryIdStr = map['ministryId'] as String;
        if (ministryIdStr.contains('ObjectId(')) {
          // Extrair ID do formato "ObjectId('68cb073d350fa8d28f1cbf7b')"
          final match = RegExp(r"ObjectId\('([^']+)'\)").firstMatch(ministryIdStr);
          extractedMinistryId = match?.group(1);
        } else {
          extractedMinistryId = ministryIdStr;
        }
      } else {
        // Se é objeto, extrair o _id
        final ministryObj = map['ministryId'];
        if (ministryObj is Map && ministryObj['_id'] != null) {
          extractedMinistryId = ministryObj['_id'].toString();
        }
      }
    }
    
    
    return InviteCodeValidation(
      isValid: map['isValid'] ?? false,
      ministryId: extractedMinistryId,
      ministryName: map['ministryName'],
      tenantId: map['tenantId'],
      branchId: map['branchId'],
      branchName: map['branchName'],
      expiresAt: map['expiresAt'] != null ? DateTime.parse(map['expiresAt']) : null,
      message: map['message'],
    );
  }
}

class InviteRegistrationData {
  final String code;
  final String name;
  final String email;
  final String phone;
  final String password;

  InviteRegistrationData({
    required this.code,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    final data = {
      'code': code,
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    };
    return data;
  }
}
