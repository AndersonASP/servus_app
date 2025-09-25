import 'package:flutter/material.dart';

class FormFieldType {
  static const String text = 'text';
  static const String email = 'email';
  static const String phone = 'phone';
  static const String select = 'select';
  static const String multiselect = 'multiselect';
  static const String textarea = 'textarea';
  static const String date = 'date';
  static const String number = 'number';
  static const String checkbox = 'checkbox';
  static const String ministrySelect = 'ministry_select';
  static const String functionMultiselect = 'function_multiselect';
}

class CustomFormField {
  final String id;
  final String label;
  final String type;
  final bool required;
  final String placeholder;
  final String helpText;
  final List<String> options;
  final String defaultValue;
  final int order;
  final bool isSelected;

  CustomFormField({
    required this.id,
    required this.label,
    required this.type,
    this.required = false,
    this.placeholder = '',
    this.helpText = '',
    this.options = const [],
    this.defaultValue = '',
    this.order = 0,
    this.isSelected = true,
  });

  factory CustomFormField.fromMap(Map<String, dynamic> map) {
    try {
      
      // Processar options
      final optionsData = map['options'];
      final options = map['type'] == 'ministry_select' 
          ? CustomForm._convertToMinistryOptions(optionsData)
          : CustomForm._convertToStringList(optionsData);
      
      return CustomFormField(
        id: map['id'] ?? '',
        label: map['label'] ?? '',
        type: map['type'] ?? FormFieldType.text,
        required: map['required'] ?? false,
        placeholder: map['placeholder'] ?? '',
        helpText: map['helpText'] ?? '',
        options: options,
        defaultValue: map['defaultValue'] ?? '',
        order: map['order'] ?? 0,
        isSelected: map['isSelected'] ?? true,
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'type': type,
      'required': required,
      'placeholder': placeholder,
      'helpText': helpText,
      'options': options,
      'defaultValue': defaultValue,
      'order': order,
      // isSelected não é enviado para o backend, é apenas para controle interno do frontend
    };
  }
}

class FormColorScheme {
  final String primaryColor;
  final String backgroundColor;
  final String textColor;

  FormColorScheme({
    this.primaryColor = '#4058DB',
    this.backgroundColor = '#FFFFFF',
    this.textColor = '#1F2937',
  });

  factory FormColorScheme.fromMap(Map<String, dynamic> map) {
    return FormColorScheme(
      primaryColor: map['primaryColor'] ?? '#4058DB',
      backgroundColor: map['backgroundColor'] ?? '#FFFFFF',
      textColor: map['textColor'] ?? '#1F2937',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'primaryColor': primaryColor,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
    };
  }

  // Métodos para converter strings hex para Color
  Color get primaryColorValue => _hexToColor(primaryColor);
  Color get backgroundColorValue => _hexToColor(backgroundColor);
  Color get textColorValue => _hexToColor(textColor);

  Color _hexToColor(String hex) {
    // Remove o # se presente
    hex = hex.replaceAll('#', '');
    
    // Adiciona FF se não tiver alpha
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    
    return Color(int.parse(hex, radix: 16));
  }
}

class FormSettings {
  final bool allowMultipleSubmissions;
  final bool requireApproval;
  final bool showProgress;
  final String successMessage;
  final String submitButtonText;
  final FormColorScheme colorScheme;

  FormSettings({
    this.allowMultipleSubmissions = true,
    this.requireApproval = false,
    this.showProgress = true,
    this.successMessage = '',
    this.submitButtonText = '',
    FormColorScheme? colorScheme,
  }) : colorScheme = colorScheme ?? FormColorScheme();

  factory FormSettings.fromMap(Map<String, dynamic> map) {
    return FormSettings(
      allowMultipleSubmissions: map['allowMultipleSubmissions'] ?? true,
      requireApproval: map['requireApproval'] ?? false,
      showProgress: map['showProgress'] ?? true,
      successMessage: map['successMessage'] ?? '',
      submitButtonText: map['submitButtonText'] ?? '',
      colorScheme: FormColorScheme.fromMap(map['colorScheme'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'allowMultipleSubmissions': allowMultipleSubmissions,
      'requireApproval': requireApproval,
      'showProgress': showProgress,
      'successMessage': successMessage,
      'submitButtonText': submitButtonText,
      'colorScheme': colorScheme.toMap(),
    };
  }
}

class CustomForm {
  final String id;
  final String title;
  final String description;
  final String tenantId;
  final String? branchId;
  final String createdBy;
  final List<CustomFormField> fields;
  final List<String> availableMinistries;
  final List<String> availableRoles;
  final FormSettings settings;
  final bool isActive;
  final bool isPublic;
  final DateTime? expiresAt;
  final int submissionCount;
  final int approvedCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomForm({
    required this.id,
    required this.title,
    required this.description,
    required this.tenantId,
    this.branchId,
    required this.createdBy,
    required this.fields,
    required this.availableMinistries,
    required this.availableRoles,
    required this.settings,
    required this.isActive,
    required this.isPublic,
    this.expiresAt,
    required this.submissionCount,
    required this.approvedCount,
    required this.createdAt,
    required this.updatedAt,
  });

  static List<String> _convertToStringList(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((item) {
        if (item is String) {
          return item;
        } else if (item is Map) {
          // Priorizar 'name' para objetos populados do MongoDB
          if (item.containsKey('name')) {
            return item['name'] as String;
          } else if (item.containsKey('_id')) {
            return item['_id'] as String;
          } else {
            // Tentar qualquer campo string disponível
            for (final key in item.keys) {
              if (item[key] is String) {
                return item[key] as String;
              }
            }
            return item.toString();
          }
        } else {
          return item.toString();
        }
      }).toList();
    }
    return [];
  }

  static List<String> _convertToMinistryOptions(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((item) {
        if (item is String) {
          return item;
        } else if (item is Map) {
          // Para campos ministry_select, preservar estrutura {value, label}
          // Retornar como string JSON para manter a estrutura
          return '${item['value']}|${item['label']}';
        } else {
          return item.toString();
        }
      }).toList();
    }
    return [];
  }

  static String _convertToString(dynamic data) {
    if (data == null) return '';
    if (data is String) {
      return data;
    } else if (data is Map) {
      // Para objetos populados do MongoDB
      if (data.containsKey('name')) {
        return data['name'] as String;
      } else if (data.containsKey('_id')) {
        return data['_id'] as String;
      } else {
        // Tentar qualquer campo string disponível
        for (final key in data.keys) {
          if (data[key] is String) {
            return data[key] as String;
          }
        }
        return data.toString();
      }
    } else {
      return data.toString();
    }
  }

  factory CustomForm.fromMap(Map<String, dynamic> map) {
    try {
      
      // Processar campos
      final fieldsData = map['fields'] as List<dynamic>?;
      
      final fields = fieldsData?.map((field) {
        try {
          return CustomFormField.fromMap(field);
        } catch (e) {
          rethrow;
        }
      }).toList() ?? [];
      
      // Processar ministérios
      final ministriesData = map['availableMinistries'];
      final availableMinistries = _convertToStringList(ministriesData);
      
      // Processar roles
      final rolesData = map['availableRoles'];
      final availableRoles = _convertToStringList(rolesData);
      
      return CustomForm(
        id: map['_id'] ?? '',
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        tenantId: map['tenantId'] ?? '',
        branchId: map['branchId'],
        createdBy: _convertToString(map['createdBy']),
        fields: fields,
        availableMinistries: availableMinistries,
        availableRoles: availableRoles,
        settings: FormSettings.fromMap(map['settings'] ?? {}),
        isActive: map['isActive'] ?? true,
        isPublic: map['isPublic'] ?? false,
        expiresAt: map['expiresAt'] != null ? DateTime.parse(map['expiresAt']) : null,
        submissionCount: map['submissionCount'] ?? 0,
        approvedCount: map['approvedCount'] ?? 0,
        createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
        updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'fields': fields.map((field) => field.toMap()).toList(),
      'availableMinistries': availableMinistries,
      'availableRoles': availableRoles,
      'settings': settings.toMap(),
      'isPublic': isPublic,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
}
