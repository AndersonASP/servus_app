import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/escalas/models/escala.dart';
import 'package:servus_app/features/leader/escalas/models/escala_status.dart';
import 'package:servus_app/features/leader/escalas/models/funcao_preenchida.dart';
import 'package:servus_app/features/leader/escalas/models/mes_agrupado.dart';
import 'package:servus_app/features/leader/escalas/repositories/escalas_repository.dart';

class EventosDoMesPage extends StatefulWidget {
  final MesAgrupado mes;
  const EventosDoMesPage({super.key, required this.mes});

  @override
  State<EventosDoMesPage> createState() => _EventosDoMesPageState();
}

class _EventosDoMesPageState extends State<EventosDoMesPage> {
  final PageController _pageController = PageController();
  final EscalasRepository repository = EscalasRepository();

  int currentPage = 0;
  Timer? _debounceTimer;
  bool _salvando = false;

  List<Escala> get escalas => widget.mes.escalas;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onFuncaoChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () async {
      await _salvarRascunhoAutomatico();
    });
  }

  Future<void> _salvarRascunhoAutomatico() async {
    setState(() => _salvando = true);
    try {
      await repository.salvarRascunho(escalas[currentPage]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Rascunho salvo'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = escalas.length;
    final prontos = escalas.where((e) => e.status == EscalaStatus.pronto).length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.mes.nomeFormatado),
            Text(
              'Evento ${currentPage + 1} de $total',
              style: context.textStyles.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          if (_salvando)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          IconButton(
            tooltip: 'Lista de eventos',
            icon: const Icon(Icons.list),
            onPressed: _mostrarListaEventos,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de progresso do mês
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Progresso do Mês', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('$prontos/$total prontos', style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: total == 0 ? 0 : prontos / total,
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) {
                setState(() => currentPage = i);
                _onFuncaoChanged();
              },
              itemCount: escalas.length,
              itemBuilder: (context, index) => _buildEventoPage(escalas[index]),
            ),
          ),
          _buildRodapeAcoes(),
        ],
      ),
    );
  }

  Widget _buildEventoPage(Escala escala) {
    final preenchidas = escala.funcoesPreenchidas;
    final total = escala.totalFuncoes;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do evento
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(escala.eventoNome, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${escala.eventoData.day.toString().padLeft(2, '0')}/${escala.eventoData.month.toString().padLeft(2, '0')}/${escala.eventoData.year} ${escala.eventoData.hour.toString().padLeft(2, '0')}:${escala.eventoData.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const Spacer(),
                    _buildStatusChip(escala.status),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: Text('$preenchidas/$total preenchidas'),
                      visualDensity: VisualDensity.compact,
                    ),
                    if (escala.temTemplate)
                      const Chip(
                        label: Text('Template'),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: escala.percentualCompleto),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Lista de funções
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: escala.funcoes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, idx) => _buildCardFuncao(escala, idx),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFuncao(Escala escala, int index) {
    final f = escala.funcoes[index];
    final preenchida = f.preenchida;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _selecionarVoluntario(escala, index),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: preenchida ? Colors.green : Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Icon(
                preenchida ? Icons.check : Icons.search,
                color: preenchida ? Colors.green[700] : Colors.blue[700],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    f.funcaoNome,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    f.voluntarioNome ?? 'Selecionar voluntário',
                    style: TextStyle(
                      color: f.voluntarioNome == null ? Colors.grey[600] : Colors.black87,
                      fontStyle: f.voluntarioNome == null ? FontStyle.italic : FontStyle.normal,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(EscalaStatus status) {
    return Chip(
      label: Text(status.label),
      backgroundColor: status.color.withOpacity(0.1),
      labelStyle: TextStyle(color: status.color),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildRodapeAcoes() {
    final escala = escalas[currentPage];
    final isPrimeiro = currentPage == 0;
    final isUltimo = currentPage == escalas.length - 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (!isPrimeiro)
                OutlinedButton(
                  onPressed: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: const Text('Anterior'),
                ),
              const Spacer(),
              ..._buildMainActionButton(escala, isUltimo),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMainActionButton(Escala escala, bool isUltimo) {
    if (escala.status == EscalaStatus.pronto) {
      return [
        OutlinedButton.icon(
          onPressed: () async {
            final atualizada = escala.copyWith(status: EscalaStatus.rascunho);
            widget.mes.escalas[currentPage] = atualizada;
            setState(() {});
            await repository.salvarRascunho(atualizada);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Marcado para edição')),
            );
          },
          icon: const Icon(Icons.edit),
          label: const Text('Editar Novamente'),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.orange[700]),
        ),
      ];
    }

    if (escala.completa) {
      return [
        ElevatedButton.icon(
          onPressed: () async {
            HapticFeedback.mediumImpact();
            final atualizada = escala.copyWith(status: EscalaStatus.pronto);
            widget.mes.escalas[currentPage] = atualizada;
            setState(() {});
            await repository.salvarRascunho(atualizada);
            if (!mounted) return;
            if (isUltimo) {
              _mostrarModalPublicacao();
            } else {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
          icon: const Icon(Icons.check_circle),
          label: const Text('Marcar como Pronto ✓'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
        ),
      ];
    }

    return [
      OutlinedButton(
        onPressed: () {
          if (currentPage < escalas.length - 1) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        },
        child: const Text('Pular Evento'),
      ),
      const SizedBox(width: 8),
      IconButton(
        tooltip: 'Ver o que falta',
        icon: const Icon(Icons.info_outline),
        onPressed: _mostrarFaltantes,
      ),
    ];
  }

  void _mostrarFaltantes() {
    final escala = escalas[currentPage];
    final faltantes = <String>[];
    for (final f in escala.funcoes) {
      if (!f.preenchida) faltantes.add(f.funcaoNome);
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Falta preencher'),
        content: Text(faltantes.isEmpty ? 'Tudo preenchido' : faltantes.join('\n')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _selecionarVoluntario(Escala escala, int index) async {
    // Integração: usar sua tela de seleção atual via Navigator
    // final voluntario = await Navigator.push(...)
    // Para mock: setar um voluntário fictício
    final mockVoluntarioId = 'user_123';
    final mockVoluntarioNome = 'Voluntário Exemplo';

    setState(() {
      final atual = escala.funcoes[index];
      escala.funcoes[index] = FuncaoPreenchida(
        funcaoId: atual.funcaoId,
        funcaoNome: atual.funcaoNome,
        voluntarioId: mockVoluntarioId,
        voluntarioNome: mockVoluntarioNome,
      );
    });
    _onFuncaoChanged();
  }

  void _mostrarListaEventos() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                controller: scrollController,
                itemCount: escalas.length,
                itemBuilder: (_, i) {
                  final e = escalas[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: const Icon(Icons.event, color: Colors.blue),
                    ),
                    title: Text(e.eventoNome),
                    subtitle: Text('${e.funcoesPreenchidas}/${e.totalFuncoes} preenchidas'),
                    trailing: _buildStatusChip(e.status),
                    onTap: () {
                      Navigator.of(context).pop();
                      _pageController.jumpToPage(i);
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarModalPublicacao() {
    // Esta tela abre a partir da Home; aqui só chamamos a Home novamente para publicar
    Navigator.of(context).pop();
  }
}
