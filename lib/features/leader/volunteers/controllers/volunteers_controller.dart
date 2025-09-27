import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:servus_app/state/auth_state.dart';
import 'package:servus_app/services/volunteers_service.dart';
import 'package:servus_app/core/enums/user_role.dart';

class VolunteersController extends ChangeNotifier {
  final AuthState auth;
  final Dio _dio = DioClient.instance;

  bool _isLoading = false;
  bool _isInitialized = false;
  List<Map<String, dynamic>> _volunteers = [];
  List<Map<String, dynamic>> _pendingApprovals = [];
  int _totalVolunteers = 0;
  int _pendingApprovalsCount = 0;

  // Getters
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  List<Map<String, dynamic>> get volunteers => _volunteers;
  List<Map<String, dynamic>> get recentVolunteers => _volunteers.take(5).toList();
  List<Map<String, dynamic>> get pendingApprovals => _pendingApprovals;
  int get totalVolunteers => _totalVolunteers;
  int get pendingApprovalsCount => _pendingApprovalsCount;

  VolunteersController({required this.auth});

  /// 🧪 TESTE: Testar endpoint manualmente
  Future<void> testEndpoint() async {
    try {
      final tenantId = auth.usuario?.tenantId;
      final ministryId = auth.usuario?.primaryMinistryId;
      
      debugPrint('🧪 [TESTE] Testando endpoint manualmente...');
      debugPrint('   - TenantId: $tenantId');
      debugPrint('   - MinistryId: $ministryId');
      
      // Teste 1: Sem filtro
      debugPrint('🧪 [TESTE] Teste 1: Sem filtro por ministério');
      final response1 = await _dio.get('/tenants/$tenantId/volunteers/pending', queryParameters: {
        'page': '1',
        'pageSize': '50',
      });
      debugPrint('🧪 [TESTE] Resposta 1: ${response1.statusCode}');
      debugPrint('🧪 [TESTE] Dados 1: ${response1.data}');
      
      // Teste 2: Com filtro
      debugPrint('🧪 [TESTE] Teste 2: Com filtro por ministério');
      final response2 = await _dio.get('/tenants/$tenantId/volunteers/pending', queryParameters: {
        'page': '1',
        'pageSize': '50',
        'ministryId': ministryId,
      });
      debugPrint('🧪 [TESTE] Resposta 2: ${response2.statusCode}');
      debugPrint('🧪 [TESTE] Dados 2: ${response2.data}');
      
    } catch (e) {
      debugPrint('🧪 [TESTE] Erro no teste: $e');
    }
  }

  /// 🔍 DEBUG: Verificar estado do usuário logado
  void debugUserState() {
    debugPrint('🔍 [VolunteersController] ===== DEBUG USUÁRIO LOGADO =====');
    debugPrint('   - Nome: ${auth.usuario?.nome}');
    debugPrint('   - Email: ${auth.usuario?.email}');
    debugPrint('   - Role: ${auth.usuario?.role}');
    debugPrint('   - TenantId: ${auth.usuario?.tenantId}');
    debugPrint('   - BranchId: ${auth.usuario?.branchId}');
    debugPrint('   - PrimaryMinistryId: ${auth.usuario?.primaryMinistryId}');
    debugPrint('   - PrimaryMinistryName: ${auth.usuario?.primaryMinistryName}');
    debugPrint('   - PrimaryMinistryId é null: ${auth.usuario?.primaryMinistryId == null}');
    debugPrint('   - PrimaryMinistryId é vazio: ${auth.usuario?.primaryMinistryId?.isEmpty ?? true}');
    debugPrint('🔍 [VolunteersController] ===== FIM DEBUG USUÁRIO =====');
  }

  Future<void> init() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadVolunteers(),
        _loadPendingApprovals(),
      ]);
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Erro ao inicializar VolunteersController: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshVolunteers() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadVolunteers(),
        _loadPendingApprovals(),
      ]);
    } catch (e) {
      debugPrint('Erro ao atualizar voluntários: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadVolunteers() async {
    try {
      final tenantId = auth.usuario?.tenantId;
      final ministryId = auth.usuario?.primaryMinistryId;
      
      debugPrint('🔍 [VolunteersController] ===== DEBUG CARREGAMENTO VOLUNTÁRIOS =====');
      debugPrint('🔍 [VolunteersController] Usuário atual:');
      debugPrint('   - Nome: ${auth.usuario?.nome}');
      debugPrint('   - Email: ${auth.usuario?.email}');
      debugPrint('   - Role: ${auth.usuario?.role}');
      debugPrint('   - TenantId: $tenantId');
      debugPrint('   - PrimaryMinistryId: $ministryId');
      debugPrint('   - PrimaryMinistryName: ${auth.usuario?.primaryMinistryName}');
      debugPrint('🔍 [VolunteersController] ===========================================');
      
      if (tenantId == null) {
        debugPrint('❌ [VolunteersController] TenantId é null - não é possível carregar voluntários');
        return;
      }
      
      // 🆕 CORREÇÃO: Para tenant_admin, não requer ministryId específico
      if (ministryId == null && auth.usuario?.role != UserRole.tenant_admin) {
        debugPrint('❌ [VolunteersController] MinistryId é null e usuário não é tenant_admin - não é possível carregar voluntários');
        debugPrint('❌ [VolunteersController] Isso pode indicar que o usuário não tem um ministério principal definido');
        return;
      }

      debugPrint('🔍 [VolunteersController] Carregando voluntários para tenant: $tenantId, ministry: $ministryId');

      // 🔍 DEBUG: Chamar método de debug primeiro
      await debugVolunteers();

      // 🆕 CORREÇÃO: Para tenant_admin sem ministryId específico, usar endpoint geral
      final String endpoint;
      final Map<String, dynamic> queryParams = {
        'page': '1',
        'limit': '100',
      };
      
      if (ministryId != null && ministryId.isNotEmpty) {
        // Usuário com ministério específico
        endpoint = '/users/tenants/$tenantId/ministries/$ministryId/volunteers';
        debugPrint('🔍 [VolunteersController] Usando endpoint específico do ministério');
      } else if (auth.usuario?.role == UserRole.tenant_admin) {
        // Tenant admin - buscar todos os voluntários do tenant
        endpoint = '/tenants/$tenantId/volunteers';
        debugPrint('🔍 [VolunteersController] Usando endpoint geral do tenant (tenant_admin)');
      } else {
        debugPrint('❌ [VolunteersController] Não é possível determinar endpoint para carregar voluntários');
        return;
      }

      final response = await _dio.get(endpoint, queryParameters: queryParams);

      debugPrint('🔍 [VolunteersController] Resposta recebida: ${response.statusCode}');
      debugPrint('🔍 [VolunteersController] Dados brutos: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final volunteers = data['users'] as List<dynamic>? ?? [];
        
        debugPrint('🔍 [VolunteersController] Voluntários encontrados: ${volunteers.length}');
        
        _volunteers = volunteers.map((volunteer) {
          debugPrint('🔍 [VolunteersController] Processando voluntário: ${volunteer['name']}');
          debugPrint('🔍 [VolunteersController] Source raw: ${volunteer['source']}');
          debugPrint('🔍 [VolunteersController] Source type: ${volunteer['source'].runtimeType}');
          debugPrint('🔍 [VolunteersController] Functions raw: ${volunteer['functions']}');
          debugPrint('🔍 [VolunteersController] Functions type: ${volunteer['functions'].runtimeType}');
          
          if (volunteer['functions'] != null && volunteer['functions'] is List) {
            final functionsList = volunteer['functions'] as List;
            debugPrint('🔍 [VolunteersController] Functions list length: ${functionsList.length}');
            for (int index = 0; index < functionsList.length; index++) {
              final func = functionsList[index];
              debugPrint('🔍 [VolunteersController] Function $index: $func');
              debugPrint('🔍 [VolunteersController] Function $index type: ${func.runtimeType}');
              if (func is Map<String, dynamic>) {
                debugPrint('🔍 [VolunteersController] Function $index keys: ${func.keys.toList()}');
                debugPrint('🔍 [VolunteersController] Function $index name: ${func['name']}');
              }
            }
          }
          
          // 🆕 CORREÇÃO: Mapear source corretamente
          String source = 'manual'; // Default
          if (volunteer['source'] != null) {
            source = volunteer['source'].toString();
          }
          
          debugPrint('🔍 [VolunteersController] Source mapeado: $source');
          
          return {
            'id': volunteer['_id'], // ID do membership (prioridade)
            'userId': volunteer['_id'], // ID do usuário (para compatibilidade)
            'name': volunteer['name'] ?? 'Nome não informado',
            'email': volunteer['email'] ?? '',
            'phone': volunteer['phone'] ?? '',
            'ministry': volunteer['ministry'], // O backend agora retorna ministry diretamente
            'functions': volunteer['functions'] ?? [],
            'status': 'approved',
            'createdAt': volunteer['createdAt'],
            'approvedAt': volunteer['approvedAt'],
            'source': source, // 🆕 CORREÇÃO: Usar source mapeado
          };
        }).toList();

        _totalVolunteers = _volunteers.length;
        
        debugPrint('🔍 [VolunteersController] Total de voluntários processados: $_totalVolunteers');
        debugPrint('🔍 [VolunteersController] Lista final de voluntários:');
        for (int i = 0; i < _volunteers.length; i++) {
          final volunteer = _volunteers[i];
          debugPrint('   ${i + 1}. ${volunteer['name']} (${volunteer['email']}) - Status: ${volunteer['status']}');
        }
      }
    } catch (e) {
      debugPrint('❌ [VolunteersController] Erro ao carregar voluntários: $e');
      _volunteers = [];
      _totalVolunteers = 0;
    }
  }

  Future<void> _loadPendingApprovals() async {
    try {
      // 🧪 TESTE: Testar endpoint manualmente
      await testEndpoint();
      
      // 🔍 DEBUG: Verificar estado do usuário
      debugUserState();
      
      final tenantId = auth.usuario?.tenantId;
      final ministryId = auth.usuario?.primaryMinistryId;
      if (tenantId == null) return;

      debugPrint('🔍 [VolunteersController] Carregando submissões pendentes para tenant: $tenantId');
      debugPrint('🔍 [VolunteersController] Filtrando por ministério: $ministryId');
      debugPrint('🔍 [VolunteersController] MinistryId é null: ${ministryId == null}');
      debugPrint('🔍 [VolunteersController] MinistryId é vazio: ${ministryId?.isEmpty ?? true}');

      // Buscar submissões pendentes usando o novo endpoint com filtro por ministério
      final queryParams = <String, dynamic>{
        'page': '1',
        'pageSize': '50',
      };
      
      // Adicionar ministryId apenas se não for null e não for vazio
      if (ministryId != null && ministryId.isNotEmpty) {
        queryParams['ministryId'] = ministryId;
        debugPrint('🔍 [VolunteersController] Adicionando filtro por ministério: $ministryId');
      } else {
        debugPrint('🔍 [VolunteersController] NÃO adicionando filtro por ministério (ministryId é null ou vazio)');
      }
      
      debugPrint('🔍 [VolunteersController] Query parameters: $queryParams');
      
      final response = await _dio.get('/tenants/$tenantId/volunteers/pending', queryParameters: queryParams);

      debugPrint('🔍 [VolunteersController] Resposta pendentes: ${response.statusCode}');
      debugPrint('🔍 [VolunteersController] Dados pendentes: ${response.data}');

      if (response.statusCode == 200) {
        // O backend retorna a lista diretamente, não dentro de um objeto 'data'
        final submissions = response.data as List<dynamic>? ?? [];
        
        debugPrint('🔍 [VolunteersController] Submissões pendentes encontradas: ${submissions.length}');
        
        // Log detalhado da primeira submissão para debug
        if (submissions.isNotEmpty) {
          debugPrint('🔍 [VolunteersController] Primeira submissão (raw): ${submissions.first}');
        }
        
        _pendingApprovals = submissions.map((submission) {
          debugPrint('🔍 [VolunteersController] Processando submissão: ${submission['_id']}');
          debugPrint('🔍 [VolunteersController] - name: ${submission['name']}');
          debugPrint('🔍 [VolunteersController] - email: ${submission['email']}');
          debugPrint('🔍 [VolunteersController] - phone: ${submission['phone']}');
          debugPrint('🔍 [VolunteersController] - ministry: ${submission['ministry']}');
          debugPrint('🔍 [VolunteersController] - functions: ${submission['functions']}');
          debugPrint('🔍 [VolunteersController] - source: ${submission['source']}');
          debugPrint('🔍 [VolunteersController] - source tipo: ${submission['source'].runtimeType}');
          debugPrint('🔍 [VolunteersController] - todos os campos: ${submission.keys.toList()}');
          
          return {
            'id': submission['userId'] ?? submission['_id'],
            'name': submission['name'] ?? 'Nome não informado',
            'email': submission['email'] ?? '',
            'phone': submission['phone'] ?? '',
            'ministry': submission['ministry'], // ✅ Backend já retorna como Map
            'functions': submission['functions'] ?? [],
            'status': submission['status'] ?? 'pending',
            'createdAt': submission['createdAt'],
            'source': submission['source'] ?? 'form',
          };
        }).toList();

        _pendingApprovalsCount = _pendingApprovals.length;
        debugPrint('✅ [VolunteersController] Carregadas $_pendingApprovalsCount aprovações pendentes');
      }
    } catch (e) {
      debugPrint('❌ [VolunteersController] Erro ao carregar aprovações pendentes: $e');
      _pendingApprovals = [];
      _pendingApprovalsCount = 0;
    }
  }

  Future<bool> approveVolunteer(String userId, {String? functionId, List<String>? functionIds, String? notes}) async {
    try {
      final tenantId = auth.usuario?.tenantId;
      if (tenantId == null) return false;

      debugPrint('🎉 [VolunteersController] Aprovando voluntário: $userId');
      debugPrint('   - Function ID: $functionId');
      debugPrint('   - Function IDs: $functionIds');

      // Usar functionIds se fornecido, senão usar functionId para compatibilidade
      final List<String> finalFunctionIds = functionIds ?? (functionId != null ? [functionId] : []);

      final response = await _dio.put(
        '/tenants/$tenantId/volunteers/$userId/approve',
        data: {
          if (finalFunctionIds.isNotEmpty) 'functionIds': finalFunctionIds,
          if (notes != null) 'notes': notes,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [VolunteersController] Voluntário aprovado com sucesso');
        
        // Remover da lista de pendentes
        _pendingApprovals.removeWhere((v) => v['id'] == userId);
        _pendingApprovalsCount = _pendingApprovals.length;
        
        // Recarregar voluntários para incluir o novo aprovado
        await _loadVolunteers();
        
        // 🔄 FORÇAR ATUALIZAÇÃO COMPLETA DO ESTADO
        debugPrint('🔄 [VolunteersController] Forçando atualização completa do estado...');
        debugPrint('   - Total de voluntários antes: $_totalVolunteers');
        debugPrint('   - Total de pendentes antes: $_pendingApprovalsCount');
        
        // Notificar mudanças
        notifyListeners();
        
        debugPrint('✅ [VolunteersController] Estado atualizado e notificado');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ [VolunteersController] Erro ao aprovar voluntário: $e');
      return false;
    }
  }

  /// Busca funções disponíveis de um ministério
  Future<List<Map<String, dynamic>>> getMinistryFunctions(String ministryId) async {
    try {
      final tenantId = auth.usuario?.tenantId;
      if (tenantId == null) return [];

      debugPrint('🔍 [VolunteersController] Buscando funções do ministério: $ministryId');

      final response = await _dio.get(
        '/tenants/$tenantId/ministries/$ministryId/functions',
      );

      if (response.statusCode == 200) {
        final List<dynamic> functions = response.data;
        debugPrint('✅ [VolunteersController] Encontradas ${functions.length} funções');
        return functions.map((f) => f as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ [VolunteersController] Erro ao buscar funções: $e');
      return [];
    }
  }

  /// 🔍 DEBUG: Método temporário para verificar dados brutos
  Future<void> debugVolunteers() async {
    try {
      final tenantId = auth.usuario?.tenantId;
      final ministryId = auth.usuario?.primaryMinistryId;
      
      if (tenantId == null || ministryId == null) {
        debugPrint('❌ [DEBUG] TenantId ou MinistryId é null');
        return;
      }

      debugPrint('🔍 [DEBUG] Chamando endpoint de debug...');
      debugPrint('   - TenantId: $tenantId');
      debugPrint('   - MinistryId: $ministryId');

      final response = await _dio.get('/users/debug/tenants/$tenantId/ministries/$ministryId/volunteers');

      if (response.statusCode == 200) {
        debugPrint('🔍 [DEBUG] Resposta do debug: ${response.data}');
      }
    } catch (e) {
      debugPrint('❌ [DEBUG] Erro ao chamar debug: $e');
    }
  }

  Future<bool> rejectVolunteer(String userId, {String? notes}) async {
    try {
      final tenantId = auth.usuario?.tenantId;
      if (tenantId == null) return false;

      final response = await _dio.put(
        '/tenants/$tenantId/volunteers/$userId/reject',
        data: {
          'notes': notes,
        },
      );

      if (response.statusCode == 200) {
        // Remover da lista de pendentes
        _pendingApprovals.removeWhere((v) => v['id'] == userId);
        _pendingApprovalsCount = _pendingApprovals.length;
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erro ao rejeitar voluntário: $e');
      return false;
    }
  }

  // Deletar voluntário
  Future<bool> deleteVolunteer(String volunteerId, BuildContext context) async {
    try {
      await VolunteersService.deleteVolunteer(volunteerId, context);
      
      // Remover da lista local
      _volunteers.removeWhere((volunteer) => 
        volunteer['id'] == volunteerId || 
        volunteer['userId'] == volunteerId || 
        volunteer['_id'] == volunteerId
      );
      _totalVolunteers = _volunteers.length;
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erro ao deletar voluntário: $e');
      return false;
    }
  }

}
