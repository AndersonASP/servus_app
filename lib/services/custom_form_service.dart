import 'package:dio/dio.dart';
import 'package:servus_app/core/models/custom_form.dart';
import 'package:servus_app/core/models/form_submission.dart';
import 'package:servus_app/services/auth_context_service.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:servus_app/core/error/notification_service.dart';

class CustomFormService {
  final Dio _dio = DioClient.instance;
  final AuthContextService _authContext = AuthContextService.instance;
  final NotificationService _errorService = NotificationService();

  CustomFormService() {
    
    // Adicionar interceptor para headers de autenticação específicos do formulário
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        
        if (_authContext.hasContext) {
          try {
            final headers = await _authContext.headers;
            options.headers.addAll(headers);
          } catch (e) {
            // Log do erro mas continua a requisição
            print('Erro ao obter headers de autenticação: $e');
          }
        }
        
        handler.next(options);
      },
      onResponse: (response, handler) {
        handler.next(response);
      },
      onError: (error, handler) {
        if (error.response != null) {
        }
        handler.next(error);
      },
    ));
  }

  /// Busca formulários do tenant
  Future<Map<String, dynamic>> getTenantForms({
    int page = 1,
    int limit = 20,
  }) async {
    
    try {
      
      // Verificar se há contexto de autenticação
      if (!_authContext.hasContext) {
        throw Exception('Contexto de autenticação não encontrado');
      }
      
      
      final headers = await _authContext.headers;
      
      
      final response = await _dio.get('/forms', 
        queryParameters: {
          'page': page,
          'limit': limit,
        },
        options: Options(headers: headers),
      );

      
      if (response.data is Map) {
        final data = response.data as Map;
        
        final formsData = data['data'];
        
        if (formsData is List) {
        }
      }

      final formsData = response.data['data'] as List<dynamic>?;
      
      if (formsData != null && formsData.isNotEmpty) {
      }
      
      final forms = formsData
          ?.map((form) {
            try {
              return CustomForm.fromMap(form);
            } catch (e) {
              rethrow;
            }
          })
          .toList() ?? [];
      
      
      final result = {
        'forms': forms,
        'pagination': response.data['pagination'] ?? {},
      };
      
      
      return result;
    } catch (e) {
      if (e is DioException) {
        _errorService.handleDioError(e, customMessage: 'Erro ao listar formulários');
      } else {
        _errorService.handleGenericError(e);
      }
      rethrow;
    }
  }

  /// Busca um formulário por ID
  Future<CustomForm> getFormById(String formId) async {
    try {
      
      // Verificar se há contexto de autenticação
      if (!_authContext.hasContext) {
        throw Exception('Contexto de autenticação não encontrado');
      }
      
      final response = await _dio.get('/forms/$formId',
        options: Options(headers: await _authContext.headers),
      );
      
      
      return CustomForm.fromMap(response.data['data']);
    } catch (e) {
      if (e is DioException) {
        _errorService.handleDioError(e, customMessage: 'Erro ao carregar formulário');
      } else {
        _errorService.handleGenericError(e);
      }
      rethrow;
    }
  }

  /// Busca um formulário público por ID
  Future<CustomForm> getPublicForm(String formId) async {
    try {
      
      final response = await _dio.get('/forms/public/$formId');
      
      
      return CustomForm.fromMap(response.data['data']);
    } catch (e) {
      if (e is DioException) {
        _errorService.handleDioError(e, customMessage: 'Erro ao carregar formulário');
      } else {
        _errorService.handleGenericError(e);
      }
      rethrow;
    }
  }

  /// Cria um novo formulário
  Future<CustomForm> createForm(CustomForm form) async {
    try {
      
      // Verificar se há contexto de autenticação
      if (!_authContext.hasContext) {
        throw Exception('Contexto de autenticação não encontrado');
      }
      
      final response = await _dio.post('/forms', 
        data: form.toMap(),
        options: Options(headers: await _authContext.headers),
      );
      
      
      return CustomForm.fromMap(response.data['data']);
    } catch (e) {
      if (e is DioException) {
        _errorService.handleDioError(e, customMessage: 'Erro ao carregar formulário');
      } else {
        _errorService.handleGenericError(e);
      }
      rethrow;
    }
  }

  /// Atualiza um formulário
  Future<CustomForm> updateForm(String formId, Map<String, dynamic> updateData) async {
    try {
      
      // Verificar se há contexto de autenticação
      if (!_authContext.hasContext) {
        throw Exception('Contexto de autenticação não encontrado');
      }
      
      final response = await _dio.put('/forms/$formId', 
        data: updateData,
        options: Options(headers: await _authContext.headers),
      );
      
      
      return CustomForm.fromMap(response.data['data']);
    } catch (e) {
      if (e is DioException) {
        _errorService.handleDioError(e, customMessage: 'Erro ao carregar formulário');
      } else {
        _errorService.handleGenericError(e);
      }
      rethrow;
    }
  }

  /// Submete um formulário
  Future<FormSubmission> submitForm(String formId, FormSubmissionData data) async {
    try {
      
      final response = await _dio.post('/forms/$formId/submit', data: data.toMap());
      
      
      return FormSubmission.fromMap(response.data['data']);
    } catch (e) {
      if (e is DioException) {
        _errorService.handleDioError(e, customMessage: 'Erro ao carregar formulário');
      } else {
        _errorService.handleGenericError(e);
      }
      rethrow;
    }
  }

  /// Busca submissões de um formulário
  Future<Map<String, dynamic>> getFormSubmissions({
    required String formId,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      
      // Verificar se há contexto de autenticação
      if (!_authContext.hasContext) {
        throw Exception('Contexto de autenticação não encontrado');
      }
      
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (status != null) {
        queryParams['status'] = status;
      }
      
      final response = await _dio.get('/forms/$formId/submissions', 
        queryParameters: queryParams,
        options: Options(headers: await _authContext.headers),
      );
      
      
      return {
        'submissions': (response.data['data'] as List<dynamic>?)
            ?.map((submission) => FormSubmission.fromMap(submission))
            .toList() ?? [],
        'pagination': response.data['pagination'] ?? {},
      };
    } catch (e) {
      if (e is DioException) {
        _errorService.handleDioError(e, customMessage: 'Erro ao carregar formulário');
      } else {
        _errorService.handleGenericError(e);
      }
      rethrow;
    }
  }

  /// Revisa uma submissão
  Future<FormSubmission> reviewSubmission(
    String submissionId,
    String status,
    String? reviewNotes,
  ) async {
    try {
      
      // Verificar se há contexto de autenticação
      if (!_authContext.hasContext) {
        throw Exception('Contexto de autenticação não encontrado');
      }
      
      final response = await _dio.put('/forms/submissions/$submissionId/review', 
        data: {
          'status': status,
          'reviewNotes': reviewNotes,
        },
        options: Options(headers: await _authContext.headers),
      );
      
      
      return FormSubmission.fromMap(response.data['data']);
    } catch (e) {
      if (e is DioException) {
        _errorService.handleDioError(e, customMessage: 'Erro ao carregar formulário');
      } else {
        _errorService.handleGenericError(e);
      }
      rethrow;
    }
  }

  /// Revisa múltiplas submissões
  Future<Map<String, dynamic>> bulkReviewSubmissions({
    required List<String> submissionIds,
    required String status,
    String? reviewNotes,
  }) async {
    try {
      
      // Verificar se há contexto de autenticação
      if (!_authContext.hasContext) {
        throw Exception('Contexto de autenticação não encontrado');
      }
      
      final response = await _dio.put('/forms/submissions/bulk-review', 
        data: {
          'submissionIds': submissionIds,
          'status': status,
          'reviewNotes': reviewNotes,
        },
        options: Options(headers: await _authContext.headers),
      );
      
      
      return response.data['data'];
    } catch (e) {
      if (e is DioException) {
        _errorService.handleDioError(e, customMessage: 'Erro ao carregar formulário');
      } else {
        _errorService.handleGenericError(e);
      }
      rethrow;
    }
  }

  /// Processa submissões aprovadas
  Future<Map<String, dynamic>> processApprovedSubmissions(String formId) async {
    try {
      
      // Verificar se há contexto de autenticação
      if (!_authContext.hasContext) {
        throw Exception('Contexto de autenticação não encontrado');
      }
      
      final headers = await _authContext.headers;
      final response = await _dio.post('/forms/$formId/process',
        options: Options(headers: headers),
      );
      
      
      return response.data['data'];
    } catch (e) {
      if (e is DioException) {
        _errorService.handleDioError(e, customMessage: 'Erro ao carregar formulário');
      } else {
        _errorService.handleGenericError(e);
      }
      rethrow;
    }
  }

  /// Deleta um formulário
  Future<void> deleteForm(String formId) async {
    try {
      
      // Verificar se há contexto de autenticação
      if (!_authContext.hasContext) {
        throw Exception('Contexto de autenticação não encontrado');
      }
      
      final headers = await _authContext.headers;
      await _dio.delete('/forms/$formId',
        options: Options(headers: headers),
      );
      
    } catch (e) {
      if (e is DioException) {
        _errorService.handleDioError(e, customMessage: 'Erro ao carregar formulário');
      } else {
        _errorService.handleGenericError(e);
      }
      rethrow;
    }
  }
}
