class EventRecurrenceType {
  static const String none = 'none';
  static const String daily = 'daily';
  static const String weekly = 'weekly';
  static const String monthly = 'monthly';
}

class EventStatus {
  static const String draft = 'draft';
  static const String published = 'published';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
}

class EventRecurrencePattern {
  final int? interval;
  final List<int>? daysOfWeek;
  final int? dayOfMonth;
  final DateTime? endDate;
  final int? occurrences;

  EventRecurrencePattern({
    this.interval,
    this.daysOfWeek,
    this.dayOfMonth,
    this.endDate,
    this.occurrences,
  });

  factory EventRecurrencePattern.fromMap(Map<String, dynamic>? map) {
    if (map == null) return EventRecurrencePattern();
    return EventRecurrencePattern(
      interval: map['interval'],
      daysOfWeek: map['daysOfWeek'] != null ? List<int>.from(map['daysOfWeek']) : null,
      dayOfMonth: map['dayOfMonth'],
      endDate: map['endDate'] != null ? DateTime.tryParse(map['endDate']) : null,
      occurrences: map['occurrences'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (interval != null) 'interval': interval,
      if (daysOfWeek != null) 'daysOfWeek': daysOfWeek,
      if (dayOfMonth != null) 'dayOfMonth': dayOfMonth,
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      if (occurrences != null) 'occurrences': occurrences,
    };
  }
}

class EventModel {
  final String id;
  final String tenantId;
  final String? branchId;
  final String ministryId;
  final String name;
  final String? description;
  final DateTime eventDate;
  final String eventTime; // HH:mm
  final String recurrenceType;
  final EventRecurrencePattern? recurrencePattern;
  final String eventType; // ordinary | ministry_specific
  final bool isOrdinary;
  final String? templateId;
  final String? specialNotes;
  final String status;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventModel({
    required this.id,
    required this.tenantId,
    this.branchId,
    required this.ministryId,
    required this.name,
    this.description,
    required this.eventDate,
    required this.eventTime,
    required this.recurrenceType,
    this.recurrencePattern,
    required this.eventType,
    required this.isOrdinary,
    this.templateId,
    this.specialNotes,
    required this.status,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['_id'] ?? map['id'] ?? '',
      tenantId: map['tenantId'] ?? '',
      branchId: map['branchId'],
      ministryId: map['ministryId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      eventDate: DateTime.parse(map['eventDate']),
      eventTime: map['eventTime'] ?? '00:00',
      recurrenceType: map['recurrenceType'] ?? EventRecurrenceType.none,
      recurrencePattern: EventRecurrencePattern.fromMap(map['recurrencePattern'] as Map<String, dynamic>?),
      eventType: map['eventType'] ?? 'ministry_specific',
      isOrdinary: map['isOrdinary'] ?? false,
      templateId: map['templateId'],
      specialNotes: map['specialNotes'],
      status: map['status'] ?? EventStatus.draft,
      createdBy: map['createdBy']?.toString(),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'tenantId': tenantId,
      'branchId': branchId,
      'ministryId': ministryId,
      'name': name,
      'description': description,
      'eventDate': eventDate.toIso8601String(),
      'eventTime': eventTime,
      'recurrenceType': recurrenceType,
      'recurrencePattern': recurrencePattern?.toMap(),
      'eventType': eventType,
      'isOrdinary': isOrdinary,
      'templateId': templateId,
      'specialNotes': specialNotes,
      'status': status,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}


