import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/auth/services/auth_service.dart';
import 'package:servus_app/core/utils/role_util.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:servus_app/core/enums/user_role.dart';
import 'package:servus_app/core/models/usuario_logado.dart';
import 'package:servus_app/state/auth_state.dart';

class LoginController extends ChangeNotifier {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool rememberMe = false;
  bool isPasswordVisible = false;

  final AuthService _authService = AuthService();

  Future<void> fazerLogin(
      String email, String senha, BuildContext context) async {
    final auth = Provider.of<AuthState>(context, listen: false);

    if (email.isEmpty || senha.isEmpty) {
      showServusSnack(context, message: 'Informe e-mail e senha', type: ServusSnackType.error);
      return;
    }

    try {
      final response =
          await _authService.loginComEmailESenha(email: email, senha: senha);
      final data = response.data;

      // Salva tokens
      final storage = FlutterSecureStorage();
      await storage.write(key: 'access_token', value: data['access_token']);
      await storage.write(key: 'refresh_token', value: data['refresh_token']);

      // Converte a role retornada para enum
      final userRole = mapRoleToEnum(data['user']['role']);

      // Cria objeto de usuário logado (ajuste conforme dados reais)
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

      // Atualiza estado global
      auth.login(usuario);

      _irParaDashboard(context, userRole);
    } catch (e) {
      showServusSnack(context, message: e.toString().replaceAll('Exception: ', ''), type: ServusSnackType.error);
    }
  }

  Future<void> fazerLoginComGoogle(BuildContext context) async {
    final auth = Provider.of<AuthState>(context, listen: false);

    try {
      final response = await _authService.loginComGoogle();
      final data = response.data;

      // Salva tokens
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access_token']);
      await prefs.setString('refresh_token', data['refresh_token']);

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
        ministerios: [], // Adapte se necessário
      );

      auth.login(usuario);

      _irParaDashboard(context, userRole);
    } catch (e) {
      showServusSnack(context, message: e.toString().replaceAll('Exception: ', ''), type: ServusSnackType.error);
    }
  }

  void _irParaDashboard(BuildContext context, UserRole papel) {
    switch (papel) {
      case UserRole.superadmin:
      case UserRole.admin:
      case UserRole.leader:
        context.go('/leader/dashboard');
        break;
      case UserRole.volunteer:
        context.go('/volunteer/dashboard');
        break;
    }
  }

  void toggleRememberMe(bool? value) {
    rememberMe = value ?? false;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
