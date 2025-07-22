import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/features/perfil/perfil_controller.dart';
import 'package:servus_app/features/volunteers/dashboard/models/botao_status_model.dart';

enum TesteEscalaModo { nenhuma, uma, varias }

TesteEscalaModo modoTeste = TesteEscalaModo.varias;

class DashboardController {
  final List<bool> expanded = List.generate(4, (_) => false);

  Future<List<Map<String, dynamic>>> fetchEscalas() async {
    await Future.delayed(const Duration(seconds: 1)); // Simula delay

    final List<Map<String, dynamic>> escalasBrutas = [
      {
        'dataIso': '2025-08-15T09:00:00',
        'nomeEvento': 'Culto da família | Manhã',
        'funcoes': ['Louvor', 'Tecladista'],
        'status': 'aguardando',
        'cor': Colors.orange,
      },
      {
        'dataIso': '2025-08-17T19:30:00',
        'nomeEvento': 'Quarta da graça',
        'funcoes': ['Louvor', 'Baixista'],
        'status': 'confirmado',
        'cor': Colors.orange,
      },
      {
        'dataIso': '2025-08-20T08:15:00',
        'nomeEvento': 'Café com Deus',
        'funcoes': ['filmagem e Transmissão', 'Móvel gimbal 3'],
        'status': 'aguardando',
        'cor': Colors.green,
      },
      {
        'dataIso': '2025-08-24T08:15:00',
        'nomeEvento': 'Seminário da família | Manhã',
        'funcoes': ['Louvor', 'Tecladista'],
        'status': 'aguardando',
        'cor': Colors.blueGrey,
      },
    ];

    final List<Map<String, dynamic>> escalas =
        escalasBrutas.asMap().entries.map((entry) {
      final int index = entry.key;
      final e = entry.value;
      final data = DateTime.parse(e['dataIso']);

      return {
        'index': index,
        'diasRestantes': formatarDiasRestantes(data),
        'dia': formatarDia(data),
        'mes': formatarMes(data),
        'horario': formatarHorario(data),
        'diaSemana': formatarDiaSemana(data),
        'nomeEvento': e['nomeEvento'],
        'funcoes': e['funcoes'],
        'status': e['status'],
        'cor': e['cor'],
        'dataIso': e['dataIso'],
      };
    }).toList();

    // Ordena por data mais próxima
    escalas.sort((a, b) {
      final dataA = DateTime.parse(a['dataIso']);
      final dataB = DateTime.parse(b['dataIso']);
      return dataA.compareTo(dataB);
    });

    return escalas;
  }

  void toggleExpand(int index) {
    expanded[index] = !expanded[index];
  }

  void confirmarEscala(int index) {
    debugPrint('Escala $index confirmada');
  }

  BotaoStatusData getBotaoStatusData(String status) {
    switch (status) {
      case 'aguardando':
        return const BotaoStatusData(
          label: 'Confirmar',
          icon: Icons.check_circle_outline,
          color: Color(0xFF788BF7),
        );
      case 'confirmado':
        return const BotaoStatusData(
          label: 'Fazer check-in',
          icon: Icons.login,
          color: Color(0xFF388E3C),
        );
      case 'finalizado':
        return const BotaoStatusData(
          label: 'Escala concluída',
          icon: Icons.check,
          color: Color(0xFFBDBDBD),
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

  ImageProvider<Object> getImagemPerfil(BuildContext context) {
    final perfilController =
        Provider.of<PerfilController>(context, listen: false);
    return perfilController.imagemPerfilProvider;
  }

  String formatarDia(DateTime data) {
    return DateFormat('dd', 'pt_BR').format(data); // Ex: 15 Jun
  }

  String formatarMes(DateTime data) {
    final mes = DateFormat('MMM', 'pt_BR').format(data); // Ex: Jun
    return mes.replaceAll('.', '');
  }

  String formatarHorario(DateTime data) {
    return DateFormat('HH:mm').format(data); // Ex: 09:00
  }

  String formatarDiaSemana(DateTime data) {
    final dia =  DateFormat('EEE', 'pt_BR').format(data); // Ex: Dom
    return dia.replaceAll('.', '').toUpperCase();
  }

  String formatarDiasRestantes(DateTime data) {
    final agora = DateTime.now();
    final diferenca = data.difference(agora).inDays;
    if (diferenca <= 0) return 'Hoje';
    if (diferenca == 1) return 'Amanhã';
    return 'Em $diferenca dias';
  }
}
