import 'package:flutter/material.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/volunteers/indisponibilidade/indisponibilidade_controller.dart';

class BloqueioCard extends StatelessWidget {
  final BloqueioIndisponibilidade bloqueio;
  final VoidCallback onEditar;
  final VoidCallback onRemover;

  const BloqueioCard({
    super.key,
    required this.bloqueio,
    required this.onEditar,
    required this.onRemover,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.block,
                  color: context.colors.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bloqueio.motivo.isNotEmpty ? bloqueio.motivo : 'Sem motivo especificado',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: context.colors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (bloqueio.ministerios.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Ministérios:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: bloqueio.ministerios.map((ministerio) {
                  return Container(
                    decoration: BoxDecoration(
                      color: context.colors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: context.colors.primary.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text(
                        ministerio,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.onPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEditar,
                  icon: Icon(
                    Icons.edit,
                    size: 16,
                    color: context.colors.primary,
                  ),
                  label: Text(
                    'Editar',
                    style: TextStyle(
                      color: context.colors.primary,
                      fontSize: 12,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onRemover,
                  icon: Icon(
                    Icons.delete,
                    size: 16,
                    color: context.colors.error,
                  ),
                  label: Text(
                    'Remover',
                    style: TextStyle(
                      color: context.colors.error,
                      fontSize: 12,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
