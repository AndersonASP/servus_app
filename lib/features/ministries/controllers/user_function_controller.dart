import 'package:flutter/foundation.dart';
import 'package:servus_app/features/ministries/models/user_function.dart';
import 'package:servus_app/features/ministries/services/user_function_service.dart';

class UserFunctionController extends ChangeNotifier {
  final UserFunctionService _userFunctionService = UserFunctionService();

  List<UserFunction> _userFunctions = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<UserFunction> get userFunctions => _userFunctions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Funções aprovadas de um usuário
  List<UserFunction> getApprovedFunctionsForUser(String userId) {
    return _userFunctions
        .where((uf) => uf.userId == userId && uf.isApproved)
        .toList();
  }

  // Funções pendentes de um ministério
  List<UserFunction> getPendingFunctionsForMinistry(String ministryId) {
    return _userFunctions
        .where((uf) => uf.ministryId == ministryId && uf.isPending)
        .toList();
  }

  // Funções de um usuário por status
  List<UserFunction> getUserFunctionsByStatus(String userId, UserFunctionStatus status) {
    return _userFunctions
        .where((uf) => uf.userId == userId && uf.status == status)
        .toList();
  }

  /// Carregar funções de um usuário
  Future<void> loadUserFunctions(String userId, {UserFunctionStatus? status}) async {
    _setLoading(true);
    _clearError();

    try {
      final functions = await _userFunctionService.getUserFunctionsByUser(
        userId: userId,
        status: status,
      );
      
      _userFunctions = functions;
      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar funções do usuário: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Carregar funções de um ministério
  Future<void> loadMinistryFunctions(String ministryId, {UserFunctionStatus? status}) async {
    _setLoading(true);
    _clearError();

    try {
      final functions = await _userFunctionService.getUserFunctionsByMinistry(
        ministryId: ministryId,
        status: status,
      );
      
      _userFunctions = functions;
      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar funções do ministério: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Carregar funções aprovadas de um usuário
  Future<void> loadApprovedFunctionsForUser(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      final functions = await _userFunctionService.getApprovedFunctionsForUser(
        userId: userId,
      );
      
      _userFunctions = functions;
      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar funções aprovadas: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Criar vínculo usuário-função
  Future<UserFunction?> createUserFunction({
    required String userId,
    required String ministryId,
    required String functionId,
    String? notes,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final userFunction = await _userFunctionService.createUserFunction(
        userId: userId,
        ministryId: ministryId,
        functionId: functionId,
        notes: notes,
      );

      // Adicionar à lista local
      _userFunctions.add(userFunction);
      notifyListeners();

      return userFunction;
    } catch (e) {
      _setError('Erro ao criar vínculo: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Aprovar vínculo usuário-função
  Future<bool> approveUserFunction(String userFunctionId, {String? notes}) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedFunction = await _userFunctionService.updateUserFunctionStatus(
        userFunctionId: userFunctionId,
        status: UserFunctionStatus.approved,
        notes: notes,
      );

      // Atualizar na lista local
      final index = _userFunctions.indexWhere((uf) => uf.id == userFunctionId);
      if (index != -1) {
        _userFunctions[index] = updatedFunction;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Erro ao aprovar vínculo: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Rejeitar vínculo usuário-função
  Future<bool> rejectUserFunction(String userFunctionId, {String? notes}) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedFunction = await _userFunctionService.updateUserFunctionStatus(
        userFunctionId: userFunctionId,
        status: UserFunctionStatus.rejected,
        notes: notes,
      );

      // Atualizar na lista local
      final index = _userFunctions.indexWhere((uf) => uf.id == userFunctionId);
      if (index != -1) {
        _userFunctions[index] = updatedFunction;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Erro ao rejeitar vínculo: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Remover vínculo usuário-função
  Future<bool> deleteUserFunction(String userFunctionId) async {
    _setLoading(true);
    _clearError();

    try {
      await _userFunctionService.deleteUserFunction(
        userFunctionId: userFunctionId,
      );

      // Remover da lista local
      _userFunctions.removeWhere((uf) => uf.id == userFunctionId);
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Erro ao remover vínculo: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verificar se usuário tem função aprovada em um ministério
  bool hasApprovedFunctionInMinistry(String userId, String ministryId) {
    return _userFunctions.any((uf) => 
      uf.userId == userId && 
      uf.ministryId == ministryId && 
      uf.isApproved
    );
  }

  /// Obter funções aprovadas de um usuário em um ministério específico
  List<UserFunction> getApprovedFunctionsInMinistry(String userId, String ministryId) {
    return _userFunctions.where((uf) => 
      uf.userId == userId && 
      uf.ministryId == ministryId && 
      uf.isApproved
    ).toList();
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

  void clear() {
    _userFunctions.clear();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
