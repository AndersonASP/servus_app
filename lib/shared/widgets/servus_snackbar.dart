import 'package:flutter/material.dart';
import 'package:servus_app/core/theme/color_scheme.dart';
import 'package:servus_app/core/theme/context_extension.dart';

enum ServusSnackType { success, warning, error, info }

void showServusSnack(
  BuildContext context, {
  required String message,
  ServusSnackType type = ServusSnackType.info,
  Duration duration = const Duration(seconds: 2),
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;

  // Cores por tipo (puxa do tema quando possível)
  final Map<ServusSnackType, Color> bg = {
    ServusSnackType.success: ServusColors.success,
    ServusSnackType.warning: ServusColors.warning, // âmbar claro
    ServusSnackType.error: scheme.error,
    ServusSnackType.info: scheme.primary,
  };

  final Map<ServusSnackType, IconData> icon = {
    ServusSnackType.success: Icons.check_circle,
    ServusSnackType.warning: Icons.warning_amber_rounded,
    ServusSnackType.error: Icons.error_rounded,
    ServusSnackType.info: Icons.info_rounded,
  };

  ScaffoldMessenger.of(context).hideCurrentSnackBar();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: bg[type],
      duration: duration,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon[type], color: context.colors.onPrimary,),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.colors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}