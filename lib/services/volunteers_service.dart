import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:servus_app/core/constants/env.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';

class VolunteersService {
  static const String baseUrl = Env.baseUrl;
  static const String endpoint = '/volunteers';

  // Obter token de autenticação
  static Future<String?> _getAuthToken() async {
    return await TokenService.getAccessToken();
  }

  // Obter tenantId do token
  static Future<String?> _getTenantId() async {
    final token = await _getAuthToken();
    if (token == null) return null;
    
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(resp);
      
      return payloadMap['tenantId'];
    } catch (e) {
      return null;
    }
  }

  // Deletar voluntário
  static Future<void> deleteVolunteer(String id, BuildContext context) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        showAuthError(context);
        throw Exception('Token de autenticação não encontrado');
      }

      // Obter tenantId do token
      final tenantId = await _getTenantId();
      if (tenantId == null) {
        showAuthError(context);
        throw Exception('Tenant ID não encontrado no token');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/tenants/$tenantId/volunteers/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'x-tenant-id': tenantId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Sucesso - não mostrar snackbar aqui, será mostrado no controller
        return;
      } else {
        final error = jsonDecode(response.body);
        showDeleteError(context, 'voluntário');
        throw Exception(error['message'] ?? 'Erro ao deletar voluntário');
      }
    } catch (e) {
      debugPrint('Erro ao deletar voluntário: $e');
      if (e.toString().contains('Token de autenticação não encontrado') ||
          e.toString().contains('Tenant ID não encontrado')) {
        // Já foi tratado acima
        return;
      }
      showDeleteError(context, 'voluntário');
      rethrow;
    }
  }
}
