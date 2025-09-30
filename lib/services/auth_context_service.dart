
import 'package:servus_app/core/auth/services/token_service.dart';

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
    print('🔐 [AuthContextService] Configurando contexto:');
    print('   - TenantId: $tenantId');
    print('   - BranchId: $branchId');
    print('   - UserId: $userId');
    
    _tenantId = tenantId;
    _branchId = branchId;
    _userId = userId;
    
    print('✅ [AuthContextService] Contexto configurado com sucesso');
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

  Future<Map<String, dynamic>> get headers async {
    try {
      print('🔐 [AuthContextService] Obtendo headers...');
      print('   - hasContext: $hasContext');
      print('   - tenantId: $_tenantId');
      print('   - branchId: $_branchId');
      print('   - userId: $_userId');
      
      if (!hasContext) {
        print('❌ [AuthContextService] Contexto de autenticação não definido');
        throw Exception('Contexto de autenticação não definido');
      }
      
      // Obter token JWT
      print('🔑 [AuthContextService] Obtendo token JWT...');
      final token = await TokenService.getAccessToken();
      if (token == null) {
        print('❌ [AuthContextService] Token de acesso não encontrado');
        throw Exception('Token de acesso não encontrado');
      }
      
      print('✅ [AuthContextService] Token obtido: ${token.substring(0, 20)}...');
      
      final headers = <String, dynamic>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'X-Tenant-ID': _tenantId!,
        if (_branchId != null) 'X-Branch-ID': _branchId!,
      };
      
      print('📦 [AuthContextService] Headers criados: ${headers.keys.join(', ')}');
      print('📦 [AuthContextService] Headers completos: $headers');
      return headers;
    } catch (e) {
      print('❌ [AuthContextService] ERRO ao obter headers: $e');
      print('❌ [AuthContextService] Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }
}
