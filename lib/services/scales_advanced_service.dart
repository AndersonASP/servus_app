import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:servus_app/core/auth/services/token_service.dart';

class ScalesAdvancedService {
  static const String _baseUrl = 'http://localhost:3000';

  // ========================================
  // 📅 DISPONIBILIDADE DE VOLUNTÁRIOS
  // ========================================

  /// Criar ou atualizar disponibilidade de um voluntário
  static Future<Map<String, dynamic>> createOrUpdateAvailability({
    required String tenantId,
    required String userId,
    required String ministryId,
    required List<Map<String, dynamic>> blockedDates,
    int? maxBlockedDaysPerMonth,
    bool? isActive,
    String? branchId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/scales/availability'),
        headers: {
          'Content-Type': 'application/json',
          'x-tenant-id': tenantId,
        },
        body: jsonEncode({
          'userId': userId,
          'ministryId': ministryId,
          'blockedDates': blockedDates,
          'maxBlockedDaysPerMonth': maxBlockedDaysPerMonth,
          'isActive': isActive,
          'branchId': branchId,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao criar disponibilidade: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  /// Bloquear uma data específica
  static Future<Map<String, dynamic>> blockDate({
    required String tenantId,
    required String userId,
    required String ministryId,
    required String date,
    required String reason,
  }) async {
    try {
      print('🔍 [ScalesAdvancedService] ===== BLOCK DATE INICIADO =====');
      print('🔍 [ScalesAdvancedService] TenantId: $tenantId');
      print('🔍 [ScalesAdvancedService] UserId: $userId');
      print('🔍 [ScalesAdvancedService] MinistryId: $ministryId');
      print('🔍 [ScalesAdvancedService] Date: $date');
      print('🔍 [ScalesAdvancedService] Reason: $reason');
      
      // Obter token de autenticação
      final token = await TokenService.getAccessToken();
      print('🔍 [ScalesAdvancedService] Token obtido: ${token != null ? 'SIM' : 'NÃO'}');
      if (token != null) {
        print('🔍 [ScalesAdvancedService] Token (primeiros 20 chars): ${token.substring(0, 20)}...');
      } else {
        print('❌ [ScalesAdvancedService] Token é NULL - problema de autenticação!');
      }
      
      final url = '$_baseUrl/scales/$tenantId/availability/block-date';
      print('🔍 [ScalesAdvancedService] URL: $url');
      
      final headers = {
        'Content-Type': 'application/json',
        'x-tenant-id': tenantId,
        if (token != null) 'Authorization': 'Bearer $token',
      };
      print('🔍 [ScalesAdvancedService] Headers: $headers');
      
      final body = {
        'userId': userId,
        'ministryId': ministryId,
        'date': date,
        'reason': reason,
      };
      print('🔍 [ScalesAdvancedService] Body: $body');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      print('🔍 [ScalesAdvancedService] Resposta da API: ${response.statusCode}');
      print('🔍 [ScalesAdvancedService] Corpo da resposta: ${response.body}');
      print('🔍 [ScalesAdvancedService] Headers da resposta: ${response.headers}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('✅ [ScalesAdvancedService] Resposta decodificada: $result');
        return result;
      } else {
        print('❌ [ScalesAdvancedService] Erro HTTP: ${response.statusCode}');
        print('❌ [ScalesAdvancedService] Corpo do erro: ${response.body}');
        throw Exception('Erro ao bloquear data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [ScalesAdvancedService] Erro na requisição: $e');
      print('❌ [ScalesAdvancedService] Tipo do erro: ${e.runtimeType}');
      throw Exception('Erro na requisição: $e');
    }
  }

  /// Desbloquear uma data específica
  static Future<Map<String, dynamic>> unblockDate({
    required String tenantId,
    required String userId,
    required String ministryId,
    required String date,
  }) async {
    try {
      // Obter token de autenticação
      final token = await TokenService.getAccessToken();
      print('🔍 [ScalesAdvancedService] Token obtido para unblock: ${token != null ? 'SIM' : 'NÃO'}');
      if (token != null) {
        print('🔍 [ScalesAdvancedService] Token (primeiros 20 chars): ${token.substring(0, 20)}...');
      } else {
        print('❌ [ScalesAdvancedService] Token é NULL - problema de autenticação!');
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/scales/$tenantId/availability/unblock-date'),
        headers: {
          'Content-Type': 'application/json',
          'x-tenant-id': tenantId,
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': userId,
          'ministryId': ministryId,
          'date': date,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao desbloquear data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  /// Verificar disponibilidade de um voluntário
  static Future<Map<String, dynamic>> checkAvailability({
    required String tenantId,
    required String userId,
    required String ministryId,
    required String date,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/scales/availability/check/$userId/$ministryId/$date'),
        headers: {
          'x-tenant-id': tenantId,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao verificar disponibilidade: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  /// Obter informações de dias bloqueados no mês
  static Future<Map<String, dynamic>> getMonthlyBlockedDaysInfo({
    required String tenantId,
    required String userId,
    required String ministryId,
    int? year,
    int? month,
  }) async {
    try {
      String url = '$_baseUrl/scales/availability/monthly-info/$userId/$ministryId';
      if (year != null && month != null) {
        url += '?year=$year&month=$month';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'x-tenant-id': tenantId,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao obter informações mensais: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  /// Obter todas as indisponibilidades de um voluntário
  static Future<Map<String, dynamic>> getVolunteerUnavailabilities({
    required String tenantId,
    required String userId,
    String? ministryId,
  }) async {
    try {
      // Obter token de autenticação
      final token = await TokenService.getAccessToken();
      
      String url = '$_baseUrl/scales/$tenantId/availability/unavailabilities?userId=$userId';
      if (ministryId != null && ministryId.isNotEmpty) {
        url += '&ministryId=$ministryId';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'x-tenant-id': tenantId,
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('🔍 [ScalesAdvancedService] Resposta getVolunteerUnavailabilities: ${response.statusCode}');
      print('🔍 [ScalesAdvancedService] URL: $url');
      print('🔍 [ScalesAdvancedService] Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao obter indisponibilidades: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  // ========================================
  // 🔄 SOLICITAÇÕES DE TROCA
  // ========================================

  /// Buscar candidatos para troca
  static Future<Map<String, dynamic>> findSwapCandidates({
    required String tenantId,
    required String scaleId,
    required String requesterId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/scales/swap/candidates/$scaleId/$requesterId'),
        headers: {
          'x-tenant-id': tenantId,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao buscar candidatos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  /// Criar solicitação de troca
  static Future<Map<String, dynamic>> createSwapRequest({
    required String tenantId,
    required String scaleId,
    required String targetId,
    required String reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/scales/swap/request'),
        headers: {
          'Content-Type': 'application/json',
          'x-tenant-id': tenantId,
        },
        body: jsonEncode({
          'scaleId': scaleId,
          'targetId': targetId,
          'reason': reason,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao criar solicitação de troca: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  /// Responder a uma solicitação de troca
  static Future<Map<String, dynamic>> respondToSwapRequest({
    required String tenantId,
    required String swapRequestId,
    required String responseValue,
    String? rejectionReason,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/scales/swap/request/$swapRequestId/respond'),
        headers: {
          'Content-Type': 'application/json',
          'x-tenant-id': tenantId,
        },
        body: jsonEncode({
          'response': responseValue,
          'rejectionReason': rejectionReason,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao responder solicitação: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  /// Cancelar uma solicitação de troca
  static Future<Map<String, dynamic>> cancelSwapRequest({
    required String tenantId,
    required String swapRequestId,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/scales/swap/request/$swapRequestId/cancel'),
        headers: {
          'x-tenant-id': tenantId,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao cancelar solicitação: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  /// Listar solicitações pendentes para o usuário
  static Future<Map<String, dynamic>> getPendingRequestsForUser({
    required String tenantId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/scales/swap/requests/pending'),
        headers: {
          'x-tenant-id': tenantId,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao obter solicitações pendentes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  /// Listar solicitações enviadas pelo usuário
  static Future<Map<String, dynamic>> getSentRequestsByUser({
    required String tenantId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/scales/swap/requests/sent'),
        headers: {
          'x-tenant-id': tenantId,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao obter solicitações enviadas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  // ========================================
  // 📊 HISTÓRICO DE SERVIÇOS
  // ========================================

  /// Criar registro de histórico de serviço
  static Future<Map<String, dynamic>> createServiceHistory({
    required String tenantId,
    required String userId,
    required String scaleId,
    required String functionId,
    required String ministryId,
    required String serviceDate,
    String? status,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/scales/service-history'),
        headers: {
          'Content-Type': 'application/json',
          'x-tenant-id': tenantId,
        },
        body: jsonEncode({
          'userId': userId,
          'scaleId': scaleId,
          'functionId': functionId,
          'ministryId': ministryId,
          'serviceDate': serviceDate,
          'status': status,
          'notes': notes,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao criar histórico: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  /// Obter estatísticas de serviço de um voluntário
  static Future<Map<String, dynamic>> getVolunteerServiceStats({
    required String tenantId,
    required String userId,
    String? ministryId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      String url = '$_baseUrl/scales/service-history/stats/volunteer/$userId';
      List<String> queryParams = [];
      
      if (ministryId != null) queryParams.add('ministryId=$ministryId');
      if (startDate != null) queryParams.add('startDate=$startDate');
      if (endDate != null) queryParams.add('endDate=$endDate');
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'x-tenant-id': tenantId,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao obter estatísticas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  /// Obter estatísticas de serviço de um ministério
  static Future<Map<String, dynamic>> getMinistryServiceStats({
    required String tenantId,
    required String ministryId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      String url = '$_baseUrl/scales/service-history/stats/ministry/$ministryId';
      List<String> queryParams = [];
      
      if (startDate != null) queryParams.add('startDate=$startDate');
      if (endDate != null) queryParams.add('endDate=$endDate');
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'x-tenant-id': tenantId,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao obter estatísticas do ministério: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  // ========================================
  // 🎯 GERAÇÃO DE ESCALAS
  // ========================================

  /// Gerar sugestões de escalação
  static Future<Map<String, dynamic>> generateScaleAssignments({
    required String tenantId,
    required String scaleId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/scales/generate-assignments/$scaleId'),
        headers: {
          'x-tenant-id': tenantId,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao gerar escalação: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }
}
