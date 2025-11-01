import 'dart:async';
import 'package:servus_app/features/leader/escalas/models/escala.dart';
import 'package:servus_app/features/leader/escalas/models/escala_status.dart';
import 'package:servus_app/features/leader/escalas/models/funcao_preenchida.dart';
import 'package:servus_app/services/scales_service.dart';
import 'package:servus_app/services/events_service.dart';
import 'package:servus_app/core/models/event.dart';
import 'dart:developer' as developer;

class EscalasRepository {
  final ScalesService _scalesService = ScalesService();
  final EventsService _eventsService = EventsService();

  // Stream de escalas com filtros opcionais
  Stream<List<Escala>> buscarEscalasStream({
    DateTime? dataInicio,
    DateTime? dataFim,
    List<EscalaStatus>? status,
  }) async* {
    try {
      while (true) {
        final escalas = await _buscarEscalas(
          dataInicio: dataInicio,
          dataFim: dataFim,
          status: status,
        );
        yield escalas;
        await Future.delayed(const Duration(seconds: 5)); // Atualizar a cada 5s
      }
    } catch (e) {
      developer.log('❌ [EscalasRepository] Erro no stream: $e', name: 'EscalasRepository');
      rethrow;
    }
  }

  Future<List<Escala>> _buscarEscalas({
    DateTime? dataInicio,
    DateTime? dataFim,
    List<EscalaStatus>? status,
  }) async {
    try {
      // Se houver múltiplos status, buscar todas e filtrar localmente
      // Se houver um único status, passar para o backend
      String? statusFilter;
      if (status != null && status.length == 1) {
        statusFilter = status.first.name;
      }
      
      // Buscar escalas do backend
      final response = await _scalesService.list(
        page: 1,
        limit: 1000, // Buscar todas para filtrar localmente
        status: statusFilter,
      );

      final items = (response['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      // Pré-processo: quando eventId vier populado como objeto, não precisamos buscar por ID
      final eventosMap = <String, EventModel>{};

      final escalas = <Escala>[];

      for (final item in items) {
        try {
          final escala = await _converterItemParaEscala(item, eventosMap);
          
          // Aplicar filtros de data
          if (dataInicio != null && escala.eventoData.isBefore(dataInicio)) {
            continue;
          }
          if (dataFim != null && escala.eventoData.isAfter(dataFim)) {
            continue;
          }
          
          // Aplicar filtros de status (se múltiplos ou nenhum passado, filtrar localmente)
          if (status != null && status.isNotEmpty) {
            if (!status.contains(escala.status)) {
              continue;
            }
          }

          escalas.add(escala);
        } catch (e) {
          developer.log('⚠️ [EscalasRepository] Erro ao converter escala: $e', name: 'EscalasRepository');
        }
      }

      return escalas;
    } catch (e) {
      developer.log('❌ [EscalasRepository] Erro ao buscar escalas: $e', name: 'EscalasRepository');
      return [];
    }
  }

  Future<Escala> _converterItemParaEscala(
    Map<String, dynamic> item,
    Map<String, EventModel> eventosMap,
  ) async {
    final dynamic eventRef = item['eventId'];
    String eventId = '';
    String eventoNome = item['name']?.toString() ?? 'Evento';
    DateTime? eventoDataFromItem;
    DateTime? eventoDataFromRef;

    // Se a escala retornou com eventId populado
    if (eventRef is Map<String, dynamic>) {
      eventId = eventRef['_id']?.toString() ?? '';
      eventoNome = eventRef['name']?.toString() ?? eventoNome;
      try {
        if (eventRef['eventDate'] != null) {
          final d = DateTime.parse(eventRef['eventDate'].toString());
          final t = (eventRef['eventTime']?.toString() ?? '00:00').split(':');
          final hh = int.tryParse(t.isNotEmpty ? t[0] : '0') ?? 0;
          final mm = int.tryParse(t.length > 1 ? t[1] : '0') ?? 0;
          eventoDataFromRef = DateTime(d.year, d.month, d.day, hh, mm);
        }
      } catch (_) {}
    } else if (eventRef is String) {
      eventId = eventRef;
    }

    final assignments = (item['assignments'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    final funcoes = assignments.map<FuncaoPreenchida>((assignment) {
      final functionId = assignment['functionId']?.toString() ?? '';
      final functionName = assignment['functionName']?.toString() ?? '';
      final assignedMembers = (assignment['assignedMembers'] as List<dynamic>? ?? [])
          .cast<String>();

      return FuncaoPreenchida(
        funcaoId: functionId,
        funcaoNome: functionName,
        voluntarioId: assignedMembers.isNotEmpty ? assignedMembers.first : null,
        voluntarioNome: null, // Será preenchido depois se necessário
      );
    }).toList();

    final statusStr = item['status']?.toString() ?? 'draft';
    final status = EscalaStatus.fromString(statusStr) ?? EscalaStatus.rascunho;

    DateTime? dataPublicacao;
    if (item['dataPublicacao'] != null) {
      try {
        dataPublicacao = DateTime.parse(item['dataPublicacao']);
      } catch (_) {}
    }

    // Tentar montar a data a partir do próprio item
    if (item['eventDate'] != null) {
      try {
        final d = DateTime.parse(item['eventDate'].toString());
        final t = (item['eventTime']?.toString() ?? '00:00').split(':');
        final hh = int.tryParse(t.isNotEmpty ? t[0] : '0') ?? 0;
        final mm = int.tryParse(t.length > 1 ? t[1] : '0') ?? 0;
        eventoDataFromItem = DateTime(d.year, d.month, d.day, hh, mm);
      } catch (_) {}
    }

    DateTime eventoData = eventoDataFromRef ?? eventoDataFromItem ?? DateTime.now();

    return Escala(
      id: item['_id']?.toString() ?? item['id']?.toString() ?? '',
      eventoId: eventId,
      eventoNome: eventoNome,
      eventoData: eventoData,
      funcoes: funcoes,
      status: status,
      dataPublicacao: dataPublicacao,
      temTemplate: item['templateId'] != null,
    );
  }

  // Salvar rascunho (usado no auto-save)
  Future<void> salvarRascunho(Escala escala) async {
    try {
      final payload = _escalaParaPayload(escala);
      
      if (escala.id.isEmpty || !(await _idExiste(escala.id))) {
        // Criar nova
        final response = await _scalesService.create(payload);
        developer.log('✅ [EscalasRepository] Rascunho criado: ${response['_id']}', name: 'EscalasRepository');
      } else {
        // Atualizar existente
        await _scalesService.update(escala.id, payload);
        developer.log('✅ [EscalasRepository] Rascunho atualizado: ${escala.id}', name: 'EscalasRepository');
      }
    } catch (e) {
      developer.log('❌ [EscalasRepository] Erro ao salvar rascunho: $e', name: 'EscalasRepository');
      rethrow;
    }
  }

  Future<bool> _idExiste(String id) async {
    try {
      await _scalesService.getById(id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _escalaParaPayload(Escala escala) {
    final formattedDate = '${escala.eventoData.year.toString().padLeft(4, '0')}-${escala.eventoData.month.toString().padLeft(2, '0')}-${escala.eventoData.day.toString().padLeft(2, '0')}';
    final formattedTime = '${escala.eventoData.hour.toString().padLeft(2, '0')}:${escala.eventoData.minute.toString().padLeft(2, '0')}';

    final assignments = escala.funcoes.map((funcao) {
      return {
        'functionId': funcao.funcaoId,
        'functionName': funcao.funcaoNome,
        'requiredSlots': 1,
        'assignedMembers': funcao.voluntarioId != null ? [funcao.voluntarioId] : [],
        'isRequired': true,
      };
    }).toList();

    return {
      'eventId': escala.eventoId,
      'name': escala.eventoNome,
      'description': '',
      'eventDate': formattedDate,
      'eventTime': formattedTime,
      'assignments': assignments,
      'status': escala.status.name,
      'autoAssign': false,
      'allowOverbooking': false,
      'reminderDaysBefore': 7,
    };
  }

  // Marcar como pronto
  Future<void> marcarComoPronto(String escalaId) async {
    try {
      final escala = await _buscarEscalaPorId(escalaId);
      if (escala == null) {
        throw Exception('Escala não encontrada');
      }

      final escalaAtualizada = escala.copyWith(status: EscalaStatus.pronto);
      await salvarRascunho(escalaAtualizada);
      
      developer.log('✅ [EscalasRepository] Escala marcada como pronta: $escalaId', name: 'EscalasRepository');
    } catch (e) {
      developer.log('❌ [EscalasRepository] Erro ao marcar como pronto: $e', name: 'EscalasRepository');
      rethrow;
    }
  }

  Future<Escala?> _buscarEscalaPorId(String id) async {
    try {
      final item = await _scalesService.getById(id);
      final eventId = item['eventId']?.toString();
      final eventosMap = <String, EventModel>{};
      
      if (eventId != null) {
        try {
          final evento = await _eventsService.getById(eventId);
          eventosMap[eventId] = evento;
        } catch (_) {}
      }
      
      return await _converterItemParaEscala(item, eventosMap);
    } catch (_) {
      return null;
    }
  }

  // Publicar múltiplas escalas em batch
  Future<void> publicarEscalas(List<String> escalaIds) async {
    try {
      for (final id in escalaIds) {
        try {
          await _scalesService.publish(id);
          developer.log('✅ [EscalasRepository] Escala publicada: $id', name: 'EscalasRepository');
        } catch (e) {
          developer.log('⚠️ [EscalasRepository] Erro ao publicar escala $id: $e', name: 'EscalasRepository');
        }
      }
    } catch (e) {
      developer.log('❌ [EscalasRepository] Erro ao publicar escalas: $e', name: 'EscalasRepository');
      rethrow;
    }
  }

  // Carregar funções do template ou padrão
  Future<List<FuncaoPreenchida>> carregarFuncoes(String eventoId) async {
    try {
      // Buscar evento para ver se tem template
      final evento = await _eventsService.getById(eventoId);
      final templateId = evento.templateId;

      if (templateId != null && templateId.isNotEmpty) {
        // Carregar funções do template
        // TODO: Implementar quando tiver acesso ao template service
      }

      // Retornar funções padrão baseadas no ministério do evento
      return [];
    } catch (e) {
      developer.log('❌ [EscalasRepository] Erro ao carregar funções: $e', name: 'EscalasRepository');
      return [];
    }
  }
}
