import 'package:flutter/material.dart';
import 'package:servus_app/features/leader/escalas/models/escala_model.dart';
import 'package:servus_app/services/scales_service.dart';
import 'package:servus_app/core/error/notification_service.dart';
import 'package:servus_app/features/leader/escalas/models/template_model.dart';
import 'package:servus_app/features/leader/escalas/models/evento_model.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:dio/dio.dart';

class EscalaController extends ChangeNotifier {
  final List<EscalaModel> _escalas = [];
  final ScalesService _scalesService = ScalesService();
  final Dio _dio = DioClient.instance;
  
  bool _isLoading = false;
  String? _errorMessage;

  // Estado para a tela em formato de matriz
  List<EventoModel> _eventos = [];
  int _selectedEventIndex = 0;
  TemplateModel? _templateSelecionado;

  // Lista de slots linearizada a partir do template selecionado
  // Cada entrada: (functionId, slotIndex, label)
  final List<_FunctionSlot> _slots = [];

  // Atribuições por evento: { eventId: { "functionId_slotIndex": volunteerUserId } }
  final Map<String, Map<String, String?>> _assignmentsByEvent = {};

  // Cache de nomes de voluntários: { userId: userName }
  final Map<String, String> _volunteerNamesCache = {};

  List<EscalaModel> get todas => List.unmodifiable(_escalas);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Listagem simplificada de escalas para tela de lista
  final List<EscalaResumo> _resumo = [];
  List<EscalaResumo> get resumo => List.unmodifiable(_resumo);

  // Exposições para a matriz
  List<EventoModel> get eventos => List.unmodifiable(_eventos);
  int get selectedEventIndex => _selectedEventIndex;
  EventoModel? get selectedEvent =>
      _eventos.isEmpty ? null : _eventos[_selectedEventIndex];
  TemplateModel? get templateSelecionado => _templateSelecionado;
  List<_FunctionSlot> get slots => List.unmodifiable(_slots);

  Map<String, String?> get currentEventAssignments {
    final eventId = selectedEvent?.id;
    if (eventId == null) return const {};
    return _assignmentsByEvent[eventId] ?? {};
  }

  void setEventos(List<EventoModel> eventos, {int initialIndex = 0}) {
    _eventos = List.of(eventos);
    _selectedEventIndex =
        initialIndex.clamp(0, _eventos.isEmpty ? 0 : _eventos.length - 1);
    notifyListeners();
  }

  void selecionarEvento(int index) {
    if (index < 0 || index >= _eventos.length) return;
    _selectedEventIndex = index;
    notifyListeners();
  }

  void setTemplate(TemplateModel template) {
    _templateSelecionado = template;
    _rebuildSlotsFromTemplate();
    notifyListeners();
  }

  void limparTemplate() {
    _templateSelecionado = null;
    _slots.clear();
    notifyListeners();
  }

  void _rebuildSlotsFromTemplate() {
    _slots.clear();
    if (_templateSelecionado == null) return;
    for (final f in _templateSelecionado!.funcoes) {
      for (int i = 0; i < f.quantidade; i++) {
        _slots.add(_FunctionSlot(
          functionId: f.id,
          slotIndex: i,
          label: f.quantidade > 1 ? "${f.nome} #${i + 1}" : f.nome,
        ));
      }
    }
  }

  String _slotKey(String functionId, int slotIndex) => "${functionId}_$slotIndex";

  String? getAssignmentFor(String eventId, String functionId, int slotIndex) {
    final map = _assignmentsByEvent[eventId];
    if (map == null) return null;
    return map[_slotKey(functionId, slotIndex)];
  }

  void assignVolunteer({
    required String eventId,
    required String functionId,
    required int slotIndex,
    required String? volunteerUserId,
    String? volunteerName,
  }) {
    _assignmentsByEvent.putIfAbsent(eventId, () => {});
    _assignmentsByEvent[eventId]![
      _slotKey(functionId, slotIndex)
    ] = volunteerUserId;
    
    // Atualizar cache de nomes
    if (volunteerUserId != null && volunteerName != null) {
      _volunteerNamesCache[volunteerUserId] = volunteerName;
    }
    
    notifyListeners();
  }

  String? getVolunteerName(String? userId) {
    if (userId == null) return null;
    return _volunteerNamesCache[userId];
  }

  void setVolunteerName(String userId, String name) {
    _volunteerNamesCache[userId] = name;
    notifyListeners();
  }

  /// Salva a escalação de um evento específico no backend
  Future<void> salvarEscalacaoPorEvento(String eventId) async {
    if (_templateSelecionado == null || _eventos.isEmpty) {
      throw Exception('Template ou eventos não configurados');
    }

    final evento = _eventos.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw Exception('Evento não encontrado'),
    );

    final assignments = _assignmentsByEvent[eventId] ?? {};
    final escalados = <Map<String, dynamic>>[];

    // Agrupar atribuições por função
    final Map<String, List<String>> functionAssignments = {};
    
    for (final slot in _slots) {
      final slotKey = _slotKey(slot.functionId, slot.slotIndex);
      final volunteerId = assignments[slotKey];
      
      if (volunteerId != null) {
        functionAssignments.putIfAbsent(slot.functionId, () => []);
        functionAssignments[slot.functionId]!.add(volunteerId);
      }
    }

    // Converter para formato do backend
    for (final entry in functionAssignments.entries) {
      escalados.add({
        'functionId': entry.key,
        'functionName': '', // Será obtido do template no backend
        'requiredSlots': functionAssignments[entry.key]!.length,
        'assignedMembers': entry.value,
        'isRequired': true,
      });
    }

    final ministryId = _templateSelecionado!.funcoes.isNotEmpty
        ? _templateSelecionado!.funcoes.first.ministerioId
        : '';

    final eventDate = evento.dataHora;
    final formattedDate = '${eventDate.year.toString().padLeft(4, '0')}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}';
    final formattedTime = '${eventDate.hour.toString().padLeft(2, '0')}:${eventDate.minute.toString().padLeft(2, '0')}';

    bool _isValidObjectId(String? id) {
      if (id == null) return false;
      return RegExp(r'^[0-9a-fA-F]{24}$', caseSensitive: false).hasMatch(id);
    }

    final Map<String, dynamic> payload = {
      'eventId': eventId,
      'ministryId': ministryId,
      'name': 'Escala ${eventDate.day}/${eventDate.month}/${eventDate.year}',
      'description': '',
      'eventDate': formattedDate,
      'eventTime': formattedTime,
      'assignments': escalados,
      'autoAssign': false,
      'allowOverbooking': false,
      'reminderDaysBefore': 7,
    };

    // Enviar templateId somente se for um ObjectId válido
    final maybeTemplateId = _templateSelecionado!.id;
    if (_isValidObjectId(maybeTemplateId)) {
      payload['templateId'] = maybeTemplateId;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _scalesService.create(payload);

      _isLoading = false;
      notifyListeners();

      print('✅ [EscalaController] Escala salva para evento: $eventId');
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();

      print('❌ [EscalaController] Erro ao salvar escala: $e');
      NotificationService().handleGenericError(e);
      rethrow;
    }
  }

  Future<void> adicionar(
    EscalaModel escala, {
    String? overrideMinistryId,
    DateTime? overrideEventDate,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Converter EscalaModel para payload do backend
      final payload = _toPayload(
        escala,
        overrideMinistryId: overrideMinistryId,
        overrideEventDate: overrideEventDate,
      );
      
      // Salvar no backend
      final response = await _scalesService.create(payload);
      
      // Atualizar escala com dados do backend
      final escalaAtualizada = escala.copyWith(
        id: response['_id'] ?? response['id'],
        status: StatusEscala.publicada,
      );
      
      // Adicionar à lista local
      _escalas.add(escalaAtualizada);
      
      _isLoading = false;
      notifyListeners();
      
      print('✅ [EscalaController] Escala salva no backend: ${escalaAtualizada.id}');
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      
      print('❌ [EscalaController] Erro ao salvar escala: $e');
      NotificationService().handleGenericError(e);
      rethrow;
    }
  }

  void atualizar(EscalaModel escalaAtualizada) {
    final index = _escalas.indexWhere((e) => e.id == escalaAtualizada.id);
    if (index != -1) {
      _escalas[index] = escalaAtualizada;
      notifyListeners();
    }
  }

  void remover(String id) {
    _escalas.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void publicarEscala(String id) {
    final index = _escalas.indexWhere((e) => e.id == id);
    if (index != -1) {
      _escalas[index] = _escalas[index].copyWith(status: StatusEscala.publicada);
      notifyListeners();
    }
  }

  List<EscalaModel> listarPorEvento(String eventoId) {
    return _escalas.where((e) => e.eventoId == eventoId).toList();
  }

  EscalaModel? buscarPorId(String id) {
    try {
      return _escalas.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  void limparTudo() {
    _escalas.clear();
    _resumo.clear();
    notifyListeners();
  }

  Future<List<String>> _getLeaderMinistryIds() async {
    try {
      final resp = await _dio.get('/ministry-memberships/me');
      final memberships = (resp.data as List<dynamic>? ?? []);
      final ids = <String>[];
      for (final m in memberships) {
        if (m['isActive'] == true && m['ministry'] != null) {
          final id = m['ministry']['_id']?.toString();
          if (id != null && id.isNotEmpty) ids.add(id);
        }
      }
      return ids;
    } catch (e) {
      return [];
    }
  }

  Future<void> carregarEscalasDoLider() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final ministryIds = await _getLeaderMinistryIds();
      final raw = await _scalesService.listByMinistries(ministryIds: ministryIds, page: 1, limit: 100);

      final parsed = <EscalaResumo>[];
      for (final item in raw) {
        final id = (item['_id'] ?? item['id'])?.toString() ?? '';
        final name = item['name']?.toString() ?? 'Escala';
        DateTime? dt;
        try {
          final d = item['eventDate']?.toString();
          final t = item['eventTime']?.toString() ?? '00:00';
          if (d != null) {
            final base = DateTime.parse(d);
            final parts = t.split(':');
            final hh = int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0;
            final mm = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
            dt = DateTime(base.year, base.month, base.day, hh, mm);
          }
        } catch (_) {}
        final ministryName = item['ministry'] is Map
            ? (item['ministry']['name']?.toString())
            : item['ministryName']?.toString();
        parsed.add(EscalaResumo(id: id, nome: name, ministryName: ministryName, dataHora: dt));
      }

      parsed.sort((a, b) {
        final ad = a.dataHora ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.dataHora ?? DateTime.fromMillisecondsSinceEpoch(0);
        return ad.compareTo(bd);
      });

      _resumo
        ..clear()
        ..addAll(parsed);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Converte EscalaModel para payload do backend
  Map<String, dynamic> _toPayload(
    EscalaModel escala, {
    String? overrideMinistryId,
    DateTime? overrideEventDate,
  }) {
    // Buscar dados do evento para obter data e hora
    // Por enquanto, vamos usar valores padrão - isso precisa ser melhorado
    final agora = DateTime.now();
    final eventDate = overrideEventDate ?? agora;
    final formattedDate = '${eventDate.year.toString().padLeft(4, '0')}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}';
    final formattedTime = '${eventDate.hour.toString().padLeft(2, '0')}:${eventDate.minute.toString().padLeft(2, '0')}';
    
    return {
      'eventId': escala.eventoId,
      'ministryId': overrideMinistryId ?? '', // Preferir valor do template
      'templateId': escala.templateId,
      'name': 'Escala ${eventDate.day}/${eventDate.month}',
      'description': '',
      'eventDate': formattedDate, // YYYY-MM-DD
      'eventTime': formattedTime, // HH:mm
      'assignments': escala.escalados.map((escalado) => {
        'functionId': escalado.funcaoId,
        'functionName': '', // Será obtido do template no backend
        'requiredSlots': 1,
        'assignedMembers': [escalado.voluntarioId],
        'isRequired': true,
      }).toList(),
      'autoAssign': false,
      'allowOverbooking': false,
      'reminderDaysBefore': 7,
    };
  }
}

class EscalaResumo {
  final String id;
  final String nome;
  final String? ministryName;
  final DateTime? dataHora;

  EscalaResumo({
    required this.id,
    required this.nome,
    this.ministryName,
    this.dataHora,
  });
}

// Removida extensão extra para evitar avisos de linter

// Slot linearizado para renderização
class _FunctionSlot {
  final String functionId;
  final int slotIndex;
  final String label;

  const _FunctionSlot({
    required this.functionId,
    required this.slotIndex,
    required this.label,
  });
}