import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:servus_app/core/constants/env.dart';
import 'package:servus_app/features/ministries/models/member_function.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';

class MemberFunctionService {
  final Dio _dio;
  static const String baseUrl = Env.baseUrl;

  MemberFunctionService() : _dio = DioClient.instance;

  /// POST /member-functions
  /// Criar vínculo membro-função
  Future<MemberFunction> createMemberFunction({
    required String userId,
    required String ministryId,
    required String functionId,
    String? status,
    String? notes,
    BuildContext? context,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/member-functions',
        data: {
          'userId': userId,
          'ministryId': ministryId,
          'functionId': functionId,
          if (status != null) 'status': status,
          if (notes != null) 'notes': notes,
        },
      );

      if (response.statusCode == 201) {
        if (context != null) {
          showCreateSuccess(context, 'Vínculo membro-função');
        }
        return MemberFunction.fromJson(response.data);
      } else {
        if (context != null) {
          showCreateError(context, 'vínculo membro-função');
        }
        throw Exception('Erro ao criar vínculo membro-função: ${response.statusMessage}');
      }
    } catch (e) {
      if (context != null) {
        showCreateError(context, 'vínculo membro-função');
      }
      throw Exception('Erro ao criar vínculo membro-função: $e');
    }
  }

  /// GET /member-functions/user/:userId/approved
  /// Listar funções aprovadas de um usuário
  Future<List<MemberFunction>> getApprovedFunctionsForUser({
    required String userId,
    BuildContext? context,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/member-functions/user/$userId/approved',
      );

      if (response.statusCode == 200) {
        return (response.data as List<dynamic>)
            .map((item) => MemberFunction.fromJson(item))
            .toList();
      } else {
        if (context != null) {
          showLoadError(context, 'funções aprovadas');
        }
        throw Exception('Erro ao listar funções aprovadas: ${response.statusMessage}');
      }
    } catch (e) {
      if (context != null) {
        showLoadError(context, 'funções aprovadas');
      }
      throw Exception('Erro ao listar funções aprovadas: $e');
    }
  }

  /// GET /member-functions/user/:userId
  /// Listar todas as funções de um usuário
  Future<List<MemberFunction>> getMemberFunctions({
    required String userId,
    BuildContext? context,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/member-functions/user/$userId',
      );

      if (response.statusCode == 200) {
        return (response.data as List<dynamic>)
            .map((item) => MemberFunction.fromJson(item))
            .toList();
      } else {
        if (context != null) {
          showLoadError(context, 'funções do usuário');
        }
        throw Exception('Erro ao listar funções do usuário: ${response.statusMessage}');
      }
    } catch (e) {
      if (context != null) {
        showLoadError(context, 'funções do usuário');
      }
      throw Exception('Erro ao listar funções do usuário: $e');
    }
  }

  /// GET /member-functions/user/:userId/ministry/:ministryId
  /// Listar funções de um usuário em um ministério específico
  Future<List<MemberFunction>> getMemberFunctionsByUserAndMinistry({
    required String userId,
    required String ministryId,
    String? status,
    BuildContext? context,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _dio.get(
        '$baseUrl/member-functions/user/$userId/ministry/$ministryId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return (response.data as List<dynamic>)
            .map((item) => MemberFunction.fromJson(item))
            .toList();
      } else {
        if (context != null) {
          showLoadError(context, 'funções do usuário no ministério');
        }
        throw Exception('Erro ao listar funções do usuário no ministério: ${response.statusMessage}');
      }
    } catch (e) {
      if (context != null) {
        showLoadError(context, 'funções do usuário no ministério');
      }
      throw Exception('Erro ao listar funções do usuário no ministério: $e');
    }
  }
}
