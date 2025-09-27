import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:servus_app/core/models/member.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';
import 'package:servus_app/core/error/error_handler_service.dart';

class MembersService {
  static const String endpoint = '/users/filter';

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

      final dio = DioClient.instance;
      
      // Usar o endpoint correto do backend
      final response = await dio.post(
        '/members',
        data: requestData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Member.fromJson(response.data);
      } else {
        final error = response.data;
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
      print('🔍 [MembersService] ===== INICIANDO getMembers =====');
      print('   - Endpoint: $endpoint');
      print('   - Filter: ${filter?.toJson()}');
      
      final dio = DioClient.instance;
      final queryParams = filter?.toJson() ?? {};
      
      print('🔍 [MembersService] Query parameters: $queryParams');
      
      final response = await dio.get(
        endpoint,
        queryParameters: queryParams,
      );

      print('🔍 [MembersService] Resposta recebida:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Data type: ${response.data.runtimeType}');
      print('   - Data: ${response.data}');

      if (response.statusCode == 200) {
        final result = MembersResponse.fromJson(response.data);
        print('🔍 [MembersService] ===== SUCESSO =====');
        print('   - Total de membros: ${result.members.length}');
        return result;
      } else {
        print('❌ [MembersService] Erro na resposta:');
        print('   - Status: ${response.statusCode}');
        print('   - Error: ${response.data}');
        if (context != null) showLoadError(context, 'membros');
        throw Exception(response.data['message'] ?? 'Erro ao buscar membros');
      }
    } catch (e) {
      print('❌ [MembersService] Exceção capturada: $e');
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

      final dio = DioClient.instance;
      
      final response = await dio.get('/users/$id');

      if (response.statusCode == 200) {
        return Member.fromJson(response.data);
      } else {
        final error = response.data;
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

      final dio = DioClient.instance;
      
      final response = await dio.put(
        '/users/$id',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        showUpdateSuccess(context, 'Membro');
        return Member.fromJson(response.data);
      } else {
        final error = response.data;
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

      final dio = DioClient.instance;
      
      final response = await dio.delete('/users/$id');

      if (response.statusCode == 200 || response.statusCode == 204) {
        showDeleteSuccess(context, 'Membro');
      } else {
        final error = response.data;
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
    print('🔍 [MembersService] ===== getActiveMembers CHAMADO =====');
    print('   - Context: ${context.runtimeType}');
    
    final filter = MemberFilter(isActive: true);
    print('   - Filter criado: ${filter.toJson()}');
    
    final result = await getMembers(filter: filter, context: context);
    print('🔍 [MembersService] ===== getActiveMembers FINALIZADO =====');
    print('   - Resultado: ${result.members.length} membros');
    
    return result;
  }

  // Buscar membros inativos
  static Future<MembersResponse> getInactiveMembers(BuildContext context) async {
    return getMembers(filter: MemberFilter(isActive: false), context: context);
  }

  // Toggle status do membro (ativar/inativar)
  static Future<Member> toggleMemberStatus(String id, BuildContext context) async {
    try {
      final dio = DioClient.instance;
      
      final response = await dio.patch(
        '/users/$id/toggle-status',
      );

      if (response.statusCode == 200) {
        showUpdateSuccess(context, 'Status do membro');
        return Member.fromJson(response.data);
      } else {
        showUpdateError(context, 'status do membro');
        throw Exception(response.data['message'] ?? 'Erro ao alterar status do membro');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        showNetworkError(context);
      }
      rethrow;
    }
  }
}
