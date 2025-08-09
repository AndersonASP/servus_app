import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../controllers/login_controller.dart';
import 'package:servus_app/core/theme/context_extension.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController emailController;
  late TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    final controller = context.read<LoginController>();
    emailController = controller.emailController;
    passwordController = controller.passwordController;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final controller = context.read<LoginController>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Fundo azul
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.33 + statusBarHeight,
            child: Container(
              color: context.theme.primaryColor,
            ),
          ),

          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        children: [
                          const SizedBox(height: 30),
                          SvgPicture.asset(
                            'assets/images/logo.svg',
                            width: 50,
                            semanticsLabel: 'Servus Logo',
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'SERVUS',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: context.colors.onPrimary,
                                ),
                          ),
                          const SizedBox(height: 33),
                          Text(
                            'Acesse sua conta',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: context.colors.onPrimary,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),

                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: context.theme.scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 24),

                                  // Botão Google
                                  ElevatedButton.icon(
                                    label: Text(
                                      'Continue com Google',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: context.colors.onSurface,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    onPressed: () async {
                                       await controller.fazerLoginComGoogle(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: context.colors.surface,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      minimumSize: const Size(double.infinity, 48),
                                    ),
                                    icon: SvgPicture.asset(
                                      'assets/images/google_logo.svg',
                                      width: 24,
                                      height: 24,
                                      semanticsLabel: 'Google Icon',
                                    ),
                                  ),

                                  const SizedBox(height: 16),
                                  Text(
                                    'Ou acesse com',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: context.colors.onSurface,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),

                                  // Campo email
                                  TextFormField(
                                    keyboardType: TextInputType.emailAddress,
                                    controller: emailController,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor, insira seu e-mail';
                                      }
                                      final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                                      if (!emailRegex.hasMatch(value)) {
                                        return 'E-mail inválido';
                                      }
                                      return null;
                                    },
                                    decoration: const InputDecoration(labelText: 'Email'),
                                  ),

                                  const SizedBox(height: 16),

                                  // Campo senha
                                  Consumer<LoginController>(
                                    builder: (context, controller, _) => TextFormField(
                                      controller: passwordController,
                                      obscureText: !controller.isPasswordVisible,
                                      maxLength: 20,
                                      buildCounter: (_, {required currentLength, required isFocused, required maxLength}) => null,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Por favor, insira sua senha';
                                        }
                                        if (value.length < 6) {
                                          return 'A senha deve ter no mínimo 6 caracteres';
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Senha',
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            controller.isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                          ),
                                          onPressed: controller.togglePasswordVisibility,
                                        ),
                                      ),
                                    ),
                                  ),

                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton(
                                      onPressed: () {
                                        context.go('/recover-password');
                                      },
                                      child: Text(
                                        'Esqueceu a senha?',
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              color: context.colors.onSurface,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Botão login
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (_formKey.currentState?.validate() ?? false) {
                                        await controller.fazerLogin(
                                          emailController.text,
                                          passwordController.text,
                                          context,
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: context.theme.primaryColor,
                                      foregroundColor: context.theme.scaffoldBackgroundColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      minimumSize: const Size(double.infinity, 48),
                                    ),
                                    child: Text(
                                      'Entrar',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: context.colors.onPrimary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}