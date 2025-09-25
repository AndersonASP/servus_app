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

  static Future<void> salvarUsuario(UsuarioLogado usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNome, usuario.nome);
    await prefs.setString(_keyEmail, usuario.email);
    await prefs.setString(_keyTenantName, usuario.tenantName ?? '');
    await prefs.setString(_keyBranchName, usuario.branchName ?? '');
    await prefs.setString(_keyPicture, usuario.picture ?? '');
    await prefs.setString(_keyRole, mapRoleToString(usuario.role));
    await prefs.setString(_keyTenantId, usuario.tenantId ?? '');
    await prefs.setString(_keyBranchId, usuario.branchId ?? '');
  }

  static Future<UsuarioLogado?> carregarUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final nome = prefs.getString(_keyNome);
    final email = prefs.getString(_keyEmail);
    final role = prefs.getString(_keyRole);
    final tenantId = prefs.getString(_keyTenantId);
    final tenantName = prefs.getString(_keyTenantName);
    final branchId = prefs.getString(_keyBranchId);
    final branchName = prefs.getString(_keyBranchName);
    final picture = prefs.getString(_keyPicture);

    if (nome != null && email != null && role != null) {
      return UsuarioLogado(
        nome: nome,
        email: email,
        tenantName: tenantName ?? '',
        branchName: branchName ?? '',
        role: mapRoleToEnum(role),
        tenantId: tenantId,
        branchId: branchId,
        picture: picture,
        ministerios: [], // TODO: Implementar quando disponível
      );
    }

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