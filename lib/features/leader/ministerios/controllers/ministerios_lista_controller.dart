import 'package:flutter/material.dart';
import 'package:servus_app/core/auth/services/ministry_service.dart';
import 'package:servus_app/core/models/ministry_dto.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';

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
  bool showOnlyActive = true;

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
      
      if (tenantId == null || branchId == null) {
        throw Exception('Contexto de tenant/branch não encontrado');
      }

      final filters = ListMinistryDto(
        page: currentPage,
        limit: 20,
        search: searchQuery.isNotEmpty ? searchQuery : null,
        isActive: showOnlyActive ? true : null,
      );

      final response = await _ministryService.listMinistries(
        tenantId: tenantId,
        branchId: branchId,
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
      print('❌ Erro ao carregar ministérios: $e');
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

  /// Filtra por status ativo/inativo
  Future<void> filtrarPorStatus(bool ativo) async {
    showOnlyActive = ativo;
    await carregarMinisterios(refresh: true);
  }

  /// Altera status do ministério (integração com backend)
  Future<void> alterarStatus(String id, bool ativo) async {
    try {
      isUpdating = true;
      notifyListeners();

      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];
      
      if (tenantId == null || branchId == null) {
        throw Exception('Contexto de tenant/branch não encontrado');
      }

      await _ministryService.toggleMinistryStatus(
        tenantId: tenantId,
        branchId: branchId,
        ministryId: id,
        isActive: ativo,
      );

      // Atualiza na lista local
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

      isUpdating = false;
      notifyListeners();

      print('✅ Ministério ${ativo ? 'ativado' : 'desativado'} com sucesso!');
    } catch (e) {
      isUpdating = false;
      notifyListeners();
      print('❌ Erro ao alterar status: ${e.toString()}');
      rethrow;
    }
  }

  /// Remove ministério (integração com backend)
  Future<void> removerMinisterio(String id) async {
    try {
      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];
      
      if (tenantId == null || branchId == null) {
        throw Exception('Contexto de tenant/branch não encontrado');
      }

      final success = await _ministryService.deleteMinistry(
        tenantId: tenantId,
        branchId: branchId,
        ministryId: id,
      );

      if (success) {
        ministerios.removeWhere((m) => m.id == id);
        totalItems--;
        notifyListeners();
        print('✅ Ministério removido com sucesso!');
      }
    } catch (e) {
      print('❌ Erro ao remover ministério: $e');
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
      
      if (tenantId == null || branchId == null) {
        throw Exception('Contexto de tenant/branch não encontrado');
      }

      final newMinistry = await _ministryService.createMinistry(
        tenantId: tenantId,
        branchId: branchId,
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
      print('❌ Erro ao criar ministério: $e');
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
      
      if (tenantId == null || branchId == null) {
        throw Exception('Contexto de tenant/branch não encontrado');
      }

      final updatedMinistry = await _ministryService.updateMinistry(
        tenantId: tenantId,
        branchId: branchId,
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
      print('❌ Erro ao atualizar ministério: $e');
      rethrow;
    }
  }

  /// Limpa filtros
  Future<void> limparFiltros() async {
    searchQuery = '';
    showOnlyActive = true;
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
    showOnlyActive = true;
    isLoading = false;
    isCreating = false;
    isUpdating = false;
    notifyListeners();
  }
}