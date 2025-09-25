import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:servus_app/state/auth_state.dart';
import 'package:servus_app/services/volunteers_service.dart';

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
      if (tenantId == null) {
        debugPrint('❌ [VolunteersController] TenantId é null');
        return;
      }

      debugPrint('🔍 [VolunteersController] Carregando voluntários para tenant: $tenantId');

      // Buscar voluntários usando endpoint existente
      final response = await _dio.get('/tenants/$tenantId/volunteers', queryParameters: {
        'page': '1',
        'pageSize': '100',
      });

      debugPrint('🔍 [VolunteersController] Resposta recebida: ${response.statusCode}');
      debugPrint('🔍 [VolunteersController] Dados brutos: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final volunteers = data['data'] as List<dynamic>? ?? [];
        
        debugPrint('🔍 [VolunteersController] Voluntários encontrados: ${volunteers.length}');
        
        _volunteers = volunteers.map((volunteer) {
          debugPrint('🔍 [VolunteersController] Processando voluntário: ${volunteer['name']}');
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
          
          return {
            'id': volunteer['id'], // ID do membership (prioridade)
            'userId': volunteer['userId'], // ID do usuário (para compatibilidade)
            'name': volunteer['name'] ?? 'Nome não informado',
            'email': volunteer['email'] ?? '',
            'phone': volunteer['phone'] ?? '',
            'ministry': volunteer['ministry'],
            'functions': volunteer['functions'] ?? [],
            'status': 'approved',
            'createdAt': volunteer['createdAt'],
            'approvedAt': volunteer['approvedAt'],
            'source': volunteer['source'] ?? 'membership',
          };
        }).toList();

        _totalVolunteers = _volunteers.length;
        
        debugPrint('🔍 [VolunteersController] Total de voluntários processados: $_totalVolunteers');
      }
    } catch (e) {
      debugPrint('❌ [VolunteersController] Erro ao carregar voluntários: $e');
      _volunteers = [];
      _totalVolunteers = 0;
    }
  }

  Future<void> _loadPendingApprovals() async {
    try {
      final tenantId = auth.usuario?.tenantId;
      if (tenantId == null) return;

      debugPrint('🔍 [VolunteersController] Carregando submissões pendentes para tenant: $tenantId');

      // Buscar submissões pendentes usando o novo endpoint
      final response = await _dio.get('/tenants/$tenantId/volunteers/pending', queryParameters: {
        'page': '1',
        'pageSize': '50',
      });

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
        
        notifyListeners();
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
      if (tenantId == null) return;

      debugPrint('🔍 [DEBUG] Chamando endpoint de debug...');

      final response = await _dio.get('/tenants/$tenantId/volunteers/debug');

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
