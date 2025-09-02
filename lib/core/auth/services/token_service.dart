import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:uuid/uuid.dart';

class TokenService {
  static const _storage = FlutterSecureStorage();
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyTokenExpiry = 'token_expiry';
  static const _keyDeviceId = 'device_id';
  static const _keyTenantId = 'tenant_id';
  static const _keyBranchId = 'branch_id';
  static const _keyMinistryId = 'ministry_id';

  // Chaves de armazenamento
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiresInKey = 'expires_in';
  static const String _deviceIdKey = 'device_id';
  static const String _tenantIdKey = 'tenant_id';
  static const String _branchIdKey = 'branch_id';
  static const String _userRoleKey = 'user_role';
  static const String _membershipRoleKey = 'membership_role';
  static const String _permissionsKey = 'permissions';

  // 🆕 Claims de segurança extraídos do JWT
  static String? _cachedTenantId;
  static String? _cachedBranchId;
  static String? _cachedUserRole;
  static String? _cachedMembershipRole;
  static List<String> _cachedPermissions = [];

  // Getters para claims de segurança
  static String? get tenantId => _cachedTenantId;
  static String? get branchId => _cachedBranchId;
  static String? get userRole => _cachedUserRole;
  static String? get membershipRole => _cachedMembershipRole;
  static List<String> get permissions => List.unmodifiable(_cachedPermissions);

  /// Gera um ID único para o dispositivo
  static Future<String> getDeviceId() async {
    String? deviceId = await _storage.read(key: _keyDeviceId);
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await _storage.write(key: _keyDeviceId, value: deviceId);
    }
    return deviceId;
  }

  /// Salva tokens de autenticação
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    final expiryTime = DateTime.now().add(Duration(seconds: expiresIn));
    
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: accessToken),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
      _storage.write(key: _keyTokenExpiry, value: expiryTime.millisecondsSinceEpoch.toString()),
    ]);
  }

  /// Obtém o token de acesso atual
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  /// Obtém o token de refresh
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  /// Verifica se o token está expirado
  static Future<bool> isTokenExpired() async {
    final expiryString = await _storage.read(key: _keyTokenExpiry);
    if (expiryString == null) return true;
    
    final expiryTime = DateTime.fromMillisecondsSinceEpoch(int.parse(expiryString));
    return DateTime.now().isAfter(expiryTime);
  }

  /// Verifica se o token expira em breve (dentro de 5 minutos)
  static Future<bool> isTokenExpiringSoon() async {
    final expiryString = await _storage.read(key: _keyTokenExpiry);
    if (expiryString == null) return true;
    
    final expiryTime = DateTime.fromMillisecondsSinceEpoch(int.parse(expiryString));
    final fiveMinutesFromNow = DateTime.now().add(const Duration(minutes: 5));
    return fiveMinutesFromNow.isAfter(expiryTime);
  }

  /// Limpa todos os tokens
  static Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyRefreshToken),
      _storage.delete(key: _keyTokenExpiry),
    ]);
  }

  /// Salva contexto do tenant/branch/ministry
  static Future<void> saveContext({
    String? tenantId,
    String? branchId,
    String? ministryId,
  }) async {
    final futures = <Future<void>>[];
    
    if (tenantId != null) {
      futures.add(_storage.write(key: _keyTenantId, value: tenantId));
    }
    if (branchId != null) {
      futures.add(_storage.write(key: _keyBranchId, value: branchId));
    }
    if (ministryId != null) {
      futures.add(_storage.write(key: _keyMinistryId, value: ministryId));
    }
    
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  /// Obtém contexto atual
  static Future<Map<String, String?>> getContext() async {
    final tenantId = await _storage.read(key: _keyTenantId);
    final branchId = await _storage.read(key: _keyBranchId);
    final ministryId = await _storage.read(key: _keyMinistryId);
    
    return {
      'tenantId': tenantId,
      'branchId': branchId,
      'ministryId': ministryId,
    };
  }

  /// Limpa contexto
  static Future<void> clearContext() async {
    await Future.wait([
      _storage.delete(key: _keyTenantId),
      _storage.delete(key: _keyBranchId),
      _storage.delete(key: _keyMinistryId),
    ]);
  }

  /// Limpa todos os dados de autenticação
  static Future<void> clearAll() async {
    await Future.wait([
      clearTokens(),
      clearContext(),
    ]);
  }

  // 🆕 Extrair e cachear claims de segurança do JWT
  static Future<void> extractSecurityClaims(String accessToken) async {
    try {
      print('🔐 Extraindo claims de segurança do JWT...');
      
      // Decodifica o JWT (sem verificar assinatura - apenas para leitura)
      final decodedToken = JwtDecoder.decode(accessToken);
      
      print('📋 JWT decodificado:');
      print('   - Subject: ${decodedToken['sub']}');
      print('   - Email: ${decodedToken['email']}');
      print('   - Role: ${decodedToken['role']}');
      print('   - Tenant ID: ${decodedToken['tenantId']}');
      print('   - Branch ID: ${decodedToken['branchId']}');
      print('   - Membership Role: ${decodedToken['membershipRole']}');
      print('   - Permissions: ${decodedToken['permissions']}');

      // Cachear claims de segurança
      _cachedTenantId = decodedToken['tenantId'];
      _cachedBranchId = decodedToken['branchId'];
      _cachedUserRole = decodedToken['role'];
      _cachedMembershipRole = decodedToken['membershipRole'];
      _cachedPermissions = List<String>.from(decodedToken['permissions'] ?? []);

      // Salvar claims no storage seguro
      await _saveSecurityClaims();
      
      print('✅ Claims de segurança extraídos e salvos:');
      print('   - Tenant ID: $_cachedTenantId');
      print('   - Branch ID: $_cachedBranchId');
      print('   - User Role: $_cachedUserRole');
      print('   - Membership Role: $_cachedMembershipRole');
      print('   - Permissions: $_cachedPermissions');
      
    } catch (e) {
      print('❌ Erro ao extrair claims de segurança: $e');
      // Em caso de erro, limpa o cache
      _clearSecurityCache();
    }
  }

  // 🆕 Salvar claims de segurança no storage
  static Future<void> _saveSecurityClaims() async {
    try {
      if (_cachedTenantId != null) {
        await _storage.write(key: _tenantIdKey, value: _cachedTenantId);
      }
      if (_cachedBranchId != null) {
        await _storage.write(key: _branchIdKey, value: _cachedBranchId);
      }
      if (_cachedUserRole != null) {
        await _storage.write(key: _userRoleKey, value: _cachedUserRole);
      }
      if (_cachedMembershipRole != null) {
        await _storage.write(key: _membershipRoleKey, value: _cachedMembershipRole);
      }
      if (_cachedPermissions.isNotEmpty) {
        await _storage.write(key: _permissionsKey, value: jsonEncode(_cachedPermissions));
      }
    } catch (e) {
      print('❌ Erro ao salvar claims de segurança: $e');
    }
  }

  // 🆕 Carregar claims de segurança do storage
  static Future<void> loadSecurityClaims() async {
    try {
      print('🔍 Carregando claims de segurança do storage...');
      
      _cachedTenantId = await _storage.read(key: _tenantIdKey);
      _cachedBranchId = await _storage.read(key: _branchIdKey);
      _cachedUserRole = await _storage.read(key: _userRoleKey);
      _cachedMembershipRole = await _storage.read(key: _membershipRoleKey);
      
      final permissionsJson = await _storage.read(key: _permissionsKey);
      if (permissionsJson != null) {
        _cachedPermissions = List<String>.from(jsonDecode(permissionsJson));
      }

      print('✅ Claims de segurança carregados:');
      print('   - Tenant ID: $_cachedTenantId');
      print('   - Branch ID: $_cachedBranchId');
      print('   - User Role: $_cachedUserRole');
      print('   - Membership Role: $_cachedMembershipRole');
      print('   - Permissions: $_cachedPermissions');
      
    } catch (e) {
      print('❌ Erro ao carregar claims de segurança: $e');
      _clearSecurityCache();
    }
  }

  // 🆕 Limpar cache de claims de segurança
  static void _clearSecurityCache() {
    _cachedTenantId = null;
    _cachedBranchId = null;
    _cachedUserRole = null;
    _cachedMembershipRole = null;
    _cachedPermissions.clear();
  }

  // 🆕 Verificar se usuário tem permissão específica
  static bool hasPermission(String permission) {
    return _cachedPermissions.contains(permission);
  }

  // 🆕 Verificar se usuário tem qualquer uma das permissões
  static bool hasAnyPermission(List<String> permissions) {
    return permissions.any((permission) => _cachedPermissions.contains(permission));
  }

  // 🆕 Verificar se usuário tem todas as permissões
  static bool hasAllPermissions(List<String> permissions) {
    return permissions.every((permission) => _cachedPermissions.contains(permission));
  }

  // 🆕 Verificar se usuário é servus_admin
  static bool get isServusAdmin => _cachedUserRole == 'servus_admin';

  // 🆕 Verificar se usuário tem contexto de tenant
  static bool get hasTenantContext => _cachedTenantId != null && _cachedTenantId!.isNotEmpty;

  // 🆕 Verificar se usuário tem contexto de branch
  static bool get hasBranchContext => _cachedBranchId != null && _cachedBranchId!.isNotEmpty;
} 