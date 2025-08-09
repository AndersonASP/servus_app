// lib/shared/widgets/more_options_sheet.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:servus_app/core/theme/context_extension.dart';

class MoreOptionsSheetLeader {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: context.theme.scaffoldBackgroundColor,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  'Mais opções',
                  style: TextStyle(
                    fontSize: 18,
                    color: context.colors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Divider(color: context.colors.onSurface, thickness: 0.5),
              _buildOption(
                  context, Icons.person, 'Meu Perfil', '/leader/perfil'),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildOption(
      BuildContext context, IconData icon, String label, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigo[700]),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        context.push(route);
      },
    );
  }
}
