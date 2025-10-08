enum SubstitutionRequestStatus {
  pending,
  accepted,
  rejected,
  cancelled,
  expired,
}

class SubstitutionRequest {
  final String id;
  final String scaleId;
  final String requesterId;
  final String targetId;
  final String functionId;
  final String reason;
  final SubstitutionRequestStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? respondedBy;
  final DateTime? respondedAt;
  final String tenantId;
  final String ministryId;

  SubstitutionRequest({
    required this.id,
    required this.scaleId,
    required this.requesterId,
    required this.targetId,
    required this.functionId,
    required this.reason,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    required this.expiresAt,
    this.respondedBy,
    this.respondedAt,
    required this.tenantId,
    required this.ministryId,
  });

  factory SubstitutionRequest.fromMap(Map<String, dynamic> map) {
    return SubstitutionRequest(
      id: map['_id'] ?? map['id'] ?? '',
      scaleId: map['scaleId'] ?? '',
      requesterId: map['requesterId'] ?? '',
      targetId: map['targetId'] ?? '',
      functionId: map['functionId'] ?? '',
      reason: map['reason'] ?? '',
      status: SubstitutionRequestStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => SubstitutionRequestStatus.pending,
      ),
      rejectionReason: map['rejectionReason'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      expiresAt: DateTime.parse(map['expiresAt'] ?? DateTime.now().add(const Duration(hours: 24)).toIso8601String()),
      respondedBy: map['respondedBy'],
      respondedAt: map['respondedAt'] != null ? DateTime.parse(map['respondedAt']) : null,
      tenantId: map['tenantId'] ?? '',
      ministryId: map['ministryId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scaleId': scaleId,
      'requesterId': requesterId,
      'targetId': targetId,
      'functionId': functionId,
      'reason': reason,
      'status': status.name,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'respondedBy': respondedBy,
      'respondedAt': respondedAt?.toIso8601String(),
      'tenantId': tenantId,
      'ministryId': ministryId,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isPending => status == SubstitutionRequestStatus.pending && !isExpired;
}

class SwapCandidate {
  final String userId;
  final String userName;
  final String userEmail;
  final String functionLevel;
  final int priority;
  final int serviceCount;
  final bool isOverloaded;
  final bool isAvailable;
  final String? availabilityReason;

  SwapCandidate({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.functionLevel,
    required this.priority,
    required this.serviceCount,
    required this.isOverloaded,
    required this.isAvailable,
    this.availabilityReason,
  });

  factory SwapCandidate.fromMap(Map<String, dynamic> map) {
    return SwapCandidate(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      functionLevel: map['functionLevel'] ?? 'iniciante',
      priority: map['priority'] ?? 1,
      serviceCount: map['serviceCount'] ?? 0,
      isOverloaded: map['isOverloaded'] ?? false,
      isAvailable: map['isAvailable'] ?? false,
      availabilityReason: map['availabilityReason'],
    );
  }
}
