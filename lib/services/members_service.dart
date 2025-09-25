import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:servus_app/core/models/member.dart';
import 'package:servus_app/core/constants/env.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';
import 'package:servus_app/core/error/error_handler_service.dart';

class MembersService {
  static const String baseUrl = Env.baseUrl;
  static const String endpoint = '/members';

  // Obter token de autenticação
  static Future<String?> _getAuthToken() async {
    return await TokenService.getAccessToken();
  }

  // Obter tenantId do tokenRRR
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

  // Criar novo membro
  static Future<Member> createMember(CreateMemberRequest request, BuildContext context) async {
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

      // Processar memberships para garantir que leaders tenham funções
      final processedMemberships = <Map<String, dynamic>>[];
      
      for (final membership in request.memberships) {
        
        // Se é leader e não tem funções específicas, deixar vazio para o backend atribuir automaticamente
        if (membership.role == 'leader' && membership.functionIds.isEmpty && membership.ministryId != null) {
        }
        
        final membershipData = {
          'role': membership.role,
          if (membership.branchId != null) 'branchId': membership.branchId,
          if (membership.ministryId != null) 'ministryId': membership.ministryId,
          if (membership.functionIds.isNotEmpty) 'functionIds': membership.functionIds,
          'isActive': true,
        };
        
        processedMemberships.add(membershipData);
      }

      // Converter para a estrutura esperada pelo backend (CreateMemberDto)
      final requestData = {
        'name': request.name,
        if (request.email != null) 'email': request.email,
        if (request.phone != null) 'phone': request.phone,
        if (request.birthDate != null) 'birthDate': request.birthDate,
        if (request.bio != null) 'bio': request.bio,
        if (request.skills != null) 'skills': request.skills,
        if (request.availability != null) 'availability': request.availability,
        if (request.address != null) 'address': request.address!.toJson(),
        if (request.password != null) 'password': request.password,
        'memberships': processedMemberships.isNotEmpty ? processedMemberships : [
          {
            'role': 'volunteer',
            'isActive': true,
          }
        ],
      };

      // Usar o endpoint correto do backend
      final response = await http.post(
        Uri.parse('$baseUrl/members'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-tenant-id': tenantId, // ObjectId como string
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Member.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        String errorMessage = error['message'] ?? 'Erro ao criar membro';
        
        // Tratar erros específicos
        if (response.statusCode == 409) {
          errorMessage = 'Este vínculo já existe. Verifique se o membro já possui vínculos com os mesmos ministérios.';
        } else if (response.statusCode == 400) {
          errorMessage = 'Dados inválidos. Verifique as informações fornecidas.';
        } else if (response.statusCode == 401) {
          errorMessage = 'Sessão expirada. Faça login novamente.';
        } else if (response.statusCode == 403) {
          errorMessage = 'Você não tem permissão para criar membros.';
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      ErrorHandlerService().logError(e, context: 'criação de membro');
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        throw Exception('Não foi possível criar o membro. Verifique sua conexão com a internet e tente novamente.');
      }
      rethrow;
    }
  }

  // Listar membros com filtros
  static Future<MembersResponse> getMembers({MemberFilter? filter, BuildContext? context}) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        if (context != null) showAuthError(context);
        throw Exception('Token de autenticação não encontrado');
      }
      

      // Obter tenantId do token
      final tenantId = await _getTenantId();
      if (tenantId == null) {
        if (context != null) showAuthError(context);
        throw Exception('Tenant ID não encontrado no token');
      }

      final queryParams = filter?.toJson() ?? {};
      
      // Converter Map<String, dynamic> para Map<String, String>
      final Map<String, String> stringQueryParams = {};
      queryParams.forEach((key, value) {
        if (value != null) {
          stringQueryParams[key] = value.toString();
        }
      });
      
      try {
        final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: stringQueryParams);
      } catch (e) {
        rethrow;
      }
      
      final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: stringQueryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'x-tenant-id': tenantId, // ObjectId como string
        },
      );


      if (response.statusCode == 200) {
        return MembersResponse.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        if (context != null) showLoadError(context, 'membros');
        throw Exception(error['message'] ?? 'Erro ao buscar membros');
      }
    } catch (e) {
      ErrorHandlerService().logError(e, context: 'busca de membros');
      if (context != null && (e.toString().contains('SocketException') || e.toString().contains('TimeoutException'))) {
        showNetworkError(context);
      }
      rethrow;
    }
  }

  // Obter membro por ID
  static Future<Member> getMemberById(String id, BuildContext context) async {
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

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'x-tenant-id': tenantId,
        },
      );

      if (response.statusCode == 200) {
        return Member.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        showLoadError(context, 'membro');
        throw Exception(error['message'] ?? 'Erro ao buscar membro');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        showNetworkError(context);
      }
      rethrow;
    }
  }

  // Atualizar membro
  static Future<Member> updateMember(String id, UpdateMemberRequest request, BuildContext context) async {
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

      final response = await http.put(
        Uri.parse('$baseUrl$endpoint/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-tenant-id': tenantId,
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        showUpdateSuccess(context, 'Membro');
        return Member.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        showUpdateError(context, 'membro');
        throw Exception(error['message'] ?? 'Erro ao atualizar membro');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        showNetworkError(context);
      }
      rethrow;
    }
  }

  // Deletar membro
  static Future<void> deleteMember(String id, BuildContext context) async {
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
        Uri.parse('$baseUrl$endpoint/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'x-tenant-id': tenantId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        showDeleteSuccess(context, 'Membro');
      } else {
        final error = jsonDecode(response.body);
        showDeleteError(context, 'membro');
        throw Exception(error['message'] ?? 'Erro ao deletar membro');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        showNetworkError(context);
      }
      rethrow;
    }
  }

  // Buscar membros por nome ou email
  static Future<MembersResponse> searchMembers(String query, BuildContext context) async {
    return getMembers(filter: MemberFilter(search: query), context: context);
  }

  // Buscar membros por filial
  static Future<MembersResponse> getMembersByBranch(String branchId, BuildContext context) async {
    return getMembers(filter: MemberFilter(branchId: branchId), context: context);
  }

  // Buscar membros por ministério
  static Future<MembersResponse> getMembersByMinistry(String ministryId, BuildContext context) async {
    return getMembers(filter: MemberFilter(ministryId: ministryId), context: context);
  }

  // Buscar membros por role
  static Future<MembersResponse> getMembersByRole(String role, BuildContext context) async {
    return getMembers(filter: MemberFilter(role: role), context: context);
  }

  // Buscar membros ativos
  static Future<MembersResponse> getActiveMembers(BuildContext context) async {
    return getMembers(filter: MemberFilter(isActive: true), context: context);
  }

  // Buscar membros inativos
  static Future<MembersResponse> getInactiveMembers(BuildContext context) async {
    return getMembers(filter: MemberFilter(isActive: false), context: context);
  }

  // Toggle status do membro (ativar/inativar)
  static Future<Member> toggleMemberStatus(String id, BuildContext context) async {
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

      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint/$id/toggle-status'),
        headers: {
          'Authorization': 'Bearer $token',
          'x-tenant-id': tenantId,
        },
      );

      if (response.statusCode == 200) {
        showUpdateSuccess(context, 'Status do membro');
        return Member.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        showUpdateError(context, 'status do membro');
        throw Exception(error['message'] ?? 'Erro ao alterar status do membro');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        showNetworkError(context);
      }
      rethrow;
    }
  }
}
