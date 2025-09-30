import 'package:servus_app/services/auth_context_service.dart';
import 'package:servus_app/core/models/usuario_logado.dart';

class AuthIntegrationService {
  static AuthIntegrationService? _instance;
  static AuthIntegrationService get instance => _instance ??= AuthIntegrationService._();
  
  AuthIntegrationService._();

  final AuthContextService _authContext = AuthContextService.instance;

  /// Integra com o estado de autenticação real usando UsuarioLogado
  void integrateWithUsuarioLogado(UsuarioLogado? usuario) {
    print('🔗 [AuthIntegrationService] Integrando com UsuarioLogado...');
    
    if (usuario != null) {
      print('👤 [AuthIntegrationService] Usuário encontrado:');
      print('   - Nome: ${usuario.nome}');
      print('   - Email: ${usuario.email}');
      print('   - TenantId: ${usuario.tenantId}');
      print('   - BranchId: ${usuario.branchId}');
      
      if (usuario.tenantId != null) {
        print('✅ [AuthIntegrationService] Configurando contexto...');
        _authContext.setContext(
          tenantId: usuario.tenantId!,
          branchId: usuario.branchId,
          userId: usuario.email,
        );
        print('✅ [AuthIntegrationService] Contexto configurado');
      } else {
        print('❌ [AuthIntegrationService] TenantId é null, limpando contexto');
        _authContext.clearContext();
      }
    } else {
      print('❌ [AuthIntegrationService] Usuário é null, limpando contexto');
      _authContext.clearContext();
    }
  }

  /// Integra com o estado de autenticação real (método legado para compatibilidade)
  void integrateWithAuthState(dynamic authState) {
    if (authState.isAuthenticated && authState.user != null) {
      // Extrair informações do usuário autenticado
      final user = authState.user!;
      
      // TODO: Obter tenantId e branchId do contexto do usuário
      // Por enquanto, usando dados mock baseados no usuário
      final tenantId = _extractTenantId(user);
      final branchId = _extractBranchId(user);
      final userId = user.id ?? user.email ?? 'unknown';
      
      _authContext.setContext(
        tenantId: tenantId,
        branchId: branchId,
        userId: userId,
      );
      
    } else {
      _authContext.clearContext();
    }
  }

  /// Extrai tenantId do usuário (implementação temporária)
  String _extractTenantId(dynamic user) {
    // TODO: Implementar extração real do tenantId
    // Por enquanto, retornando um valor mock baseado no email
    final email = user.email ?? 'unknown@example.com';
    return 'tenant_${email.split('@')[0]}';
  }

  /// Extrai branchId do usuário (implementação temporária)
  String? _extractBranchId(dynamic user) {
    // TODO: Implementar extração real do branchId
    // Por enquanto, retornando null (matriz)
    return null;
  }

  /// Verifica se o contexto está disponível
  bool get hasValidContext => _authContext.hasContext;

  /// Obtém headers para requisições autenticadas
  Future<Map<String, dynamic>> getAuthHeaders() async {
    if (!hasValidContext) {
      throw Exception('Contexto de autenticação não disponível');
    }
    return await _authContext.headers;
  }
}
