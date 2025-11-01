import 'package:flutter/material.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/escalas/models/escala.dart';
import 'package:servus_app/features/leader/escalas/models/escala_status.dart';
import 'package:servus_app/features/leader/escalas/models/mes_agrupado.dart';
import 'package:servus_app/features/leader/escalas/repositories/escalas_repository.dart';
import 'package:servus_app/features/leader/escalas/services/filtro_service.dart';
import 'package:servus_app/features/leader/escalas/screens/escala/eventos_do_mes_page.dart';
import 'package:servus_app/features/leader/escalas/screens/escala/modal_publicacao.dart';
import 'package:servus_app/shared/widgets/fab_safe_scroll_view.dart';

class EscalasHomePage extends StatefulWidget {
  const EscalasHomePage({super.key});

  @override
  State<EscalasHomePage> createState() => _EscalasHomePageState();
}

class _EscalasHomePageState extends State<EscalasHomePage> {
  final EscalasRepository _repository = EscalasRepository();
  FiltroEscala _filtroAtual = FiltroEscala.todos;
  String? _selectedStatusFilter; // null = todos, 'rascunhos', 'publicados'
  Stream<List<Escala>>? _escalasStream;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _atualizarFiltro(_filtroAtual);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _atualizarFiltro(FiltroEscala filtro, {String? statusFilter}) {
    setState(() {
      _filtroAtual = filtro;
      if (statusFilter != null) {
        _selectedStatusFilter = statusFilter;
      }
      final (inicio, fim) = FiltroEscala.obterRangeFiltro(filtro);
      
      List<EscalaStatus>? statusList;
      if (_selectedStatusFilter != null) {
        switch (_selectedStatusFilter) {
          case 'rascunhos':
            // Rascunhos inclui tanto rascunhos quanto prontos (em edição)
            statusList = [EscalaStatus.rascunho, EscalaStatus.pronto];
            break;
          case 'publicados':
            statusList = [EscalaStatus.publicado];
            break;
        }
      }
      
      _escalasStream = _repository.buscarEscalasStream(
        dataInicio: inicio,
        dataFim: fim,
        status: statusList,
      );
    });
  }

  Future<void> _refreshEscalas() async {
    _atualizarFiltro(_filtroAtual, statusFilter: _selectedStatusFilter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Criar Escalas'),
        backgroundColor: Colors.transparent,
        foregroundColor: context.colors.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: [
          PopupMenuButton<FiltroEscala>(
            icon: Icon(Icons.filter_list, color: context.colors.onSurface),
            onSelected: (filtro) => _atualizarFiltro(filtro),
            itemBuilder: (context) {
              return FiltroEscala.values.map((filtro) {
                return PopupMenuItem<FiltroEscala>(
                  value: filtro,
                  child: Row(
                    children: [
                      if (_filtroAtual == filtro)
                        const Icon(Icons.check, size: 20)
                      else
                        const SizedBox(width: 20),
                      const SizedBox(width: 8),
                      Text(FiltroEscala.obterLabel(filtro)),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Escala>>(
        stream: _escalasStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 80,
                      color: context.colors.error,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Erro ao carregar escalas',
                      style: context.textStyles.headlineSmall?.copyWith(
                        color: context.colors.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${snapshot.error}',
                      style: context.textStyles.bodyLarge?.copyWith(
                        color: context.colors.onSurface.withOpacity(0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final escalas = snapshot.data ?? [];
          final meses = escalas.isNotEmpty ? MesAgrupado.agruparPorMes(escalas) : <MesAgrupado>[];
          final resumo = _calcularResumo(escalas);

          if (escalas.isEmpty) {
            return FabSafeScrollView(
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: [
                    _buildStatsCards(context, resumo),
                    const SizedBox(height: 32),
                    _buildEmptyState(context),
                  ],
                ),
              ),
            );
          }

          return FabSafeScrollView(
            controller: _scrollController,
            child: RefreshIndicator(
              onRefresh: _refreshEscalas,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsCards(context, resumo),
                    const SizedBox(height: 24),
                    if (meses.isNotEmpty)
                      ...meses.map((mes) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildCardMes(mes),
                          )),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: StreamBuilder<List<Escala>>(
        stream: _repository.buscarEscalasStream(
          status: [EscalaStatus.pronto],
        ),
        builder: (context, snapshot) {
          final escalasProntas = snapshot.data ?? [];
          final quantidade = escalasProntas.length;

          if (quantidade == 0) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: () => _mostrarModalPublicacao(context, escalasProntas),
            backgroundColor: Colors.green.shade700,
            icon: Badge(
              label: Text('$quantidade'),
              child: const Icon(Icons.publish),
            ),
            label: const Text('Publicar'),
          );
        },
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context, _ResumoEstatisticas resumo) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Rascunhos',
            resumo.rascunhos.toString(),
            Icons.edit,
            Colors.orange.shade700,
            'rascunhos',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'Publicados',
            resumo.publicados.toString(),
            Icons.send,
            Colors.blue.shade700,
            'publicados',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String filterType,
  ) {
    final isSelected = _selectedStatusFilter == filterType;

    return InkWell(
      onTap: () {
        final newFilter = isSelected ? null : filterType;
        _atualizarFiltro(_filtroAtual, statusFilter: newFilter);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : context.colors.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: context.textStyles.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 80,
            color: context.colors.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Nenhuma escala encontrada',
            style: context.textStyles.headlineSmall?.copyWith(
              color: context.colors.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _selectedStatusFilter != null
                ? 'Nenhuma escala corresponde ao filtro selecionado'
                : 'Filtre por período ou aguarde novos eventos',
            style: context.textStyles.bodyLarge?.copyWith(
              color: context.colors.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCardMes(MesAgrupado mes) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventosDoMesPage(mes: mes),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.colors.outline.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: context.colors.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.calendar_month,
                    color: context.colors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mes.nomeFormatado,
                        style: context.textStyles.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${mes.totalEventos} eventos',
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: context.colors.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: context.colors.onSurface.withOpacity(0.5),
                ),
              ],
            ),
            if (mes.pendentes > 0 || mes.prontos > 0) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (mes.rascunhos > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: EscalaStatus.rascunho.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: EscalaStatus.rascunho.color.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '${mes.rascunhos} rascunhos',
                        style: context.textStyles.bodySmall?.copyWith(
                          color: EscalaStatus.rascunho.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (mes.prontos > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: EscalaStatus.pronto.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: EscalaStatus.pronto.color.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '${mes.prontos} prontos',
                        style: context.textStyles.bodySmall?.copyWith(
                          color: EscalaStatus.pronto.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (mes.publicados > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: EscalaStatus.publicado.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: EscalaStatus.publicado.color.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '${mes.publicados} publicados',
                        style: context.textStyles.bodySmall?.copyWith(
                          color: EscalaStatus.publicado.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  _ResumoEstatisticas _calcularResumo(List<Escala> escalas) {
    int rascunhos = 0;
    int publicados = 0;

    for (final escala in escalas) {
      switch (escala.status) {
        case EscalaStatus.rascunho:
        case EscalaStatus.pronto: // "Prontos" também são considerados rascunhos (em edição)
          rascunhos++;
          break;
        case EscalaStatus.publicado:
          publicados++;
          break;
      }
    }

    return _ResumoEstatisticas(
      rascunhos: rascunhos,
      publicados: publicados,
    );
  }

  void _mostrarModalPublicacao(BuildContext context, List<Escala> escalasProntas) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalPublicacao(
        escalas: escalasProntas,
        repository: _repository,
      ),
    );
  }
}

class _ResumoEstatisticas {
  final int rascunhos;
  final int publicados;

  _ResumoEstatisticas({
    required this.rascunhos,
    required this.publicados,
  });
}
