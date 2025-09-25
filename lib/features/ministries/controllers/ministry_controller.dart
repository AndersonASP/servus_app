import 'package:flutter/material.dart';
import 'package:servus_app/features/ministries/services/ministry_service.dart';
import 'package:servus_app/features/ministries/models/ministry_dto.dart';
import 'package:servus_app/core/auth/services/token_service.dart';

class MinistryController extends ChangeNotifier {
  final MinistryService _ministryService = MinistryService();
  
  List<MinistryResponse> _ministries = [];
  MinistryResponse? _selectedMinistry;
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isUpdating = false;
  bool _isDeleting = false;
  
  // Paginação
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _itemsPerPage = 20;
  
  // Filtros
  String _searchQuery = '';
  bool _showOnlyActive = false; // Mudança: agora mostra todos por padrão
  
  // Getters
  List<MinistryResponse> get ministries => _ministries;
  MinistryResponse? get selectedMinistry => _selectedMinistry;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isUpdating => _isUpdating;
  bool get isDeleting => _isDeleting;
  
  // Paginação
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  int get itemsPerPage => _itemsPerPage;
  
  // Filtros
  String get searchQuery => _searchQuery;
  bool get showOnlyActive => _showOnlyActive;
  
  /// Carrega a lista de ministérios
  Future<void> loadMinistries({
    bool refresh = false,
    String? search,
    bool? showOnlyActive,
  }) async {
    try {
      if (refresh) {
        _currentPage = 1;
      }
      
      _setLoading(true);
      
      // Obtém contexto atual
      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];
      
      if (tenantId == null || branchId == null) {
        throw Exception('Contexto de tenant/branch não encontrado');
      }
      
      // Aplica filtros
      if (search != null) _searchQuery = search;
      if (showOnlyActive != null) _showOnlyActive = showOnlyActive;
      
      final filters = ListMinistryDto(
        page: _currentPage,
        limit: _itemsPerPage,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        isActive: _showOnlyActive ? true : null,
      );
      
      final response = await _ministryService.listMinistries(
        tenantId: tenantId,
        branchId: branchId,
        filters: filters,
      );
      
      if (refresh) {
        _ministries = response.items;
      } else {
        _ministries.addAll(response.items);
      }
      
      _totalPages = response.pages;
      _totalItems = response.total;
      _currentPage = response.page;
      
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Carrega mais ministérios (pagination)
  Future<void> loadMoreMinistries() async {
    if (_currentPage < _totalPages && !_isLoading) {
      _currentPage++;
      await loadMinistries();
    }
  }
  
  /// Cria um novo ministério
  Future<bool> createMinistry(CreateMinistryDto ministryData) async {
    try {
      _setCreating(true);
      
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
      _ministries.insert(0, newMinistry);
      _totalItems++;
      
      notifyListeners();
      return true;
    } catch (e) {
      rethrow;
    } finally {
      _setCreating(false);
    }
  }
  
  /// Atualiza um ministério existente
  Future<bool> updateMinistry(String ministryId, UpdateMinistryDto ministryData) async {
    try {
      _setUpdating(true);
      
      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];
      
      if (tenantId == null || branchId == null) {
        throw Exception('Contexto de tenant/branch não encontrado');
      }
      
      final updatedMinistry = await _ministryService.updateMinistry(
        tenantId: tenantId,
        branchId: branchId,
        ministryId: ministryId,
        ministryData: ministryData,
      );
      
      // Atualiza na lista
      final index = _ministries.indexWhere((m) => m.id == ministryId);
      if (index != -1) {
        _ministries[index] = updatedMinistry;
      }
      
      // Atualiza o selecionado se for o mesmo
      if (_selectedMinistry?.id == ministryId) {
        _selectedMinistry = updatedMinistry;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      rethrow;
    } finally {
      _setUpdating(false);
    }
  }
  
  /// Remove um ministério
  Future<bool> deleteMinistry(String ministryId) async {
    try {
      _setDeleting(true);
      
      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];
      
      if (tenantId == null || branchId == null) {
        throw Exception('Contexto de tenant/branch não encontrado');
      }
      
      final success = await _ministryService.deleteMinistry(
        tenantId: tenantId,
        branchId: branchId,
        ministryId: ministryId,
      );
      
      if (success) {
        // Remove da lista
        _ministries.removeWhere((m) => m.id == ministryId);
        _totalItems--;
        
        // Remove da seleção se for o mesmo
        if (_selectedMinistry?.id == ministryId) {
          _selectedMinistry = null;
        }
        
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      rethrow;
    } finally {
      _setDeleting(false);
    }
  }
  
  /// Ativa/desativa um ministério
  Future<bool> toggleMinistryStatus(String ministryId, bool isActive) async {
    try {
      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];
      
      if (tenantId == null || branchId == null) {
        throw Exception('Contexto de tenant/branch não encontrado');
      }
      
      final updatedMinistry = await _ministryService.toggleMinistryStatus(
        tenantId: tenantId,
        branchId: branchId,
        ministryId: ministryId,
        isActive: isActive,
      );
      
      // Atualiza na lista
      final index = _ministries.indexWhere((m) => m.id == ministryId);
      if (index != -1) {
        _ministries[index] = updatedMinistry;
      }
      
      // Atualiza o selecionado se for o mesmo
      if (_selectedMinistry?.id == ministryId) {
        _selectedMinistry = updatedMinistry;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Seleciona um ministério
  void selectMinistry(MinistryResponse? ministry) {
    _selectedMinistry = ministry;
    notifyListeners();
  }
  
  /// Limpa a seleção
  void clearSelection() {
    _selectedMinistry = null;
    notifyListeners();
  }
  
  /// Aplica filtros e recarrega
  Future<void> applyFilters({
    String? search,
    bool? showOnlyActive,
  }) async {
    _searchQuery = search ?? _searchQuery;
    _showOnlyActive = showOnlyActive ?? _showOnlyActive;
    _currentPage = 1;
    
    await loadMinistries(refresh: true);
  }
  
  /// Limpa filtros
  Future<void> clearFilters() async {
    _searchQuery = '';
    _showOnlyActive = false; // Mudança: agora mostra todos por padrão
    _currentPage = 1;
    
    await loadMinistries(refresh: true);
  }
  
  /// Reseta o controller
  void reset() {
    _ministries.clear();
    _selectedMinistry = null;
    _currentPage = 1;
    _totalPages = 1;
    _totalItems = 0;
    _searchQuery = '';
    _showOnlyActive = false; // Mudança: agora mostra todos por padrão
    _setLoading(false);
    _setCreating(false);
    _setUpdating(false);
    _setDeleting(false);
    notifyListeners();
  }
  
  // Métodos privados para controlar estados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setCreating(bool creating) {
    _isCreating = creating;
    notifyListeners();
  }
  
  void _setUpdating(bool updating) {
    _isUpdating = updating;
    notifyListeners();
  }
  
  void _setDeleting(bool deleting) {
    _isDeleting = deleting;
    notifyListeners();
  }
} 