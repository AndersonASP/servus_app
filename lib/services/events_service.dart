import 'package:dio/dio.dart';
import 'package:servus_app/core/models/event.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:servus_app/services/auth_context_service.dart';
import 'dart:developer' as developer;

class EventsService {
  final Dio _dio = DioClient.instance;
  final AuthContextService _auth = AuthContextService.instance;

  EventsService() {
    // Removido interceptor duplicado - AuthInterceptor global já cuida da autenticação
    developer.log('🔧 [EventsService] EventsService inicializado sem interceptor duplicado', name: 'EventsService');
  }

  String _basePath({String? branchId}) {
    final tenantId = _auth.tenantId!;
    final bId = branchId ?? _auth.branchId;
    if (bId != null && bId.isNotEmpty) {
      return '/tenants/$tenantId/branches/$bId/events';
    }
    // Para tenant admin (sem branch), usar rota direta
    return '/tenants/$tenantId/events';
  }

  Future<Map<String, dynamic>> list({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? eventType,
    bool? isOrdinary,
  }) async {
    final response = await _dio.get(
      _basePath(),
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null) 'status': status,
        if (eventType != null) 'eventType': eventType,
        if (isOrdinary != null) 'isOrdinary': isOrdinary,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<EventModel> create(Map<String, dynamic> payload) async {
    developer.log('📤 [EventsService] Método create chamado', name: 'EventsService');
    
    final path = _basePath();
    developer.log('📤 [EventsService] Criando evento em: $path', name: 'EventsService');
    developer.log('📦 [EventsService] Payload: ${payload.toString()}', name: 'EventsService');
    
    try {
      developer.log('🚀 [EventsService] Fazendo requisição POST...', name: 'EventsService');
      final response = await _dio.post(path, data: payload);
      developer.log('✅ [EventsService] Evento criado com sucesso: ${response.statusCode}', name: 'EventsService');
      developer.log('📊 [EventsService] Resposta: ${response.data}', name: 'EventsService');
      return EventModel.fromMap(response.data as Map<String, dynamic>);
    } catch (e) {
      developer.log('❌ [EventsService] Erro ao criar evento: $e', name: 'EventsService');
      if (e is DioException) {
        developer.log('📊 [EventsService] Status: ${e.response?.statusCode}', name: 'EventsService');
        developer.log('📊 [EventsService] Headers: ${e.response?.headers}', name: 'EventsService');
        developer.log('📊 [EventsService] Data: ${e.response?.data}', name: 'EventsService');
        developer.log('📊 [EventsService] Request Headers: ${e.requestOptions.headers}', name: 'EventsService');
      }
      rethrow;
    }
  }

  Future<EventModel> getById(String id) async {
    final response = await _dio.get('${_basePath()}/$id');
    return EventModel.fromMap(response.data as Map<String, dynamic>);
  }

  Future<EventModel> update(String id, Map<String, dynamic> payload) async {
    final response = await _dio.patch('${_basePath()}/$id', data: payload);
    return EventModel.fromMap(response.data as Map<String, dynamic>);
  }

  Future<void> remove(String id) async {
    developer.log('🗑️ [EventsService] Removendo evento $id em ${_basePath()}/$id', name: 'EventsService');
    try {
      final response = await _dio.delete('${_basePath()}/$id');
      developer.log('✅ [EventsService] Remoção status: ${response.statusCode}', name: 'EventsService');
      developer.log('📊 [EventsService] Resposta: ${response.data}', name: 'EventsService');
      // ignore: avoid_print
      print('[EventsService] DELETE ${_basePath()}/$id -> ${response.statusCode} ${response.data}');
    } catch (e) {
      developer.log('❌ [EventsService] Erro ao remover evento: $e', name: 'EventsService');
      // ignore: avoid_print
      print('[EventsService] Erro ao remover: $e');
      rethrow;
    }
  }

  // Pula (cancela) uma ocorrência específica de um evento recorrente
  Future<void> skipInstance({
    required String eventId,
    required DateTime instanceDate,
  }) async {
    final dateIso = instanceDate.toUtc().toIso8601String();
    await _dio.delete('${_basePath()}/$eventId/instances', queryParameters: {
      'date': dateIso,
    });
  }

  // Encerra a série após (e incluindo) uma data
  Future<void> cancelSeriesAfter({
    required String eventId,
    required DateTime fromDate,
  }) async {
    final fromIso = fromDate.toUtc().toIso8601String();
    await _dio.patch('${_basePath()}/$eventId/cancel-after', queryParameters: {
      'from': fromIso,
    });
  }

  /// Busca recorrências de eventos para um mês específico
  /// Usa lógica híbrida: instâncias pré-calculadas para próximos 6 meses,
  /// cálculo on-demand para meses distantes
  Future<Map<String, dynamic>> getRecurrences({
    String? month, // formato: YYYY-MM (ex: 2024-01)
    int? monthNumber, // 1-12
    int? year, // 2020-2030
    String? ministryId,
    String? status,
  }) async {
    developer.log('🔄 [EventsService] Buscando recorrências', name: 'EventsService');
    developer.log('📅 [EventsService] Parâmetros: month=$month, monthNumber=$monthNumber, year=$year', name: 'EventsService');
    
    final queryParams = <String, dynamic>{};
    
    if (month != null && month.isNotEmpty) {
      queryParams['month'] = month;
    } else if (monthNumber != null && year != null) {
      queryParams['monthNumber'] = monthNumber;
      queryParams['year'] = year;
    }
    
    if (ministryId != null && ministryId.isNotEmpty) {
      queryParams['ministryId'] = ministryId;
    }
    
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    developer.log('📤 [EventsService] Query params: $queryParams', name: 'EventsService');
    
    try {
      final response = await _dio.get(
        '${_basePath()}/recurrences',
        queryParameters: queryParams,
      );
      
      developer.log('✅ [EventsService] Recorrências carregadas com sucesso', name: 'EventsService');
      developer.log('📊 [EventsService] Resposta: ${response.data}', name: 'EventsService');
      
      return response.data as Map<String, dynamic>;
    } catch (e) {
      developer.log('❌ [EventsService] Erro ao carregar recorrências: $e', name: 'EventsService');
      if (e is DioException) {
        developer.log('📊 [EventsService] Status: ${e.response?.statusCode}', name: 'EventsService');
        developer.log('📊 [EventsService] Data: ${e.response?.data}', name: 'EventsService');
      }
      rethrow;
    }
  }
}


