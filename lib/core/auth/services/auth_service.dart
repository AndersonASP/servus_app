import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:servus_app/core/models/login_response.dart';
import 'package:servus_app/core/models/usuario_logado.dart';
import 'package:servus_app/core/models/ministerio.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:servus_app/core/utils/role_util.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/state/auth_state.dart';
import 'package:servus_app/services/local_storage_service.dart';
import 'package:servus_app/core/enums/user_role.dart';

class AuthService {
  final Dio dio;
  final GoogleSignIn googleSignIn;

  AuthService({GoogleSignIn? googleSignIn})
      : dio = DioClient.instance,
        googleSignIn = googleSignIn ?? GoogleSignIn();

  /// Busca o tenant do usuário pelo email
  Future<String?> _findUserTenant(String email) async {
    try {
      print('🔍 Buscando tenant do usuário: $email');
      
      final deviceId = await TokenService.getDeviceId();
      
      // Primeiro, tenta buscar o usuário para descobrir seu tenant
      final response = await dio.get(
        '/users/find-by-email/$email',
        options: Options(
          headers: {
            'device-id': deviceId,
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data;
        print('📋 Dados do usuário encontrados:');
        print('   - ID: ${userData['id']}');
        print('   - Email: ${userData['email']}');
        print('   - Role: ${userData['role']}');
        
        // Se for servus_admin, não precisa de tenant
        if (userData['role'] == 'servus_admin') {
          print('👑 Usuário é servus_admin - não precisa de tenant');
          return null;
        }
        
        // Busca os memberships do usuário para encontrar o tenant
        if (userData['memberships'] != null && userData['memberships'].isNotEmpty) {
          final membership = userData['memberships'][0];
          if (membership['tenant'] != null) {
            final tenantId = membership['tenant']['tenantId'];
            print('✅ Tenant encontrado: $tenantId');
            return tenantId;
          }
        }
        
        // Se não encontrou no membership, tenta buscar diretamente
        print('🔍 Tentando buscar tenant diretamente...');
        final tenantResponse = await dio.get(
          '/users/$email/tenant',
          options: Options(
            headers: {
              'device-id': deviceId,
            },
          ),
        );
        
        if (tenantResponse.statusCode == 200 && tenantResponse.data != null) {
          final tenantId = tenantResponse.data['tenantId'];
          print('✅ Tenant encontrado diretamente: $tenantId');
          return tenantId;
        }
      }
      
      print('⚠️ Não foi possível encontrar o tenant do usuário');
      return null;
      
    } on DioException catch (e) {
      print('❌ Erro ao buscar tenant do usuário:');
      print('   - Status: ${e.response?.statusCode}');
      print('   - Dados: ${e.response?.data}');
      return null;
    } catch (e) {
      print('❌ Erro inesperado ao buscar tenant: $e');
      return null;
    }
  }

  /// Login com email e senha (versão inteligente)
  Future<LoginResponse> loginComEmailESenha({
    required String email,
    required String senha,
    String? tenantId,
  }) async {
    try {
      final deviceId = await TokenService.getDeviceId();
      
      print('🔐 Iniciando login com email e senha...');
      print('   - Email: $email');
      print('   - Device ID: $deviceId');
      print('   - Tenant ID (opcional): $tenantId');
      
      // Primeira tentativa de login
      LoginResponse? loginResponse;
      String? discoveredTenantId = tenantId;
      
      try {
        // Tenta fazer login com o tenant fornecido (ou sem tenant)
        loginResponse = await _attemptLogin(email, senha, deviceId, discoveredTenantId);
        print('✅ Login realizado com sucesso na primeira tentativa');
        
      } catch (e) {
        print('⚠️ Primeira tentativa de login falhou: $e');
        
        // Se a falha foi por credenciais inválidas (401), não tenta descobrir tenant
        if (e.toString().contains('Email ou senha incorretos')) {
          print('❌ Credenciais inválidas - não tentando descobrir tenant');
          throw e; // Re-throw o erro de credenciais
        }
        
        // Se falhou por outro motivo e não temos tenant, tenta descobrir
        if (discoveredTenantId == null || discoveredTenantId.isEmpty) {
          print('🔍 Tentando descobrir tenant automaticamente...');
          discoveredTenantId = await _findUserTenant(email);
          
          if (discoveredTenantId != null) {
            print('✅ Tenant descoberto: $discoveredTenantId');
            
            // Segunda tentativa com o tenant descoberto
            try {
              loginResponse = await _attemptLogin(email, senha, deviceId, discoveredTenantId);
              print('✅ Login realizado com sucesso na segunda tentativa');
            } catch (e2) {
              print('❌ Segunda tentativa também falhou: $e2');
              throw e2; // Re-throw o erro da segunda tentativa
            }
          } else {
            print('❌ Não foi possível descobrir o tenant');
            throw Exception('Não foi possível determinar o tenant do usuário');
          }
        } else {
          // Se já tinha tenant e falhou, re-throw o erro
          rethrow;
        }
      }
      
      // Salva tokens
      await TokenService.saveTokens(
        accessToken: loginResponse!.accessToken,
        refreshToken: loginResponse.refreshToken,
        expiresIn: loginResponse.expiresIn,
      );
      print('✅ Tokens salvos com sucesso');

      // 🆕 Extrair claims de segurança do JWT
      await TokenService.extractSecurityClaims(loginResponse.accessToken);
      print('✅ Claims de segurança extraídos do JWT');

      // Extrai contexto do membership (se disponível)
      await _extractAndSaveContextFromLogin(loginResponse);

      return loginResponse;
      
    } catch (e) {
      print('❌ Erro final no login: $e');
      rethrow;
    }
  }

  /// Tenta fazer login com credenciais específicas
  Future<LoginResponse> _attemptLogin(
    String email, 
    String senha, 
    String deviceId, 
    String? tenantId
  ) async {
    print('🚀 Tentando login com tenant: ${tenantId ?? "nenhum"}');
    
    try {
      final response = await dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': senha,
        },
        options: Options(
          headers: {
            'device-id': deviceId,
            if (tenantId != null && tenantId.isNotEmpty) 'x-tenant-id': tenantId,
          },
        ),
      );

      print('📡 Resposta do login recebida:');
      print('   - Status: ${response.statusCode}');
      print('   - Headers: ${response.headers}');
      print('   - Dados brutos: ${response.data}');
      print('   - Tipo de dados: ${response.data.runtimeType}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Verifica se a resposta tem dados
        if (response.data == null) {
          print('❌ Resposta vazia do backend');
          throw Exception('Resposta vazia do backend');
        }

        // Tenta fazer o parse da resposta
        try {
          final loginResponse = LoginResponse.fromJson(response.data);
          
          print('🔍 LoginResponse processado com sucesso:');
          print('   - User: ${loginResponse.user.name} (${loginResponse.user.role})');
          print('   - Tenant: ${loginResponse.tenant?.name} (${loginResponse.tenant?.tenantId})');
          print('   - Branches: ${loginResponse.branches?.length ?? 0}');
          print('   - Memberships: ${loginResponse.memberships?.length ?? 0}');
          
          // Log detalhado de cada campo
          print('📋 Análise detalhada:');
          print('   - user: ${loginResponse.user.name} (${loginResponse.user.role})');
          print('   - tenant: ${loginResponse.tenant?.name} (${loginResponse.tenant?.tenantId})');
          print('   - branches: ${loginResponse.branches?.length ?? 0}');
          print('   - memberships: ${loginResponse.memberships?.length ?? 0}');
          
          if (loginResponse.memberships?.isNotEmpty == true) {
            print('   - Primeiro membership:');
            final firstMembership = loginResponse.memberships!.first;
            print('     * ID: ${firstMembership.id}');
            print('     * Role: ${firstMembership.role}');
            print('     * Branch: ${firstMembership.branch?.name} (${firstMembership.branch?.branchId})');
            print('     * Ministry: ${firstMembership.ministry?.name} (${firstMembership.ministry?.id})');
          }
          
          return loginResponse;
          
        } catch (parseError) {
          print('❌ Erro ao fazer parse da resposta: $parseError');
          print('   - Dados que falharam: ${response.data}');
          throw Exception('Erro ao processar resposta do login: $parseError');
        }
      } else {
        throw Exception('Erro no login: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Erro DioException no login:');
      print('   - Status: ${e.response?.statusCode}');
      print('   - Dados: ${e.response?.data}');
      print('   - Mensagem: ${e.message}');
      
      // Trata erros específicos do backend
      if (e.response?.statusCode == 401) {
        throw Exception('Email ou senha incorretos');
      } else if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        } else {
          throw Exception('Dados de login inválidos');
        }
      } else if (e.response?.statusCode == 404) {
        throw Exception('Usuário não encontrado');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Acesso negado');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Erro interno no servidor');
      } else {
        throw Exception('Erro de conexão: ${e.message}');
      }
    } catch (e) {
      print('❌ Erro inesperado no login: $e');
      throw Exception('Erro inesperado: $e');
    }
  }

  /// Login com Google (versão inteligente)
  Future<LoginResponse> loginComGoogle({
    String? tenantId,
  }) async {
    try {
      final deviceId = await TokenService.getDeviceId();
      
      print('🔐 Iniciando login com Google...');
      print('   - Device ID: $deviceId');
      print('   - Tenant ID (opcional): $tenantId');
      
      // Faz login com Google
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Login com Google cancelado');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null || accessToken == null) {
        throw Exception('Falha na autenticação com Google');
      }

      print('✅ Autenticação Google realizada');
      print('   - Email: ${googleUser.email}');
      print('   - Nome: ${googleUser.displayName}');

      // Primeira tentativa de login
      LoginResponse? loginResponse;
      String? discoveredTenantId = tenantId;
      
      try {
        // Tenta fazer login com o tenant fornecido (ou sem tenant)
        loginResponse = await _attemptGoogleLogin(idToken, accessToken, deviceId, discoveredTenantId);
        print('✅ Login realizado com sucesso na primeira tentativa');
        
      } catch (e) {
        print('⚠️ Primeira tentativa de login falhou: $e');
        
        // Se falhou e não temos tenant, tenta descobrir
        if (discoveredTenantId == null || discoveredTenantId.isEmpty) {
          print('🔍 Tentando descobrir tenant automaticamente...');
          discoveredTenantId = await _findUserTenant(googleUser.email);
          
          if (discoveredTenantId != null) {
            print('✅ Tenant descoberto: $discoveredTenantId');
            
            // Segunda tentativa com o tenant descoberto
            try {
              loginResponse = await _attemptGoogleLogin(idToken, accessToken, deviceId, discoveredTenantId);
              print('✅ Login realizado com sucesso na segunda tentativa');
            } catch (e2) {
              print('❌ Segunda tentativa também falhou: $e2');
              throw e2; // Re-throw o erro da segunda tentativa
            }
          } else {
            print('❌ Não foi possível descobrir o tenant');
            throw Exception('Não foi possível determinar o tenant do usuário');
          }
        } else {
          // Se já tinha tenant e falhou, re-throw o erro
          rethrow;
        }
      }
      
      // Salva tokens
      await TokenService.saveTokens(
        accessToken: loginResponse!.accessToken,
        refreshToken: loginResponse.refreshToken,
        expiresIn: loginResponse.expiresIn,
      );
      print('✅ Tokens salvos com sucesso');

      // 🆕 Extrair claims de segurança do JWT
      await TokenService.extractSecurityClaims(loginResponse.accessToken);
      print('✅ Claims de segurança extraídos do JWT');

      // Extrai contexto do membership (se disponível)
      await _extractAndSaveContextFromLogin(loginResponse);

      return loginResponse;
      
    } catch (e) {
      print('❌ Erro final no login com Google: $e');
      rethrow;
    }
  }

  /// Tenta fazer login com Google com credenciais específicas
  Future<LoginResponse> _attemptGoogleLogin(
    String idToken, 
    String accessToken, 
    String deviceId, 
    String? tenantId
  ) async {
    print('🚀 Tentando login Google com tenant: ${tenantId ?? "nenhum"}');
    
    final response = await dio.post(
      '/auth/google',
      data: {
        'idToken': idToken,
        'accessToken': accessToken,
      },
      options: Options(
        headers: {
          'device-id': deviceId,
          if (tenantId != null && tenantId.isNotEmpty) 'x-tenant-id': tenantId,
        },
      ),
    );

    print('📡 Resposta do login Google recebida:');
    print('   - Status: ${response.statusCode}');
    print('   - Headers: ${response.headers}');
    print('   - Dados brutos: ${response.data}');
    print('   - Tipo de dados: ${response.data.runtimeType}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Verifica se a resposta tem dados
      if (response.data == null) {
        print('❌ Resposta vazia do backend');
        throw Exception('Resposta vazia do backend');
      }

      // Tenta fazer o parse da resposta
      try {
        final loginResponse = LoginResponse.fromJson(response.data);
        
        print('🔍 LoginResponse Google processado com sucesso:');
        print('   - User: ${loginResponse.user.name} (${loginResponse.user.role})');
        print('   - Tenant: ${loginResponse.tenant?.name} (${loginResponse.tenant?.tenantId})');
        print('   - Branches: ${loginResponse.branches?.length ?? 0}');
        print('   - Memberships: ${loginResponse.memberships?.length ?? 0}');
        
        // Log detalhado de cada campo
        print('📋 Análise detalhada:');
        print('   - user: ${loginResponse.user.name} (${loginResponse.user.role})');
        print('   - tenant: ${loginResponse.tenant?.name} (${loginResponse.tenant?.tenantId})');
        print('   - branches: ${loginResponse.branches?.length ?? 0}');
        print('   - memberships: ${loginResponse.memberships?.length ?? 0}');
        
        if (loginResponse.memberships?.isNotEmpty == true) {
          print('   - Primeiro membership:');
          final firstMembership = loginResponse.memberships!.first;
          print('     * ID: ${firstMembership.id}');
          print('     * Role: ${firstMembership.role}');
          print('     * Branch: ${firstMembership.branch?.name} (${firstMembership.branch?.branchId})');
          print('     * Ministry: ${firstMembership.ministry?.name} (${firstMembership.ministry?.id})');
        }
        
        return loginResponse;
        
      } catch (parseError) {
        print('❌ Erro ao fazer parse da resposta Google: $parseError');
        print('   - Dados que falharam: ${response.data}');
        throw Exception('Erro ao processar resposta do login Google: $parseError');
      }
    } else {
      throw Exception('Erro no login Google: ${response.statusCode}');
    }
  }

  /// Extrai e salva contexto do login (sem chamadas adicionais)
  Future<void> _extractAndSaveContextFromLogin(LoginResponse loginResponse) async {
    try {
      print('🔍 Extraindo contexto do login...');
      
      String? tenantId;
      String? branchId;
      
      // Tenta obter do tenant direto
      if (loginResponse.tenant != null) {
        tenantId = loginResponse.tenant!.tenantId;
        print('   - Tenant ID do tenant: $tenantId');
      }
      
      // Tenta obter do membership (mais confiável)
      if (loginResponse.memberships?.isNotEmpty == true) {
        final membership = loginResponse.memberships!.first;
        print('   - Membership encontrado: ${membership.id}');
        
        // Branch vem do membership
        if (membership.branch != null) {
          branchId = membership.branch!.branchId;
          print('   - Branch ID do membership: $branchId');
        }
        
        // Se não tiver tenantId do tenant, precisa ser obtido de outra forma
        // O membership não tem tenant diretamente
        if (tenantId == null) {
          print('   - ⚠️ Tenant ID não encontrado - membership não tem campo tenant');
        }
      }
      
      // Tenta obter branch das branches (fallback)
      if (branchId == null && loginResponse.branches?.isNotEmpty == true) {
        branchId = loginResponse.branches!.first.branchId;
        print('   - Branch ID das branches: $branchId');
      }
      
      // Salva contexto se encontrou
      if (tenantId != null) {
        print('💾 Salvando contexto extraído:');
        print('   - Tenant ID: $tenantId');
        print('   - Branch ID: $branchId');
        
        await TokenService.saveContext(
          tenantId: tenantId,
          branchId: branchId,
        );
        print('✅ Contexto salvo com sucesso');
      } else {
        print('⚠️ Nenhum contexto encontrado no login');
        print('   - Verifique se o backend está retornando tenant no login');
        print('   - Verifique se o usuário tem vínculos ativos');
        print('   - O membership não contém tenant diretamente');
      }

      // 🆕 SALVAR USUÁRIO NO LOCAL STORAGE (para compatibilidade)
      try {
        print('💾 Salvando usuário no LocalStorage para compatibilidade...');
        
        // 🆕 CORREÇÃO: Para ServusAdmin, sempre usa user.role
        String rolePrincipal = loginResponse.user.role;
        if (loginResponse.user.role == 'servus_admin') {
          // ServusAdmin sempre usa seu role global, não o do membership
          rolePrincipal = loginResponse.user.role;
          print('   - 🎯 ServusAdmin detectado - usando role global: $rolePrincipal');
        } else if (loginResponse.memberships?.isNotEmpty == true) {
          final membership = loginResponse.memberships!.first;
          // Para outros usuários, membership role tem prioridade sobre user role
          rolePrincipal = membership.role;
          print('   - Role do membership usado: $rolePrincipal');
        } else {
          print('   - Role do usuário usado: $rolePrincipal');
        }

        // Cria objeto UsuarioLogado
        final usuario = UsuarioLogado(
          nome: loginResponse.user.name,
          email: loginResponse.user.email,
          role: _mapearRoleStringParaEnum(rolePrincipal),
          tenantId: tenantId,
          branchId: branchId,
          tenantName: loginResponse.tenant?.name,
          branchName: loginResponse.branches?.isNotEmpty == true 
              ? loginResponse.branches!.first.name 
              : null,
          picture: loginResponse.user.picture,
          ministerios: [], // TODO: Implementar quando disponível
        );

        // Salva no LocalStorage
        await LocalStorageService.salvarUsuario(usuario);
        print('✅ Usuário salvo no LocalStorage com sucesso');
        print('   - Nome: ${usuario.nome}');
        print('   - Email: ${usuario.email}');
        print('   - Role: ${usuario.role.name}');
        print('   - Tenant: ${usuario.tenantName}');
        print('   - Branch: ${usuario.branchName}');
        
      } catch (e) {
        print('❌ Erro ao salvar usuário no LocalStorage: $e');
        // Não falha o login por isso, apenas loga o erro
      }
      
    } catch (e) {
      print('❌ Erro ao extrair contexto: $e');
    }
  }

  /// 🆕 Mapeia role string para enum UserRole
  UserRole _mapearRoleStringParaEnum(String role) {
    switch (role.toLowerCase()) {
      case 'servus_admin':
        return UserRole.servus_admin;
      case 'tenant_admin':
        return UserRole.tenant_admin;
      case 'branch_admin':
        return UserRole.branch_admin;
      case 'leader':
        return UserRole.leader;
      case 'volunteer':
        return UserRole.volunteer;
      default:
        print('⚠️ Role desconhecido: $role, usando volunteer como padrão');
        return UserRole.volunteer;
    }
  }

  /// Renova token
  Future<bool> renovarToken(BuildContext context) async {
    final auth = Provider.of<AuthState>(context, listen: false);
    
    try {
      final refreshToken = await TokenService.getRefreshToken();
      if (refreshToken == null) return false;

      final deviceId = await TokenService.getDeviceId();
      final context = await TokenService.getContext();

      final response = await dio.post(
        '/auth/refresh',
        data: {
          'refresh_token': refreshToken,
        },
        options: Options(
          headers: {
            'device-id': deviceId,
            if (context['tenantId'] != null) 'x-tenant-id': context['tenantId'],
            if (context['branchId'] != null) 'x-branch-id': context['branchId'],
            if (context['ministryId'] != null) 'x-ministry-id': context['ministryId'],
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        
        await TokenService.saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          expiresIn: data['expires_in'] ?? 3600,
        );

        return true;
      } else {
        return false;
      }
    } on DioException catch (e) {
      print('❌ Erro ao renovar token: ${e.message}');
      return false;
    } catch (e) {
      print('❌ Erro inesperado: $e');
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      final deviceId = await TokenService.getDeviceId();
      final context = await TokenService.getContext();

      await dio.post(
        '/auth/logout',
        options: Options(
          headers: {
            'device-id': deviceId,
            if (context['tenantId'] != null) 'x-tenant-id': context['tenantId'],
            if (context['branchId'] != null) 'x-branch-id': context['branchId'],
            if (context['ministryId'] != null) 'x-ministry-id': context['ministryId'],
          },
        ),
      );
    } on DioException catch (e) {
      print('Erro ao fazer logout no backend: $e');
      // Mesmo com erro, limpa os dados locais
    } finally {
      await TokenService.clearAll();
    }
  }

  /// Obtém contexto do usuário
  Future<LoginResponse?> getUserContext() async {
    try {
      final deviceId = await TokenService.getDeviceId();
      final context = await TokenService.getContext();

      final response = await dio.get(
        '/auth/me/context',
        options: Options(
          headers: {
            'device-id': deviceId,
            if (context['tenantId'] != null) 'x-tenant-id': context['tenantId'],
            if (context['branchId'] != null) 'x-branch-id': context['branchId'],
            if (context['ministryId'] != null) 'x-ministry-id': context['ministryId'],
          },
        ),
      );

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(response.data);
      }
      
      return null;
    } on DioException catch (e) {
      print('❌ Erro ao obter contexto: ${e.message}');
      return null;
    }
  }

  /// Obtém contexto do usuário via membership
  Future<Map<String, dynamic>?> getUserMembershipContext() async {
    try {
      print('🔍 Consultando membership do usuário...');
      
      final deviceId = await TokenService.getDeviceId();
      
      // Chama endpoint para obter membership do usuário
      final response = await dio.get(
        '/auth/me/membership',
        options: Options(
          headers: {
            'device-id': deviceId,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print('📄 Dados do membership recebidos: $data');
        
        // Extrai informações do membership
        final membership = data['membership'];
        if (membership != null) {
          final tenantId = membership['tenant']?['tenantId'];
          final branchId = membership['branch']?['branchId'];
          final role = membership['role'];
          
          print('🔍 Contexto extraído do membership:');
          print('   - Tenant ID: $tenantId');
          print('   - Branch ID: $branchId');
          print('   - Role: $role');
          
          return {
            'tenantId': tenantId,
            'branchId': branchId,
            'role': role,
            'membershipData': membership,
          };
        }
      }
      
      return null;
    } on DioException catch (e) {
      print('❌ Erro ao obter membership: ${e.message}');
      print('   - Status: ${e.response?.statusCode}');
      print('   - Dados: ${e.response?.data}');
      return null;
    } catch (e) {
      print('❌ Erro inesperado ao obter membership: $e');
      return null;
    }
  }

  /// Converte LoginResponse para UsuarioLogado
  UsuarioLogado convertToUsuarioLogado(LoginResponse loginResponse) {
    print('DEBUG: Role recebido do backend: "${loginResponse.user.role}"');
    
    // Tenta usar o role do membership primeiro, depois do user
    String? roleToUse;
    if (loginResponse.memberships != null && loginResponse.memberships!.isNotEmpty) {
      roleToUse = loginResponse.memberships!.first.role;
      print('DEBUG: Usando role do membership: "$roleToUse"');
    } else if (loginResponse.user.role.isNotEmpty) {
      roleToUse = loginResponse.user.role;
      print('DEBUG: Usando role do user: "$roleToUse"');
    }
    
    final userRole = mapRoleToEnum(roleToUse);
    print('DEBUG: Role convertido para enum: $userRole');
    
    return UsuarioLogado(
      nome: loginResponse.user.name,
      email: loginResponse.user.email,
      tenantName: loginResponse.tenant?.name,
      branchName: loginResponse.branches?.isNotEmpty == true 
          ? loginResponse.branches!.first.name 
          : null,
      tenantId: loginResponse.tenant?.tenantId,
      branchId: loginResponse.branches?.isNotEmpty == true 
          ? loginResponse.branches!.first.branchId 
          : null,
      picture: loginResponse.user.picture,
      role: userRole,
      ministerios: [], // TODO: Implementar quando disponível
    );
  }

  /// Trata erros do Dio para mensagens mais amigáveis
  String _handleDioError(DioException e) {
    if (e.response != null) {
      final status = e.response?.statusCode ?? 0;
      switch (status) {
        case 400:
          return 'Requisição inválida';
        case 401:
          return 'Credenciais inválidas';
        case 403:
          return 'Acesso negado';
        case 500:
          return 'Erro interno no servidor';
        default:
          return 'Erro desconhecido (${e.message})';
      }
    } else {
      return 'Erro de conexão: ${e.message}';
    }
  }

  /// Testa se o backend está funcionando
  Future<void> testBackendConnection() async {
    try {
      print('🧪 Testando conexão com o backend...');
      
      final deviceId = await TokenService.getDeviceId();
      
      // Testa endpoint de health ou simples
      final response = await dio.get(
        '/health',
        options: Options(
          headers: {
            'device-id': deviceId,
          },
        ),
      );

      print('✅ Backend está funcionando:');
      print('   - Status: ${response.statusCode}');
      print('   - Dados: ${response.data}');
      
    } on DioException catch (e) {
      print('❌ Backend não está funcionando:');
      print('   - Tipo: ${e.type}');
      print('   - Mensagem: ${e.message}');
      print('   - Status: ${e.response?.statusCode}');
      print('   - Dados: ${e.response?.data}');
    } catch (e) {
      print('❌ Erro inesperado ao testar backend: $e');
    }
  }

  /// Testa endpoint de login sem credenciais (para ver estrutura)
  Future<void> testLoginEndpoint() async {
    try {
      print('🧪 Testando endpoint de login...');
      
      final deviceId = await TokenService.getDeviceId();
      
      // Testa com credenciais vazias para ver a estrutura de erro
      final response = await dio.post(
        '/auth/login',
        data: {
          'email': 'test@test.com',
          'password': 'wrongpassword',
        },
        options: Options(
          headers: {
            'device-id': deviceId,
          },
        ),
      );

      print('✅ Endpoint de login está funcionando:');
      print('   - Status: ${response.statusCode}');
      print('   - Dados: ${response.data}');
      
    } on DioException catch (e) {
      print('📋 Endpoint de login respondeu (esperado para credenciais inválidas):');
      print('   - Status: ${e.response?.statusCode}');
      print('   - Dados: ${e.response?.data}');
      print('   - Estrutura da resposta: ${e.response?.data.runtimeType}');
    } catch (e) {
      print('❌ Erro inesperado ao testar login: $e');
    }
  }
}


