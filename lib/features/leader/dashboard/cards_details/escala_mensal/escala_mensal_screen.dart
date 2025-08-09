import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/dashboard/cards_details/escala_mensal/escala_mensal_controller.dart';

class EscalaMensalScreen extends StatefulWidget {
  const EscalaMensalScreen({super.key});

  @override
  State<EscalaMensalScreen> createState() => _EscalaMensalScreenState();
}

class _EscalaMensalScreenState extends State<EscalaMensalScreen> {
  int eventoSelecionadoIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _chipKeys = [];

  @override
  void initState() {
    super.initState();

    final controller = context.read<EscalaMensalController>();
    final totalChips = controller.escalasPorData.entries
        .expand((e) => e.value)
        .length;

    _chipKeys.addAll(List.generate(totalChips, (_) => GlobalKey()));
  }

  void _scrollToChip(int index) {
    final keyContext = _chipKeys[index].currentContext;
    if (keyContext != null) {
      Scrollable.ensureVisible(
        keyContext,
        duration: const Duration(milliseconds: 300),
        alignment: 0.3,
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EscalaMensalController>();
    final todasDatas = controller.escalasPorData.entries.toList();

    final eventosCompletos = todasDatas.expand((entry) {
      final data = entry.key;
      final eventos = entry.value;
      return eventos.map((evento) => {
            'data': data,
            'evento': evento['evento'],
            'horario': evento['horario'],
            'voluntarios': evento['voluntarios'],
          });
    }).toList();

    final eventoAtual = eventosCompletos[eventoSelecionadoIndex];
    final voluntarios = eventoAtual['voluntarios'] as List;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        title: Text(
          'Escalas do mês',
          style: context.textStyles.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colors.onSurface,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ChoiceChip com scroll automático
          SizedBox(
            height: 70,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: eventosCompletos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = eventosCompletos[index];
                final isSelected = index == eventoSelecionadoIndex;
                return Container(
                  key: _chipKeys[index],
                  child: ChoiceChip(
                    label: Text(
                      '${item['data']} – ${item['evento']} – ${item['horario']}',
                      style: TextStyle(
                        color: isSelected
                            ? context.colors.onPrimary
                            : context.colors.onSurface,
                      ),
                    ),
                    checkmarkColor: context.colors.onPrimary,
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => eventoSelecionadoIndex = index);
                      _scrollToChip(index);
                    },
                    selectedColor: context.colors.primary,
                    backgroundColor: context.colors.surface,
                    side: BorderSide(
                      color: isSelected
                          ? context.colors.primary
                          : context.colors.outline,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: voluntarios.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final v = voluntarios[index];
                final nome = v['nome'] ?? '';
                final funcao = v['funcao'] ?? '';
                final imagem = v['foto'] ?? '';
                final confirmado = v['confirmado'] ?? true;

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(imagem),
                      radius: 25,
                    ),
                    title: Text(
                      nome,
                      style: context.textStyles.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      funcao,
                      style: context.textStyles.bodyMedium,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 6),
                            Icon(
                              confirmado ? Icons.check_circle : Icons.cancel,
                              size: 18,
                              color: confirmado ? Colors.green : Colors.red,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          confirmado ? 'Confirmado' : 'Pendente',
                          style: context.textStyles.labelMedium?.copyWith(
                            color: confirmado ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}