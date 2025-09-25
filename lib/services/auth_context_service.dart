
class AuthContextService {
  static AuthContextService? _instance;
  static AuthContextService get instance => _instance ??= AuthContextService._();
  
  AuthContextService._();

  String? _tenantId;
  String? _branchId;
  String? _userId;

  void setContext({
    required String tenantId,
    String? branchId,
    required String userId,
  }) {
    
    _tenantId = tenantId;
    _branchId = branchId;
    _userId = userId;
    
  }

  void clearContext() {
    _tenantId = null;
    _branchId = null;
    _userId = null;
  }

  String? get tenantId => _tenantId;
  String? get branchId => _branchId;
  String? get userId => _userId;

  bool get hasContext => _tenantId != null && _userId != null;

  Map<String, String> get headers {
    
    if (!hasContext) {
      throw Exception('Contexto de autenticação não definido');
    }
    
    final headers = {
      'X-Tenant-ID': _tenantId!,
      if (_branchId != null) 'X-Branch-ID': _branchId!,
    };
    
    return headers;
  }
}
