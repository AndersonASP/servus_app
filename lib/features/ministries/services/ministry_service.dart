import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:servus_app/features/ministries/models/ministry_dto.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/core/services/feedback_service.dart';

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
        // print('🏢 Listando ministérios da MATRIZ');
        // print('   - Branch ID recebido: "$branchId" (vazio)');
      } else {
        // 🏪 Ministérios de filial específica
        url = '/tenants/$tenantId/branches/$branchId/ministries';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          'x-branch-id': branchId,
        };
        // print('🏪 Listando ministérios da FILIAL: $branchId');
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
          FeedbackService.showLoadError(context, 'ministérios');
        }
        throw Exception('Erro ao listar ministérios: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (context != null) {
        FeedbackService.showLoadError(context, 'ministérios');
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
        // print('🏢 Obtendo ministério da MATRIZ');
        // print('   - Branch ID recebido: "$branchId" (vazio)');
      } else {
        // 🏪 Ministério de filial específica
        url = '/tenants/$tenantId/branches/$branchId/ministries/$ministryId';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          'x-branch-id': branchId,
        };
        // print('🏪 Obtendo ministério da FILIAL: $branchId');
      }

      final response = await dio.get(
        url,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return MinistryResponse.fromJson(response.data);
      } else {
        if (context != null) {
          FeedbackService.showLoadError(context, 'ministério');
        }
        throw Exception('Erro ao obter ministério: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (context != null) {
        FeedbackService.showLoadError(context, 'ministério');
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
        // print('🏢 Criando ministério da MATRIZ');
        // print('   - Branch ID recebido: "$branchId" (vazio)');
      } else {
        // 🏪 Ministério de filial específica
        url = '/tenants/$tenantId/branches/$branchId/ministries';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          'x-branch-id': branchId,
        };
        // print('🏪 Criando ministério da FILIAL: $branchId');
      }

      // print('🚀 MinistryService.createMinistry:');
      // print('   - URL: $url');
      // print('   - Dados: ${ministryData.toJson()}');
      // print('   - Headers: $headers');

      final response = await dio.post(
        url,
        data: ministryData.toJson(),
        options: Options(headers: headers),
      );

      // print('📡 Resposta do servidor:');
      // print('   - Status: ${response.statusCode}');
      // print('   - Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (context != null) {
          FeedbackService.showCreateSuccess(context, 'Ministério');
        }
        return MinistryResponse.fromJson(response.data);
      } else {
        if (context != null) {
          FeedbackService.showCreateError(context, 'ministério');
        }
        throw Exception('Erro ao criar ministério: ${response.statusCode}');
      }
    } on DioException catch (e) {
      // print('❌ DioException ao criar ministério:');
      // print('   - Status: ${e.response?.statusCode}');
      // print('   - Data: ${e.response?.data}');
      // print('   - Message: ${e.message}');
      
      if (context != null) {
        FeedbackService.showCreateError(context, 'ministério');
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
        // print('🏢 Atualizando ministério da MATRIZ');
        // print('   - Branch ID recebido: "$branchId" (vazio)');
      } else {
        // 🏪 Ministério de filial específica
        url = '/tenants/$tenantId/branches/$branchId/ministries/$ministryId';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          'x-branch-id': branchId,
        };
        // print('🏪 Atualizando ministério da FILIAL: $branchId');
      }

      // print('🔄 MinistryService.updateMinistry:');
      // print('   - URL: $url');
      // print('   - Dados: ${ministryData.toJson()}');
      // print('   - Headers: $headers');

      final response = await dio.patch(
        url,
        data: ministryData.toJson(),
        options: Options(headers: headers),
      );

      // print('✅ Resposta do backend: ${response.statusCode}');
      // print('📄 Dados da resposta: ${response.data}');

      if (response.statusCode == 200) {
        if (context != null) {
          FeedbackService.showUpdateSuccess(context, 'Ministério');
        }
        return MinistryResponse.fromJson(response.data);
      } else {
        if (context != null) {
          FeedbackService.showUpdateError(context, 'ministério');
        }
        throw Exception('Erro ao atualizar ministério: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (context != null) {
        FeedbackService.showUpdateError(context, 'ministério');
      }
      throw Exception(_handleDioError(e));
    } catch (e) {
      if (context != null) {
        FeedbackService.showUpdateError(context, 'ministério');
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
        // print('🏢 Removendo ministério da MATRIZ');
        // print('   - Branch ID recebido: "$branchId" (vazio)');
      } else {
        // 🏪 Ministério de filial específica
        url = '/tenants/$tenantId/branches/$branchId/ministries/$ministryId';
        headers = {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          'x-branch-id': branchId,
        };
        // print('🏪 Removendo ministério da FILIAL: $branchId');
      }

      final response = await dio.delete(
        url,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (context != null) {
          FeedbackService.showDeleteSuccess(context, 'Ministério');
        }
        return true;
      } else {
        if (context != null) {
          FeedbackService.showDeleteError(context, 'ministério');
        }
        return false;
      }
    } on DioException catch (e) {
      if (context != null) {
        FeedbackService.showDeleteError(context, 'ministério');
      }
      throw Exception(_handleDioError(e));
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