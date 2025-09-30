class FunctionAssignmentModel {
  final String functionId;
  final int requiredSlots;
  final List<String> assignedMembers;
  final bool isComplete;

  FunctionAssignmentModel({
    required this.functionId,
    required this.requiredSlots,
    required this.assignedMembers,
    required this.isComplete,
  });

  factory FunctionAssignmentModel.fromMap(Map<String, dynamic> map) {
    return FunctionAssignmentModel(
      functionId: map['functionId'] ?? '',
      requiredSlots: map['requiredSlots'] ?? 0,
      assignedMembers: map['assignedMembers'] != null
          ? List<String>.from(map['assignedMembers'].map((e) => e.toString()))
          : <String>[],
      isComplete: map['isComplete'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'functionId': functionId,
      'requiredSlots': requiredSlots,
      'assignedMembers': assignedMembers,
      'isComplete': isComplete,
    };
  }
}

class MinistryScaleModel {
  final String ministryId;
  final List<FunctionAssignmentModel> functionAssignments;

  MinistryScaleModel({
    required this.ministryId,
    required this.functionAssignments,
  });

  factory MinistryScaleModel.fromMap(Map<String, dynamic> map) {
    return MinistryScaleModel(
      ministryId: map['ministryId'] ?? '',
      functionAssignments: (map['functionAssignments'] as List? ?? [])
          .map((e) => FunctionAssignmentModel.fromMap(e))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ministryId': ministryId,
      'functionAssignments': functionAssignments.map((e) => e.toMap()).toList(),
    };
  }
}

class EventInstanceModel {
  final String id;
  final String eventId;
  final String tenantId;
  final String? branchId;
  final DateTime instanceDate;
  final List<MinistryScaleModel> ministryScales;
  final String status; // scheduled | in_progress | completed | cancelled
  final String? notes;

  EventInstanceModel({
    required this.id,
    required this.eventId,
    required this.tenantId,
    this.branchId,
    required this.instanceDate,
    required this.ministryScales,
    required this.status,
    this.notes,
  });

  factory EventInstanceModel.fromMap(Map<String, dynamic> map) {
    // Lidar com eventId que pode ser string ou objeto
    String eventId;
    if (map['eventId'] is Map) {
      // Se eventId é um objeto, extrair o _id
      eventId = map['eventId']['_id']?.toString() ?? '';
    } else {
      // Se eventId é uma string
      eventId = map['eventId']?.toString() ?? '';
    }
    
    return EventInstanceModel(
      id: map['_id'] ?? map['id'] ?? '',
      eventId: eventId,
      tenantId: map['tenantId'] ?? '',
      branchId: map['branchId'],
      instanceDate: DateTime.parse(map['instanceDate']),
      ministryScales: (map['ministryScales'] as List? ?? [])
          .map((e) => MinistryScaleModel.fromMap(e))
          .toList(),
      status: map['status'] ?? 'scheduled',
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'eventId': eventId,
      'tenantId': tenantId,
      'branchId': branchId,
      'instanceDate': instanceDate.toIso8601String(),
      'ministryScales': ministryScales.map((e) => e.toMap()).toList(),
      'status': status,
      'notes': notes,
    };
  }
}


