import 'package:flutter/material.dart';

enum EscalaStatus {
  rascunho,
  pronto,
  publicado;

  String get label {
    switch (this) {
      case EscalaStatus.rascunho:
        return 'Rascunho';
      case EscalaStatus.pronto:
        return 'Pronto';
      case EscalaStatus.publicado:
        return 'Publicado';
    }
  }

  Color get color {
    switch (this) {
      case EscalaStatus.rascunho:
        return Colors.orange.shade700;
      case EscalaStatus.pronto:
        return Colors.green.shade700;
      case EscalaStatus.publicado:
        return Colors.blue.shade700;
    }
  }

  IconData get icon {
    switch (this) {
      case EscalaStatus.rascunho:
        return Icons.edit_outlined;
      case EscalaStatus.pronto:
        return Icons.check_circle_outline;
      case EscalaStatus.publicado:
        return Icons.published_with_changes;
    }
  }

  static EscalaStatus? fromString(String? value) {
    if (value == null) return null;
    return EscalaStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EscalaStatus.rascunho,
    );
  }
}
