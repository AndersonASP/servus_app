import 'package:dio/dio.dart';
import 'package:servus_app/features/ministries/models/ministry_function.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:servus_app/core/constants/env.dart';
import 'package:servus_app/core/error/notification_service.dart';

class MinistryFunctionsService {
  final Dio _dio;
  final NotificationService _errorService = NotificationService();
  static const String baseUrl = Env.baseUrl;
  MinistryFunctionsService() : _dio = DioClient.instance;

  /// POST /ministries/{ministryId}/functions/bulk-upsert
  /// Cria ou reutiliza funções e vincula ao ministério
  Future<BulkUpsertResponse> bulkUpsertFunctions(
    String ministryId,
    List<String> names, {
    String? category,
    List<String>? tags,
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
        _errorService.showSuccess('Funções do ministério criadas com sucesso!');
        return BulkUpsertResponse.fromJson(response.data);
      } else {
        _errorService.handleGenericError('Erro ao criar funções do ministério');
        throw Exception('Erro ao criar funções: ${response.statusMessage}');
      }
    } catch (e) {
      if (e is DioException) {
        _errorService.handleDioError(e, customMessage: 'Erro ao criar funções do ministério');
      } else {
        _errorService.handleGenericError('Erro ao criar funções do ministério');
      }
      rethrow;
    }
  }

  /// GET /ministries/{ministryId}/functions
  /// Lista funções habilitadas do ministério
  Future<List<MinistryFunction>> getMinistryFunctions(
    String ministryId, {
    bool? active,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (active != null) {
        queryParams['active'] = active.toString();
      }


      final response = await _dio.get(
        '$baseUrl/ministries/$ministryId/functions',
        queryParameters: queryParams,
      );


      if (response.statusCode == 200) {
        return (response.data as List<dynamic>)
            .map((item) => MinistryFunction.fromJson(item))
            .toList();
      } else {
        _errorService.handleGenericError('Erro ao carregar funções do ministério');
        throw Exception('Erro ao listar funções do ministério: ${response.statusMessage}');
      }
    } catch (e) {
      if (e is DioException) {
        _errorService.handleDioError(e, customMessage: 'Erro ao carregar funções do ministério');
      } else {
        _errorService.handleGenericError('Erro ao carregar funções do ministério');
      }
      rethrow;
    }
  }

  /// GET /functions?scope=tenant&ministryId=...&search=...
  /// Lista catálogo do tenant com indicação se está habilitada no ministério
  Future<List<MinistryFunction>> getTenantFunctions({
    String? ministryId,
    String? search,
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


      final response = await _dio.get(
        '$baseUrl/functions',
        queryParameters: queryParams,
      );


      if (response.statusCode == 200) {
        return (response.data as List<dynamic>)
            .map((item) => MinistryFunction.fromJson(item))
            .toList();
      } else {
        _errorService.handleGenericError('Erro ao carregar funções do tenant');
        throw Exception('Erro ao listar funções do tenant: ${response.statusMessage}');
      }
    } catch (e) {
      if (e is DioException) {
        _errorService.handleDioError(e, customMessage: 'Erro ao carregar funções do tenant');
      } else {
        _errorService.handleGenericError('Erro ao carregar funções do tenant');
      }
      rethrow;
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
        _errorService.showSuccess('Função do ministério atualizada com sucesso!');
        return MinistryFunction.fromJson(response.data);
      } else {
        _errorService.handleGenericError('Erro ao atualizar função do ministério');
        throw Exception('Erro ao atualizar função: ${response.statusMessage}');
      }
    } catch (e) {
      if (e is DioException) {
        _errorService.handleDioError(e, customMessage: 'Erro ao atualizar função do ministério');
      } else {
        _errorService.handleGenericError('Erro ao atualizar função do ministério');
      }
      rethrow;
    }
  }
}
