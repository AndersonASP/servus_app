import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/core/error/notification_service.dart';

class MinistryMembershipService {
  final Dio _dio = DioClient.instance;
  final NotificationService _errorService = NotificationService();

  /// Vincular usuário a um ministério
  Future<Map<String, dynamic>> addUserToMinistry({
    required String userId,
    required String ministryId,
    required String role,
    String? notes,
  }) async {
    try {
      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];

      if (tenantId == null) {
        throw Exception('Tenant ID não encontrado');
      }

      final data = {
        'userId': userId,
        'ministryId': ministryId,
        'role': role,
        if (notes != null) 'notes': notes,
      };

      final response = await _dio.post(
        '/ministry-memberships',
        data: data,
        options: Options(
          headers: {
            'X-Tenant-ID': tenantId,
            if (branchId != null) 'X-Branch-ID': branchId,
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        _errorService.handleGenericError('Erro ao vincular usuário ao ministério');
        throw Exception('Erro ao vincular usuário: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioException) {
        _errorService.handleDioError(e, customMessage: 'Erro ao vincular usuário ao ministério');
      } else {
        _errorService.handleGenericError(e);
      }
      rethrow;
    }
  }

  /// Desvincular usuário de um ministério
  Future<Map<String, dynamic>> removeUserFromMinistry({
    required String userId,
    required String ministryId,
  }) async {
    try {
      debugPrint('🔗 [MinistryMembershipService] Iniciando desvinculação...');
      debugPrint('   - User ID: $userId');
      debugPrint('   - Ministry ID: $ministryId');
      
      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];
      final currentUserId = context['userId'];

      if (tenantId == null) {
        throw Exception('Tenant ID não encontrado');
      }

      if (currentUserId == null) {
        throw Exception('User ID não encontrado no contexto');
      }

      debugPrint('   - Tenant ID: $tenantId');
      debugPrint('   - Branch ID: $branchId');
      debugPrint('   - Current User ID: $currentUserId');

      final response = await _dio.delete(
        '/ministry-memberships/user/$userId/ministry/$ministryId',
        options: Options(
          headers: {
            'X-Tenant-ID': tenantId,
            'X-Current-User-ID': currentUserId,
            if (branchId != null) 'X-Branch-ID': branchId,
          },
        ),
      );

      debugPrint('📡 [MinistryMembershipService] Resposta recebida:');
      debugPrint('   - Status: ${response.statusCode}');
      debugPrint('   - Data: ${response.data}');

      if (response.statusCode == 200) {
        debugPrint('✅ [MinistryMembershipService] Usuário desvinculado com sucesso');
        return response.data;
      } else {
        throw Exception('Erro ao desvincular usuário: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('❌ [MinistryMembershipService] DioException capturada:');
      debugPrint('   - Tipo: ${e.type}');
      debugPrint('   - Status: ${e.response?.statusCode}');
      debugPrint('   - Mensagem: ${e.message}');
      debugPrint('   - Dados: ${e.response?.data}');
      
      _errorService.handleDioError(e, customMessage: 'Erro ao desvincular usuário do ministério');
      
      if (e.response?.statusCode == 404) {
        throw Exception('Usuário não está vinculado a este ministério ou vínculo não encontrado');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Você não tem permissão para remover este membro');
      } else if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'Dados inválidos para desvinculação';
        throw Exception(message);
      } else if (e.type == DioExceptionType.connectionTimeout || 
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.sendTimeout) {
        throw Exception('Timeout na conexão. Verifique sua internet e tente novamente.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Erro de conexão. Verifique sua internet e tente novamente.');
      } else {
        throw Exception('Erro ao desvincular usuário: ${e.response?.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [MinistryMembershipService] Erro geral: $e');
      rethrow;
    }
  }

  /// Listar membros de um ministério
  Future<List<Map<String, dynamic>>> getMinistryMembers({
    required String ministryId,
    String? role,
    bool includeInactive = false,
    int? limit,
    int? offset,
  }) async {
    try {
      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];

      if (tenantId == null) {
        throw Exception('Tenant ID não encontrado');
      }

      final queryParams = <String, dynamic>{
        if (role != null) 'role': role,
        if (includeInactive) 'includeInactive': 'true',
        if (limit != null) 'limit': limit.toString(),
        if (offset != null) 'offset': offset.toString(),
      };

      final response = await _dio.get(
        '/ministry-memberships/ministry/$ministryId',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'X-Tenant-ID': tenantId,
            if (branchId != null) 'X-Branch-ID': branchId,
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> membersData = response.data;
        return membersData.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Erro ao buscar membros: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Listar ministérios de um usuário
  Future<List<Map<String, dynamic>>> getUserMinistries({
    required String userId,
    bool includeInactive = false,
    String? role,
  }) async {
    try {
      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];

      if (tenantId == null) {
        throw Exception('Tenant ID não encontrado');
      }

      final queryParams = <String, dynamic>{
        if (includeInactive) 'includeInactive': 'true',
        if (role != null) 'role': role,
      };

      final response = await _dio.get(
        '/ministry-memberships/user/$userId',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'X-Tenant-ID': tenantId,
            if (branchId != null) 'X-Branch-ID': branchId,
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> ministriesData = response.data;
        return ministriesData.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Erro ao buscar ministérios: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Atualizar vínculo de ministério
  Future<Map<String, dynamic>> updateMinistryMembership({
    required String userId,
    required String ministryId,
    String? role,
    String? notes,
  }) async {
    try {
      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];

      if (tenantId == null) {
        throw Exception('Tenant ID não encontrado');
      }

      final data = <String, dynamic>{};
      if (role != null) data['role'] = role;
      if (notes != null) data['notes'] = notes;

      final response = await _dio.put(
        '/ministry-memberships/user/$userId/ministry/$ministryId',
        data: data,
        options: Options(
          headers: {
            'X-Tenant-ID': tenantId,
            if (branchId != null) 'X-Branch-ID': branchId,
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Erro ao atualizar vínculo: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Verificar se usuário está vinculado a um ministério
  Future<bool> isUserInMinistry({
    required String userId,
    required String ministryId,
  }) async {
    try {
      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];

      if (tenantId == null) {
        throw Exception('Tenant ID não encontrado');
      }

      final response = await _dio.get(
        '/ministry-memberships/user/$userId/ministry/$ministryId/check',
        options: Options(
          headers: {
            'X-Tenant-ID': tenantId,
            if (branchId != null) 'X-Branch-ID': branchId,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['isInMinistry'] ?? false;
      } else {
        throw Exception('Erro ao verificar vínculo: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Obter estatísticas de um ministério
  Future<Map<String, dynamic>> getMinistryStats({
    required String ministryId,
  }) async {
    try {
      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];

      if (tenantId == null) {
        throw Exception('Tenant ID não encontrado');
      }

      final response = await _dio.get(
        '/ministry-memberships/ministry/$ministryId/stats',
        options: Options(
          headers: {
            'X-Tenant-ID': tenantId,
            if (branchId != null) 'X-Branch-ID': branchId,
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Erro ao buscar estatísticas: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
