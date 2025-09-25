import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:servus_app/core/models/login_response.dart';
import 'package:servus_app/core/models/usuario_logado.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:servus_app/core/utils/role_util.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/services/local_storage_service.dart';
import 'package:servus_app/core/enums/user_role.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';

class AuthService {
  final Dio dio;
  final GoogleSignIn googleSignIn;

  AuthService({GoogleSignIn? googleSignIn})
      : dio = DioClient.instance,
        googleSignIn = googleSignIn ?? GoogleSignIn(
          scopes: ['email', 'profile'],
          clientId: '44996683041-uk5gv79jb8bes7877slu97pbl6bm5ste.apps.googleusercontent.com',
        );

  /// Busca o tenant do usuário pelo email
  Future<String?> _findUserTenant(String email) async {
    try {
      
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
        
        // Se for servus_admin, não precisa de tenant
        if (userData['role'] == 'servus_admin') {
          return null;
        }
        
        // Busca os memberships do usuário para encontrar o tenant
        if (userData['memberships'] != null && userData['memberships'].isNotEmpty) {
          for (int i = 0; i < userData['memberships'].length; i++) {
            final membership = userData['memberships'][i];
            
            if (membership['tenant'] != null) {
              final tenantId = membership['tenant']['id']; // ObjectId como string
              
              // Workaround temporário para [object Object]
              if (tenantId == '[object Object]') {
                return '68c87299b8c04c89dd8f1089';
              }
              
              return tenantId;
            }
          }
        } else {
        }
        
        // Se não encontrou no membership, tenta buscar diretamente
        final tenantResponse = await dio.get(
          '/users/$email/tenant',
          options: Options(
            headers: {
              'device-id': deviceId,
            },
          ),
        );
        
        
        if (tenantResponse.statusCode == 200 && tenantResponse.data != null) {
          final tenantId = tenantResponse.data['id']; // ObjectId como string
          
          // Workaround temporário para [object Object]
          if (tenantId == '[object Object]') {
            return '68c87299b8c04c89dd8f1089';
          }
          
          return tenantId;
        }
      } else {
      }
      
      return null;
      
      } on DioException catch (e) {
        
        // Se o usuário não existe na base de dados
        if (e.response?.statusCode == 404) {
          final message = e.response?.data?['message'] ?? 'Usuário não encontrado';
          throw Exception('Usuário não cadastrado: $message');
        }
        
        return null;
      } catch (e) {
        return null;
      }
  }

  /// Login com email e senha (versão inteligente)
  Future<LoginResponse> loginComEmailESenha({
    BuildContext? context,
    required String email,
    required String senha,
    String? tenantId,
  }) async {
    try {
      final deviceId = await TokenService.getDeviceId();
      
      
      // Primeira tentativa de login
      LoginResponse? loginResponse;
      String? discoveredTenantId = tenantId;
      
      try {
        // Tenta fazer login com o tenant fornecido (ou sem tenant)
        loginResponse = await _attemptLogin(email, senha, deviceId, discoveredTenantId);
        
      } catch (e) {
        
        // Se a falha foi por credenciais inválidas (401), não tenta descobrir tenant
        // EXCETO se for erro de usuário pendente de aprovação
        if (e.toString().contains('Email ou senha incorretos') && 
            !e.toString().contains('aguardando aprovação') &&
            !e.toString().contains('aprovação do líder')) {
          rethrow; // Re-throw o erro de credenciais
        }
        
        // Se a falha foi por erro de conexão, não tenta descobrir tenant
        if (e.toString().contains('Erro de conexão')) {
          rethrow; // Re-throw o erro de conexão
        }
        
        // Se falhou por outro motivo e não temos tenant, tenta descobrir
        if (discoveredTenantId == null || discoveredTenantId.isEmpty) {
          discoveredTenantId = await _findUserTenant(email);
          
          if (discoveredTenantId != null) {
            
            // Segunda tentativa com o tenant descoberto
            try {
              loginResponse = await _attemptLogin(email, senha, deviceId, discoveredTenantId);
            } catch (e2) {
              rethrow; // Re-throw o erro da segunda tentativa
            }
          } else {
            throw Exception('Não foi possível determinar o tenant do usuário');
          }
        } else {
          // Se já tinha tenant e falhou, re-throw o erro
          rethrow;
        }
      }
      
      // Salva tokens
      await TokenService.saveTokens(
        accessToken: loginResponse.accessToken,
        refreshToken: loginResponse.refreshToken,
        expiresIn: loginResponse.expiresIn,
      );

      // 🆕 Extrair claims de segurança do JWT
      await TokenService.extractSecurityClaims(loginResponse.accessToken);

      // Extrai contexto do membership (se disponível)
      await _extractAndSaveContextFromLogin(loginResponse);

      if (context != null) {
        showSuccess(context, 'Login realizado com sucesso!');
      }
      return loginResponse;
      
    } catch (e) {
      if (context != null) {
        showError(context, 'Erro no login. Tente novamente.');
      }
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


      if (response.statusCode == 200 || response.statusCode == 201) {
        // Verifica se a resposta tem dados
        if (response.data == null) {
          throw Exception('Resposta vazia do backend');
        }

        // Tenta fazer o parse da resposta
        try {
          final loginResponse = LoginResponse.fromJson(response.data);
          
          
          // Log detalhado de cada campo
          
          if (loginResponse.memberships?.isNotEmpty == true) {
          }
          
          return loginResponse;
          
        } catch (parseError) {
          throw Exception('Erro ao processar resposta do login: $parseError');
        }
      } else {
        throw Exception('Erro no login: ${response.statusCode}');
      }
    } on DioException catch (e) {
      
      // Trata erros de conexão especificamente
      if (e.type == DioExceptionType.connectionError) {
        if (e.message?.contains('Failed host lookup') == true) {
          throw Exception('Erro de conexão: Servidor não encontrado. Verifique sua internet e tente novamente.');
        } else if (e.message?.contains('Connection refused') == true) {
          throw Exception('Erro de conexão: Servidor recusou a conexão. Tente novamente em alguns instantes.');
        } else if (e.message?.contains('timeout') == true) {
          throw Exception('Erro de conexão: Tempo limite esgotado. Verifique sua internet e tente novamente.');
        } else {
          throw Exception('Erro de conexão: ${e.message}. Verifique sua internet e tente novamente.');
        }
      }
      
      // Trata erros específicos do backend
      if (e.response?.statusCode == 401) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        } else {
          throw Exception('Email ou senha incorretos');
        }
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
      throw Exception('Erro inesperado: $e');
    }
  }

  /// Login com Google (versão simplificada)
  Future<LoginResponse> loginComGoogle({
    BuildContext? context,
    String? tenantId,
  }) async {
    try {
      final deviceId = await TokenService.getDeviceId();
      
      
      // Verifica se o Google Sign-In está disponível
      final isGoogleConnected = await testGoogleSignInConnection();
      if (!isGoogleConnected) {
        throw Exception('Google Sign-In não está disponível. Verifique sua conexão com a internet.');
      }
      
      // Faz login com Google
      final googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Login com Google cancelado pelo usuário');
      }
      

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;


      if (idToken == null || accessToken == null) {
        throw Exception('Falha na autenticação com Google - tokens não disponíveis');
      }


      // Primeira tentativa de login
      LoginResponse? loginResponse;
      String? discoveredTenantId = tenantId;
      
      try {
        // Tenta fazer login com o tenant fornecido (ou sem tenant)
        loginResponse = await _attemptGoogleLogin(idToken, accessToken, deviceId, discoveredTenantId);
        
      } catch (e) {
        
        // Se falhou e não temos tenant, tenta descobrir
        if (discoveredTenantId == null || discoveredTenantId.isEmpty) {
          try {
            discoveredTenantId = await _findUserTenant(googleUser.email);
            
            if (discoveredTenantId != null) {
              
              // Segunda tentativa com o tenant descoberto
              try {
                loginResponse = await _attemptGoogleLogin(idToken, accessToken, deviceId, discoveredTenantId);
              } catch (e2) {
                rethrow; // Re-throw o erro da segunda tentativa
              }
            } else {
              throw Exception('Não foi possível determinar o tenant do usuário');
            }
          } catch (tenantError) {
            // Se o erro é de usuário não cadastrado, re-throw
            if (tenantError.toString().contains('Usuário não cadastrado')) {
              rethrow;
            }
            // Outros erros de tenant discovery
            throw Exception('Não foi possível determinar o tenant do usuário');
          }
        } else {
          // Se já tinha tenant e falhou, re-throw o erro
          rethrow;
        }
      }
      
      // Salva tokens
      await TokenService.saveTokens(
        accessToken: loginResponse.accessToken,
        refreshToken: loginResponse.refreshToken,
        expiresIn: loginResponse.expiresIn,
      );

      // 🆕 Extrair claims de segurança do JWT
      await TokenService.extractSecurityClaims(loginResponse.accessToken);

      // Extrai contexto do membership (se disponível)
      await _extractAndSaveContextFromLogin(loginResponse);

      if (context != null) {
        showSuccess(context, 'Login com Google realizado com sucesso!');
      }
      return loginResponse;
      
    } catch (e) {
      
      // Trata erros específicos do Google Sign-In
      if (e.toString().contains('sign_in_canceled')) {
        if (context != null) {
          showError(context, 'Login com Google cancelado. Tente novamente.');
        }
        throw Exception('Login com Google cancelado pelo usuário');
      } else if (e.toString().contains('network_error')) {
        if (context != null) {
          showError(context, 'Erro de conexão. Verifique sua internet.');
        }
        throw Exception('Erro de conexão com Google');
      } else if (e.toString().contains('sign_in_failed')) {
        if (context != null) {
          showError(context, 'Falha na autenticação com Google.');
        }
        throw Exception('Falha na autenticação com Google');
      } else if (e.toString().contains('Usuário não cadastrado')) {
        if (context != null) {
          showError(context, 'Seu email não está cadastrado no sistema. Entre em contato com o administrador para solicitar acesso.');
        }
        throw Exception('Usuário não cadastrado');
      } else {
        if (context != null) {
          showError(context, 'Erro no login com Google. Tente novamente.');
        }
        rethrow;
      }
    }
  }

  /// Tenta fazer login com Google com credenciais específicas
  Future<LoginResponse> _attemptGoogleLogin(
    String idToken, 
    String accessToken, 
    String deviceId, 
    String? tenantId
  ) async {
    
    try {
      final response = await dio.post(
        '/auth/google',
        data: {
          'idToken': idToken,
        },
        options: Options(
          headers: {
            'device-id': deviceId,
            if (tenantId != null && tenantId.isNotEmpty) 'x-tenant-id': tenantId,
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Verifica se a resposta tem dados
        if (response.data == null) {
          throw Exception('Resposta vazia do backend');
        }

        // Tenta fazer o parse da resposta
        try {
          final loginResponse = LoginResponse.fromJson(response.data);
          
          return loginResponse;
          
        } catch (parseError) {
          throw Exception('Erro ao processar resposta do login Google: $parseError');
        }
      } else {
        throw Exception('Erro no login Google: ${response.statusCode}');
      }
    } on DioException catch (e) {
      // Trata erros de conexão especificamente
      if (e.type == DioExceptionType.connectionError) {
        if (e.message?.contains('Failed host lookup') == true) {
          throw Exception('Erro de conexão: Servidor não encontrado. Verifique sua internet e tente novamente.');
        } else if (e.message?.contains('Connection refused') == true) {
          throw Exception('Erro de conexão: Servidor recusou a conexão. Tente novamente em alguns instantes.');
        } else if (e.message?.contains('timeout') == true) {
          throw Exception('Erro de conexão: Tempo limite esgotado. Verifique sua internet e tente novamente.');
        } else {
          throw Exception('Erro de conexão: ${e.message}. Verifique sua internet e tente novamente.');
        }
      }
      
      // Trata erros específicos do backend
      if (e.response?.statusCode == 401) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        } else {
          throw Exception('Falha na autenticação com Google');
        }
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
      throw Exception('Erro inesperado: $e');
    }
  }

  /// Busca contexto do usuário via endpoint /auth/me/context
  Future<void> _fetchUserContext() async {
    try {
      
      final token = await TokenService.getAccessToken();
      if (token == null) {
        return;
      }

      final response = await dio.get('/auth/me/context');
      
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        // Processar contexto e salvar
        if (data['tenants'] != null && data['tenants'].isNotEmpty) {
          final tenant = data['tenants'][0]; // Usar primeiro tenant
          final tenantId = tenant['tenantId'];
          final branchId = tenant['branches']?.isNotEmpty == true 
              ? tenant['branches'][0]['branchId'] 
              : null;
          
          
          await TokenService.saveContext(
            tenantId: tenantId,
            branchId: branchId,
          );
        } else {
        }
      } else {
      }
    } catch (e) {
      if (e is DioException) {
      }
    }
  }

  /// Extrai e salva contexto do login (sem chamadas adicionais)
  Future<void> _extractAndSaveContextFromLogin(LoginResponse loginResponse) async {
    try {
      
      String? tenantId;
      String? branchId;
      
      // Tenta obter do tenant direto
      if (loginResponse.tenant != null) {
        tenantId = loginResponse.tenant!.tenantId;
      }
      
      // Tenta obter do membership (mais confiável)
      if (loginResponse.memberships?.isNotEmpty == true) {
        final membership = loginResponse.memberships!.first;
        
        // Branch vem do membership
        if (membership.branch != null) {
          branchId = membership.branch!.branchId;
        }
        
        // Se não tiver tenantId do tenant, precisa ser obtido de outra forma
        // O membership não tem tenant diretamente
        if (tenantId == null) {
        }
      }
      
      // Tenta obter branch das branches (fallback)
      if (branchId == null && loginResponse.branches?.isNotEmpty == true) {
        branchId = loginResponse.branches!.first.branchId;
      }
      
      // Salva contexto se encontrou
      if (tenantId != null) {
        
        await TokenService.saveContext(
          tenantId: tenantId,
          branchId: branchId,
        );
      } else {
        
        // Tentar obter contexto via endpoint específico
        try {
          await _fetchUserContext();
        } catch (e) {
        }
      }

      // 🆕 SALVAR USUÁRIO NO LOCAL STORAGE (para compatibilidade)
      try {
        
        // 🆕 CORREÇÃO: Para ServusAdmin, sempre usa user.role
        String rolePrincipal = loginResponse.user.role;
        if (loginResponse.user.role == 'servus_admin') {
          // ServusAdmin sempre usa seu role global, não o do membership
          rolePrincipal = loginResponse.user.role;
        } else if (loginResponse.memberships?.isNotEmpty == true) {
          // Filtrar apenas memberships ATIVOS
          final activeMemberships = loginResponse.memberships!
              .where((m) => m.isActive == true)
              .toList();
          
          if (activeMemberships.isNotEmpty) {
            final membership = activeMemberships.first;
            // Para outros usuários, membership role tem prioridade sobre user role
            rolePrincipal = membership.role;
            print('🔍 [AuthService] Usando membership ATIVO: ${membership.role}');
          } else {
            // Sem memberships ativos, usar role do usuário
            rolePrincipal = loginResponse.user.role;
            print('🔍 [AuthService] Sem memberships ativos, usando user role: ${loginResponse.user.role}');
          }
        } else {
          // Sem memberships, usar role do usuário
          rolePrincipal = loginResponse.user.role;
          print('🔍 [AuthService] Sem memberships, usando user role: ${loginResponse.user.role}');
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
        
      } catch (e) {
        // Não falha o login por isso, apenas loga o erro
      }
      
    } catch (e) {
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
        return UserRole.volunteer;
    }
  }

  /// Renova token
  Future<bool> renovarToken(BuildContext context) async {
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
    } on DioException {
      return false;
    } catch (e) {
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
    } on DioException {
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
    } on DioException {
      return null;
    }
  }

  /// Obtém contexto do usuário via membership
  Future<Map<String, dynamic>?> getUserMembershipContext() async {
    try {
      
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
        
        // Extrai informações do membership
        final membership = data['membership'];
        if (membership != null) {
          final tenantId = membership['tenant']?['tenantId'];
          final branchId = membership['branch']?['branchId'];
          final role = membership['role'];
          
          
          return {
            'tenantId': tenantId,
            'branchId': branchId,
            'role': role,
            'membershipData': membership,
          };
        }
      }
      
      return null;
    } on DioException {
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Converte LoginResponse para UsuarioLogado
  UsuarioLogado convertToUsuarioLogado(LoginResponse loginResponse) {
    
    // Tenta usar o role do membership primeiro, depois do user
    String? roleToUse;
    if (loginResponse.memberships != null && loginResponse.memberships!.isNotEmpty) {
      roleToUse = loginResponse.memberships!.first.role;
    } else if (loginResponse.user.role.isNotEmpty) {
      roleToUse = loginResponse.user.role;
    }
    
    final userRole = mapRoleToEnum(roleToUse);
    
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


  /// Testa a conectividade do Google Sign-In
  Future<bool> testGoogleSignInConnection() async {
    try {
      
      // Tenta fazer login silencioso para testar conectividade
      final googleUser = await googleSignIn.signInSilently();
      
      if (googleUser != null) {
        // Faz logout para não interferir no login real
        await googleSignIn.signOut();
        return true;
      } else {
        return true; // Não é erro, apenas não há usuário logado
      }
    } catch (e) {
      return false;
    }
  }

  /// Testa se o backend está funcionando
  Future<void> testBackendConnection() async {
    try {
      final deviceId = await TokenService.getDeviceId();
      
      // Testa endpoint de health ou simples
      await dio.get(
        '/health',
        options: Options(
          headers: {
            'device-id': deviceId,
          },
        ),
      );
    } catch (e) {
      // Ignora erros de teste
    }
  }

  /// Testa endpoint de login sem credenciais (para ver estrutura)
  Future<void> testLoginEndpoint() async {
    try {
      final deviceId = await TokenService.getDeviceId();
      
      // Testa com credenciais vazias para ver a estrutura de erro
      await dio.post(
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
    } catch (e) {
      // Ignora erros de teste
    }
  }
}


