import 'package:flutter/material.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/ministries/models/ministry_function.dart';
import 'package:servus_app/features/ministries/services/ministry_functions_service.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';

class FunctionSelectorWidget extends StatefulWidget {
  final String ministryId;
  final List<String> selectedFunctionIds;
  final Function(List<String>) onFunctionsChanged;
  final bool enabled;

  const FunctionSelectorWidget({
    super.key,
    required this.ministryId,
    required this.selectedFunctionIds,
    required this.onFunctionsChanged,
    this.enabled = true,
  });

  @override
  State<FunctionSelectorWidget> createState() => _FunctionSelectorWidgetState();
}

class _FunctionSelectorWidgetState extends State<FunctionSelectorWidget> {
  final MinistryFunctionsService _ministryFunctionsService = MinistryFunctionsService();
  List<MinistryFunction> _availableFunctions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFunctions();
  }

  Future<void> _loadFunctions() async {
    if (widget.ministryId.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final functions = await _ministryFunctionsService.getMinistryFunctions(widget.ministryId);
      setState(() {
        _availableFunctions = functions.where((f) => f.isActive).toList();
      });
    } catch (e) {
      if (mounted) {
        showError(context, 'Erro ao carregar funções: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleFunction(String functionId) {
    if (!widget.enabled) return;

    // Debug: verificar tipo antes de processar

    // Garantir que selectedFunctionIds é uma List<String>
    final currentIds = List<String>.from(widget.selectedFunctionIds);
    
    final newSelectedIds = List<String>.from(currentIds);
    
    if (newSelectedIds.contains(functionId)) {
      newSelectedIds.remove(functionId);
    } else {
      newSelectedIds.add(functionId);
    }
    
    widget.onFunctionsChanged(newSelectedIds);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_availableFunctions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: context.colors.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: context.colors.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Nenhuma função disponível neste ministério',
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Funções do Ministério',
          style: context.textStyles.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableFunctions.map((function) {
            // Debug: verificar tipo dos selectedFunctionIds
            
            // Garantir que selectedFunctionIds é uma List<String>
            final selectedIds = List<String>.from(widget.selectedFunctionIds);
                
            final isSelected = selectedIds.contains(function.functionId);
            
            return GestureDetector(
              onTap: widget.enabled ? () => _toggleFunction(function.functionId) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? context.colors.primary 
                    : context.colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                      ? context.colors.primary 
                      : context.colors.outline.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: context.colors.primary.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      Icon(
                        Icons.check,
                        size: 16,
                        color: context.colors.onPrimary,
                      ),
                    if (isSelected) const SizedBox(width: 4),
                    Text(
                      function.name,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: isSelected 
                          ? context.colors.onPrimary 
                          : context.colors.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (widget.selectedFunctionIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: context.colors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.selectedFunctionIds.length} função(ões) selecionada(s)',
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.w500,
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
}
