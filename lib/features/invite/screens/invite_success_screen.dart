import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:servus_app/core/theme/context_extension.dart';

class InviteSuccessScreen extends StatelessWidget {
  final String ministryName;
  final String userName;

  const InviteSuccessScreen({
    super.key,
    required this.ministryName,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Ícone de sucesso
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Colors.green,
                ),
              ),

              const SizedBox(height: 32),

              // Título de sucesso
              Text(
                'Bem-vindo!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurface,
                ),
              ),

              const SizedBox(height: 16),

              // Mensagem de boas-vindas
              Text(
                'Olá, $userName!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: context.colors.onSurface,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Sua conta foi criada com sucesso e você foi vinculado ao ministério:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.colors.onSurface.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 16),

              // Card do ministério
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.colors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.car_rental,
                      size: 48,
                      color: context.colors.onPrimary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ministryName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Informações sobre próximos passos
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.colors.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 24,
                          color: context.colors.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Próximos Passos',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStepItem(
                      context,
                      '1',
                      'Suas funções serão definidas pelo líder do ministério',
                      Icons.assignment_ind,
                    ),
                    const SizedBox(height: 12),
                    _buildStepItem(
                      context,
                      '2',
                      'Você receberá um email de boas-vindas com mais informações',
                      Icons.email,
                    ),
                    const SizedBox(height: 12),
                    _buildStepItem(
                      context,
                      '3',
                      'Complete seu perfil para uma melhor experiência',
                      Icons.person,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Botão para fazer login
              ElevatedButton(
                onPressed: () => context.go('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Fazer Login',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Botão para voltar ao início
              OutlinedButton(
                onPressed: () => context.go('/'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.colors.primary,
                  side: BorderSide(color: context.colors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Voltar ao Início',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(
    BuildContext context,
    String number,
    String text,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: context.colors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              // Icon(
              //   icon,
              //   size: 16,
              //   color: context.colors.primary,
              // ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: context.colors.onSurface.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
