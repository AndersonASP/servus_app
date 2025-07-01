import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:servus_app/core/theme/color_scheme.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final DashboardController controller = DashboardController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundImage: NetworkImage('https://picsum.photos/200'),
                    radius: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Olá, Anderson Alves!',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: context.colors.primary)),
                        Text('Você tem 4 escalas este mês',
                            style: context.textStyles.bodyLarge?.copyWith(
                                fontSize: 14,
                                color: context.colors.onSurface,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const Icon(Icons.notifications, color: Color(0xFF4058DB)),
                ],
              ),
              const SizedBox(height: 24),
              Text('sua próxima escala',
                  style: context.textStyles.bodyLarge?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.colors.onSurface)),
              const SizedBox(height: 12),
              escalaCard(
                  0,
                  'Em 8 dias',
                  'Domingo, 15 de junho de 2025',
                  'Culto da família | Manhã',
                  '09:00h',
                  ['Louvor', 'Tecladista'],
                  'aguardando',
                  Colors.orange),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('o que vem por aí',
                      style: context.textStyles.bodyLarge?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.colors.onSurface)),
                  Icon(Icons.filter_alt_outlined,
                      color: context.colors.primary),
                ],
              ),
              const SizedBox(height: 12),
              escalaCard(
                  1,
                  'Em 10 dias',
                  'Quarta, 14 de junho de 2025',
                  'Quarta da graça',
                  '19:30h',
                  ['Louvor', 'Baixista'],
                  'confirmado',
                  Colors.orange),
              escalaCard(
                  2,
                  'Em 13 dias',
                  'Sábado, 18 de junho de 2025',
                  'Café com Deus',
                  '08:15h',
                  ['filmagem e Transmissão', 'Móvel gimbal 3'],
                  'finalizado',
                  Colors.green),
              escalaCard(
                  3,
                  'Em 17 dias',
                  'Sábado, 18 de junho de 2025',
                  'Seminário da família | Manhã',
                  '08:15h',
                  ['Louvor', 'Tecladista'],
                  'aguardando',
                  Colors.blueGrey),
            ],
          ),
        ),
      ),
    );
  }

  Widget escalaCard(
      int index,
      String diasRestantes,
      String data,
      String nomeEvento,
      String horario,
      List<String> funcoes,
      String statusLabel,
      Color statusColor) {
    final bool isProximaEscala = index == 0;
    final Color backgroundColor =
        isProximaEscala ? const Color(0xFF4058DB) : const Color(0xFFEBEEFF);
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
        // onTap: () => setState(() => controller.toggleExpand(index)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(diasRestantes,
                      style: context.textStyles.bodyLarge?.copyWith(
                        fontSize: 12,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w700,
                      )),
                  Text(data,
                      style: context.textStyles.bodyLarge?.copyWith(
                        fontSize: 12,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      nomeEvento,
                      style: context.textStyles.bodyLarge?.copyWith(
                        fontSize: 18,
                        color: textColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    horario,
                    style: context.textStyles.bodyLarge?.copyWith(
                      fontSize: 18,
                      color: secondaryTextColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    print('Presença confirmada!');
                  },
                  icon:  Icon(statusButton.icon, size: 20),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              Center(
                  child: TextButton.icon(
                onPressed: () => setState(() {
                  controller.toggleExpand(index);
                }),
                icon: !controller.expanded[index]
                    ? Icon(Icons.expand_more,
                        size: 15,
                        color: isProximaEscala
                            ? context.colors.surface
                            : context.colors.onSurface)
                    : Icon(Icons.expand_less,
                        size: 15,
                        color: isProximaEscala
                            ? context.colors.surface
                            : context.colors.onSurface),
                label: Text(!controller.expanded[index] ? 'mais detalhes' : 'menos detalhes',
                    style: context.textStyles.bodyLarge?.copyWith(
                      fontSize: 12,
                      color: isProximaEscala
                          ? context.colors.surface
                          : context.colors.onSurface,
                      fontWeight: FontWeight.w700,
                    )),
                style: TextButton.styleFrom(
                  foregroundColor: ServusColors.funcoesBackground,
                ),
              )),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: controller.expanded[index]
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Divider(color: textColor.withOpacity(0.3)),
                          Text('Local: Igreja Principal',
                              style: TextStyle(color: textColor)),
                          Text('Escalados: Anderson, Lucas M., Priscila A.',
                              style: TextStyle(color: textColor)),
                          const SizedBox(height: 6),
                          Text('Observações:',
                              style: TextStyle(color: textColor)),
                          Text('- Chegar 15 minutos antes',
                              style: TextStyle(color: textColor)),
                          Text('- Levar cabo HDMI reserva',
                              style: TextStyle(color: textColor)),
                        ],
                      )
                    : const SizedBox.shrink(),
              )
            ],
          ),
        ),
      ),
    );
  }
}
