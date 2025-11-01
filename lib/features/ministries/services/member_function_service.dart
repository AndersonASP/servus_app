import 'package:dio/dio.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:servus_app/core/constants/env.dart';
import 'package:servus_app/features/ministries/models/member_function.dart';
import 'package:servus_app/core/error/notification_service.dart';

class MemberFunctionService {
  final Dio _dio;
  final NotificationService _errorService = NotificationService();
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
        _errorService.showSuccess('Vínculo membro-função criado com sucesso!');
        return MemberFunction.fromJson(response.data);
      } else {
        _errorService.handleGenericError('Erro ao criar vínculo membro-função');
        throw Exception('Erro ao criar vínculo membro-função: ${response.statusMessage}');
      }
    } catch (e) {
      if (e is DioException) {
        _errorService.handleDioError(e, customMessage: 'Erro ao criar vínculo membro-função');
      } else {
        _errorService.handleGenericError('Erro ao criar vínculo membro-função');
      }
      rethrow;
    }
  }

  /// GET /member-functions/user/:userId/approved
  /// Listar funções aprovadas de um usuário
  Future<List<MemberFunction>> getApprovedFunctionsForUser({
    required String userId,
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
        _errorService.handleGenericError('Erro ao carregar funções aprovadas');
        throw Exception('Erro ao listar funções aprovadas: ${response.statusMessage}');
      }
    } catch (e) {
      if (e is DioException) {
        _errorService.handleDioError(e, customMessage: 'Erro ao carregar funções aprovadas');
      } else {
        _errorService.handleGenericError('Erro ao carregar funções aprovadas');
      }
      rethrow;
    }
  }

  /// GET /member-functions/user/:userId
  /// Listar todas as funções de um usuário
  Future<List<MemberFunction>> getMemberFunctions({
    required String userId,
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
        _errorService.handleGenericError('Erro ao carregar funções do usuário');
        throw Exception('Erro ao listar funções do usuário: ${response.statusMessage}');
      }
    } catch (e) {
      if (e is DioException) {
        _errorService.handleDioError(e, customMessage: 'Erro ao carregar funções do usuário');
      } else {
        _errorService.handleGenericError('Erro ao carregar funções do usuário');
      }
      rethrow;
    }
  }

  /// GET /member-functions/user/:userId/ministry/:ministryId
  /// Listar funções de um usuário em um ministério específico
  Future<List<MemberFunction>> getMemberFunctionsByUserAndMinistry({
    required String userId,
    required String ministryId,
    String? status,
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
        _errorService.handleGenericError('Erro ao carregar funções do usuário no ministério');
        throw Exception('Erro ao listar funções do usuário no ministério: ${response.statusMessage}');
      }
    } catch (e) {
      if (e is DioException) {
        _errorService.handleDioError(e, customMessage: 'Erro ao carregar funções do usuário no ministério');
      } else {
        _errorService.handleGenericError('Erro ao carregar funções do usuário no ministério');
      }
      rethrow;
    }
  }

  /// GET /member-functions/ministry/:ministryId/function/:functionId/approved
  /// Busca membros aprovados para uma função específica em um ministério
  Future<List<MemberFunction>> getApprovedMembersByFunction({
    required String ministryId,
    required String functionId,
  }) async {
    print('🔄 [MemberFunctionService] Buscando membros aprovados...');
    print('   - MinistryId: $ministryId');
    print('   - FunctionId: $functionId');
    
    try {
      final response = await _dio.get(
        '$baseUrl/member-functions/ministry/$ministryId/function/$functionId/approved',
      );

      print('📡 [MemberFunctionService] Resposta recebida: ${response.statusCode}');
      print('   - Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        print('📋 [MemberFunctionService] Total de itens: ${data.length}');
        
        final result = data.map((item) => MemberFunction.fromJson(item)).toList();
        
        print('✅ [MemberFunctionService] Membros processados: ${result.length}');
        for (final member in result) {
          print('   - ${member.user?.name} (${member.userId}) - Status: ${member.status}');
        }
        
        return result;
      } else {
        _errorService.handleGenericError('Erro ao buscar voluntários para esta função');
        throw Exception('Erro ao buscar voluntários: ${response.statusMessage}');
      }
    } catch (e) {
      print('❌ [MemberFunctionService] Erro na requisição: $e');
      if (e is DioException) {
        _errorService.handleDioError(e, customMessage: 'Erro ao buscar voluntários para esta função');
      } else {
        _errorService.handleGenericError('Erro ao buscar voluntários para esta função');
      }
      rethrow;
    }
  }
}
