import 'package:flutter/material.dart';
import 'package:servus_app/features/leader/escalas/models/substitution_request_model.dart';
import 'package:servus_app/services/scales_advanced_service.dart';

class SubstitutionController extends ChangeNotifier {
  final List<SubstitutionRequest> _pendingRequests = [];
  final List<SubstitutionRequest> _sentRequests = [];
  final List<SwapCandidate> _swapCandidates = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SubstitutionRequest> get pendingRequests => List.unmodifiable(_pendingRequests);
  List<SubstitutionRequest> get sentRequests => List.unmodifiable(_sentRequests);
  List<SwapCandidate> get swapCandidates => List.unmodifiable(_swapCandidates);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Carregar solicitações pendentes
  Future<void> loadPendingRequests({required String tenantId}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await ScalesAdvancedService.getPendingRequestsForUser(
        tenantId: tenantId,
      );

      if (response['success'] == true) {
        _pendingRequests.clear();
        final data = response['data'] as List<dynamic>;
        _pendingRequests.addAll(
          data.map((item) => SubstitutionRequest.fromMap(item)).toList(),
        );
      }
    } catch (e) {
      _setError('Erro ao carregar solicitações pendentes: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Carregar solicitações enviadas
  Future<void> loadSentRequests({required String tenantId}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await ScalesAdvancedService.getSentRequestsByUser(
        tenantId: tenantId,
      );

      if (response['success'] == true) {
        _sentRequests.clear();
        final data = response['data'] as List<dynamic>;
        _sentRequests.addAll(
          data.map((item) => SubstitutionRequest.fromMap(item)).toList(),
        );
      }
    } catch (e) {
      _setError('Erro ao carregar solicitações enviadas: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Buscar candidatos para troca
  Future<void> findSwapCandidates({
    required String tenantId,
    required String scaleId,
    required String requesterId,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await ScalesAdvancedService.findSwapCandidates(
        tenantId: tenantId,
        scaleId: scaleId,
        requesterId: requesterId,
      );

      if (response['success'] == true) {
        _swapCandidates.clear();
        final data = response['data'] as List<dynamic>;
        _swapCandidates.addAll(
          data.map((item) => SwapCandidate.fromMap(item)).toList(),
        );
      }
    } catch (e) {
      _setError('Erro ao buscar candidatos: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Criar solicitação de troca
  Future<bool> createSwapRequest({
    required String tenantId,
    required String scaleId,
    required String targetId,
    required String reason,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await ScalesAdvancedService.createSwapRequest(
        tenantId: tenantId,
        scaleId: scaleId,
        targetId: targetId,
        reason: reason,
      );

      if (response['success'] == true) {
        // Recarregar solicitações enviadas
        await loadSentRequests(tenantId: tenantId);
        return true;
      }
      return false;
    } catch (e) {
      _setError('Erro ao criar solicitação de troca: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Responder a uma solicitação de troca
  Future<bool> respondToSwapRequest({
    required String tenantId,
    required String swapRequestId,
    required String response,
    String? rejectionReason,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await ScalesAdvancedService.respondToSwapRequest(
        tenantId: tenantId,
        swapRequestId: swapRequestId,
        responseValue: response,
        rejectionReason: rejectionReason,
      );

      if (result['success'] == true) {
        // Recarregar solicitações pendentes
        await loadPendingRequests(tenantId: tenantId);
        return true;
      }
      return false;
    } catch (e) {
      _setError('Erro ao responder solicitação: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Cancelar uma solicitação de troca
  Future<bool> cancelSwapRequest({
    required String tenantId,
    required String swapRequestId,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await ScalesAdvancedService.cancelSwapRequest(
        tenantId: tenantId,
        swapRequestId: swapRequestId,
      );

      if (response['success'] == true) {
        // Recarregar solicitações enviadas
        await loadSentRequests(tenantId: tenantId);
        return true;
      }
      return false;
    } catch (e) {
      _setError('Erro ao cancelar solicitação: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Obter solicitação por ID
  SubstitutionRequest? getRequestById(String id) {
    try {
      return _pendingRequests.firstWhere((r) => r.id == id);
    } catch (_) {
      try {
        return _sentRequests.firstWhere((r) => r.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  /// Verificar se há solicitações pendentes
  bool get hasPendingRequests => _pendingRequests.isNotEmpty;

  /// Contar solicitações pendentes
  int get pendingRequestsCount => _pendingRequests.length;

  /// Obter candidatos disponíveis
  List<SwapCandidate> get availableCandidates =>
      _swapCandidates.where((c) => c.isAvailable).toList();

  /// Obter candidatos por nível de função
  List<SwapCandidate> getCandidatesByLevel(String level) =>
      _swapCandidates.where((c) => c.functionLevel == level).toList();

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clear() {
    _pendingRequests.clear();
    _sentRequests.clear();
    _swapCandidates.clear();
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
