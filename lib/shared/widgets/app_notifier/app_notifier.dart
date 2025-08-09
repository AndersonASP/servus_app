import 'package:flutter/material.dart';

enum NotificationType { success, error, warning }

class AppNotifier {
  static void show(
    BuildContext context, {
    required String message,
    NotificationType type = NotificationType.success,
  }) {
    final color = switch (type) {
      NotificationType.success => Colors.green[600],
      NotificationType.error => Colors.red[600],
      NotificationType.warning => Colors.orange[700],
    };

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}