import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:table_calendar/table_calendar.dart';
import 'indisponibilidade_controller.dart';

class IndisponibilidadeScreen extends StatelessWidget {
  const IndisponibilidadeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<IndisponibilidadeController>(context);
    final today = DateTime.now();
   

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(height: 8),
                // Row(
                //   children: [
                //     const CircleAvatar(
                //       backgroundImage:
                //           NetworkImage('https://picsum.photos/200'),
                //       radius: 24,
                //     ),
                //     const SizedBox(width: 12),
                //     Expanded(
                //       child: Column(
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         children: [
                //           Text('Olá, Anderson Alves!',
                //               style: Theme.of(context)
                //                   .textTheme
                //                   .bodyLarge
                //                   ?.copyWith(
                //                       fontSize: 25,
                //                       fontWeight: FontWeight.w800,
                //                       color: context.colors.primary)),
                //           // Text('Você tem 4 escalas este mês',
                //           //     style: context.textStyles.bodyLarge?.copyWith(
                //           //         fontSize: 18,
                //           //         color: context.colors.onSurface,
                //           //         fontWeight: FontWeight.w500)),
                //         ],
                //       ),
                //     ),
                //     Stack(
                //       alignment: Alignment.topRight,
                //       children: [
                //         const Icon(Icons.notifications_none, size: 30),
                //         Positioned(
                //           right: 0,
                //           child: Container(
                //             padding: const EdgeInsets.all(4),
                //             decoration: const BoxDecoration(
                //               color: Colors.red,
                //               shape: BoxShape.circle,
                //             ),
                //             child: const Text('15',
                //                 style: TextStyle(
                //                     fontSize: 8,
                //                     color: Colors.white,
                //                     fontWeight: FontWeight.w700)),
                //           ),
                //         ),
                //       ],
                //     ),
                //   ],
                // ),
                // const SizedBox(height: 30),

                // Instruções
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: context.colors.primary,
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
                const SizedBox(height: 6),
                Text(
                  'Essas datas serão marcadas como indisponíveis.\nQuando terminar, toque em “Salvar indisponibilidade”.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.onSurface,
                        fontSize: 12,
                      ),
                ),

                const SizedBox(height: 20),

                // Calendário com sombra (card)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
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
                        return !day.isBefore(
                          DateTime(today.year, today.month, today.day),
                        );
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
                      calendarStyle: CalendarStyle(
                        defaultTextStyle: TextStyle(
                            color: context.colors.onSecondary,
                            fontSize: 18,
                            fontFamily: GoogleFonts.poppins().fontFamily),
                        weekendTextStyle: TextStyle(
                            color: context.colors.onSecondary,
                            fontSize: 18,
                            fontFamily: GoogleFonts.poppins().fontFamily),
                        outsideTextStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 15,
                            fontFamily: GoogleFonts.poppins().fontFamily),
                        todayDecoration: BoxDecoration(
                          color: context.colors.primary,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: Color(0xFFFF7D7D),
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle:
                            const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      selectedDayPredicate: (day) => controller.selectedDays
                          .any((d) => controller.isSameDay(d, day)),
                      onDaySelected: (selectedDay, focusedDay) {
                        if (controller.selectedDays.contains(selectedDay)) {
                          controller.toggleDay(selectedDay);
                          controller.setFocusedDay(focusedDay);
                        } else if (controller.selectedDays.length >= controller.maxDiasIndisponiveis) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Limite de bloqueios atingido',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: context.colors.error,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      )),
                              content: RichText(
                                text: TextSpan(
                                  style: context.textStyles.bodyLarge?.copyWith(
                                    fontSize: 14,
                                    color: context.colors.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  children: [
                                    TextSpan(text: 'Você só pode marcar até ${controller.maxDiasIndisponiveis} dias como indisponível.\n\n'),
                                    TextSpan(
                                      text: 'Em caso de dúvidas, procure sua liderança.',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('OK',),
                                ),
                              ],
                            ),
                          );
                        } else {
                          controller.toggleDay(selectedDay);
                          controller.setFocusedDay(focusedDay);
                        }
                      },
                      calendarFormat: CalendarFormat.month,
                      availableGestures: AvailableGestures.all,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Botão
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.salvarIndisponibilidade,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4058DB),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Salvar indisponibilidade',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
