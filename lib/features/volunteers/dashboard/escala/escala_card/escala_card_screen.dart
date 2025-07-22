import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/core/theme/color_scheme.dart';

class EscalaCardWidget extends StatelessWidget {
  final int index;
  final String diasRestantes;
  final String dia;
  final String mes;
  final String horario;
  final String diaSemana;
  final String nomeEvento;
  final List<String> funcoes;
  final String statusLabel;
  final Color statusColor;
  final dynamic controller; // Substitua por seu tipo real

  const EscalaCardWidget({
    super.key,
    required this.index,
    required this.diasRestantes,
    required this.dia,
    required this.mes,
    required this.horario,
    required this.diaSemana,
    required this.nomeEvento,
    required this.funcoes,
    required this.statusLabel,
    required this.statusColor,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final bool isProximaEscala = index == 0;
    final Color backgroundColor = isProximaEscala
        ? context.colors.primary
        : context.colors.surface;
    final Color textColor =
        isProximaEscala ? context.colors.surface : context.colors.onSurface;
    final Color secondaryTextColor =
        isProximaEscala ? context.colors.surface : context.colors.onSurface;
    final statusButton = controller.getBotaoStatusData(statusLabel);

    return Slidable(
      key: ValueKey(index),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => controller.confirmarEscala(index),
            backgroundColor: statusColor,
            foregroundColor: Colors.white,
            icon: Icons.check,
            label: 'Confirmar',
          ),
        ],
      ),
      child: GestureDetector(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(15),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Coluna da data e hora
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    dia, // Ex: '28 Jul'
                    style: context.textStyles.bodyLarge?.copyWith(
                      fontSize: 18,
                      color: secondaryTextColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    mes, // Ex: 'Jul'
                    style: context.textStyles.bodyLarge?.copyWith(
                      fontSize: 18,
                      color: secondaryTextColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    diaSemana,
                    style: context.textStyles.bodyLarge?.copyWith(
                      fontSize: 14,
                      color: secondaryTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),              
                  Text(
                    '${horario}h',
                    style: context.textStyles.bodyLarge?.copyWith(
                      fontSize: 14,
                      color: secondaryTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Coluna principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomeEvento,
                      style: context.textStyles.bodyLarge?.copyWith(
                        fontSize: 19,
                        color: textColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                    diasRestantes,
                    style: context.textStyles.bodyLarge?.copyWith(
                      fontSize: 12,
                      color: secondaryTextColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: funcoes
                          .map((funcao) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: ServusColors.funcoesBackground,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  funcao,
                                  style: context.textStyles.bodyLarge?.copyWith(
                                    fontSize: 12,
                                    color: context.colors.surface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (statusButton.label == 'Fazer check-in') {
                            context.push('/qr-checkin');
                          } else if (statusButton.label == 'Confirmar') {
                            controller.confirmarEscala(index);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Ação indisponível para o status atual: ${statusButton.label}',
                                  style: context.textStyles.bodyLarge?.copyWith(
                                    fontSize: 14,
                                    color: context.colors.surface,
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                        icon: Icon(statusButton.icon, size: 20),
                        label: Text(
                          statusButton.label,
                          style: context.textStyles.bodyLarge?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: statusButton.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
