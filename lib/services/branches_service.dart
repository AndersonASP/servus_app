import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:servus_app/core/models/branch.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/core/constants/env.dart';
import 'package:servus_app/core/services/feedback_service.dart';

class BranchesService {
  static const String baseUrl = Env.baseUrl;
  
  static Future<Map<String, String>> _getHeaders() async {
    final token = await TokenService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<String> _getTenantId() async {
    final token = await TokenService.getAccessToken();
    if (token == null) throw Exception('Token não encontrado');
    
    // Decodificar o token JWT para extrair o tenantId
    final parts = token.split('.');
    if (parts.length != 3) throw Exception('Token inválido');
    
    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final resp = utf8.decode(base64Url.decode(normalized));
    final payloadMap = json.decode(resp);
    
    return payloadMap['tenantId'] ?? '';
  }

  /// Lista todas as filiais do tenant com filtros opcionais
  static Future<BranchListResponse> getBranches({
    BranchFilter? filter,
    BuildContext? context,
  }) async {
    try {
      final tenantId = await _getTenantId();
      final headers = await _getHeaders();
      
      final queryParams = filter?.toJson() ?? {};
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      
      final url = Uri.parse('$baseUrl/tenants/$tenantId/branches?$queryString');
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BranchListResponse.fromJson(data);
      } else {
        if (context != null) {
          FeedbackService.showLoadError(context, 'filiais');
        }
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Erro ao buscar filiais');
      }
    } catch (e) {
      if (context != null) {
        FeedbackService.showLoadError(context, 'filiais');
      }
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  /// Obtém detalhes de uma filial específica
  static Future<Branch> getBranchById(String branchId, {BuildContext? context}) async {
    try {
      final tenantId = await _getTenantId();
      final headers = await _getHeaders();
      
      final url = Uri.parse('$baseUrl/tenants/$tenantId/branches/$branchId');
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Branch.fromJson(data);
      } else {
        if (context != null) {
          FeedbackService.showLoadError(context, 'filial');
        }
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Erro ao buscar filial');
      }
    } catch (e) {
      if (context != null) {
        FeedbackService.showLoadError(context, 'filial');
      }
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  /// Cria uma nova filial
  static Future<Branch> createBranch(Map<String, dynamic> branchData, {BuildContext? context}) async {
    try {
      final tenantId = await _getTenantId();
      final headers = await _getHeaders();
      
      final url = Uri.parse('$baseUrl/tenants/$tenantId/branches');
      
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(branchData),
      );
      
      if (response.statusCode == 201) {
        if (context != null) {
          FeedbackService.showCreateSuccess(context, 'Filial');
        }
        final data = json.decode(response.body);
        return Branch.fromJson(data);
      } else {
        if (context != null) {
          FeedbackService.showCreateError(context, 'filial');
        }
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Erro ao criar filial');
      }
    } catch (e) {
      if (context != null) {
        FeedbackService.showCreateError(context, 'filial');
      }
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  /// Cria uma filial com administrador
  static Future<Map<String, dynamic>> createBranchWithAdmin({
    required Map<String, dynamic> branchData,
    required Map<String, dynamic> adminData,
    BuildContext? context,
  }) async {
    try {
      final tenantId = await _getTenantId();
      final headers = await _getHeaders();
      
      final url = Uri.parse('$baseUrl/tenants/$tenantId/branches/with-admin');
      
      final requestData = {
        'branchData': branchData,
        'adminData': adminData,
      };
      
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(requestData),
      );
      
      if (response.statusCode == 201) {
        if (context != null) {
          FeedbackService.showCreateSuccess(context, 'Filial com administrador');
        }
        return json.decode(response.body);
      } else {
        if (context != null) {
          FeedbackService.showCreateError(context, 'filial com administrador');
        }
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Erro ao criar filial com administrador');
      }
    } catch (e) {
      if (context != null) {
        FeedbackService.showCreateError(context, 'filial com administrador');
      }
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  /// Atualiza uma filial existente
  static Future<Branch> updateBranch(String branchId, Map<String, dynamic> updateData, {BuildContext? context}) async {
    try {
      final tenantId = await _getTenantId();
      final headers = await _getHeaders();
      
      final url = Uri.parse('$baseUrl/tenants/$tenantId/branches/$branchId');
      
      final response = await http.put(
        url,
        headers: headers,
        body: json.encode(updateData),
      );
      
      if (response.statusCode == 200) {
        if (context != null) {
          FeedbackService.showUpdateSuccess(context, 'Filial');
        }
        final data = json.decode(response.body);
        return Branch.fromJson(data);
      } else {
        if (context != null) {
          FeedbackService.showUpdateError(context, 'filial');
        }
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Erro ao atualizar filial');
      }
    } catch (e) {
      if (context != null) {
        FeedbackService.showUpdateError(context, 'filial');
      }
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  /// Desativa uma filial (soft delete)
  static Future<void> deactivateBranch(String branchId, {BuildContext? context}) async {
    try {
      final tenantId = await _getTenantId();
      final headers = await _getHeaders();
      
      final url = Uri.parse('$baseUrl/tenants/$tenantId/branches/$branchId');
      
      final response = await http.delete(url, headers: headers);
      
      if (response.statusCode == 200) {
        if (context != null) {
          FeedbackService.showDeleteSuccess(context, 'Filial');
        }
      } else {
        if (context != null) {
          FeedbackService.showDeleteError(context, 'filial');
        }
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Erro ao desativar filial');
      }
    } catch (e) {
      if (context != null) {
        FeedbackService.showDeleteError(context, 'filial');
      }
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  /// Remove uma filial permanentemente
  static Future<void> removeBranch(String branchId, {BuildContext? context}) async {
    try {
      final tenantId = await _getTenantId();
      final headers = await _getHeaders();
      
      final url = Uri.parse('$baseUrl/tenants/$tenantId/branches/$branchId/permanent');
      
      final response = await http.delete(url, headers: headers);
      
      if (response.statusCode == 200) {
        if (context != null) {
          FeedbackService.showDeleteSuccess(context, 'Filial');
        }
      } else {
        if (context != null) {
          FeedbackService.showDeleteError(context, 'filial');
        }
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Erro ao remover filial');
      }
    } catch (e) {
      if (context != null) {
        FeedbackService.showDeleteError(context, 'filial');
      }
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  /// Busca filiais por termo de pesquisa
  static Future<BranchListResponse> searchBranches(String searchTerm, {BuildContext? context}) async {
    final filter = BranchFilter(
      search: searchTerm,
      page: 1,
      limit: 50,
    );
    return getBranches(filter: filter, context: context);
  }

  /// Busca filiais por cidade
  static Future<BranchListResponse> getBranchesByCity(String city, {BuildContext? context}) async {
    final filter = BranchFilter(
      cidade: city,
      page: 1,
      limit: 50,
    );
    return getBranches(filter: filter, context: context);
  }

  /// Busca filiais por estado
  static Future<BranchListResponse> getBranchesByState(String state, {BuildContext? context}) async {
    final filter = BranchFilter(
      estado: state,
      page: 1,
      limit: 50,
    );
    return getBranches(filter: filter, context: context);
  }

  /// Busca apenas filiais ativas
  static Future<BranchListResponse> getActiveBranches({BuildContext? context}) async {
    final filter = BranchFilter(
      isActive: true,
      page: 1,
      limit: 100,
    );
    return getBranches(filter: filter, context: context);
  }

  /// Busca apenas filiais inativas
  static Future<BranchListResponse> getInactiveBranches({BuildContext? context}) async {
    final filter = BranchFilter(
      isActive: false,
      page: 1,
      limit: 100,
    );
    return getBranches(filter: filter, context: context);
  }

  /// Vincula um administrador à filial
  static Future<Map<String, dynamic>> assignAdmin(
    String branchId,
    Map<String, dynamic> assignData,
  ) async {
    try {
      final tenantId = await _getTenantId();
      final headers = await _getHeaders();
      
      final url = Uri.parse('$baseUrl/tenants/$tenantId/branches/$branchId/assign-admin');
      
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(assignData),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Erro ao vincular administrador');
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }
}
