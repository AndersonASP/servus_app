enum ServiceHistoryStatus {
  completed,
  missed,
  cancelled,
  replaced,
}

class ServiceHistory {
  final String id;
  final String userId;
  final String scaleId;
  final String functionId;
  final String ministryId;
  final DateTime serviceDate;
  final ServiceHistoryStatus status;
  final String? notes;
  final String? recordedBy;
  final DateTime recordedAt;
  final String tenantId;
  final String? branchId;
  final String? originalUserId;
  final String? substitutionRequestId;

  ServiceHistory({
    required this.id,
    required this.userId,
    required this.scaleId,
    required this.functionId,
    required this.ministryId,
    required this.serviceDate,
    required this.status,
    this.notes,
    this.recordedBy,
    required this.recordedAt,
    required this.tenantId,
    this.branchId,
    this.originalUserId,
    this.substitutionRequestId,
  });

  factory ServiceHistory.fromMap(Map<String, dynamic> map) {
    return ServiceHistory(
      id: map['_id'] ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      scaleId: map['scaleId'] ?? '',
      functionId: map['functionId'] ?? '',
      ministryId: map['ministryId'] ?? '',
      serviceDate: DateTime.parse(map['serviceDate']),
      status: ServiceHistoryStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => ServiceHistoryStatus.completed,
      ),
      notes: map['notes'],
      recordedBy: map['recordedBy'],
      recordedAt: DateTime.parse(map['recordedAt'] ?? DateTime.now().toIso8601String()),
      tenantId: map['tenantId'] ?? '',
      branchId: map['branchId'],
      originalUserId: map['originalUserId'],
      substitutionRequestId: map['substitutionRequestId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'scaleId': scaleId,
      'functionId': functionId,
      'ministryId': ministryId,
      'serviceDate': serviceDate.toIso8601String(),
      'status': status.name,
      'notes': notes,
      'recordedBy': recordedBy,
      'recordedAt': recordedAt.toIso8601String(),
      'tenantId': tenantId,
      'branchId': branchId,
      'originalUserId': originalUserId,
      'substitutionRequestId': substitutionRequestId,
    };
  }
}

class VolunteerServiceStats {
  final int totalServices;
  final int completedServices;
  final int missedServices;
  final int cancelledServices;
  final double attendanceRate;
  final List<Map<String, dynamic>> stats;

  VolunteerServiceStats({
    required this.totalServices,
    required this.completedServices,
    required this.missedServices,
    required this.cancelledServices,
    required this.attendanceRate,
    required this.stats,
  });

  factory VolunteerServiceStats.fromMap(Map<String, dynamic> map) {
    return VolunteerServiceStats(
      totalServices: map['totalServices'] ?? 0,
      completedServices: map['completedServices'] ?? 0,
      missedServices: map['missedServices'] ?? 0,
      cancelledServices: map['cancelledServices'] ?? 0,
      attendanceRate: (map['attendanceRate'] ?? 0.0).toDouble(),
      stats: (map['stats'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
    );
  }
}

class MinistryServiceStats {
  final int totalVolunteers;
  final int totalServices;
  final List<Map<String, dynamic>> volunteerStats;

  MinistryServiceStats({
    required this.totalVolunteers,
    required this.totalServices,
    required this.volunteerStats,
  });

  factory MinistryServiceStats.fromMap(Map<String, dynamic> map) {
    return MinistryServiceStats(
      totalVolunteers: map['totalVolunteers'] ?? 0,
      totalServices: map['totalServices'] ?? 0,
      volunteerStats: (map['volunteerStats'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
    );
  }
}
