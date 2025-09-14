import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:servus_app/features/ministries/models/ministry_function.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:servus_app/core/constants/env.dart';
import 'package:servus_app/core/services/feedback_service.dart';

class MinistryFunctionsService {
  final Dio _dio;
  static const String baseUrl = Env.baseUrl;
  MinistryFunctionsService() : _dio = DioClient.instance;

  /// POST /ministries/{ministryId}/functions/bulk-upsert
  /// Cria ou reutiliza funções e vincula ao ministério
  Future<BulkUpsertResponse> bulkUpsertFunctions(
    String ministryId,
    List<String> names, {
    String? category,
    List<String>? tags,
    BuildContext? context,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/ministries/$ministryId/functions/bulk-upsert',
        data: {
          'names': names,
          if (category != null) 'category': category,
          if (tags != null) 'tags': tags,
        },
      );

      if (response.statusCode == 200) {
        if (context != null) {
          FeedbackService.showCreateSuccess(context, 'Funções do ministério');
        }
        return BulkUpsertResponse.fromJson(response.data);
      } else {
        if (context != null) {
          FeedbackService.showCreateError(context, 'funções do ministério');
        }
        throw Exception('Erro ao criar funções: ${response.statusMessage}');
      }
    } catch (e) {
      if (context != null) {
        FeedbackService.showCreateError(context, 'funções do ministério');
      }
      throw Exception('Erro ao criar funções: $e');
    }
  }

  /// GET /ministries/{ministryId}/functions
  /// Lista funções habilitadas do ministério
  Future<List<MinistryFunction>> getMinistryFunctions(
    String ministryId, {
    bool? active,
    BuildContext? context,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (active != null) {
        queryParams['active'] = active.toString();
      }

      // print('🔍 Fazendo requisição para: $baseUrl/ministries/$ministryId/functions');
      // print('🔍 Query params: $queryParams');

      final response = await _dio.get(
        '$baseUrl/ministries/$ministryId/functions',
        queryParameters: queryParams,
      );

      // print('✅ Resposta recebida: ${response.statusCode}');
      // print('✅ Dados: ${response.data}');

      if (response.statusCode == 200) {
        return (response.data as List<dynamic>)
            .map((item) => MinistryFunction.fromJson(item))
            .toList();
      } else {
        if (context != null) {
          FeedbackService.showLoadError(context, 'funções do ministério');
        }
        throw Exception('Erro ao listar funções do ministério: ${response.statusMessage}');
      }
    } catch (e) {
      // print('❌ Erro na requisição: $e');
      if (e is DioException) {
        // print('❌ Status code: ${e.response?.statusCode}');
        // print('❌ Response data: ${e.response?.data}');
        // print('❌ Request URL: ${e.requestOptions.uri}');
      }
      if (context != null) {
        FeedbackService.showLoadError(context, 'funções do ministério');
      }
      throw Exception('Erro ao listar funções do ministério: $e');
    }
  }

  /// GET /functions?scope=tenant&ministryId=...&search=...
  /// Lista catálogo do tenant com indicação se está habilitada no ministério
  Future<List<MinistryFunction>> getTenantFunctions({
    String? ministryId,
    String? search,
    BuildContext? context,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'scope': 'tenant',
      };
      
      if (ministryId != null) {
        queryParams['ministryId'] = ministryId;
      }
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      // print('🔍 Fazendo requisição para: $baseUrl/functions');
      // print('🔍 Query params: $queryParams');

      final response = await _dio.get(
        '$baseUrl/functions',
        queryParameters: queryParams,
      );

      // print('✅ Resposta recebida: ${response.statusCode}');
      // print('✅ Dados: ${response.data}');

      if (response.statusCode == 200) {
        return (response.data as List<dynamic>)
            .map((item) => MinistryFunction.fromJson(item))
            .toList();
      } else {
        if (context != null) {
          FeedbackService.showLoadError(context, 'funções do tenant');
        }
        throw Exception('Erro ao listar funções do tenant: ${response.statusMessage}');
      }
    } catch (e) {
      // print('❌ Erro na requisição: $e');
      if (e is DioException) {
        // print('❌ Status code: ${e.response?.statusCode}');
        // print('❌ Response data: ${e.response?.data}');
        // print('❌ Request URL: ${e.requestOptions.uri}');
      }
      if (context != null) {
        FeedbackService.showLoadError(context, 'funções do tenant');
      }
      throw Exception('Erro ao listar funções do tenant: $e');
    }
  }

  /// PATCH /ministries/{ministryId}/functions/{functionId}
  /// Atualiza vínculo ministério-função
  Future<MinistryFunction> updateMinistryFunction(
    String ministryId,
    String functionId, {
    bool? isActive,
    int? defaultSlots,
    String? notes,
    BuildContext? context,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (isActive != null) data['isActive'] = isActive;
      if (defaultSlots != null) data['defaultSlots'] = defaultSlots;
      if (notes != null) data['notes'] = notes;

      final response = await _dio.patch(
        '$baseUrl/ministries/$ministryId/functions/$functionId',
        data: data,
      );

      if (response.statusCode == 200) {
        if (context != null) {
          FeedbackService.showUpdateSuccess(context, 'Função do ministério');
        }
        return MinistryFunction.fromJson(response.data);
      } else {
        if (context != null) {
          FeedbackService.showUpdateError(context, 'função do ministério');
        }
        throw Exception('Erro ao atualizar função: ${response.statusMessage}');
      }
    } catch (e) {
      if (context != null) {
        FeedbackService.showUpdateError(context, 'função do ministério');
      }
      throw Exception('Erro ao atualizar função: $e');
    }
  }
}
