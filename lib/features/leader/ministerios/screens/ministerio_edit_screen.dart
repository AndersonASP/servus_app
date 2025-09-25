import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/ministerios/controllers/ministerio_controller.dart';
import 'package:servus_app/shared/widgets/fab_safe_scroll_view.dart';

class MinisterioEditScreen extends StatefulWidget {
  const MinisterioEditScreen({super.key});

  @override
  State<MinisterioEditScreen> createState() => _MinisterioEditScreenState();
}

class _MinisterioEditScreenState extends State<MinisterioEditScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final controller = MinisterioController();
        // Inicializar com o ministério do líder atual
        controller.initializeForLeader();
        return controller;
      },
      child: Consumer<MinisterioController>(
        builder: (context, controller, _) {
          return Scaffold(
            appBar: AppBar(
              surfaceTintColor: Colors.transparent,
              centerTitle: false,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: context.colors.onSurface),
                onPressed: () => context.pop(),
              ),
              title: Text(
                'Gerenciar meu ministério',
                style: context.textStyles.titleLarge?.copyWith(
                  color: context.colors.onSurface
                )
              ),
              actions: [
                // Botão de refresh
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: controller.isSaving ? null : () => controller.loadLeaderMinistry(),
                  tooltip: 'Atualizar dados',
                ),
              ],
            ),
            body: FabSafeScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informação sobre o ministério
                  _buildMinistryInfo(context, controller),
                  
                  const SizedBox(height: 24),
                  
                  // Nome do ministério
                  _buildFieldSection(
                    context: context,
                    title: 'Nome do ministério *',
                    hint: 'Ex: Louvor, Mídia, Acolhimento...',
                    controller: controller.nomeController,
                    error: controller.nomeError,
                    maxLines: 1,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Descrição
                  _buildFieldSection(
                    context: context,
                    title: 'Descrição',
                    hint: 'Descreva o propósito e responsabilidades do ministério...',
                    controller: controller.descricaoController,
                    error: controller.descricaoError,
                    maxLines: 3,
                    optional: true,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Funções do ministério
                  _buildFunctionsSection(context, controller),
                  
                  const SizedBox(height: 24),
                  
                  // Informações adicionais
                  _buildInfoSection(context),
                ],
              ),
            ),
            
            // Botão flutuante de salvar
            floatingActionButton: FloatingActionButton.extended(
              onPressed: controller.isSaving ? null : () => controller.salvarMinisterio(context),
              icon: controller.isSaving 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save),
              label: Text(controller.isSaving ? 'Salvando...' : 'Salvar'),
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMinistryInfo(BuildContext context, MinisterioController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
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
                color: context.colors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Informações do seu ministério',
                style: context.textStyles.titleMedium?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Como líder, você pode editar apenas o ministério que você lidera. '
            'Alterações serão aplicadas imediatamente.',
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldSection({
    required BuildContext context,
    required String title,
    required String hint,
    required TextEditingController controller,
    required String? error,
    int maxLines = 1,
    bool optional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: context.textStyles.titleMedium?.copyWith(
                color: context.colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (optional) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Opcional',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            errorText: error,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: context.colors.surface,
          ),
        ),
      ],
    );
  }

  Widget _buildFunctionsSection(BuildContext context, MinisterioController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Funções do ministério',
          style: context.textStyles.titleMedium?.copyWith(
            color: context.colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.colors.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.work_outline,
                size: 48,
                color: context.colors.outline,
              ),
              const SizedBox(height: 8),
              Text(
                'Funções do ministério',
                style: context.textStyles.titleSmall?.copyWith(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'As funções são gerenciadas automaticamente pelo sistema.',
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
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
                Icons.lightbulb_outline,
                color: context.colors.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Dicas',
                style: context.textStyles.titleSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Mantenha o nome do ministério claro e objetivo\n'
            '• A descrição ajuda outros membros a entenderem o propósito\n'
            '• Alterações são salvas automaticamente',
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
