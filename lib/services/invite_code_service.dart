import 'package:dio/dio.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:servus_app/core/models/invite_code.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/core/error/error_handler_service.dart';
import 'package:servus_app/core/constants/env.dart';

class InviteCodeService {
  final Dio _dio = DioClient.instance;
  
  /// Dio para requisições públicas (sem autenticação)
  late final Dio _publicDio;

  InviteCodeService() {
    // Criar cliente público sem interceptor de autenticação
    _publicDio = Dio(BaseOptions(
      baseUrl: Env.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
    ));
    
    // Adicionar apenas interceptor de retry (sem AuthInterceptor)
    _publicDio.interceptors.add(RetryInterceptor(
      dio: _publicDio,
      logPrint: print,
      retries: 2,
      retryDelays: const [
        Duration(seconds: 2),
        Duration(seconds: 5),
      ],
    ));
  }

  /// Valida um código de convite (requisição pública, sem autenticação)
  Future<InviteCodeValidation> validateInviteCode(String code) async {
    try {
      final response = await _publicDio.post(
        '/invite-codes/validate',
        data: {'code': code.toUpperCase()},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            // Garantir que nenhum header de contexto seja enviado
            'device-id': '', // Header vazio para evitar problemas
          },
        ),
      );

      
      if (response.statusCode == 200) {
        final validation = InviteCodeValidation.fromMap(response.data);
        return validation;
      } else {
        throw Exception('Erro ao validar código: ${response.statusCode}');
      }
    } on DioException catch (e) {
      ErrorHandlerService().logError(e, context: 'validação de código de convite');
      if (e.response?.statusCode == 400) {
        return InviteCodeValidation(
          isValid: false,
          message: e.response?.data['message'] ?? 'Este código de convite não é válido ou já expirou.',
        );
      }
      throw Exception('Não foi possível validar o código. Verifique sua conexão e tente novamente.');
    }
  }

  /// Registra um novo usuário usando código de convite (requisição pública, sem autenticação)
  Future<Map<String, dynamic>> registerWithInviteCode(
    InviteRegistrationData data,
  ) async {
    try {
      print('🌐 Enviando requisição de registro...');
      print('   - URL: ${Env.baseUrl}/invite-codes/register');
      print('   - Dados: ${data.toMap()}');
      
      final response = await _publicDio.post(
        '/invite-codes/register',
        data: data.toMap(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            // Garantir que nenhum header de contexto seja enviado
            'device-id': '', // Header vazio para evitar problemas
          },
        ),
      );

      print('📡 Resposta recebida:');
      print('   - Status: ${response.statusCode}');
      print('   - Dados: ${response.data}');
      
      if (response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Erro ao registrar usuário: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Erro DioException:');
      print('   - Tipo: ${e.type}');
      print('   - Status: ${e.response?.statusCode}');
      print('   - Mensagem: ${e.message}');
      print('   - Dados: ${e.response?.data}');
      
      ErrorHandlerService().logError(e, context: 'registro de usuário com código de convite');
      
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'Não foi possível criar sua conta. Verifique os dados e tente novamente.';
        throw Exception(message);
      } else if (e.response?.statusCode == 409) {
        throw Exception('Email já está em uso. Tente fazer login ou use outro email.');
      } else if (e.type == DioExceptionType.connectionTimeout || 
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.sendTimeout) {
        throw Exception('Timeout na conexão. Verifique sua internet e tente novamente.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Erro de conexão. Verifique sua internet e tente novamente.');
      }
      
      throw Exception('Não foi possível criar sua conta. Verifique sua conexão e tente novamente.');
    } catch (e) {
      print('❌ Erro geral: $e');
      rethrow;
    }
  }

  /// Cria ou regenera código de convite para um ministério
  Future<InviteCode> createMinistryInviteCode(
    String ministryId, {
    bool regenerate = false,
    DateTime? expiresAt,
  }) async {
    try {
      final token = await TokenService.getAccessToken();
      if (token == null) {
        throw Exception('Token de acesso não encontrado');
      }

      final response = await _dio.post(
        '/invite-codes/ministries/$ministryId',
        data: {
          'regenerate': regenerate,
          if (expiresAt != null) 'expiresAt': expiresAt.toIso8601String(),
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201) {
        return InviteCode.fromMap(response.data['data']);
      } else {
        throw Exception('Erro ao criar código: ${response.statusCode}');
      }
    } on DioException catch (e) {
      ErrorHandlerService().logError(e, context: 'criação de código de convite');
      if (e.response?.statusCode == 400) {
        throw Exception(e.response?.data['message'] ?? 'Não foi possível criar o código de convite. Tente novamente.');
      }
      throw Exception('Não foi possível criar o código de convite. Verifique sua conexão e tente novamente.');
    }
  }

  /// Busca códigos de convite de um ministério
  Future<List<InviteCode>> getMinistryInviteCodes(String ministryId) async {
    try {
      final token = await TokenService.getAccessToken();
      if (token == null) {
        throw Exception('Token de acesso não encontrado');
      }

      final response = await _dio.get(
        '/invite-codes/ministries/$ministryId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((item) => InviteCode.fromMap(item)).toList();
      } else {
        throw Exception('Erro ao buscar códigos: ${response.statusCode}');
      }
    } on DioException catch (e) {
      ErrorHandlerService().logError(e, context: 'busca de códigos de convite');
      if (e.response?.statusCode == 400) {
        throw Exception(e.response?.data['message'] ?? 'Não foi possível buscar os códigos de convite. Tente novamente.');
      }
      throw Exception('Não foi possível buscar os códigos de convite. Verifique sua conexão e tente novamente.');
    }
  }

  /// Regenera código de convite de um ministério
  Future<InviteCode> regenerateMinistryInviteCode(
    String ministryId, {
    DateTime? expiresAt,
  }) async {
    try {
      final token = await TokenService.getAccessToken();
      if (token == null) {
        throw Exception('Token de acesso não encontrado');
      }

      final response = await _dio.put(
        '/invite-codes/ministries/$ministryId/regenerate',
        data: {
          if (expiresAt != null) 'expiresAt': expiresAt.toIso8601String(),
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return InviteCode.fromMap(response.data['data']);
      } else {
        throw Exception('Erro ao regenerar código: ${response.statusCode}');
      }
    } on DioException catch (e) {
      ErrorHandlerService().logError(e, context: 'regeneração de código de convite');
      if (e.response?.statusCode == 400) {
        throw Exception(e.response?.data['message'] ?? 'Não foi possível regenerar o código de convite. Tente novamente.');
      }
      throw Exception('Não foi possível regenerar o código de convite. Verifique sua conexão e tente novamente.');
    }
  }
}
