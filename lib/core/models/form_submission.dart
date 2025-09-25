class FormSubmissionStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String processed = 'processed';
}

class FormSubmission {
  final String id;
  final String formId;
  final String tenantId;
  final String? branchId;
  final String volunteerName;
  final String email;
  final String phone;
  final String? preferredMinistry;
  final String preferredRole;
  final Map<String, dynamic> customFields;
  final String status;
  final String? reviewedBy;
  final String? reviewNotes;
  final DateTime? reviewedAt;
  final String? processedBy;
  final DateTime? processedAt;
  final String? createdUserId;
  final String? createdMembershipId;
  final DateTime createdAt;
  final DateTime updatedAt;

  FormSubmission({
    required this.id,
    required this.formId,
    required this.tenantId,
    this.branchId,
    required this.volunteerName,
    required this.email,
    required this.phone,
    this.preferredMinistry,
    required this.preferredRole,
    required this.customFields,
    required this.status,
    this.reviewedBy,
    this.reviewNotes,
    this.reviewedAt,
    this.processedBy,
    this.processedAt,
    this.createdUserId,
    this.createdMembershipId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FormSubmission.fromMap(Map<String, dynamic> map) {
    // Tratar campos populados que podem vir como objetos
    String? preferredMinistryId;
    if (map['preferredMinistry'] != null) {
      if (map['preferredMinistry'] is String) {
        preferredMinistryId = map['preferredMinistry'];
      } else if (map['preferredMinistry'] is Map) {
        preferredMinistryId = map['preferredMinistry']['_id']?.toString();
      }
    }

    String? reviewedById;
    if (map['reviewedBy'] != null) {
      if (map['reviewedBy'] is String) {
        reviewedById = map['reviewedBy'];
      } else if (map['reviewedBy'] is Map) {
        reviewedById = map['reviewedBy']['_id']?.toString();
      }
    }

    String? processedById;
    if (map['processedBy'] != null) {
      if (map['processedBy'] is String) {
        processedById = map['processedBy'];
      } else if (map['processedBy'] is Map) {
        processedById = map['processedBy']['_id']?.toString();
      }
    }

    return FormSubmission(
      id: map['_id']?.toString() ?? '',
      formId: map['formId']?.toString() ?? '',
      tenantId: map['tenantId']?.toString() ?? '',
      branchId: map['branchId']?.toString(),
      volunteerName: map['volunteerName']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      preferredMinistry: preferredMinistryId,
      preferredRole: map['preferredRole']?.toString() ?? 'volunteer',
      customFields: Map<String, dynamic>.from(map['customFields'] ?? {}),
      status: map['status']?.toString() ?? FormSubmissionStatus.pending,
      reviewedBy: reviewedById,
      reviewNotes: map['reviewNotes']?.toString(),
      reviewedAt: map['reviewedAt'] != null ? DateTime.parse(map['reviewedAt'].toString()) : null,
      processedBy: processedById,
      processedAt: map['processedAt'] != null ? DateTime.parse(map['processedAt'].toString()) : null,
      createdUserId: map['createdUserId']?.toString(),
      createdMembershipId: map['createdMembershipId']?.toString(),
      createdAt: DateTime.parse(map['createdAt'].toString()),
      updatedAt: DateTime.parse(map['updatedAt'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'volunteerName': volunteerName,
      'email': email,
      'phone': phone,
      'preferredMinistry': preferredMinistry,
      'preferredRole': preferredRole,
      'customFields': customFields,
    };
  }
}

class FormSubmissionData {
  final String volunteerName;
  final String email;
  final String phone;
  final String? preferredMinistry;
  final String preferredRole;
  final Map<String, dynamic> customFields;
  final List<String> selectedFunctions;

  FormSubmissionData({
    required this.volunteerName,
    required this.email,
    required this.phone,
    this.preferredMinistry,
    required this.preferredRole,
    required this.customFields,
    this.selectedFunctions = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'volunteerName': volunteerName,
      'email': email,
      'phone': phone,
      'preferredMinistry': preferredMinistry,
      'preferredRole': preferredRole,
      'customFields': customFields,
      'selectedFunctions': selectedFunctions,
    };
  }
}
