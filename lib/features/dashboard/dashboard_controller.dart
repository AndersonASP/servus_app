import 'package:flutter/material.dart';
import 'package:servus_app/features/dashboard/models/botao_status_model.dart';

class DashboardController {
  final List<bool> expanded = List.generate(4, (_) => false);

  void toggleExpand(int index) {
    expanded[index] = !expanded[index];
  }

  void confirmarEscala(int index) {
    // Aqui você pode integrar com lógica de backend ou estado
    debugPrint('Escala $index confirmada');
  }

  BotaoStatusData getBotaoStatusData(String status) {
    switch (status) {
      case 'aguardando':
        return const BotaoStatusData(
          label: 'Confirmar',
          icon: Icons.check_circle_outline,
          color: Color.fromARGB(255, 72, 99, 247), // azul primário
        );
      case 'confirmado':
        return const BotaoStatusData(
          label: 'Fazer check-in',
          icon: Icons.login,
          color: Color(0xFF388E3C), // verde forte
        );
      case 'finalizado':
        return const BotaoStatusData(
          label: 'Escala concluída',
          icon: Icons.check,
          color: Color(0xFFBDBDBD), // cinza claro
          enabled: false,
        );
      default:
        return const BotaoStatusData(
          label: 'Confirmar',
          icon: Icons.check_circle_outline,
          color: Color(0xFF4058DB),
        );
    }
  }
}
