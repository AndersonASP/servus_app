import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/models/usuario_logado.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:servus_app/core/utils/role_util.dart';
import 'package:servus_app/state/auth_state.dart';

class AuthService {
  final Dio dio;
  final GoogleSignIn googleSignIn;
  final _storage = const FlutterSecureStorage();

  AuthService({GoogleSignIn? googleSignIn})
      : dio = DioClient.instance,
        googleSignIn = googleSignIn ?? GoogleSignIn();

  /// Login com email e senha
  Future<Response> loginComEmailESenha({
    required String email,
    required String senha,
  }) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': senha,
        },
      );
      return response;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<bool> renovarToken(String refreshToken, BuildContext context) async {
    final auth = Provider.of<AuthState>(context, listen: false);
    try {
      final response = await dio.post(
        '/auth/refresh',
        data: {
          'refreshToken': refreshToken,
        },
        options: Options(headers: {
          'Content-Type': 'application/json',
          'device-id': 'flutter-app',
        }),
      );

      if (response.statusCode == 201) {
        final data = response.data;

        await _storage.write(key: 'access_token', value: data['access_token']);
        await _storage.write(
            key: 'refresh_token', value: data['refresh_token']);

        final userRole = mapRoleToEnum(data['user']['role']);
        final usuario = UsuarioLogado(
          nome: data['user']['name'],
          email: data['user']['email'],
          tenantName: data['tenant'] != null ? data['tenant']['name'] : null,
          branchName: data['branch'] != null ? data['branch']['name'] : null,
          tenantId: data['tenant'] != null ? data['tenant']['tenantId'] : null,
          branchId: data['branch'] != null ? data['branch']['branchId'] : null,
          picture: data['user']['picture'],
          role: userRole,
          ministerios: [], // Atualize conforme necessário
        );

        auth.login(usuario);

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

  /// Login com Google
  Future<Response> loginComGoogle() async {
    try {
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw Exception('Login cancelado');

      final googleAuth = await googleUser.authentication;

      final response = await dio.post(
        '/auth/google',
        data: {'access_token': googleAuth.accessToken},
      );

      return response;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (_) {
      throw Exception('Erro ao autenticar com Google');
    }
  }

  Future<void> logout() async {
    try {
      final dio = DioClient.instance;
      await dio.post(
        '/auth/logout',
        options: Options(
          headers: {
            'device-id': 'flutter-app',
          },
        ),
      );
    } on DioException catch (e) {
      print('Erro ao fazer logout no backend: $e');
      throw Exception(_handleDioError(e));
    }
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
}
