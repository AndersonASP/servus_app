import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:servus_app/core/constants/env.dart';
import 'package:servus_app/features/ministries/models/user_function.dart';
import 'package:servus_app/core/services/feedback_service.dart';

class UserFunctionService {
  final Dio _dio;
  static const String baseUrl = Env.baseUrl;

  UserFunctionService() : _dio = DioClient.instance;

  /// POST /user-functions
  /// Criar vínculo usuário-função
  Future<UserFunction> createUserFunction({
    required String userId,
    required String ministryId,
    required String functionId,
    String? notes,
    String? status,
    BuildContext? context,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/user-functions',
        data: {
          'userId': userId,
          'ministryId': ministryId,
          'functionId': functionId,
          if (notes != null) 'notes': notes,
          if (status != null) 'status': status,
        },
      );

      if (response.statusCode == 201) {
        if (context != null) {
          FeedbackService.showCreateSuccess(context, 'Vínculo usuário-função');
        }
        return UserFunction.fromJson(response.data);
      } else {
        if (context != null) {
          FeedbackService.showCreateError(context, 'vínculo usuário-função');
        }
        throw Exception('Erro ao criar vínculo usuário-função: ${response.statusMessage}');
      }
    } catch (e) {
      if (context != null) {
        FeedbackService.showCreateError(context, 'vínculo usuário-função');
      }
      throw Exception('Erro ao criar vínculo usuário-função: $e');
    }
  }

  /// PATCH /user-functions/:id/status
  /// Aprovar/rejeitar vínculo usuário-função
  Future<UserFunction> updateUserFunctionStatus({
    required String userFunctionId,
    required UserFunctionStatus status,
    String? notes,
    BuildContext? context,
  }) async {
    try {
      final response = await _dio.patch(
        '$baseUrl/user-functions/$userFunctionId/status',
        data: {
          'status': status.name,
          if (notes != null) 'notes': notes,
        },
      );

      if (response.statusCode == 200) {
        if (context != null) {
          FeedbackService.showUpdateSuccess(context, 'Status do vínculo');
        }
        return UserFunction.fromJson(response.data);
      } else {
        if (context != null) {
          FeedbackService.showUpdateError(context, 'status do vínculo');
        }
        throw Exception('Erro ao atualizar status: ${response.statusMessage}');
      }
    } catch (e) {
      if (context != null) {
        FeedbackService.showUpdateError(context, 'status do vínculo');
      }
      throw Exception('Erro ao atualizar status: $e');
    }
  }

  /// GET /user-functions/user/:userId
  /// Listar funções de um usuário
  Future<List<UserFunction>> getUserFunctionsByUser({
    required String userId,
    UserFunctionStatus? status,
    BuildContext? context,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) {
        queryParams['status'] = status.name;
      }

      final response = await _dio.get(
        '$baseUrl/user-functions/user/$userId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return (response.data as List<dynamic>)
            .map((item) => UserFunction.fromJson(item))
            .toList();
      } else {
        if (context != null) {
          FeedbackService.showLoadError(context, 'funções do usuário');
        }
        throw Exception('Erro ao listar funções do usuário: ${response.statusMessage}');
      }
    } catch (e) {
      if (context != null) {
        FeedbackService.showLoadError(context, 'funções do usuário');
      }
      throw Exception('Erro ao listar funções do usuário: $e');
    }
  }

  /// GET /user-functions/ministry/:ministryId
  /// Listar funções de um ministério
  Future<List<UserFunction>> getUserFunctionsByMinistry({
    required String ministryId,
    UserFunctionStatus? status,
    BuildContext? context,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) {
        queryParams['status'] = status.name;
      }

      final response = await _dio.get(
        '$baseUrl/user-functions/ministry/$ministryId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return (response.data as List<dynamic>)
            .map((item) => UserFunction.fromJson(item))
            .toList();
      } else {
        if (context != null) {
          FeedbackService.showLoadError(context, 'funções do ministério');
        }
        throw Exception('Erro ao listar funções do ministério: ${response.statusMessage}');
      }
    } catch (e) {
      if (context != null) {
        FeedbackService.showLoadError(context, 'funções do ministério');
      }
      throw Exception('Erro ao listar funções do ministério: $e');
    }
  }

  /// GET /user-functions/user/:userId/approved
  /// Listar funções aprovadas de um usuário
  Future<List<UserFunction>> getApprovedFunctionsForUser({
    required String userId,
    BuildContext? context,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/user-functions/user/$userId/approved',
      );

      if (response.statusCode == 200) {
        return (response.data as List<dynamic>)
            .map((item) => UserFunction.fromJson(item))
            .toList();
      } else {
        if (context != null) {
          FeedbackService.showLoadError(context, 'funções aprovadas');
        }
        throw Exception('Erro ao listar funções aprovadas: ${response.statusMessage}');
      }
    } catch (e) {
      if (context != null) {
        FeedbackService.showLoadError(context, 'funções aprovadas');
      }
      throw Exception('Erro ao listar funções aprovadas: $e');
    }
  }

  /// DELETE /user-functions/:id
  /// Remover vínculo usuário-função
  Future<void> deleteUserFunction({
    required String userFunctionId,
    BuildContext? context,
  }) async {
    try {
      final response = await _dio.delete(
        '$baseUrl/user-functions/$userFunctionId',
      );

      if (response.statusCode == 200) {
        if (context != null) {
          FeedbackService.showDeleteSuccess(context, 'Vínculo usuário-função');
        }
      } else {
        if (context != null) {
          FeedbackService.showDeleteError(context, 'vínculo usuário-função');
        }
        throw Exception('Erro ao remover vínculo: ${response.statusMessage}');
      }
    } catch (e) {
      if (context != null) {
        FeedbackService.showDeleteError(context, 'vínculo usuário-função');
      }
      throw Exception('Erro ao remover vínculo: $e');
    }
  }
}
