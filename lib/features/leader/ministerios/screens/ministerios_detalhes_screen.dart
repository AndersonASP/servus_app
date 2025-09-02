import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/ministerios/controllers/ministerios_detalhes_controller.dart';
import 'package:go_router/go_router.dart';

class MinisterioDetalhesScreen extends StatelessWidget {
  final String ministerioId;
  const MinisterioDetalhesScreen({super.key, required this.ministerioId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MinisterioDetalhesController(ministerioId: ministerioId)..carregarDados(),
      child: Consumer<MinisterioDetalhesController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            appBar: AppBar(
              centerTitle: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/leader/ministerio/lista'),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ministério', style: context.textStyles.titleLarge
                    ?.copyWith(color: context.colors.onSurface)),
                  Text(
                    controller.igreja,
                    style: context.textStyles.labelSmall,
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: controller.carregarDados,
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Aba de navegação
                  Row(
                    children: [
                      _tabButton(context, "Informações", true),
                      const SizedBox(width: 8),
                      _tabButton(context, "Membros (${controller.totalMembros}/${controller.limiteMembros})", false),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Card com imagem e nome
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            color: context.colors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.church, size: 40),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            controller.nomeMinisterio,
                            style: context.textStyles.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.colors.onSurface,
                            ),
                          ),
                        ),
                        const Icon(Icons.more_vert),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Lista de opções
                  _optionTile(Icons.groups, "Equipes", () {}),
                  _optionTile(Icons.manage_accounts, "Funções", () {}),
                  _optionTile(Icons.star_border, "Classificações", () {}),
                  _optionTile(Icons.admin_panel_settings, "Administradores", () {}),
                  _optionTile(Icons.extension, "Módulos", () {}),
                  _optionTile(Icons.insert_drive_file, "Modelos de roteiro", () {}),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tabButton(BuildContext context, String text, bool selected) {
    return Expanded(
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: selected ? context.colors.primary.withValues(alpha: 0.2) : context.colors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: selected ? context.colors.primary : context.colors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _optionTile(IconData icon, String title, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        const Divider(height: 0),
      ],
    );
  }
}