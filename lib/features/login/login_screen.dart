import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/color_scheme.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'login_controller.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          // Fundo azul ocupando 40% da tela + área da notch
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.33 + statusBarHeight,
            child: Container(
              color: context.theme.colorScheme.primary,
            ),
          ),

          // Conteúdo sobreposto ao fundo
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 30),

                    // Logo
                    SvgPicture.asset(
                      'assets/images/logo.svg',
                      width: 50,
                      semanticsLabel: 'Servus Logo',
                    ),
                    const SizedBox(height: 5),
                    Text('SERVUS',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 33),
                    Text(
                      'Acesse sua conta',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontSize: 32, fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Caixa de login
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            label: Text(
                              'Continue com Google',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: ServusColors.textHigh,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.theme.scaffoldBackgroundColor,
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
                          Text('Ou acesse com',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: ServusColors.textMedium,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          TextField(
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: ServusColors.textHigh,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                            controller:
                                context.read<LoginController>().emailController,
                            decoration:
                                const InputDecoration(labelText: 'Email'),
                          ),
                          const SizedBox(height: 16),
                          Consumer<LoginController>(
                            builder: (context, controller, _) => TextField(
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: ServusColors.textHigh,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                              maxLength: 10,
                              controller: controller.passwordController,
                              obscureText: !controller.isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    controller.isPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed:
                                      controller.togglePasswordVisibility,
                                ),
                              ),
                            ),
                          ),
                          Consumer<LoginController>(
                            builder: (context, controller, _) => Row(
                              children: [
                                Checkbox(
                                  value: controller.rememberMe,
                                  onChanged: controller.toggleRememberMe,
                                ),
                                Text('Lembrar senha',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: ServusColors.textHigh,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        )),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'Esqueceu a senha?',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: context.theme.colorScheme.primary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.theme.colorScheme.primary,
                              foregroundColor: context.theme.scaffoldBackgroundColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: Text(
                              'Entrar',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: context.theme.scaffoldBackgroundColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}