import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/ministerios/controllers/ministerio_controller.dart';
import 'package:servus_app/features/ministries/models/ministry_dto.dart';
import 'package:servus_app/shared/widgets/fab_safe_scroll_view.dart';

class MinisterioFormScreen extends StatefulWidget {
  final MinistryResponse? ministerio; // Para edição
  
  const MinisterioFormScreen({super.key, this.ministerio});

  @override
  State<MinisterioFormScreen> createState() => _MinisterioFormScreenState();
}

class _MinisterioFormScreenState extends State<MinisterioFormScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final controller = MinisterioController();
        // Se recebeu um ministério, inicializa para edição
        if (widget.ministerio != null) {
          controller.initializeForEdit(widget.ministerio!);
        }
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
                widget.ministerio != null ? 'Editar Ministério' : 'Novo Ministério',
                style: context.textStyles.titleLarge?.copyWith(
                  color: context.colors.onSurface
                )
              ),
              actions: [
                // Botão de reset
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: controller.isSaving ? null : () => controller.reset(),
                  tooltip: 'Limpar formulário',
                ),
              ],
            ),
            body: FabSafeScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  
                  // Limite de bloqueios
                  _buildBlockLimitSection(context, controller),
                  
                  const SizedBox(height: 24),
                  
                  // Funções do ministério
                  _buildFunctionsSection(context, controller),
                  
                  const SizedBox(height: 24),
                  
                  // Status ativo/inativo
                  // _buildStatusSection(context, controller),
                  
                  // const SizedBox(height: 32),
                  
                  // Informações adicionais
                  _buildInfoSection(context),
                ],
              ),
            ),
            
            // Botão flutuante de salvar
            floatingActionButton: FloatingActionButton.extended(
              onPressed: controller.isSaving
                  ? null
                  : () => controller.salvarMinisterio(context),
              icon: controller.isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check),
              label: controller.isSaving
                  ? Text(
                      'Salvando...',
                      style: context.textStyles.bodyLarge?.copyWith(
                        color: context.colors.onPrimary,
                        fontWeight: FontWeight.w800
                      )
                    )
                  : Text(
                      widget.ministerio != null ? 'Atualizar' : 'Criar',
                      style: context.textStyles.bodyLarge?.copyWith(
                        color: context.colors.onPrimary,
                        fontWeight: FontWeight.w800
                      )
                    ),
              backgroundColor: context.colors.primary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFieldSection({
    required BuildContext context,
    required String title,
    required String hint,
    required TextEditingController controller,
    String? error,
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
              style: context.textStyles.labelLarge?.copyWith(
                color: context.colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (optional) ...[
              const SizedBox(width: 4),
              Text(
                '(opcional)',
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.onSurface.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            errorText: error,
            errorStyle: TextStyle(
              color: Colors.red[600],
              fontSize: 12,
            ),
            filled: true,
            fillColor: context.colors.surface,
          ),
        ),
      ],
    );
  }

  Widget _buildBlockLimitSection(BuildContext context, MinisterioController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.block,
              color: context.colors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Limite de dias bloqueados',
              style: context.textStyles.labelLarge?.copyWith(
                color: context.colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Número máximo de dias que um voluntário pode bloquear por mês',
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurface.withValues(alpha: 0.7),
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: controller.maxBlockedDays.toDouble(),
                min: 1,
                max: 50,
                divisions: 49,
                activeColor: context.colors.primary,
                inactiveColor: context.colors.primary.withValues(alpha: 0.3),
                onChanged: (value) {
                  controller.updateMaxBlockedDays(value.round());
                },
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.colors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '${controller.maxBlockedDays} dias',
                style: context.textStyles.titleMedium?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Recomendado: 10-15 dias para ministérios com alta demanda',
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurface.withValues(alpha: 0.5),
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
          'Funções do ministério *',
          style: context.textStyles.labelLarge?.copyWith(
            color: context.colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Digite uma função por vez ou várias separadas por vírgula',
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurface.withOpacity(0.7),
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        
        // Campo para adicionar função
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller.funcaoController,
                decoration: InputDecoration(
                  hintText: 'Digite funções separadas por vírgula: Vocal, Instrumentos, Técnico...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorText: controller.funcaoError,
                  errorStyle: TextStyle(
                    color: Colors.red[600],
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: context.colors.surface,
                ),
                onSubmitted: (_) => controller.adicionarFuncoes(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: controller.funcaoController.text.trim().isNotEmpty ? controller.adicionarFuncoes : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: context.colors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 18, color: context.colors.onPrimary),
                  const SizedBox(width: 4),
                  Text(
                    'Adicionar',
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Lista de funções
        if (controller.funcoes.isNotEmpty) ...[
          Text(
            'Funções adicionadas:',
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.funcoes.map((funcao) {
              return Container(
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => controller.removerFuncao(funcao),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            funcao,
                            style: TextStyle(
                              color: context.colors.onPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.close,
                            size: 18,
                            color: context.colors.onPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Adicione pelo menos uma função para o ministério',
                    style: context.textStyles.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusSection(BuildContext context, MinisterioController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status do ministério',
          style: context.textStyles.labelLarge?.copyWith(
            color: context.colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Switch(
              value: controller.ativo,
              onChanged: controller.toggleAtivo,
              activeThumbColor: context.colors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.ativo ? 'Ativo' : 'Inativo',
                    style: context.textStyles.titleMedium?.copyWith(
                      color: controller.ativo ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    controller.ativo 
                        ? 'O ministério está ativo e pode ser usado'
                        : 'O ministério está inativo e não será exibido',
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue[600],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dicas para um bom ministério',
                  style: context.textStyles.titleSmall?.copyWith(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Use nomes claros e objetivos\n'
                  '• Descreva bem as responsabilidades\n'
                  '• Defina funções específicas\n',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}