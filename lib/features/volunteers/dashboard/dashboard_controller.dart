import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:servus_app/core/models/usuario_logado.dart';
import 'package:servus_app/state/auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:servus_app/features/volunteers/dashboard/models/botao_status_model.dart';

enum TesteEscalaModo { nenhuma, uma, varias }

TesteEscalaModo modoTeste = TesteEscalaModo.varias;

class DashboardController extends ChangeNotifier {
  final AuthState auth;
  final List<bool> expanded = List.generate(4, (_) => false);

  int _qtdEscalas = 0;
  int get qtdEscalas => _qtdEscalas;
  List<Map<String, dynamic>> escalas = [];

  bool isLoading = true;
  bool isInitialized = false;
  bool showOverlay = false;

  late UsuarioLogado usuario;

  DashboardController({required this.auth});

  Future<void> init() async {
    showOverlay = true;
    isLoading = true;
    notifyListeners();

    await Future.wait([
      carregarNome(),
      carregarEscalasComQtd(),
    ]);

    showOverlay = false;
    isLoading = false;
    isInitialized = true;
    notifyListeners();
  }

  Future<void> carregarNome() async {
    usuario = auth.usuario!;
  }

  Future<void> carregarEscalasComQtd() async {
    final data = await fetchEscalas();
    escalas = data;
    _qtdEscalas = data.length;
  }

  Future<void> refresh() async {
    isLoading = true;
    notifyListeners();

    await carregarEscalasComQtd();

    isLoading = false;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> fetchEscalas() async {
    await Future.delayed(const Duration(seconds: 2)); // simula delay da API

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
      final index = entry.key;
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

    escalas.sort((a, b) {
      final dataA = DateTime.parse(a['dataIso']);
      final dataB = DateTime.parse(b['dataIso']);
      return dataA.compareTo(dataB);
    });

    return escalas;
  }

  void toggleExpand(int index) {
    expanded[index] = !expanded[index];
    notifyListeners();
  }

  void confirmarEscala(int index) {
    debugPrint('Escala $index confirmada');
  }

  BotaoStatusData getBotaoStatusData(String status, BuildContext context) {
    switch (status) {
      case 'aguardando':
        return BotaoStatusData(
          label: 'Confirmar',
          icon: Icons.check_circle,
          color: Theme.of(context).canvasColor,
        );
      case 'confirmado':
        return const BotaoStatusData(
          label: 'Fazer check-in',
          icon: Icons.qr_code_scanner,
          color: Color(0xFF1E8E3E),
        );
      case 'finalizado':
        return const BotaoStatusData(
          label: 'Escala concluída',
          icon: Icons.check,
          color: Color(0xFFBDBDBD),
          enabled: false,
        );
      default:
        return BotaoStatusData(
          label: 'Confirmar',
          icon: Icons.check_circle_outline,
          color: Theme.of(context).canvasColor,
        );
    }
  }

  String formatarDia(DateTime data) => DateFormat('dd', 'pt_BR').format(data);

  String formatarMes(DateTime data) =>
      DateFormat('MMM', 'pt_BR').format(data).replaceAll('.', '');

  String formatarHorario(DateTime data) => DateFormat('HH:mm').format(data);

  String formatarDiaSemana(DateTime data) =>
      DateFormat('EEE', 'pt_BR').format(data).replaceAll('.', '').toUpperCase();

  String formatarDiasRestantes(DateTime data) {
    final agora = DateTime.now();
    final diferenca = data.difference(agora).inDays;
    if (diferenca <= 0) return 'Hoje';
    if (diferenca == 1) return 'Amanhã';
    return 'Em $diferenca dias';
  }
}
