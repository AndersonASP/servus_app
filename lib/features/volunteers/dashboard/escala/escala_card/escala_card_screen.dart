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
  final dynamic controller;

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
        ? context.theme.primaryColor
        : context.colors.surface;
    final Color textColor =
        isProximaEscala ? context.colors.onPrimary : context.colors.onSurface;
    final Color secondaryTextColor =
        isProximaEscala ? context.colors.onPrimary : context.colors.onSurface;
    final statusButton = controller.getBotaoStatusData(statusLabel, context);

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
        onTap: () {
          context.push('/volunteer/detalhes-escalas'); // TODO vai ser preciso usar o ID da escala aqui para buscar as infos
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 22),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: ServusColors.darkSurface.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 👉 Destaque da data com fundo
              Container(
                width: 70,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: isProximaEscala
                      ? context.theme.canvasColor
                      : context.theme.canvasColor.withValues(
                          alpha: 0.3,
                        ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dia,
                      style: context.textStyles.bodyLarge?.copyWith(
                        fontSize: 20,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w900,
                        height: 0.6
                      ),
                    ),
                    Text(
                      mes,
                      style: context.textStyles.bodyLarge?.copyWith(
                        fontSize: 15,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      diaSemana,
                      style: context.textStyles.bodyLarge?.copyWith(
                        fontSize: 15,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${horario}h',
                      style: context.textStyles.bodyLarge?.copyWith(
                        fontSize: 15,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 👉 Conteúdo principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomeEvento,
                      style: context.textStyles.bodyLarge?.copyWith(
                        fontSize: 20,
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
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: funcoes
                          .map((funcao) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: context.theme.canvasColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  funcao,
                                  style: context.textStyles.bodyLarge?.copyWith(
                                    fontSize: 12,
                                    color: context.colors.onPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 10),
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
                            color: context.colors.onPrimary,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: statusButton.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
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