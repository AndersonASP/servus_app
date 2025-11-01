import 'package:dio/dio.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:servus_app/services/auth_context_service.dart';

class ScalesService {
  final Dio _dio = DioClient.instance;
  final AuthContextService _auth = AuthContextService.instance;

  ScalesService() {
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      if (_auth.hasContext) {
        try {
          final headers = await _auth.headers;
          options.headers.addAll(headers);
        } catch (e) {
          print('Erro ao obter headers de autenticação: $e');
        }
      }
      handler.next(options);
    }));
  }

  String _basePath({String? branchId}) {
    final tenantId = _auth.tenantId!;
    final bId = branchId ?? _auth.branchId;
    if (bId != null && bId.isNotEmpty) {
      return '/tenants/$tenantId/branches/$bId/scales';
    }
    return '/tenants/$tenantId/scales';
  }

  /// Criar uma nova escala
  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    try {
      print('🔄 [ScalesService] Criando escala...');
      print('📤 [ScalesService] Payload: $payload');
      
      final response = await _dio.post(
        _basePath(),
        data: payload,
      );
      
      print('✅ [ScalesService] Escala criada com sucesso: ${response.data}');
      final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return data;
    } catch (e) {
      print('❌ [ScalesService] Erro ao criar escala: $e');
      rethrow;
    }
  }

  /// Listar escalas
  Future<Map<String, dynamic>> list({
    int page = 1,
    int limit = 20,
    String? eventId,
    String? ministryId,
    String? status,
  }) async {
    try {
      final response = await _dio.get(
        _basePath(),
        queryParameters: {
          'page': page,
          'limit': limit,
          if (eventId != null && eventId.isNotEmpty) 'eventId': eventId,
          if (ministryId != null && ministryId.isNotEmpty) 'ministryId': ministryId,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return data;
    } catch (e) {
      print('❌ [ScalesService] Erro ao listar escalas: $e');
      rethrow;
    }
  }

  /// Listar escalas por múltiplos ministérios e mesclar localmente
  Future<List<Map<String, dynamic>>> listByMinistries({
    required List<String> ministryIds,
    int page = 1,
    int limit = 50,
    String? status,
  }) async {
    final results = <Map<String, dynamic>>[];
    for (final mId in ministryIds) {
      try {
        final data = await list(page: page, limit: limit, ministryId: mId, status: status);
        final items = (data['items'] as List? ?? []).cast<Map<String, dynamic>>();
        results.addAll(items);
      } catch (e) {
        // Continua mesmo se um ministério falhar
        print('⚠️ [ScalesService] Falha ao listar escalas do ministério $mId: $e');
      }
    }
    return results;
  }

  /// Obter escala por ID
  Future<Map<String, dynamic>> getById(String id) async {
    try {
      final response = await _dio.get('${_basePath()}/$id');
      final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return data;
    } catch (e) {
      print('❌ [ScalesService] Erro ao obter escala: $e');
      rethrow;
    }
  }

  /// Atualizar escala
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.put('${_basePath()}/$id', data: payload);
      final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return data;
    } catch (e) {
      print('❌ [ScalesService] Erro ao atualizar escala: $e');
      rethrow;
    }
  }

  /// Deletar escala
  Future<void> delete(String id) async {
    try {
      await _dio.delete('${_basePath()}/$id');
    } catch (e) {
      print('❌ [ScalesService] Erro ao deletar escala: $e');
      rethrow;
    }
  }

  /// Publicar escala (mudar status para published)
  Future<Map<String, dynamic>> publish(String id) async {
    try {
      final response = await _dio.patch(
        '${_basePath()}/$id/publish',
      );
      final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return data;
    } catch (e) {
      print('❌ [ScalesService] Erro ao publicar escala: $e');
      rethrow;
    }
  }
}
