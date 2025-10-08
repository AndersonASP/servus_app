import 'package:flutter/material.dart';
import 'package:servus_app/features/leader/escalas/models/template_model.dart';
import 'package:servus_app/features/ministries/services/ministry_service.dart';
import 'package:servus_app/features/ministries/models/ministry_dto.dart';
import 'package:servus_app/core/auth/services/token_service.dart';

class TemplateController extends ChangeNotifier {
  final List<TemplateModel> _templates = [];
  final MinistryService _ministryService = MinistryService();
  
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

  /// Carrega ministérios do backend
  Future<void> _loadMinisterios() async {
    try {
      isLoadingMinistries = true;
      notifyListeners();

      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];
      
      if (tenantId == null) {
        throw Exception('Contexto de tenant não encontrado');
      }

      final filters = ListMinistryDto(
        page: 1,
        limit: 100, // Carrega todos os ministérios
        isActive: true, // Apenas ministérios ativos
      );

      final response = await _ministryService.listMinistries(
        tenantId: tenantId,
        branchId: branchId ?? '',
        filters: filters,
      );

      _ministerios = response.items;
      isLoadingMinistries = false;
      notifyListeners();
    } catch (e) {
      isLoadingMinistries = false;
      errorMessage = 'Erro ao carregar ministérios: $e';
      notifyListeners();
    }
  }

  /// Recarrega ministérios
  Future<void> refreshMinisterios() async {
    await _loadMinisterios();
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

  /// Carrega templates do armazenamento local
  Future<void> _loadTemplatesFromStorage() async {
    try {
      // TODO: Implementar carregamento do storage quando necessário
      // Por enquanto, mantém lista vazia
      debugPrint('Carregando templates do storage...');
    } catch (e) {
      debugPrint('Erro ao carregar templates do storage: $e');
    }
  }

  /// Salva templates no armazenamento local
  Future<void> _saveTemplatesToStorage() async {
    try {
      // TODO: Implementar salvamento no storage quando necessário
      debugPrint('Salvando templates no storage...');
    } catch (e) {
      debugPrint('Erro ao salvar templates no storage: $e');
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

      _templates.add(template);
      await _saveTemplatesToStorage();
      
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

      _templates[index] = templateAtualizado;
      await _saveTemplatesToStorage();
      
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

      _templates.removeWhere((t) => t.id == id);
      await _saveTemplatesToStorage();
      
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
      await _saveTemplatesToStorage();
      
      isLoading = false;
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