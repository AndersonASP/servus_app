// lib/shared/widgets/more_options_sheet.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:servus_app/core/theme/color_scheme.dart';

class MoreOptionsSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  'Mais opções',
                  style: TextStyle(
                    fontSize: 18,
                    color: ServusColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: ServusColors.primaryDark, thickness: 0.5),
              _buildOption(context, Icons.person, 'Meu Perfil', '/volunteer/perfil'),
              _buildOption(context, Icons.logout, 'Sair da Conta', '/login'),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildOption(BuildContext context, IconData icon, String label, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigo[700]),
      title: Text(label),
      onTap: () {
        Navigator.pop(context); // fecha o modal
        if (route == '/logout') {
          // TODO: Implementar logout
        } else {
          context.push(route);
        }
      },
    );
  }
}
