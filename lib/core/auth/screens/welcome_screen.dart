import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servus_app/core/theme/color_scheme.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/core/theme/design_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
                  // Botão principal - Entrar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusMd),
                        ),
                      ),
                      onPressed: () async{
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
