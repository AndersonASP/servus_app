class FunctionRequirementModel {
  final String functionId;
  final int requiredSlots;
  final bool isRequired;
  final int priority;
  final String? notes;

  FunctionRequirementModel({
    required this.functionId,
    required this.requiredSlots,
    required this.isRequired,
    required this.priority,
    this.notes,
  });

  factory FunctionRequirementModel.fromMap(Map<String, dynamic> map) {
    return FunctionRequirementModel(
      functionId: map['functionId'] ?? '',
      requiredSlots: map['requiredSlots'] ?? 0,
      isRequired: map['isRequired'] ?? true,
      priority: map['priority'] ?? 0,
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'functionId': functionId,
      'requiredSlots': requiredSlots,
      'isRequired': isRequired,
      'priority': priority,
      'notes': notes,
    };
  }
}

class MinistryRequirementsModel {
  final String ministryId;
  final List<FunctionRequirementModel> functions;

  MinistryRequirementsModel({
    required this.ministryId,
    required this.functions,
  });

  factory MinistryRequirementsModel.fromMap(Map<String, dynamic> map) {
    return MinistryRequirementsModel(
      ministryId: map['ministryId'] ?? '',
      functions: (map['functions'] as List? ?? [])
          .map((e) => FunctionRequirementModel.fromMap(e))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ministryId': ministryId,
      'functions': functions.map((e) => e.toMap()).toList(),
    };
  }
}

class ScaleTemplateModel {
  final String id;
  final String tenantId;
  final String? branchId;
  final String name;
  final String? description;
  final String eventType;
  final List<MinistryRequirementsModel> ministryRequirements;
  final bool autoAssign;
  final bool allowOverbooking;
  final int reminderDaysBefore;
  final String? createdBy;

  ScaleTemplateModel({
    required this.id,
    required this.tenantId,
    this.branchId,
    required this.name,
    this.description,
    required this.eventType,
    required this.ministryRequirements,
    required this.autoAssign,
    required this.allowOverbooking,
    required this.reminderDaysBefore,
    this.createdBy,
  });

  factory ScaleTemplateModel.fromMap(Map<String, dynamic> map) {
    return ScaleTemplateModel(
      id: map['_id'] ?? map['id'] ?? '',
      tenantId: map['tenantId'] ?? '',
      branchId: map['branchId'],
      name: map['name'] ?? '',
      description: map['description'],
      eventType: map['eventType'] ?? 'culto',
      ministryRequirements: (map['ministryRequirements'] as List? ?? [])
          .map((e) => MinistryRequirementsModel.fromMap(e))
          .toList(),
      autoAssign: map['autoAssign'] ?? false,
      allowOverbooking: map['allowOverbooking'] ?? false,
      reminderDaysBefore: map['reminderDaysBefore'] ?? 2,
      createdBy: map['createdBy']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'tenantId': tenantId,
      'branchId': branchId,
      'name': name,
      'description': description,
      'eventType': eventType,
      'ministryRequirements': ministryRequirements.map((e) => e.toMap()).toList(),
      'autoAssign': autoAssign,
      'allowOverbooking': allowOverbooking,
      'reminderDaysBefore': reminderDaysBefore,
      'createdBy': createdBy,
    };
  }
}


