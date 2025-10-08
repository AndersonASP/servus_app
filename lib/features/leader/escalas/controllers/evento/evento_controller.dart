import 'package:flutter/material.dart';
import 'package:servus_app/services/events_service.dart';
import 'package:servus_app/core/models/event_instance.dart';
import '../../models/evento_model.dart';
import 'dart:developer' as developer;

class EventoController extends ChangeNotifier {
  final List<EventoModel> _eventos = [];
  final EventsService _service = EventsService();
  bool _isLoading = false;
  String? _error;

  List<EventoModel> get todos => List.unmodifiable(_eventos);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> carregarEventos({int page = 1, int limit = 20}) async {
    developer.log('🔄 Carregando eventos - página: $page, limite: $limit', name: 'EventoController');
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final data = await _service.list(page: page, limit: limit);
      developer.log('📡 Resposta do serviço: ${data.toString()}', name: 'EventoController');
      final items = (data['items'] as List? ?? []);
      developer.log('📋 Total de itens recebidos: ${items.length}', name: 'EventoController');

      _eventos.clear();
      for (final e in items) {
        final nome = e['name']?.toString() ?? '';
        final eventDateStr = e['eventDate']?.toString();
        final eventTimeStr = e['eventTime']?.toString() ?? '00:00';
        developer.log('📅 Processando evento: $nome, data: $eventDateStr, hora: $eventTimeStr', name: 'EventoController');
        
        DateTime dataHora;
        try {
          final base = DateTime.parse(eventDateStr ?? DateTime.now().toIso8601String());
          final parts = eventTimeStr.split(':');
          final hh = int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0;
          final mm = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
          dataHora = DateTime(base.year, base.month, base.day, hh, mm);
          developer.log('✅ Data/hora processada: ${dataHora.toIso8601String()}', name: 'EventoController');
        } catch (error) {
          developer.log('❌ Erro ao processar data/hora: $error', name: 'EventoController');
          dataHora = DateTime.now();
        }

        final recorrenciaTipoStr = e['recurrenceType']?.toString() ?? 'none';
        final recorrenciaTipo = _mapRecurrenceType(recorrenciaTipoStr);
        final diasSemanaAny = (e['recurrencePattern'] != null ? e['recurrencePattern']['daysOfWeek'] : null);
        int? diaSemana;
        if (diasSemanaAny is List && diasSemanaAny.isNotEmpty) {
          final first = diasSemanaAny.first;
          if (first is int) {
            diaSemana = first;
          } else if (first is String) {
            diaSemana = int.tryParse(first);
          }
        }
        final semanaAny = (e['recurrencePattern'] != null ? e['recurrencePattern']['dayOfMonth'] : null);
        int? semanaDoMes;
        if (semanaAny is int) {
          semanaDoMes = semanaAny;
        } else if (semanaAny is String) {
          semanaDoMes = int.tryParse(semanaAny);
        }
        
        developer.log('🔄 Recorrência: $recorrenciaTipoStr -> $recorrenciaTipo, diaSemana: $diaSemana, semanaDoMes: $semanaDoMes', name: 'EventoController');

        _eventos.add(EventoModel(
          id: (e['_id'] ?? e['id'])?.toString(),
          nome: nome,
          dataHora: dataHora,
          ministerioId: e['ministryId']?.toString() ?? '',
          isOrdinary: e['isOrdinary'] ?? false,
          recorrente: recorrenciaTipo != RecorrenciaTipo.nenhum,
          tipoRecorrencia: recorrenciaTipo,
          diaSemana: recorrenciaTipo == RecorrenciaTipo.semanal ? diaSemana : null,
          semanaDoMes: recorrenciaTipo == RecorrenciaTipo.mensal ? semanaDoMes : null,
          observacoes: e['specialNotes']?.toString(),
        ));
      }
      developer.log('✅ Total de eventos carregados: ${_eventos.length}', name: 'EventoController');
    } catch (e) {
      developer.log('❌ Erro ao carregar eventos: $e', name: 'EventoController');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Adiciona novo evento
  Future<void> adicionarEvento(EventoModel evento, {String? templateId}) async {
    developer.log('➕ Adicionando novo evento: ${evento.nome}', name: 'EventoController');
    developer.log('📅 Data/hora: ${evento.dataHora.toIso8601String()}', name: 'EventoController');
    developer.log('🔄 Tipo recorrência: ${evento.tipoRecorrencia}', name: 'EventoController');
    
    final payload = _toPayload(evento);
    developer.log('📤 Payload enviado: ${payload.toString()}', name: 'EventoController');
    // Fallback de log caso developer.log não apareça no console
    // ignore: avoid_print
    print('[EventoController] Payload enviado: ${payload.toString()}');
    
    if (templateId != null && templateId.isNotEmpty) {
      payload['templateId'] = templateId;
      developer.log('📋 Template ID adicionado: $templateId', name: 'EventoController');
    }
    
    try {
      final created = await _service.create(payload);
      developer.log('✅ Evento criado com sucesso: ${created.id}', name: 'EventoController');
      // ignore: avoid_print
      print('[EventoController] Evento criado com sucesso: ${created.id}');
      // Recarregar recorrências do mês do evento com pequenas tentativas (evita race conditions)
      await _refreshRecurrencesAfterChange(evento.dataHora);
      
      // Converte EventModel para EventoModel e adiciona à lista local
      final novoEvento = _convertFromEventModel(created);
      _eventos.add(novoEvento);
      developer.log('📝 Evento adicionado à lista local. Total: ${_eventos.length}', name: 'EventoController');
      notifyListeners();
    } catch (e) {
      developer.log('❌ Erro ao criar evento: $e', name: 'EventoController');
      // ignore: avoid_print
      print('[EventoController] Erro ao criar evento: $e');
      rethrow;
    }
  }

  Future<void> _refreshRecurrencesAfterChange(DateTime referenceDate) async {
    final ed = referenceDate.toUtc();
    final m = ed.month;
    final y = ed.year;
    int attempts = 0;
    while (attempts < 3) {
      try {
        await carregarRecorrencias(
          monthNumber: m,
          year: y,
          status: 'published',
        );
        break;
      } catch (e) {
        attempts += 1;
        await Future.delayed(const Duration(milliseconds: 250));
      }
    }
  }

  // Atualiza um evento existente
  Future<void> atualizarEvento(EventoModel eventoAtualizado) async {
    if (eventoAtualizado.id.isEmpty) return;
    final payload = _toPayload(eventoAtualizado);
    await _service.update(eventoAtualizado.id, payload);
    final index = _eventos.indexWhere((e) => e.id == eventoAtualizado.id);
    if (index != -1) {
      _eventos[index] = eventoAtualizado;
      notifyListeners();
    }
  }

  // Remove um evento
  Future<void> removerEvento(String id) async {
    await _service.remove(id);
    _eventos.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // Pula (cancela) uma ocorrência específica de um evento recorrente
  Future<void> pularOcorrencia({
    required String eventId,
    required DateTime instanceDate,
  }) async {
    await _service.skipInstance(eventId: eventId, instanceDate: instanceDate);
  }

  // Encerra a série após (e incluindo) uma data
  Future<void> encerrarSerieApos({
    required String eventId,
    required DateTime fromDate,
  }) async {
    await _service.cancelSeriesAfter(eventId: eventId, fromDate: fromDate);
  }

  // Filtrar eventos por ministério
  List<EventoModel> filtrarPorMinisterio(String ministerioId) {
    return _eventos.where((e) => e.ministerioId == ministerioId).toList();
  }

  // Listar apenas eventos futuros
  List<EventoModel> get eventosFuturos {
    return _eventos.where((e) => e.dataHora.isAfter(DateTime.now())).toList();
  }

  // Buscar evento por ID
  EventoModel? buscarPorId(String id) {
    try {
      return _eventos.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  // Limpa tudo (útil para testes)
  void limparEventos() {
    _eventos.clear();
    notifyListeners();
  }

  // Carrega recorrências para um mês específico
  Future<List<EventInstanceModel>> carregarRecorrencias({
    String? month, // formato: YYYY-MM (ex: 2024-01)
    int? monthNumber, // 1-12
    int? year, // 2020-2030
    String? ministryId,
    String? status,
  }) async {
    developer.log('🔄 Carregando recorrências - mês: $month, monthNumber: $monthNumber, year: $year', name: 'EventoController');
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final data = await _service.getRecurrences(
        month: month,
        monthNumber: monthNumber,
        year: year,
        ministryId: ministryId,
        status: status,
      );
      
      developer.log('📡 Resposta das recorrências: ${data.toString()}', name: 'EventoController');
      
      final instances = (data['instances'] as List? ?? []);
      developer.log('📋 Total de instâncias recebidas: ${instances.length}', name: 'EventoController');
      developer.log('🔍 Fonte dos dados: ${data['source']}', name: 'EventoController');

      final eventInstances = <EventInstanceModel>[];
      
      for (final instance in instances) {
        try {
          developer.log('🔍 Processando instância: ${instance.toString()}', name: 'EventoController');
          final eventInstance = EventInstanceModel.fromMap(instance);
          eventInstances.add(eventInstance);
          developer.log('✅ Instância processada: ${eventInstance.instanceDate.toIso8601String()}, eventId: ${eventInstance.eventId}', name: 'EventoController');
        } catch (e) {
          developer.log('❌ Erro ao processar instância: $e', name: 'EventoController');
          developer.log('❌ Dados da instância: ${instance.toString()}', name: 'EventoController');
        }
      }
      
      developer.log('✅ Total de instâncias processadas: ${eventInstances.length}', name: 'EventoController');
      return eventInstances;
      
    } catch (e) {
      developer.log('❌ Erro ao carregar recorrências: $e', name: 'EventoController');
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> _toPayload(EventoModel e) {
    developer.log('🔧 Criando payload para evento: ${e.nome}', name: 'EventoController');
    
    // Validações básicas
    if (e.nome.isEmpty) {
      throw Exception('Nome do evento é obrigatório');
    }
    if (e.dataHora.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      developer.log('⚠️ Aviso: Evento no passado', name: 'EventoController');
    }
    
    final date = e.dataHora;
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    
    developer.log('📅 Data original: ${date.toIso8601String()}', name: 'EventoController');
    developer.log('⏰ Hora formatada: $hh:$mm', name: 'EventoController');

    final payload = <String, dynamic>{
      'name': e.nome,
      'eventDate': DateTime(date.year, date.month, date.day).toIso8601String(),
      'eventTime': '$hh:$mm',
      'recurrenceType': _mapRecorrenciaToBackend(e.tipoRecorrencia),
      'eventType': 'global', // Tenant admin sempre cria eventos globais
      'isGlobal': true, // Tenant admin sempre cria eventos globais
      'isOrdinary': e.isOrdinary,
      'status': 'published', // Status padrão para novos eventos
      if (e.observacoes != null && e.observacoes!.isNotEmpty) 'specialNotes': e.observacoes,
    };
    developer.log('🧱 Payload base criado', name: 'EventoController');
    developer.log('🧱 recurrenceType: ${payload['recurrenceType']}', name: 'EventoController');
    developer.log('🧱 specialNotes: ${payload['specialNotes']}', name: 'EventoController');

    // Adicionar ministryId apenas se não estiver vazio
    if (e.ministerioId.isNotEmpty) {
      payload['ministryId'] = e.ministerioId;
      developer.log('🏛️ Ministry ID adicionado: ${e.ministerioId}', name: 'EventoController');
    }

    if (e.tipoRecorrencia == RecorrenciaTipo.diario) {
      developer.log('↪️ Montando recurrencePattern diário', name: 'EventoController');
      // Definir padrão diário com interval default 1 (pode ser estendido futuramente)
      payload['recurrencePattern'] = {
        'interval': 1,
      };
      developer.log('📅 Padrão diário adicionado: interval 1', name: 'EventoController');
    } else if (e.tipoRecorrencia == RecorrenciaTipo.semanal) {
      developer.log('↪️ Montando recurrencePattern semanal', name: 'EventoController');
      if (e.diaSemana == null) {
        throw Exception('Dia da semana é obrigatório para eventos semanais');
      }
      if (e.diaSemana! < 0 || e.diaSemana! > 6) {
        throw Exception('Dia da semana deve estar entre 0 (domingo) e 6 (sábado)');
      }
      payload['recurrencePattern'] = {
        'interval': 1,
        'daysOfWeek': [e.diaSemana],
      };
      developer.log('📅 Padrão semanal adicionado: dia ${e.diaSemana}', name: 'EventoController');
      developer.log('📅 Payload recurrencePattern: ${payload['recurrencePattern']}', name: 'EventoController');
    } else if (e.tipoRecorrencia == RecorrenciaTipo.mensal) {
      developer.log('↪️ Montando recurrencePattern mensal', name: 'EventoController');
      if (e.semanaDoMes == null) {
        throw Exception('Semana do mês é obrigatória para eventos mensais');
      }
      if (e.semanaDoMes! < 1 || e.semanaDoMes! > 5) {
        throw Exception('Semana do mês deve estar entre 1 e 5');
      }
      
      // Para eventos mensais, usar o dia da semana da data original
      final diaSemanaOriginal = e.dataHora.weekday % 7; // Converte weekday (1-7) para (0-6)
      
      payload['recurrencePattern'] = {
        'interval': 1,
        'weekOfMonth': e.semanaDoMes, // 1-5 (primeira, segunda, etc.)
        'dayOfWeek': diaSemanaOriginal, // 0-6 (domingo, segunda, etc.)
      };
      developer.log('📅 Padrão mensal adicionado: semana ${e.semanaDoMes}, dia da semana $diaSemanaOriginal', name: 'EventoController');
    }

    // Adicionar data limite se definida
    if (e.dataLimiteRecorrencia != null) {
      // Garantir que recurrencePattern exista antes de setar endDate
      final existedBefore = payload['recurrencePattern'] != null;
      developer.log('⏱️ Tentando setar endDate; recurrencePattern existe antes? $existedBefore', name: 'EventoController');
      payload['recurrencePattern'] ??= {};
      final end = e.dataLimiteRecorrencia!;
      final endOnlyDate = DateTime(end.year, end.month, end.day).toIso8601String();
      payload['recurrencePattern']['endDate'] = endOnlyDate;
      developer.log('📅 Data limite adicionada: ${e.dataLimiteRecorrencia!.toIso8601String()}', name: 'EventoController');
    }

    developer.log('📦 Payload final: ${payload.toString()}', name: 'EventoController');
    // Coerção final: garantir tipos numéricos corretos no recurrencePattern
    try {
      if (payload['recurrencePattern'] != null) {
        final rp = payload['recurrencePattern'] as Map<String, dynamic>;
        int? toInt(dynamic v) {
          if (v == null) return null;
          if (v is int) return v;
          if (v is String) return int.tryParse(v);
          return null;
        }
        List<int>? toIntList(dynamic v) {
          if (v == null) return null;
          if (v is List) {
            final out = <int>[];
            for (final item in v) {
              final parsed = toInt(item);
              if (parsed != null) out.add(parsed);
            }
            return out;
          }
          return null;
        }

        if (rp.containsKey('interval')) {
          final val = toInt(rp['interval']);
          if (val != null) {
            rp['interval'] = val;
          } else {
            rp.remove('interval');
          }
        }
        if (rp.containsKey('dayOfMonth')) {
          final val = toInt(rp['dayOfMonth']);
          if (val != null) {
            rp['dayOfMonth'] = val;
          } else {
            rp.remove('dayOfMonth');
          }
        }
        if (rp.containsKey('occurrences')) {
          final val = toInt(rp['occurrences']);
          if (val != null) {
            rp['occurrences'] = val;
          } else {
            rp.remove('occurrences');
          }
        }
        if (rp.containsKey('daysOfWeek')) {
          final list = toIntList(rp['daysOfWeek']);
          if (list != null) {
            rp['daysOfWeek'] = list;
          } else {
            rp.remove('daysOfWeek');
          }
        }
        payload['recurrencePattern'] = rp;
      }
    } catch (err) {
      developer.log('⚠️ Falha ao coagir recurrencePattern: $err', name: 'EventoController');
    }

    developer.log('📦 Payload coerced: ${payload.toString()}', name: 'EventoController');
    // Se diário, garantir que não enviamos campos que não se aplicam
    if (payload['recurrenceType'] == 'daily') {
      final rp = payload['recurrencePattern'] as Map<String, dynamic>?;
      if (rp != null) {
        rp.remove('daysOfWeek');
        rp.remove('dayOfMonth');
        payload['recurrencePattern'] = rp;
      }
    }
    // fallback print
    // ignore: avoid_print
    print('[EventoController] Payload coerced: ${payload.toString()}');
    return payload;
  }

  RecorrenciaTipo _mapRecurrenceType(String value) {
    if (value == 'daily') return RecorrenciaTipo.diario;
    if (value == 'weekly') return RecorrenciaTipo.semanal;
    if (value == 'monthly') return RecorrenciaTipo.mensal;
    return RecorrenciaTipo.nenhum;
  }

  String _mapRecorrenciaToBackend(RecorrenciaTipo tipo) {
    if (tipo == RecorrenciaTipo.diario) return 'daily';
    if (tipo == RecorrenciaTipo.semanal) return 'weekly';
    if (tipo == RecorrenciaTipo.mensal) return 'monthly';
    return 'none';
  }

  // Converte EventModel (do serviço) para EventoModel (do app)
  EventoModel _convertFromEventModel(dynamic eventModel) {
    developer.log('🔄 Convertendo EventModel para EventoModel: ${eventModel.name}', name: 'EventoController');
    
    final eventDateStr = eventModel.eventDate?.toString();
    final eventTimeStr = eventModel.eventTime?.toString() ?? '00:00';
    developer.log('📅 Data/hora recebida: $eventDateStr, $eventTimeStr', name: 'EventoController');
    
    DateTime dataHora;
    try {
      final base = DateTime.parse(eventDateStr ?? DateTime.now().toIso8601String());
      final parts = eventTimeStr.split(':');
      final hh = int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0;
      final mm = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      dataHora = DateTime(base.year, base.month, base.day, hh, mm);
      developer.log('✅ Data/hora convertida: ${dataHora.toIso8601String()}', name: 'EventoController');
    } catch (error) {
      developer.log('❌ Erro ao converter data/hora: $error', name: 'EventoController');
      dataHora = DateTime.now();
    }

    final recorrenciaTipo = _mapRecurrenceType(eventModel.recurrenceType ?? 'none');
    // Coerção segura para dias da semana e semana do mês (podem vir como string)
    int? coerceInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }
    int? diaSemana;
    final diasSemanaDyn = eventModel.recurrencePattern?.daysOfWeek;
    if (diasSemanaDyn is List && diasSemanaDyn.isNotEmpty) {
      diaSemana = coerceInt(diasSemanaDyn.first);
    }
    final semanaDoMes = coerceInt(eventModel.recurrencePattern?.dayOfMonth);
    
    developer.log('🔄 Recorrência convertida: ${eventModel.recurrenceType} -> $recorrenciaTipo', name: 'EventoController');
    developer.log('📅 Dia da semana: $diaSemana, Semana do mês: $semanaDoMes', name: 'EventoController');

    final eventoConvertido = EventoModel(
      id: eventModel.id,
      nome: eventModel.name ?? '',
      dataHora: dataHora,
      ministerioId: eventModel.ministryId ?? '',
      isOrdinary: eventModel.isOrdinary ?? false,
      recorrente: recorrenciaTipo != RecorrenciaTipo.nenhum,
      tipoRecorrencia: recorrenciaTipo,
      diaSemana: recorrenciaTipo == RecorrenciaTipo.semanal ? diaSemana : null,
      semanaDoMes: recorrenciaTipo == RecorrenciaTipo.mensal ? semanaDoMes : null,
      observacoes: eventModel.specialNotes,
    );
    
    developer.log('✅ EventoModel criado: ${eventoConvertido.nome}', name: 'EventoController');
    return eventoConvertido;
  }
}