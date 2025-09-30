import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servus_app/core/theme/color_scheme.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/core/theme/design_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late final AnimationController _buttonAnimationController;
  late final Animation<double> _buttonScaleAnimation;
  late final Animation<double> _buttonElevationAnimation;

  @override
  void initState() {
    super.initState();
    
    // Inicializar animações para micro-interações
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _buttonElevationAnimation = Tween<double>(
      begin: 2.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ServusColors.background,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // ILUSTRAÇÃO
            Builder(
              builder: (context) => Image.asset(
                'assets/images/welcome_illustration.png',
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.cover,
              ),
            ),

            // TEXTO INSTITUCIONAL
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingMd),
              child: Builder(
                builder: (context) => RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 28,
                          letterSpacing: -2.0,
                          fontFamily: GoogleFonts.poppins().fontFamily,
                        ),
                    children: [
                      TextSpan(
                        text: 'VOCÊ ',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: context.theme.colorScheme.secondary,
                            fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: 'É MAIS DO QUE UM VOLUNTÁRIO\n',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: ServusColors.primaryDark,
                            fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: 'VOCÊ É PARTE DA ',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: ServusColors.primaryDark,
                            fontSize: 24,
                            letterSpacing: 0,
                            fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: 'MISSÃO.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: context.theme.colorScheme.secondary,
                            fontSize: 24,
                            letterSpacing: 0,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // BOTÕES
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingMd),
              child: Column(
                children: [
                  // Botão principal - Entrar com micro-interações
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedBuilder(
                      animation: _buttonAnimationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _buttonScaleAnimation.value,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.theme.colorScheme.primary,
                              elevation: _buttonElevationAnimation.value,
                              shadowColor: context.theme.colorScheme.primary.withOpacity(0.3),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(DesignTokens.radiusMd),
                              ),
                            ),
                            onPressed: () async{
                              // Animação de press
                              _buttonAnimationController.forward().then((_) {
                                _buttonAnimationController.reverse();
                              });
                              
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('viu_welcome', true);
                              if (!context.mounted) return;
                              // Redireciona para a tela de login
                              context.go('/login');
                            },
                      child: Text(
                        'Entrar',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: context.theme.colorScheme.onPrimary,
                        ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Botão secundário - Código de convite
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusMd),
                        ),
                        side: BorderSide(
                          color: context.theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      onPressed: () {
                        context.go('/invite/code');
                      },
                      child: Text(
                        'Tenho código de convite',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: context.theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
