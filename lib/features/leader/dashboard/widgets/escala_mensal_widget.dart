import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:servus_app/core/theme/context_extension.dart';

class EscalasResumoWidget extends StatefulWidget {
  final String ministerioId;

  const EscalasResumoWidget({super.key, required this.ministerioId});

  @override
  State<EscalasResumoWidget> createState() => _EscalasResumoWidgetState();
}

class _EscalasResumoWidgetState extends State<EscalasResumoWidget> {
  final List<String> datas = ['04/08', '11/08', '18/08'];
  int dataSelecionadaIndex = 0;

  final Map<String, List<Map<String, dynamic>>> escalasPorData = {
    '04/08': [
      {
        'evento': 'Culto Manhã',
        'horario': '09:00',
        'funcoes': {
          'Louvor': [
            {
              'nome': 'João',
              'funcao': 'Guitarra',
              'foto': 'https://randomuser.me/api/portraits/men/1.jpg'
            },
            {
              'nome': 'Maria',
              'funcao': 'Vocal',
              'foto': 'https://randomuser.me/api/portraits/women/1.jpg'
            },
          ],
        },
      },
    ],
    '11/08': [
      {
        'evento': 'Culto Noite',
        'horario': '18:00',
        'funcoes': {
          'Louvor': [
            {
              'nome': 'Pedro',
              'funcao': 'Teclado',
              'foto': 'https://randomuser.me/api/portraits/men/2.jpg'
            },
            {
              'nome': 'Beatriz',
              'funcao': 'Vocal',
              'foto': 'https://randomuser.me/api/portraits/women/2.jpg'
            },
          ],
        },
      },
    ],
    '18/08': [
      {
        'evento': 'Santa Ceia (Manhã)',
        'horario': '09:00',
        'funcoes': {
          'Louvor': [
            {
              'nome': 'Lucas',
              'funcao': 'Violão',
              'foto': 'https://randomuser.me/api/portraits/men/3.jpg'
            },
            {
              'nome': 'João',
              'funcao': 'Voz principal',
              'foto': 'https://randomuser.me/api/portraits/men/1.jpg'
            },
          ],
        },
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    final dataSelecionada = datas[dataSelecionadaIndex];
    final eventos = escalasPorData[dataSelecionada] ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 Título e botão lado a lado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📆 Escalas do mês',
                style: context.textStyles.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.push('/leader/escalas-mensal');
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver todas',
                      style: context.textStyles.bodyLarge?.copyWith(
                        color: context.colors.onSurface,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: context.colors.onSurface),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          /// Datas das escalas
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: datas.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = index == dataSelecionadaIndex;
                return ChoiceChip(
                  label: Text(
                    datas[index],
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: isSelected
                          ? context.colors.onPrimary
                          : context.colors.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: context.colors.primary,
                  backgroundColor: context.colors.surface,
                  side: BorderSide(
                    color: isSelected
                        ? context.colors.primary
                        : context.colors.onSurface,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (_) {
                    setState(() => dataSelecionadaIndex = index);
                  },
                  checkmarkColor: context.colors.onPrimary,
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          /// Lista de eventos
          ...eventos.map((evento) {
            final nomeEvento = evento['evento'] ?? '';
            final horario = evento['horario'] ?? '';
            final funcoes =
                evento['funcoes'] as Map<String, List<Map<String, String>>>? ??
                    {};

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    '$nomeEvento – $horario',
                    style: context.textStyles.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...funcoes.entries.map((entry) {
                  final nomeFuncao = entry.key;
                  final voluntarios = entry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nomeFuncao,
                        style: context.textStyles.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: voluntarios.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            final v = voluntarios[i];
                            return Column(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage:
                                      NetworkImage(v['foto'] ?? ''),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  v['nome'] ?? '',
                                  style:
                                      context.textStyles.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.colors.onSurface,
                                  ),
                                ),
                                Text(
                                  v['funcao'] ?? '',
                                  style:
                                      context.textStyles.labelSmall?.copyWith(
                                    color: context.colors.onSurface,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }
}