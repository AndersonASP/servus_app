import 'package:dio/dio.dart';
import 'package:servus_app/core/models/scale_template.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:servus_app/services/auth_context_service.dart';

class TemplatesService {
  final Dio _dio = DioClient.instance;
  final AuthContextService _auth = AuthContextService.instance;

  TemplatesService() {
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
      return '/tenants/$tenantId/branches/$bId/templates';
    }
    return '/tenants/$tenantId/branches/null/templates';
  }

  Future<Map<String, dynamic>> list({
    int page = 1,
    int limit = 20,
    String? search,
    String? eventType,
    String? ministryId,
  }) async {
    final response = await _dio.get(
      _basePath(),
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (eventType != null) 'eventType': eventType,
        if (ministryId != null) 'ministryId': ministryId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<ScaleTemplateModel> create(Map<String, dynamic> payload) async {
    final response = await _dio.post(_basePath(), data: payload);
    return ScaleTemplateModel.fromMap(response.data as Map<String, dynamic>);
  }

  Future<ScaleTemplateModel> getById(String id) async {
    final response = await _dio.get('${_basePath()}/$id');
    return ScaleTemplateModel.fromMap(response.data as Map<String, dynamic>);
  }

  Future<ScaleTemplateModel> update(String id, Map<String, dynamic> payload) async {
    final response = await _dio.patch('${_basePath()}/$id', data: payload);
    return ScaleTemplateModel.fromMap(response.data as Map<String, dynamic>);
  }

  Future<void> remove(String id) async {
    await _dio.delete('${_basePath()}/$id');
  }
}


