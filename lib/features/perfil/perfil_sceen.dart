import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/color_scheme.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'perfil_controller.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  @override
  void initState() {
    super.initState();
    // Carrega dados após o primeiro frame para garantir Provider montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PerfilController>().carregarDadosSalvos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PerfilController>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Perfil',
          style: context.textStyles.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colors.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // Foto de perfil (URL > arquivo local > placeholder)
              GestureDetector(
                onTap: () => controller.selecionarImagemDaGaleria(),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.primary,
                  foregroundImage: controller.imagemPerfilProvider,
                  child: Text(
                    _iniciais(controller.nome),
                    style: context.textStyles.bodyLarge?.copyWith(
                      color: context.colors.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Nome
              Text(
                controller.nome,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: context.colors.onSurface,
                ),
              ),

              const SizedBox(height: 4),

              // Igreja e campus
              Text(
                controller.igreja,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurface,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 20),

              // Card de vezes que serviu
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4058DB),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      const TextSpan(text: 'Uau! Você já serviu '),
                      TextSpan(
                        text: '${controller.vezesServiu}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const TextSpan(text: ' vezes este ano 🏆'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Lista de opções
              ...controller.menuItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBEEFF),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      collapsedBackgroundColor: context.colors.surface,
                      backgroundColor: context.colors.surface,
                      collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        item.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.colors.onSurface,
                          fontSize: 15,
                        ),
                      ),
                      children: [
                        if (item.title == 'Informações pessoais') ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Nome: ${controller.nome}'),
                                Text('Email: ${controller.email}'),
                                Text('Igreja: ${controller.igreja}'),
                              ],
                            ),
                          ),
                        ] else if (item.title == 'Suas funções') ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Column(
                              children: [
                                const SizedBox(height: 12),
                                TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Nova função',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {},
                                  child: const Text('Adicionar função'),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text(
                              'Informações detalhadas...',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: context.colors.onSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ],
                      onExpansionChanged: (expanded) {
                        if (expanded) item.onTap.call();
                      },
                    ),
                  ),
                ),
              ),

              Align(
                alignment: Alignment.center,
                child: Text(
                  'Versão 1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurface.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Logout
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ServusColors.error,
                  foregroundColor: ServusColors.darkTextHigh,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: context.colors.surface,
                      title: Text(
                        'Encerrar sessão',
                        style: context.textStyles.titleLarge?.copyWith(
                          color: context.colors.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: Text(
                        'Você deseja realmente sair?',
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      actionsPadding: const EdgeInsets.only(
                        left: 16, right: 16, bottom: 12,
                      ),
                      actions: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: context.colors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => context.pop(false),
                                child: Text(
                                  'Cancelar',
                                  style: context.textStyles.bodyLarge?.copyWith(
                                    color: context.colors.onSurface,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: context.colors.error,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => context.pop(true),
                                child: Text(
                                  'Sair',
                                  style: context.textStyles.bodyLarge?.copyWith(
                                    color: context.colors.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await context.read<PerfilController>().logout(context);
                    if (context.mounted) context.go('/login');
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sair do aplicativo'),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// helper simples para iniciais
String _iniciais(String nome) {
  final partes = nome.trim().split(RegExp(r'\s+'));
  if (partes.isEmpty) return '';
  if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
  return (partes.first[0] + partes.last[0]).toUpperCase();
}