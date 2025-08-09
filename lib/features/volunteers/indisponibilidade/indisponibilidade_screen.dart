import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/volunteers/indisponibilidade/bloqueios/screens/bloqueio_screen.dart';
import 'package:servus_app/shared/widgets/calendar_widget.dart';
import 'package:table_calendar/table_calendar.dart';
import 'indisponibilidade_controller.dart';

class IndisponibilidadeScreen extends StatefulWidget {
  const IndisponibilidadeScreen({super.key});

  @override
  State<IndisponibilidadeScreen> createState() => _IndisponibilidadeScreenState();
}

class _IndisponibilidadeScreenState extends State<IndisponibilidadeScreen> {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<IndisponibilidadeController>(context);
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Indisponibilidade',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.onSurface,
              ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: context.colors.onSurface,
                        ),
                    children: [
                      const TextSpan(text: 'Toque nos dias em que você '),
                      TextSpan(
                        text: 'não',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: context.colors.error,
                        ),
                      ),
                      const TextSpan(text: ' poderá servir.'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      height: 390,
                      child: TableCalendar(
                        locale: 'pt_BR',
                        firstDay: DateTime.utc(today.year, today.month - 3, 1),
                        lastDay: DateTime.utc(today.year, today.month + 3, 31),
                        focusedDay: controller.focusedDay,
                        onPageChanged: (newFocusedDay) {
                          controller.setFocusedDay(newFocusedDay);
                        },
                        enabledDayPredicate: (day) {
                          final now = DateTime.now();
                          final todayOnlyDate =
                              DateTime(now.year, now.month, now.day);
                          final currentDayOnly =
                              DateTime(day.year, day.month, day.day);
                          return !currentDayOnly.isBefore(todayOnlyDate);
                        },
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: TextStyle(
                            color: context.colors.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        calendarStyle: buildCalendarStyle(context),
                        selectedDayPredicate: (day) =>
                            controller.isDiaBloqueado(day),
                        onDaySelected: (selectedDay, focusedDay) {
                          controller.setFocusedDay(focusedDay);
                          if (controller.isDiaBloqueado(selectedDay)) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => BloqueioScreen(
                                  onConfirmar: (motivo, ministerios) {
                                    // Aqui você pode atualizar o estado após editar
                                    controller.registrarBloqueio(
                                      dia: selectedDay,
                                      motivo: motivo,
                                      ministerios: ministerios,
                                    );
                                  },
                                  ministeriosDisponiveis: [
                                    'Ministério de Louvor',
                                    'Ministério Infantil',
                                    'Ministério de Oração',
                                    'Ministério de Ação Social',
                                  ],
                                ),
                              ),
                            );
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => BloqueioScreen(
                                  onConfirmar: (motivo, ministerios) {
                                    controller.registrarBloqueio(
                                      dia: selectedDay,
                                      motivo: motivo,
                                      ministerios: ministerios,
                                    );
                                  },
                                  ministeriosDisponiveis: [
                                    'Ministério de Louvor',
                                    'Ministério Infantil',
                                    'Ministério de Oração',
                                    'Ministério de Ação Social',
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                        calendarFormat: CalendarFormat.month,
                        availableGestures: AvailableGestures.all,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // SizedBox(
                //   width: double.infinity,
                //   child: ElevatedButton(
                //     onPressed: controller.salvarIndisponibilidade,
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: const Color(0xFF4058DB),
                //       padding: const EdgeInsets.symmetric(vertical: 16),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //     ),
                // child: const Text(
                //   'Salvar indisponibilidade',
                //   style: TextStyle(
                //     fontSize: 15,
                //     fontWeight: FontWeight.bold,
                //     color: Colors.white,
                //   ),
                // ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
