import 'package:flutter/foundation.dart';
import 'package:servus_app/features/ministries/models/ministry_function.dart';
import 'package:servus_app/features/ministries/services/ministry_functions_service.dart';

class MinistryFunctionsController extends ChangeNotifier {
  final MinistryFunctionsService _service;

  MinistryFunctionsController(this._service);

  // Estado
  List<MinistryFunction> _ministryFunctions = [];
  List<MinistryFunction> _tenantFunctions = [];
  bool _isLoading = false;
  String? _error;
  bool _showOnlyMinistry = true;

  // Getters
  List<MinistryFunction> get ministryFunctions => _ministryFunctions;
  List<MinistryFunction> get tenantFunctions => _tenantFunctions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get showOnlyMinistry => _showOnlyMinistry;

  // Funções filtradas baseadas no toggle
  List<MinistryFunction> get filteredFunctions {
    if (_showOnlyMinistry) {
      return _ministryFunctions;
    } else {
      return _tenantFunctions;
    }
  }

  // Funções habilitadas no ministério
  List<MinistryFunction> get enabledFunctions {
    return _ministryFunctions.where((f) => f.isActive).toList();
  }

  /// Carrega funções do ministério
  Future<void> loadMinistryFunctions(String ministryId) async {
    _setLoading(true);
    _clearError();

    try {
      // Carregar todas as funções (ativas e inativas)
      _ministryFunctions = await _service.getMinistryFunctions(ministryId);
      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar funções do ministério: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Carrega catálogo do tenant
  Future<void> loadTenantFunctions({String? ministryId, String? search}) async {
    _setLoading(true);
    _clearError();

    try {
      _tenantFunctions = await _service.getTenantFunctions(
        ministryId: ministryId,
        search: search,
      );
      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar funções do tenant: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Cria ou reutiliza funções via bulk upsert
  Future<BulkUpsertResponse> bulkUpsertFunctions(
    String ministryId,
    List<String> names, {
    String? category,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _service.bulkUpsertFunctions(
        ministryId,
        names,
        category: category,
      );

      // Recarregar funções após criação
      await loadMinistryFunctions(ministryId);
      await loadTenantFunctions(ministryId: ministryId);

      return response;
    } catch (e) {
      _setError('Erro ao criar funções: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Atualiza função do ministério
  Future<void> updateMinistryFunction(
    String ministryId,
    String functionId, {
    bool? isActive,
    int? defaultSlots,
    String? notes,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _service.updateMinistryFunction(
        ministryId,
        functionId,
        isActive: isActive,
        defaultSlots: defaultSlots,
        notes: notes,
      );

      // Recarregar funções após atualização
      await loadMinistryFunctions(ministryId);
      await loadTenantFunctions(ministryId: ministryId);
    } catch (e) {
      _setError('Erro ao atualizar função: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Alterna filtro entre ministério e tenant
  void toggleFilter() {
    _showOnlyMinistry = !_showOnlyMinistry;
    notifyListeners();
  }

  /// Busca funções no catálogo
  Future<void> searchFunctions(String ministryId, String search) async {
    if (search.isEmpty) {
      await loadTenantFunctions(ministryId: ministryId);
    } else {
      await loadTenantFunctions(ministryId: ministryId, search: search);
    }
  }

  // Métodos privados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
