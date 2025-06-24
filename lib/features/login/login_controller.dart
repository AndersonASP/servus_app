import 'package:flutter/material.dart';

class LoginController extends ChangeNotifier {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool rememberMe = false;
  bool isPasswordVisible = false;

  void toggleRememberMe(bool? value) {
    rememberMe = value ?? false;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    notifyListeners();
  }

  void disposeFields() {
    emailController.dispose();
    passwordController.dispose();
  }

  void login() {
    // Implement login logic here
    // For example, you can validate the input and call an authentication service
    final email = emailController.text;
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      // Show error message
      return;
    }

    // Proceed with login
    print('Logging in with email: $email and password: $password');
  }
}