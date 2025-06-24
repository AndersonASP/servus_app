import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/core/theme/design_tokens.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
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
                            fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: 'É MAIS DO QUE UM VOLUNTÁRIO\n',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: context.theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: 'VOCÊ É PARTE DA ',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: context.theme.colorScheme.onSurface,
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

            // BOTÃO
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingMd),
              child: SizedBox(
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
                  onPressed: () {
                    context.go('/login');
                  },
                  child: Text(
                    'Entrar',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: context.theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
