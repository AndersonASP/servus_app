import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/ministries/controllers/ministry_functions_controller.dart';
import 'package:servus_app/features/ministries/models/ministry_function.dart';
import 'package:servus_app/core/services/feedback_service.dart';

class MinistryFunctionsTab extends StatefulWidget {
  final String ministryId;
  final String ministryName;

  const MinistryFunctionsTab({
    Key? key,
    required this.ministryId,
    required this.ministryName,
  }) : super(key: key);

  @override
  State<MinistryFunctionsTab> createState() => _MinistryFunctionsTabState();
}

class _MinistryFunctionsTabState extends State<MinistryFunctionsTab> {
  final Map<String, bool> _functionStates = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFunctions();
    });
  }

  void _loadFunctions() {
    final controller = context.read<MinistryFunctionsController>();
    // Carregar apenas as funções do ministério específico
    controller.loadMinistryFunctions(widget.ministryId);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MinistryFunctionsController>(
      builder: (context, controller, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gerencie as funções do ministério. Use o switch para ativar/desativar funções.',
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              
              // Lista de funções
              _buildFunctionsList(controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFunctionsList(MinistryFunctionsController controller) {
    if (controller.isLoading && controller.filteredFunctions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: context.colors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar funções',
              style: context.textStyles.titleMedium?.copyWith(
                color: context.colors.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.error!,
              style: context.textStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFunctions,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    // Usar todas as funções carregadas (ativas e inativas)
    final functions = controller.ministryFunctions;

    if (functions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 64,
              color: context.colors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma função definida',
              style: context.textStyles.titleMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Edite o ministério para adicionar funções',
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: functions.map((function) => 
        _buildFunctionCard(function, controller)
      ).toList(),
    );
  }

  Widget _buildFunctionCard(MinistryFunction function, MinistryFunctionsController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: context.colors.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Ícone da função
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: function.isActive
                    ? context.colors.primary.withOpacity(0.1)
                    : context.colors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.work,
                color: function.isActive
                    ? context.colors.primary
                    : context.colors.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            
            // Informações da função
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    function.name,
                    style: context.textStyles.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colors.onSurface,
                    ),
                  ),
                  if (function.description != null && function.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      function.description!,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        function.isActive ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: function.isActive 
                            ? Colors.green 
                            : context.colors.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        function.isActive ? 'Ativa' : 'Inativa',
                        style: context.textStyles.bodySmall?.copyWith(
                          color: function.isActive 
                              ? Colors.green 
                              : context.colors.onSurface.withOpacity(0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Switch para ativar/desativar função
            Switch(
              value: _functionStates[function.functionId] ?? function.isActive,
              onChanged: controller.isLoading ? null : (value) async {
                // Atualizar estado local imediatamente
                setState(() {
                  _functionStates[function.functionId] = value;
                });

                try {
                  await controller.updateMinistryFunction(
                    widget.ministryId,
                    function.functionId,
                    isActive: value,
                  );
                } catch (e) {
                  // Reverter estado local em caso de erro
                  setState(() {
                    _functionStates[function.functionId] = function.isActive;
                  });
                  
                  // Mostrar erro se necessário
                  if (mounted) {
                    FeedbackService.showUpdateError(context, 'função');
                  }
                }
              },
              activeColor: Colors.green,
              inactiveThumbColor: Colors.red,
              inactiveTrackColor: Colors.red.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}