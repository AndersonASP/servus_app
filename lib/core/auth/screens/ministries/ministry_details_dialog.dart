import 'package:flutter/material.dart';
import 'package:servus_app/core/models/ministry_dto.dart';
import 'package:servus_app/core/theme/context_extension.dart';

class MinistryDetailsDialog extends StatelessWidget {
  final MinistryResponse ministry;

  const MinistryDetailsDialog({
    super.key,
    required this.ministry,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: ministry.isActive 
                ? context.theme.primaryColor 
                : Colors.grey,
            child: Text(
              ministry.name[0].toUpperCase(),
              style: TextStyle(
                color: ministry.isActive 
                    ? context.colors.onPrimary 
                    : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ministry.name,
              style: context.textStyles.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ministry.isActive ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ministry.isActive ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    ministry.isActive ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: ministry.isActive ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ministry.isActive ? 'Ativo' : 'Inativo',
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: ministry.isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Descrição
            if (ministry.description != null && ministry.description!.isNotEmpty) ...[
              Text(
                'Descrição',
                style: context.textStyles.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ministry.description!,
                style: context.textStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
            
            // Funções do ministério
            Text(
              'Funções do Ministério',
              style: context.textStyles.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            if (ministry.ministryFunctions.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ministry.ministryFunctions.map((function) => Chip(
                  label: Text(function),
                  backgroundColor: context.theme.primaryColor.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: context.theme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                )).toList(),
              )
            else
              Text(
                'Nenhuma função definida',
                style: context.textStyles.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Informações de criação/atualização
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informações do Sistema',
                    style: context.textStyles.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Criado em: ${_formatDate(ministry.createdAt)}',
                        style: context.textStyles.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.update, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Atualizado em: ${_formatDate(ministry.updatedAt)}',
                        style: context.textStyles.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
} 