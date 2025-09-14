import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/core/services/feedback_service.dart';

class MembershipService {
  final Dio dio = DioClient.instance;

  /// Obtém a contagem de membros (líderes e voluntários) de um ministério
  /// Versão com timeout reduzido e fallback
  Future<Map<String, int>> getMinistryMembersCount({
    required String tenantId,
    required String branchId,
    required String ministryId,
    BuildContext? context,
  }) async {
    try {
      
      final deviceId = await TokenService.getDeviceId();
      

      // 🆕 CORREÇÃO: Usa rota diferente para matriz vs filial
      final String url;
      final Map<String, String> headers;
      
      // 🏢 Verifica se é matriz (branchId vazio, null ou apenas espaços)
      if (branchId.isEmpty || branchId.trim().isEmpty) {
        // 🏢 Ministério da matriz (sem branch)
        url = '/users/tenants/$tenantId/ministries/$ministryId/volunteers?limit=1';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          // Não inclui x-branch-id para matriz
        };
      } else {
        // 🏪 Ministério de filial específica
        url = '/users/tenants/$tenantId/ministries/$ministryId/volunteers?limit=1&branchId=$branchId';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          'x-branch-id': branchId,
        };
      }

      final response = await dio.get(
        url,
        options: Options(
          headers: headers,
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );


      if (response.statusCode == 200) {
        final data = response.data;
        final totalVolunteers = data['pagination']?['total'] ?? 0;
        
        
        // Por enquanto, vamos assumir que todos são voluntários
        // Em uma implementação futura, podemos buscar líderes separadamente
        return {
          'volunteers': totalVolunteers,
          'leaders': 0, // TODO: Implementar busca de líderes
          'total': totalVolunteers,
        };
      } else {
        if (context != null) {
          FeedbackService.showLoadError(context, 'contagem de membros');
        }
        throw Exception('Erro ao obter contagem de membros: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (context != null) {
        FeedbackService.showLoadError(context, 'contagem de membros');
      }
      throw Exception(_handleDioError(e));
          } catch (e) {
        // Retorna dados mockados como fallback
        if (context != null) {
          FeedbackService.showLoadError(context, 'contagem de membros');
        }
        return {
          'volunteers': 0,
          'leaders': 0,
          'total': 0,
        };
      }
  }

  /// Obtém a lista de membros de um ministério
  Future<Map<String, dynamic>> getMinistryMembers({
    required String tenantId,
    required String branchId,
    required String ministryId,
    int page = 1,
    int limit = 20,
    String? search,
    String? role,
    BuildContext? context,
  }) async {
    try {
      final deviceId = await TokenService.getDeviceId();

      // Construir query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (role != null && role.isNotEmpty) {
        queryParams['role'] = role;
      }

      // 🆕 CORREÇÃO: Usa rota diferente para matriz vs filial
      final String url;
      final Map<String, String> headers;
      
      // 🏢 Verifica se é matriz (branchId vazio, null ou apenas espaços)
      if (branchId.isEmpty || branchId.trim().isEmpty) {
        // 🏢 Ministério da matriz (sem branch)
        url = '/memberships/tenants/$tenantId/ministries/$ministryId/members';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          // Não inclui x-branch-id para matriz
        };
      } else {
        // 🏪 Ministério de filial específica
        queryParams['branchId'] = branchId;
        url = '/memberships/tenants/$tenantId/branches/$branchId/ministries/$ministryId/members';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          'x-branch-id': branchId,
        };
      }

      final response = await dio.get(
        url,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        if (context != null) {
          FeedbackService.showLoadError(context, 'membros do ministério');
        }
        throw Exception('Erro ao obter voluntários: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (context != null) {
        FeedbackService.showLoadError(context, 'membros do ministério');
      }
      throw Exception(_handleDioError(e));
    }
  }

  /// Adiciona um voluntário ao ministério
  Future<Map<String, dynamic>> addVolunteerToMinistry({
    required String tenantId,
    required String branchId,
    required String ministryId,
    required String userId,
    BuildContext? context,
  }) async {
    try {
      final deviceId = await TokenService.getDeviceId();

      // 🆕 CORREÇÃO: Usa rota diferente para matriz vs filial
      final String url;
      final Map<String, String> headers;
      
      // 🏢 Verifica se é matriz (branchId vazio, null ou apenas espaços)
      if (branchId.isEmpty || branchId.trim().isEmpty) {
        // 🏢 Ministério da matriz (sem branch)
        url = '/memberships/tenants/$tenantId/ministries/$ministryId/volunteers';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          'Content-Type': 'application/json',
        };
      } else {
        // 🏪 Ministério de filial específica
        url = '/memberships/tenants/$tenantId/branches/$branchId/ministries/$ministryId/volunteers';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          'x-branch-id': branchId,
          'Content-Type': 'application/json',
        };
      }

      final response = await dio.post(
        url,
        data: {
          'userId': userId,
          'role': 'volunteer',
          'isActive': true,
        },
        options: Options(headers: headers),
      );

      if (response.statusCode == 201) {
        if (context != null) {
          FeedbackService.showCreateSuccess(context, 'Voluntário');
        }
        return response.data;
      } else {
        if (context != null) {
          FeedbackService.showCreateError(context, 'voluntário');
        }
        throw Exception('Erro ao adicionar voluntário: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (context != null) {
        FeedbackService.showCreateError(context, 'voluntário');
      }
      throw Exception(_handleDioError(e));
    }
  }

  /// Adiciona um líder ao ministério
  Future<Map<String, dynamic>> addLeaderToMinistry({
    required String tenantId,
    required String branchId,
    required String ministryId,
    required String userId,
    BuildContext? context,
  }) async {
    try {
      final deviceId = await TokenService.getDeviceId();

      // 🆕 CORREÇÃO: Usa rota diferente para matriz vs filial
      final String url;
      final Map<String, String> headers;
      
      // 🏢 Verifica se é matriz (branchId vazio, null ou apenas espaços)
      if (branchId.isEmpty || branchId.trim().isEmpty) {
        // 🏢 Ministério da matriz (sem branch)
        url = '/memberships/tenants/$tenantId/ministries/$ministryId/leaders';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          'Content-Type': 'application/json',
        };
      } else {
        // 🏪 Ministério de filial específica
        url = '/memberships/tenants/$tenantId/branches/$branchId/ministries/$ministryId/leaders';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          'x-branch-id': branchId,
          'Content-Type': 'application/json',
        };
      }

      final response = await dio.post(
        url,
        data: {
          'userId': userId,
          'role': 'leader',
          'isActive': true,
        },
        options: Options(headers: headers),
      );

      if (response.statusCode == 201) {
        if (context != null) {
          FeedbackService.showCreateSuccess(context, 'Líder');
        }
        return response.data;
      } else {
        if (context != null) {
          FeedbackService.showCreateError(context, 'líder');
        }
        throw Exception('Erro ao adicionar líder: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (context != null) {
        FeedbackService.showCreateError(context, 'líder');
      }
      throw Exception(_handleDioError(e));
    }
  }

  /// Remove um membro do ministério
  Future<bool> removeMinistryMember({
    required String tenantId,
    required String branchId,
    required String ministryId,
    required String membershipId,
    BuildContext? context,
  }) async {
    try {
      print('🗑️ [MembershipService] removeMinistryMember iniciado');
      print('   - tenantId: $tenantId');
      print('   - branchId: $branchId');
      print('   - ministryId: $ministryId');
      print('   - membershipId: $membershipId');
      
      final deviceId = await TokenService.getDeviceId();
      print('   - deviceId: $deviceId');

      // 🆕 CORREÇÃO: Usa rota diferente para matriz vs filial
      final String url;
      final Map<String, String> headers;
      
      // 🏢 Verifica se é matriz (branchId vazio, null ou apenas espaços)
      if (branchId.isEmpty || branchId.trim().isEmpty) {
        // 🏢 Ministério da matriz (sem branch)
        url = '/memberships/tenants/$tenantId/ministries/$ministryId/members/$membershipId';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
        };
        print('   - Usando rota da matriz: $url');
      } else {
        // 🏪 Ministério de filial específica
        url = '/memberships/tenants/$tenantId/branches/$branchId/ministries/$ministryId/members/$membershipId';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          'x-branch-id': branchId,
        };
        print('   - Usando rota da filial: $url');
      }
      
      print('   - Headers: $headers');

      print('   - Fazendo requisição DELETE...');
      final response = await dio.delete(
        url,
        options: Options(headers: headers),
      );

      print('   - Resposta recebida: ${response.statusCode}');
      print('   - Dados da resposta: ${response.data}');

      if (response.statusCode == 204) {
        print('✅ Membro removido com sucesso');
        if (context != null) {
          FeedbackService.showDeleteSuccess(context, 'Membro');
        }
        return true;
      } else {
        print('❌ Erro na resposta: ${response.statusCode}');
        if (context != null) {
          FeedbackService.showDeleteError(context, 'membro');
        }
        throw Exception('Erro ao remover membro: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ DioException ao remover membro: $e');
      print('   - Status code: ${e.response?.statusCode}');
      print('   - Response data: ${e.response?.data}');
      if (context != null) {
        FeedbackService.showDeleteError(context, 'membro');
      }
      throw Exception(_handleDioError(e));
    } catch (e) {
      print('❌ Erro geral ao remover membro: $e');
      if (context != null) {
        FeedbackService.showDeleteError(context, 'membro');
      }
      rethrow;
    }
  }

  /// Trata erros do Dio
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Timeout na conexão. Verifique sua internet.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Erro desconhecido';
        return 'Erro $statusCode: $message';
      case DioExceptionType.cancel:
        return 'Requisição cancelada.';
      case DioExceptionType.connectionError:
        return 'Erro de conexão. Verifique sua internet.';
      case DioExceptionType.unknown:
      default:
        return 'Erro desconhecido: ${e.message}';
    }
  }
}
