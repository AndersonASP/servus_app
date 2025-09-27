import 'package:servus_app/core/utils/role_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:servus_app/core/models/usuario_logado.dart';

class LocalStorageService {
  static const _keyNome = 'nome';
  static const _keyEmail = 'email';
  static const _keyRole = 'role';
  static const _keyTenantId = 'tenantId';
  static const _keyTenantName = 'tenantName';
  static const _keyBranchId = 'branchId';
  static const _keyBranchName = 'branchName';
  static const _keyPicture = 'picture';
  static const _keyPrimaryMinistryId = 'primaryMinistryId';
  static const _keyPrimaryMinistryName = 'primaryMinistryName';

  static Future<void> salvarUsuario(UsuarioLogado usuario) async {
    print('🔍 [LocalStorage] ===== SALVANDO USUÁRIO =====');
    print('🔍 [LocalStorage] Dados do usuário:');
    print('   - Nome: ${usuario.nome}');
    print('   - Email: ${usuario.email}');
    print('   - Role: ${usuario.role}');
    print('   - PrimaryMinistryId: ${usuario.primaryMinistryId}');
    print('   - PrimaryMinistryName: ${usuario.primaryMinistryName}');
    print('   - TenantId: ${usuario.tenantId}');
    print('   - BranchId: ${usuario.branchId}');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNome, usuario.nome);
    await prefs.setString(_keyEmail, usuario.email);
    await prefs.setString(_keyTenantName, usuario.tenantName ?? '');
    await prefs.setString(_keyBranchName, usuario.branchName ?? '');
    await prefs.setString(_keyPicture, usuario.picture ?? '');
    await prefs.setString(_keyRole, mapRoleToString(usuario.role));
    await prefs.setString(_keyTenantId, usuario.tenantId ?? '');
    await prefs.setString(_keyBranchId, usuario.branchId ?? '');
    
    // 🆕 CORREÇÃO: Salvar primaryMinistryId apenas se não for null
    if (usuario.primaryMinistryId != null && usuario.primaryMinistryId!.isNotEmpty) {
      await prefs.setString(_keyPrimaryMinistryId, usuario.primaryMinistryId!);
      print('✅ [LocalStorage] PrimaryMinistryId salvo: ${usuario.primaryMinistryId}');
    } else {
      await prefs.remove(_keyPrimaryMinistryId); // Remove se for null/vazio
      print('⚠️ [LocalStorage] PrimaryMinistryId é null/vazio, removendo do storage');
    }
    
    if (usuario.primaryMinistryName != null && usuario.primaryMinistryName!.isNotEmpty) {
      await prefs.setString(_keyPrimaryMinistryName, usuario.primaryMinistryName!);
      print('✅ [LocalStorage] PrimaryMinistryName salvo: ${usuario.primaryMinistryName}');
    } else {
      await prefs.remove(_keyPrimaryMinistryName); // Remove se for null/vazio
      print('⚠️ [LocalStorage] PrimaryMinistryName é null/vazio, removendo do storage');
    }
    
    print('🔍 [LocalStorage] ===== USUÁRIO SALVO COM SUCESSO =====');
  }

  static Future<UsuarioLogado?> carregarUsuario() async {
    print('🔍 [LocalStorage] ===== CARREGANDO USUÁRIO =====');
    
    final prefs = await SharedPreferences.getInstance();
    final nome = prefs.getString(_keyNome);
    final email = prefs.getString(_keyEmail);
    final role = prefs.getString(_keyRole);
    final tenantId = prefs.getString(_keyTenantId);
    final tenantName = prefs.getString(_keyTenantName);
    final branchId = prefs.getString(_keyBranchId);
    final branchName = prefs.getString(_keyBranchName);
    final picture = prefs.getString(_keyPicture);
    final primaryMinistryId = prefs.getString(_keyPrimaryMinistryId);
    final primaryMinistryName = prefs.getString(_keyPrimaryMinistryName);

    print('🔍 [LocalStorage] Dados carregados do storage:');
    print('   - Nome: $nome');
    print('   - Email: $email');
    print('   - Role: $role');
    print('   - PrimaryMinistryId (raw): $primaryMinistryId');
    print('   - PrimaryMinistryName (raw): $primaryMinistryName');
    print('   - TenantId: $tenantId');
    print('   - BranchId: $branchId');

    if (nome != null && email != null && role != null) {
      final processedPrimaryMinistryId = primaryMinistryId?.isNotEmpty == true ? primaryMinistryId : null;
      final processedPrimaryMinistryName = primaryMinistryName?.isNotEmpty == true ? primaryMinistryName : null;
      
      print('🔍 [LocalStorage] Dados processados:');
      print('   - PrimaryMinistryId (processado): $processedPrimaryMinistryId');
      print('   - PrimaryMinistryName (processado): $processedPrimaryMinistryName');
      
      final usuario = UsuarioLogado(
        nome: nome,
        email: email,
        tenantName: tenantName ?? '',
        branchName: branchName ?? '',
        role: mapRoleToEnum(role),
        tenantId: tenantId,
        branchId: branchId,
        picture: picture,
        ministerios: [], // TODO: Implementar quando disponível
        primaryMinistryId: processedPrimaryMinistryId,
        primaryMinistryName: processedPrimaryMinistryName,
      );
      
      print('✅ [LocalStorage] Usuário carregado com sucesso');
      print('🔍 [LocalStorage] ===== FIM DO CARREGAMENTO =====');
      return usuario;
    }

    print('❌ [LocalStorage] Dados insuficientes para carregar usuário');
    print('🔍 [LocalStorage] ===== FIM DO CARREGAMENTO =====');
    return null;
  }

  static Future<void> limparDados() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Verifica se há dados de usuário salvos
  static Future<bool> temUsuarioSalvo() async {
    final prefs = await SharedPreferences.getInstance();
    final nome = prefs.getString(_keyNome);
    final email = prefs.getString(_keyEmail);
    final role = prefs.getString(_keyRole);
    
    return nome != null && email != null && role != null;
  }

  /// Obtém apenas informações básicas do usuário
  static Future<Map<String, String?>> getInfoBasica() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'nome': prefs.getString(_keyNome),
      'email': prefs.getString(_keyEmail),
      'role': prefs.getString(_keyRole),
      'tenantId': prefs.getString(_keyTenantId),
      'branchId': prefs.getString(_keyBranchId),
    };
  }
}