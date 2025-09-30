import 'package:dio/dio.dart';
import 'package:servus_app/services/auth_context_service.dart';
import 'package:servus_app/core/network/dio_client.dart';

class MinistryFunctionsService {
  final Dio _dio = DioClient.instance;
  final AuthContextService _authContext = AuthContextService.instance;

  MinistryFunctionsService() {
    // DioClient já está configurado com baseUrl e interceptors
    
    // Adicionar interceptor para headers de autenticação
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_authContext.hasContext) {
          try {
            final headers = await _authContext.headers;
            options.headers.addAll(headers);
          } catch (e) {
            print('Erro ao obter headers de autenticação: $e');
          }
        }
        handler.next(options);
      },
    ));
  }

  /// Busca todos os ministérios disponíveis
  Future<List<Map<String, dynamic>>> getMinistries() async {
    try {
      
      if (!_authContext.hasContext) {
        throw Exception('Contexto de autenticação não definido');
      }
      
      final tenantId = _authContext.tenantId!;
      final branchId = _authContext.branchId;
      
      
      String endpoint;
      if (branchId != null && branchId.isNotEmpty) {
        endpoint = '/tenants/$tenantId/branches/$branchId/ministries';
      } else {
        endpoint = '/tenants/$tenantId/ministries';
      }
      
      final response = await _dio.get(endpoint);
      
      
      return (response.data['items'] as List<dynamic>?)
          ?.map((ministry) => Map<String, dynamic>.from(ministry))
          .toList() ?? [];
    } catch (e) {
      rethrow;
    }
  }

  /// Busca as funções de um ministério específico
  Future<List<Map<String, dynamic>>> getMinistryFunctions(String ministryId) async {
    try {
      
      if (!_authContext.hasContext) {
        throw Exception('Contexto de autenticação não definido');
      }
      
      final tenantId = _authContext.tenantId!;
      final branchId = _authContext.branchId;
      
      
      String endpoint;
      if (branchId != null && branchId.isNotEmpty) {
        endpoint = '/tenants/$tenantId/branches/$branchId/ministries/$ministryId/functions';
      } else {
        endpoint = '/tenants/$tenantId/ministries/$ministryId/functions';
      }
      
      final response = await _dio.get(endpoint);
      
      
      return (response.data as List<dynamic>?)
          ?.map((function) => Map<String, dynamic>.from(function))
          .toList() ?? [];
    } catch (e) {
      rethrow;
    }
  }
}
