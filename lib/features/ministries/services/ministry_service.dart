import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:servus_app/features/ministries/models/ministry_dto.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';

class MinistryService {
  final Dio dio;

  MinistryService() : dio = DioClient.instance;

  /// Lista ministérios com paginação e filtros
  Future<MinistryListResponse> listMinistries({
    required String tenantId,
    required String branchId,
    ListMinistryDto? filters,
    BuildContext? context,
  }) async {
    try {
      final deviceId = await TokenService.getDeviceId();

      // 🆕 CORREÇÃO: Usa rota diferente para matriz vs filial
      final String url;
      final Map<String, String> headers;
      
      // 🏢 Verifica se é matriz (branchId vazio, null ou apenas espaços)
      if (branchId.isEmpty || branchId.trim().isEmpty) {
        // 🏢 Ministérios da matriz (sem branch)
        url = '/tenants/$tenantId/ministries';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          // Não inclui x-branch-id para matriz
        };
      } else {
        // 🏪 Ministérios de filial específica
        url = '/tenants/$tenantId/branches/$branchId/ministries';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          'x-branch-id': branchId,
        };
      }

      final response = await dio.get(
        url,
        queryParameters: filters?.toJson(),
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return MinistryListResponse.fromJson(response.data);
      } else {
        if (context != null) {
          showLoadError(context, 'ministérios');
        }
        throw Exception('Erro ao listar ministérios: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (context != null) {
        showLoadError(context, 'ministérios');
      }
      throw Exception(_handleDioError(e));
    }
  }

  /// Obtém um ministério específico
  Future<MinistryResponse> getMinistry({
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
        url = '/tenants/$tenantId/ministries/$ministryId';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          // Não inclui x-branch-id para matriz
        };
      } else {
        // 🏪 Ministério de filial específica
        url = '/tenants/$tenantId/branches/$branchId/ministries/$ministryId';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          'x-branch-id': branchId,
        };
      }

      final response = await dio.get(
        url,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return MinistryResponse.fromJson(response.data);
      } else {
        if (context != null) {
          showLoadError(context, 'ministério');
        }
        throw Exception('Erro ao obter ministério: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (context != null) {
        showLoadError(context, 'ministério');
      }
      throw Exception(_handleDioError(e));
    }
  }

  /// Cria um novo ministério
  Future<MinistryResponse> createMinistry({
    required String tenantId,
    required String branchId,
    required CreateMinistryDto ministryData,
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
        url = '/tenants/$tenantId/ministries';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          // Não inclui x-branch-id para matriz
        };
      } else {
        // 🏪 Ministério de filial específica
        url = '/tenants/$tenantId/branches/$branchId/ministries';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          'x-branch-id': branchId,
        };
      }


      final response = await dio.post(
        url,
        data: ministryData.toJson(),
        options: Options(headers: headers),
      );


      if (response.statusCode == 200 || response.statusCode == 201) {
        if (context != null) {
          showCreateSuccess(context, 'Ministério');
        }
        return MinistryResponse.fromJson(response.data);
      } else {
        if (context != null) {
          showCreateError(context, 'ministério');
        }
        throw Exception('Erro ao criar ministério: ${response.statusCode}');
      }
    } on DioException catch (e) {
      
      if (context != null) {
        showCreateError(context, 'ministério');
      }
      throw Exception(_handleDioError(e));
    }
  }

  /// Atualiza um ministério existente
  Future<MinistryResponse> updateMinistry({
    required String tenantId,
    required String branchId,
    required String ministryId,
    required UpdateMinistryDto ministryData,
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
        url = '/tenants/$tenantId/ministries/$ministryId';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          // Não inclui x-branch-id para matriz
        };
      } else {
        // 🏪 Ministério de filial específica
        url = '/tenants/$tenantId/branches/$branchId/ministries/$ministryId';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          'x-branch-id': branchId,
        };
      }


      final response = await dio.patch(
        url,
        data: ministryData.toJson(),
        options: Options(headers: headers),
      );


      if (response.statusCode == 200) {
        if (context != null) {
          showUpdateSuccess(context, 'Ministério');
        }
        return MinistryResponse.fromJson(response.data);
      } else {
        if (context != null) {
          showUpdateError(context, 'ministério');
        }
        throw Exception('Erro ao atualizar ministério: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (context != null) {
        showUpdateError(context, 'ministério');
      }
      throw Exception(_handleDioError(e));
    } catch (e) {
      if (context != null) {
        showUpdateError(context, 'ministério');
      }
      rethrow;
    }
  }

  /// Remove um ministério
  Future<bool> deleteMinistry({
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
        url = '/tenants/$tenantId/ministries/$ministryId';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          // Não inclui x-branch-id para matriz
        };
      } else {
        // 🏪 Ministério de filial específica
        url = '/tenants/$tenantId/branches/$branchId/ministries/$ministryId';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          'x-branch-id': branchId,
        };
      }

      final response = await dio.delete(
        url,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (context != null) {
          showDeleteSuccess(context, 'Ministério');
        }
        return true;
      } else {
        if (context != null) {
          showDeleteError(context, 'ministério');
        }
        return false;
      }
    } on DioException catch (e) {
      if (context != null) {
        showDeleteError(context, 'ministério');
      }
      throw Exception(_handleDioError(e));
    }
  }

  /// Obtém o ministério do líder atual
  Future<MinistryResponse?> getLeaderMinistry({
    required String tenantId,
    required String branchId,
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
        url = '/tenants/$tenantId/ministries/leader';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          // Não inclui x-branch-id para matriz
        };
      } else {
        // 🏪 Ministério de filial específica
        url = '/tenants/$tenantId/branches/$branchId/ministries/leader';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          'x-branch-id': branchId,
        };
      }

      final response = await dio.get(
        url,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return MinistryResponse.fromJson(response.data);
      } else if (response.statusCode == 404) {
        // Líder não tem ministério
        return null;
      } else {
        if (context != null) {
          showLoadError(context, 'ministério do líder');
        }
        throw Exception('Erro ao obter ministério do líder: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Líder não tem ministério
        return null;
      }
      if (context != null) {
        showLoadError(context, 'ministério do líder');
      }
      throw Exception(_handleDioError(e));
    }
  }

  /// Obtém o ministério do líder atual usando endpoints existentes
  Future<MinistryResponse?> getLeaderMinistryV2({
    required String tenantId,
    required String branchId,
    BuildContext? context,
  }) async {
    try {
      debugPrint('🔍 [MinistryService] getLeaderMinistryV2 iniciado');
      debugPrint('🔍 [MinistryService] TenantId: $tenantId');
      debugPrint('🔍 [MinistryService] BranchId: $branchId');
      
      final deviceId = await TokenService.getDeviceId();
      debugPrint('🔍 [MinistryService] DeviceId: $deviceId');

      // Primeiro, buscar os memberships do usuário atual para encontrar o ministério que ele lidera
      debugPrint('🔍 [MinistryService] Buscando memberships em /ministry-memberships/me');
      final membershipResponse = await dio.get(
        '/ministry-memberships/me',
        options: Options(headers: {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          if (branchId.isNotEmpty) 'x-branch-id': branchId,
        }),
      );
      
      debugPrint('🔍 [MinistryService] Status da resposta: ${membershipResponse.statusCode}');

      if (membershipResponse.statusCode != 200) {
        throw Exception('Erro ao buscar memberships do usuário');
      }

      final memberships = membershipResponse.data as List;
      debugPrint('🔍 [MinistryService] Memberships encontrados: ${memberships.length}');
      debugPrint('🔍 [MinistryService] Dados dos memberships: $memberships');
      
      // Encontrar o membership onde o usuário é líder
      final leaderMembership = memberships.firstWhere(
        (membership) => membership['role'] == 'leader' && membership['isActive'] == true,
        orElse: () => null,
      );

      debugPrint('🔍 [MinistryService] LeaderMembership encontrado: $leaderMembership');

      if (leaderMembership == null) {
        debugPrint('❌ [MinistryService] Líder não tem ministério');
        return null;
      }

      final ministryId = leaderMembership['ministry']['_id'];
      
      // Agora buscar os detalhes do ministério usando o endpoint normal
      final String url;
      final Map<String, String> headers;
      
      if (branchId.isEmpty || branchId.trim().isEmpty) {
        // Ministério da matriz
        url = '/tenants/$tenantId/ministries/$ministryId';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
        };
      } else {
        // Ministério de filial
        url = '/tenants/$tenantId/branches/$branchId/ministries/$ministryId';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          'x-branch-id': branchId,
        };
      }

      final response = await dio.get(
        url,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return MinistryResponse.fromJson(response.data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        if (context != null) {
          showLoadError(context, 'ministério do líder');
        }
        throw Exception('Erro ao obter ministério do líder: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      } else {
        if (context != null) {
          showLoadError(context, 'ministério do líder');
        }
        throw Exception(_handleDioError(e));
      }
    }
  }

  /// Ativa/desativa um ministério
  Future<MinistryResponse> toggleMinistryStatus({
    required String tenantId,
    required String branchId,
    required String ministryId,
    required bool isActive,
    BuildContext? context,
  }) async {
    return await updateMinistry(
      tenantId: tenantId,
      branchId: branchId,
      ministryId: ministryId,
      ministryData: UpdateMinistryDto(isActive: isActive),
      context: context,
    );
  }

  /// Trata erros do Dio para mensagens mais amigáveis
  String _handleDioError(DioException e) {
    if (e.response != null) {
      final status = e.response?.statusCode ?? 0;
      final data = e.response?.data;
      
      switch (status) {
        case 400:
          return 'Dados inválidos para o ministério';
        case 401:
          return 'Não autorizado';
        case 403:
          return 'Sem permissão para gerenciar ministérios';
        case 404:
          // Verifica se é erro de rota ou de ministério
          if (data != null && data is Map) {
            final message = data['message']?.toString() ?? '';
            if (message.contains('Cannot POST') || message.contains('Cannot GET')) {
              return 'Rota não encontrada - verifique se o backend está funcionando';
            }
          }
          return 'Ministério não encontrado';
        case 409:
          return 'Já existe um ministério com este nome';
        case 500:
          return 'Erro interno no servidor';
        default:
          return 'Erro desconhecido (${e.message})';
      }
    } else {
      return 'Erro de conexão: ${e.message}';
    }
  }
} 