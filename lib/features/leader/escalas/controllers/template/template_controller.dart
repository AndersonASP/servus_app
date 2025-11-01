import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:servus_app/features/leader/escalas/models/template_model.dart';
import 'package:servus_app/features/ministries/services/ministry_functions_service.dart';
import 'package:servus_app/features/ministries/services/ministry_service.dart';
import 'package:servus_app/features/ministries/models/ministry_dto.dart';
import 'package:servus_app/features/ministries/models/ministry_function.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/core/network/dio_client.dart';

class TemplateController extends ChangeNotifier {
  final List<TemplateModel> _templates = [];
  final MinistryFunctionsService _functionsService = MinistryFunctionsService();
  
  // Estados
  bool isLoading = false;
  bool isLoadingMinistries = false;
  String? errorMessage;
  
  // Ministérios disponíveis
  List<MinistryResponse> _ministerios = [];

  List<TemplateModel> get todos => List.unmodifiable(_templates);
  List<MinistryResponse> get ministerios => List.unmodifiable(_ministerios);
  
  bool get hasMinistries => _ministerios.isNotEmpty;
  bool get hasTemplates => _templates.isNotEmpty;

  TemplateController() {
    _loadTemplatesFromStorage();
    _loadMinisterios();
  }

  /// Carrega ministérios que o usuário lidera
  Future<void> _loadMinisterios() async {
    try {
      isLoadingMinistries = true;
      notifyListeners();

      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      
      if (tenantId == null) {
        throw Exception('Contexto de tenant não encontrado');
      }

      // Tentar primeiro o endpoint específico para líderes
      Response? response;
      try {
        // Primeiro tentar sem filtro de role para ver todos os ministérios
        response = await DioClient.instance.get(
          '/ministry-memberships/my-ministries',
        );
        debugPrint('My-ministries (sem filtro) response status: ${response.statusCode}');
        debugPrint('My-ministries (sem filtro) data: ${response.data}');
        
        // Se retornou dados, agora filtrar por role LEADER
        if (response.statusCode == 200 && response.data is List && response.data.isNotEmpty) {
          debugPrint('Dados encontrados sem filtro, aplicando filtro LEADER...');
          // Aplicar filtro localmente
          final allMemberships = response.data as List;
          final leaderMemberships = allMemberships.where((membership) {
            return membership['role'] == 'leader' && membership['isActive'] == true;
          }).toList();
          
          debugPrint('Memberships filtrados por LEADER: ${leaderMemberships.length}');
          debugPrint('Leader memberships: $leaderMemberships');
          
          // Criar nova resposta com dados filtrados
          response = Response(
            requestOptions: RequestOptions(path: '/ministry-memberships/my-ministries'),
            statusCode: 200,
            data: leaderMemberships,
          );
        }
      } catch (e) {
        debugPrint('Erro no endpoint my-ministries: $e');
        // Fallback para endpoint original
        final branchId = context['branchId'];
        final filters = ListMinistryDto(
          page: 1,
          limit: 100,
          isActive: true,
        );
        
        final ministryService = MinistryService();
        final ministryResponse = await ministryService.listMinistries(
          tenantId: tenantId,
          branchId: branchId ?? '',
          filters: filters,
        );
        
        // Simular resposta do DioClient
        response = Response(
          requestOptions: RequestOptions(path: '/ministries'),
          statusCode: 200,
          data: {
            'items': ministryResponse.items.map((m) => {
              'ministry': {
                '_id': m.id,
                'name': m.name,
                'description': m.description,
                'isActive': m.isActive,
                'ministryFunctions': m.ministryFunctions,
              },
              'role': 'leader', // Assumir que é líder de todos por enquanto
              'isActive': true,
            }).toList(),
          },
        );
        debugPrint('Fallback response status: ${response.statusCode}');
      }
      
      debugPrint('Final response status: ${response.statusCode}');
      debugPrint('Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        // Verificar estrutura da resposta
        final responseData = response.data;
        debugPrint('Response data structure: $responseData');
        
        // Tentar diferentes estruturas possíveis
        List<dynamic> membershipsList = [];
        
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data') && responseData['data'] is List) {
            membershipsList = responseData['data'];
          } else if (responseData.containsKey('items') && responseData['items'] is List) {
            membershipsList = responseData['items'];
          } else if (responseData.containsKey('ministries') && responseData['ministries'] is List) {
            membershipsList = responseData['ministries'];
          } else if (responseData.containsKey('memberships') && responseData['memberships'] is List) {
            membershipsList = responseData['memberships'];
          }
        } else if (responseData is List) {
          membershipsList = responseData;
        }
        
        debugPrint('Memberships list length: ${membershipsList.length}');
        
        _ministerios = membershipsList
            .where((membership) {
              if (membership is! Map<String, dynamic>) return false;
              
              final isActive = membership['isActive'] == true;
              final hasMinistry = membership['ministry'] != null;
              final isLeader = membership['role'] == 'leader';
              return isActive && hasMinistry && isLeader;
            })
            .map((membership) {
              final ministry = membership['ministry'];
              if (ministry is! Map<String, dynamic>) {
                throw Exception('Ministry data is not a map: $ministry');
              }
              
              return MinistryResponse(
                id: ministry['_id']?.toString() ?? ministry['id']?.toString() ?? '',
                name: ministry['name'] ?? 'Ministério sem nome',
                description: ministry['description'] ?? '',
                isActive: ministry['isActive'] ?? true,
                ministryFunctions: ministry['ministryFunctions'] is List 
                    ? List<String>.from(ministry['ministryFunctions'])
                    : [],
                createdAt: DateTime.now(), // TODO: Usar data real do backend
                updatedAt: DateTime.now(), // TODO: Usar data real do backend
              );
            })
            .toList();
      }
      
      isLoadingMinistries = false;
      notifyListeners();
    } catch (e) {
      isLoadingMinistries = false;
      errorMessage = 'Erro ao carregar ministérios: $e';
      debugPrint('Erro detalhado ao carregar ministérios: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      notifyListeners();
    }
  }

  /// Recarrega ministérios
  Future<void> refreshMinisterios() async {
    await _loadMinisterios();
  }

  /// Recarrega templates do backend
  Future<void> refreshTemplates() async {
    await _loadTemplatesFromStorage();
  }

  /// Busca ministério por ID
  MinistryResponse? buscarMinisterioPorId(String id) {
    try {
      return _ministerios.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Busca funções de um ministério
  List<String> buscarFuncoesDoMinisterio(String ministerioId) {
    final ministerio = buscarMinisterioPorId(ministerioId);
    return ministerio?.ministryFunctions ?? [];
  }

  /// Carrega funções de um ministério específico
  Future<List<MinistryFunction>> getFuncoesDoMinisterio(String ministryId) async {
    try {
      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      
      if (tenantId == null) {
        throw Exception('Contexto de tenant não encontrado');
      }

      return await _functionsService.getMinistryFunctions(
        ministryId,
        active: true,
      );
    } catch (e) {
      debugPrint('Erro ao carregar funções do ministério: $e');
      return [];
    }
  }

  /// Carrega templates do backend
  Future<void> _loadTemplatesFromStorage() async {
    try {
      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];
      
      if (tenantId == null) {
        throw Exception('Contexto de tenant não encontrado');
      }

      final deviceId = await TokenService.getDeviceId();
      // Usar rota diferente dependendo se há branchId ou não
      final endpoint = branchId != null && branchId.isNotEmpty
          ? '/tenants/$tenantId/branches/$branchId/templates'
          : '/tenants/$tenantId/templates';

      final response = await DioClient.instance.get(
        endpoint,
        options: Options(headers: {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          if (branchId != null && branchId.isNotEmpty) 'x-branch-id': branchId,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['items'] ?? response.data ?? [];
        _templates.clear();
        
        for (final item in data) {
          try {
            // Converter dados do backend para TemplateModel
            final templateMinistryId = item['ministryId']?.toString() ?? '';
            debugPrint('🔍 [TemplateController] Carregando template: ${item['name']}');
            debugPrint('🔍 [TemplateController] MinistryId: $templateMinistryId');
            debugPrint('🔍 [TemplateController] FunctionRequirements: ${item['functionRequirements']}');
            
            final template = TemplateModel(
              id: item['_id']?.toString() ?? item['id']?.toString() ?? '',
              nome: item['name'] ?? 'Template sem nome',
              observacoes: item['description'] ?? item['observations'],
              funcoes: _convertFunctionRequirements(item['functionRequirements'] ?? [], templateMinistryId),
            );
            
            debugPrint('🔍 [TemplateController] Template convertido - Funções: ${template.funcoes.map((f) => '${f.nome}:${f.quantidade}').toList()}');
            
            _templates.add(template);
            debugPrint('Template carregado: ${template.nome}');
          } catch (e) {
            debugPrint('Erro ao converter template: $e');
          }
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao carregar templates: $e');
    }
  }

  /// Converte functionRequirements do backend para FuncaoEscala
  List<FuncaoEscala> _convertFunctionRequirements(List<dynamic> functionRequirements, String templateMinistryId) {
    debugPrint('🔍 [TemplateController] Convertendo ${functionRequirements.length} functionRequirements');
    
    return functionRequirements.map((req) {
      debugPrint('🔍 [TemplateController] Req completo: $req');
      debugPrint('🔍 [TemplateController] req keys: ${req.keys.toList()}');
      debugPrint('🔍 [TemplateController] requiredSlots: ${req['requiredSlots']}');
      debugPrint('🔍 [TemplateController] quantity: ${req['quantity']}');
      debugPrint('🔍 [TemplateController] functionName: ${req['functionName']}');
      debugPrint('🔍 [TemplateController] name: ${req['name']}');
      
      final quantidade = req['requiredSlots'] ?? req['quantity'] ?? req['required'] ?? 1;
      debugPrint('🔍 [TemplateController] Quantidade calculada: $quantidade');
      
      final funcao = FuncaoEscala(
        id: req['functionId']?.toString() ?? '',
        nome: req['functionName'] ?? req['name'] ?? 'Função sem nome',
        ministerioId: req['ministryId']?.toString() ?? templateMinistryId,
        quantidade: quantidade is int ? quantidade : (quantidade is String ? int.tryParse(quantidade) ?? 1 : 1),
      );
      
      debugPrint('🔍 [TemplateController] Função convertida: ${funcao.nome} - Quantidade: ${funcao.quantidade}');
      
      return funcao;
    }).toList();
  }

  /// Salva template no backend
  Future<void> _saveTemplateToBackend(TemplateModel template) async {
    try {
      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];
      
      if (tenantId == null) {
        throw Exception('Contexto de tenant não encontrado');
      }

      final deviceId = await TokenService.getDeviceId();
      // Usar rota diferente dependendo se há branchId ou não
      final endpoint = branchId != null && branchId.isNotEmpty
          ? '/tenants/$tenantId/branches/$branchId/templates'
          : '/tenants/$tenantId/templates';

      // Obter funções do ministério para mapear nomes para IDs
      final ministryId = template.funcoes.isNotEmpty ? template.funcoes.first.ministerioId : null;
      if (ministryId == null) {
        throw Exception('Ministério não encontrado no template');
      }
      
      final funcoesDisponiveis = await getFuncoesDoMinisterio(ministryId);
      
      // Preparar dados para o backend conforme o schema
      final data = {
        'name': template.nome,
        'description': template.observacoes,
        'eventType': 'culto', // TODO: Permitir seleção do tipo de evento
        'ministryId': ministryId,
        'functionRequirements': template.funcoes.map((f) {
          // Encontrar a função correspondente para obter o functionId
          final funcao = funcoesDisponiveis.firstWhere(
            (func) => func.name == f.nome,
            orElse: () => throw Exception('Função "${f.nome}" não encontrada'),
          );
          return {
            'functionId': funcao.functionId,
            'functionName': funcao.name, // Incluir o nome da função
            'requiredSlots': f.quantidade,
            'isRequired': true,
            'priority': 0,
            'ministryId': ministryId, // Incluir ministryId na função
          };
        }).toList(),
      };

      // Verificar se é criação ou atualização
      // Para templates novos, o ID é gerado automaticamente pelo UUID
      // Precisamos verificar se o template já existe no backend
      final isNewTemplate = !_templates.any((t) => t.id == template.id);
      
      if (isNewTemplate) {
        // Criar novo template
        await DioClient.instance.post(
          endpoint,
          data: data,
          options: Options(headers: {
            'device-id': deviceId,
            'x-tenant-id': tenantId,
            if (branchId != null && branchId.isNotEmpty) 'x-branch-id': branchId,
          }),
        );
        debugPrint('Template criado com sucesso');
      } else {
        // Atualizar template existente
        await DioClient.instance.patch(
          '$endpoint/${template.id}',
          data: data,
          options: Options(headers: {
            'device-id': deviceId,
            'x-tenant-id': tenantId,
            if (branchId != null && branchId.isNotEmpty) 'x-branch-id': branchId,
          }),
        );
        debugPrint('Template atualizado com sucesso');
      }
    } catch (e) {
      debugPrint('Erro ao salvar template: $e');
      rethrow;
    }
  }

  /// Remove template do backend
  Future<void> _removerTemplateDoBackend(String templateId) async {
    try {
      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];
      
      if (tenantId == null) {
        throw Exception('Contexto de tenant não encontrado');
      }

      final deviceId = await TokenService.getDeviceId();
      // Usar rota diferente dependendo se há branchId ou não
      final endpoint = branchId != null && branchId.isNotEmpty
          ? '/tenants/$tenantId/branches/$branchId/templates'
          : '/tenants/$tenantId/templates';

      await DioClient.instance.delete(
        '$endpoint/$templateId',
        options: Options(headers: {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          if (branchId != null && branchId.isNotEmpty) 'x-branch-id': branchId,
        }),
      );
    } catch (e) {
      debugPrint('Erro ao remover template: $e');
      rethrow;
    }
  }

  /// Adiciona um novo template
  Future<void> adicionarTemplate(TemplateModel template) async {
    try {
      isLoading = true;
      notifyListeners();

      // Validações
      if (template.nome.isEmpty) {
        throw Exception('Nome do template é obrigatório');
      }
      
      if (template.funcoes.isEmpty) {
        throw Exception('Template deve ter pelo menos uma função');
      }

      // Verifica se já existe template com mesmo nome
      if (_templates.any((t) => t.nome.toLowerCase() == template.nome.toLowerCase())) {
        throw Exception('Já existe um template com este nome');
      }

      // Valida ministérios das funções
      for (final funcao in template.funcoes) {
        final ministerio = buscarMinisterioPorId(funcao.ministerioId);
        if (ministerio == null) {
          throw Exception('Ministério "${funcao.ministerioId}" não encontrado');
        }
        
        if (!ministerio.isActive) {
          throw Exception('Ministério "${ministerio.name}" está inativo');
        }
      }

      // Salvar no backend
      await _saveTemplateToBackend(template);

      // Recarregar templates do backend para garantir sincronização
      await refreshTemplates();
      
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Atualiza um template existente
  Future<void> atualizarTemplate(TemplateModel templateAtualizado) async {
    try {
      isLoading = true;
      notifyListeners();

      final index = _templates.indexWhere((t) => t.id == templateAtualizado.id);
      if (index == -1) {
        throw Exception('Template não encontrado');
      }

      // Validações
      if (templateAtualizado.nome.isEmpty) {
        throw Exception('Nome do template é obrigatório');
      }
      
      if (templateAtualizado.funcoes.isEmpty) {
        throw Exception('Template deve ter pelo menos uma função');
      }

      // Verifica se já existe outro template com mesmo nome
      if (_templates.any((t) => t.id != templateAtualizado.id && 
          t.nome.toLowerCase() == templateAtualizado.nome.toLowerCase())) {
        throw Exception('Já existe um template com este nome');
      }

      // Valida ministérios das funções
      for (final funcao in templateAtualizado.funcoes) {
        final ministerio = buscarMinisterioPorId(funcao.ministerioId);
        if (ministerio == null) {
          throw Exception('Ministério "${funcao.ministerioId}" não encontrado');
        }
        
        if (!ministerio.isActive) {
          throw Exception('Ministério "${ministerio.name}" está inativo');
        }
      }

      // Salvar no backend
      await _saveTemplateToBackend(templateAtualizado);

      // Recarregar templates do backend para garantir sincronização
      await refreshTemplates();
      
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Remove um template
  Future<void> removerTemplate(String id) async {
    try {
      isLoading = true;
      notifyListeners();

      final template = buscarPorId(id);
      if (template == null) {
        throw Exception('Template não encontrado');
      }

      // Remover do backend
      await _removerTemplateDoBackend(id);

      // Remover localmente
      _templates.removeWhere((t) => t.id == id);
      
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Busca template por ID
  TemplateModel? buscarPorId(String id) {
    try {
      return _templates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Busca templates por ministério
  List<TemplateModel> buscarPorMinisterio(String ministerioId) {
    return _templates.where((t) => 
        t.funcoes.any((f) => f.ministerioId == ministerioId)).toList();
  }

  /// Duplica um template
  Future<void> duplicarTemplate(String id) async {
    try {
      final templateOriginal = buscarPorId(id);
      if (templateOriginal == null) {
        throw Exception('Template não encontrado');
      }

      final templateDuplicado = TemplateModel(
        nome: '${templateOriginal.nome} (Cópia)',
        funcoes: templateOriginal.funcoes.map((f) => f.copyWith()).toList(),
        observacoes: templateOriginal.observacoes,
      );

      await adicionarTemplate(templateDuplicado);
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Limpa todos os templates
  Future<void> limparTemplates() async {
    try {
      isLoading = true;
      notifyListeners();

      _templates.clear();
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Limpa mensagens de erro
  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}