import 'package:flutter/material.dart';
import 'package:servus_app/features/ministries/services/ministry_service.dart';
import 'package:servus_app/features/ministries/models/ministry_dto.dart';
import 'package:servus_app/core/auth/services/token_service.dart';

class MinisterioListController extends ChangeNotifier {
  final MinistryService _ministryService = MinistryService();
  
  bool isLoading = false;
  bool isCreating = false;
  bool isUpdating = false;
  List<MinistryResponse> ministerios = [];
  
  // Paginação
  int currentPage = 1;
  int totalPages = 1;
  int totalItems = 0;
  bool hasMorePages = true;
  
  // Filtros
  String searchQuery = '';
  bool showOnlyActive = false; // Mudança: agora mostra todos por padrão
  String filterStatus = 'todos'; // Mudança: filtro padrão é 'todos' ao invés de 'ativos'

  // Getters para compatibilidade com a UI existente
  bool get hasData => ministerios.isNotEmpty;
  int get itemCount => ministerios.length;

  /// Carrega ministérios do backend
  Future<void> carregarMinisterios({bool refresh = false}) async {
    try {
      if (refresh) {
        currentPage = 1;
        hasMorePages = true;
      }
      
      if (!hasMorePages && !refresh) return;
      
      isLoading = true;
      notifyListeners();

      // Obtém contexto atual
      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];
      
      if (tenantId == null) {
        throw Exception('Contexto de tenant não encontrado');
      }
      
      // Para ministérios da matriz, branchId pode ser null
      // Para ministérios de filiais, branchId deve ser fornecido

      // Determina o filtro de status baseado no filterStatus
      bool? isActiveFilter;
      switch (filterStatus) {
        case 'ativos':
          isActiveFilter = true;
          break;
        case 'inativos':
          isActiveFilter = false;
          break;
        case 'todos':
        default:
          isActiveFilter = null;
          break;
      }

      final filters = ListMinistryDto(
        page: currentPage,
        limit: 20,
        search: searchQuery.isNotEmpty ? searchQuery : null,
        isActive: isActiveFilter,
      );

      final response = await _ministryService.listMinistries(
        tenantId: tenantId,
        branchId: branchId ?? '', // Para ministérios da matriz, usa string vazia
        filters: filters,
      );

      if (refresh) {
        ministerios = response.items;
      } else {
        ministerios.addAll(response.items);
      }

      totalPages = response.pages;
      totalItems = response.total;
      currentPage = response.page;
      hasMorePages = currentPage < totalPages;

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      notifyListeners();
      // print('❌ Erro ao carregar ministérios: $e');
      rethrow;
    }
  }

  /// Carrega mais ministérios (pagination)
  Future<void> carregarMaisMinisterios() async {
    if (hasMorePages && !isLoading) {
      currentPage++;
      await carregarMinisterios();
    }
  }

  /// Busca ministérios
  Future<void> buscarMinisterios(String query) async {
    searchQuery = query;
    await carregarMinisterios(refresh: true);
  }

  /// Filtra por status ativo/inativo/todos
  Future<void> filtrarPorStatus(String status) async {
    filterStatus = status;
    await carregarMinisterios(refresh: true);
  }

  /// Altera status do ministério (integração com backend)
  Future<void> alterarStatus(String id, bool ativo) async {
    try {
      // Atualiza na lista local primeiro para feedback imediato
      final index = ministerios.indexWhere((m) => m.id == id);
      if (index != -1) {
        // Recria o objeto com o novo status
        final oldMinistry = ministerios[index];
        ministerios[index] = MinistryResponse(
          id: oldMinistry.id,
          name: oldMinistry.name,
          description: oldMinistry.description,
          ministryFunctions: oldMinistry.ministryFunctions,
          isActive: ativo,
          createdAt: oldMinistry.createdAt,
          updatedAt: DateTime.now(),
        );
      }

      isUpdating = true;
      notifyListeners();

      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];
      
      if (tenantId == null) {
        throw Exception('Contexto de tenant não encontrado');
      }
      
      // Para ministérios da matriz, branchId pode ser null
      // Para ministérios de filiais, branchId deve ser fornecido

      await _ministryService.toggleMinistryStatus(
        tenantId: tenantId,
        branchId: branchId ?? '', // Para ministérios da matriz, usa string vazia
        ministryId: id,
        isActive: ativo,
      );

      isUpdating = false;
      notifyListeners();

      // print('✅ Ministério ${ativo ? 'ativado' : 'desativado'} com sucesso!');
    } catch (e) {
      // Reverte a mudança em caso de erro
      final index = ministerios.indexWhere((m) => m.id == id);
      if (index != -1) {
        final oldMinistry = ministerios[index];
        ministerios[index] = MinistryResponse(
          id: oldMinistry.id,
          name: oldMinistry.name,
          description: oldMinistry.description,
          ministryFunctions: oldMinistry.ministryFunctions,
          isActive: !ativo, // Reverte o status
          createdAt: oldMinistry.createdAt,
          updatedAt: oldMinistry.updatedAt,
        );
      }
      
      isUpdating = false;
      notifyListeners();
      // print('❌ Erro ao alterar status: ${e.toString()}');
      rethrow;
    }
  }

  /// Remove ministério (integração com backend)
  Future<void> removerMinisterio(String id) async {
    try {
      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];
      
      if (tenantId == null) {
        throw Exception('Contexto de tenant não encontrado');
      }
      
      // Para ministérios da matriz, branchId pode ser null
      // Para ministérios de filiais, branchId deve ser fornecido

      final success = await _ministryService.deleteMinistry(
        tenantId: tenantId,
        branchId: branchId ?? '', // Para ministérios da matriz, usa string vazia
        ministryId: id,
      );

      if (success) {
        ministerios.removeWhere((m) => m.id == id);
        totalItems--;
        notifyListeners();
        // print('✅ Ministério removido com sucesso!');
      }
    } catch (e) {
      // print('❌ Erro ao remover ministério: $e');
      rethrow;
    }
  }

  /// Cria novo ministério (integração com backend)
  Future<bool> criarMinisterio(CreateMinistryDto ministryData) async {
    try {
      isCreating = true;
      notifyListeners();

      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];
      
      if (tenantId == null) {
        throw Exception('Contexto de tenant não encontrado');
      }
      
      // Para ministérios da matriz, branchId pode ser null
      // Para ministérios de filiais, branchId deve ser fornecido

      final newMinistry = await _ministryService.createMinistry(
        tenantId: tenantId,
        branchId: branchId ?? '', // Para ministérios da matriz, usa string vazia
        ministryData: ministryData,
      );

      // Adiciona no início da lista
      ministerios.insert(0, newMinistry);
      totalItems++;

      isCreating = false;
      notifyListeners();
      return true;
    } catch (e) {
      isCreating = false;
      notifyListeners();
      // print('❌ Erro ao criar ministério: $e');
      rethrow;
    }
  }

  /// Atualiza ministério existente (integração com backend)
  Future<bool> atualizarMinisterio(String id, UpdateMinistryDto ministryData) async {
    try {
      isUpdating = true;
      notifyListeners();

      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];
      
      if (tenantId == null) {
        throw Exception('Contexto de tenant não encontrado');
      }
      
      // Para ministérios da matriz, branchId pode ser null
      // Para ministérios de filiais, branchId deve ser fornecido

      final updatedMinistry = await _ministryService.updateMinistry(
        tenantId: tenantId,
        branchId: branchId ?? '', // Para ministérios da matriz, usa string vazia
        ministryId: id,
        ministryData: ministryData,
      );

      // Atualiza na lista local
      final index = ministerios.indexWhere((m) => m.id == id);
      if (index != -1) {
        ministerios[index] = updatedMinistry;
      }

      isUpdating = false;
      notifyListeners();
      return true;
    } catch (e) {
      isUpdating = false;
      notifyListeners();
      // print('❌ Erro ao atualizar ministério: $e');
      rethrow;
    }
  }

  /// Limpa filtros
  Future<void> limparFiltros() async {
    searchQuery = '';
    filterStatus = 'todos'; // Mudança: agora volta para 'todos' ao invés de 'ativos'
    await carregarMinisterios(refresh: true);
  }

  /// Reseta o controller
  void reset() {
    ministerios.clear();
    currentPage = 1;
    totalPages = 1;
    totalItems = 0;
    hasMorePages = true;
    searchQuery = '';
    filterStatus = 'todos'; // Mudança: agora volta para 'todos' ao invés de 'ativos'
    isLoading = false;
    isCreating = false;
    isUpdating = false;
    notifyListeners();
  }
}