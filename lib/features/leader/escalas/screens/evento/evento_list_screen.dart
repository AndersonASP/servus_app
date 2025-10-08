import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/core/models/event_instance.dart';
import 'package:servus_app/features/leader/escalas/controllers/evento/evento_controller.dart';
import 'package:servus_app/features/leader/escalas/models/evento_model.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'evento_form_screen.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;

class EventoListScreen extends StatefulWidget {
  const EventoListScreen({super.key});

  @override
  State<EventoListScreen> createState() => _EventoListScreenState();
}

class _EventoListScreenState extends State<EventoListScreen> {
  final ScrollController _scrollController = ScrollController();
  
  // Variáveis do calendário
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  // Cache de eventos por mês
  Map<DateTime, List<EventoModel>> _eventsByMonth = {};
  
  // Cache de instâncias de recorrências por mês
  Map<String, List<EventInstanceModel>> _recurrencesByMonth = {};
  
  // Estado de carregamento das recorrências
  bool _isLoadingRecurrences = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _selectedDay = DateTime.now();
    // Inicializar localização para português
    initializeDateFormatting('pt_BR', null);
    // carregar eventos na abertura da tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<EventoController>();
      controller.carregarEventos();
      // Carregar recorrências para o mês atual
      _loadEventsForMonth(_focusedDay, controller);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Implementar paginação se necessário
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EventoController>(
      builder: (context, controller, _) {

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/leader/dashboard'),
            ),
            title: Text('Eventos', style: context.textStyles.titleLarge?.copyWith(
              color: context.colors.onSurface,
            ),),
            backgroundColor: Colors.transparent,
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => controller.carregarEventos(),
                tooltip: 'Recarregar',
              ),
            ],
          ),
          body: Column(
            children: [
              // Calendário fixo
              Stack(
                children: [
                  _buildCalendar(controller),
                  if (_isLoadingRecurrences)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.colors.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Lista de eventos com scroll
              Expanded(
                child: _buildEventsList(controller),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EventoFormScreen(),
                ),
              );
              controller.carregarEventos();
            },
            icon: const Icon(Icons.add),
            label: Text('Novo Evento', style: context.textStyles.bodyLarge?.copyWith(
              color: context.colors.onPrimary,
              fontWeight: FontWeight.bold,
            ),),
          ),
        );
      },
    );
  }

  Widget _buildCalendar(EventoController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TableCalendar<EventoModel>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        locale: 'pt_BR',
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: TextStyle(
            color: context.colors.onSurface.withValues(alpha: 0.6),
          ),
          defaultTextStyle: TextStyle(
            color: context.colors.onSurface,
          ),
          selectedTextStyle: TextStyle(
            color: context.colors.onPrimary,
            fontWeight: FontWeight.bold,
          ),
          todayTextStyle: TextStyle(
            color: context.colors.primary,
            fontWeight: FontWeight.bold,
          ),
          selectedDecoration: BoxDecoration(
            color: context.colors.primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: context.colors.primary.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: context.colors.secondary,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: context.textStyles.titleLarge?.copyWith(
            color: context.colors.onSurface,
            fontWeight: FontWeight.bold,
          ) ?? TextStyle(
            color: context.colors.onSurface,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: context.colors.onSurface,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: context.colors.onSurface,
          ),
        ),
        onDaySelected: _onDaySelected,
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() {
              _calendarFormat = format;
            });
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          _loadEventsForMonth(focusedDay, controller);
        },
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
      ),
    );
  }

  Widget _buildEventsList(EventoController controller) {
    if (controller.isLoading && controller.todos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Filtrar eventos pela data selecionada
    final eventosDoDia = _selectedDay != null 
        ? _getEventsForDay(_selectedDay!)
        : <EventoModel>[];

    if (eventosDoDia.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum evento neste dia',
              style: context.textStyles.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecione outro dia ou crie um novo evento.',
              style: context.textStyles.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.carregarEventos(),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: eventosDoDia.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final evento = eventosDoDia[index];
          return _buildEventCard(evento, controller);
        },
      ),
    );
  }

  Widget _buildEventCard(EventoModel evento, EventoController controller) {
    return GestureDetector(
      onTap: () => _editEvent(evento),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Texto de data no topo
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _formatFullDateTime(evento.dataHora),
                  style: context.textStyles.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: context.colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            // Conteúdo principal
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          evento.nome,
                          style: context.textStyles.bodyLarge?.copyWith(
                            fontSize: 20,
                            color: context.colors.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      // Ícone de recorrência se aplicável
                      if (evento.recorrente)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.repeat,
                            size: 16,
                            color: Colors.orange,
                          ),
                        ),
                      const SizedBox(width: 8),
                      // Menu de opções
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _editEvent(evento);
                              break;
                            case 'delete':
                              _showDeleteEventDialog(evento, controller);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Editar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Excluir', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.more_vert,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Métodos do calendário
  List<EventoModel> _getEventsForDay(DateTime day) {
    developer.log('🎯 [_getEventsForDay] CHAMADO PELO CALENDÁRIO para: ${day.toIso8601String()}', name: 'EventoListScreen');
    
    final controller = context.read<EventoController>();
    final eventosDoDia = controller.todos.where((evento) {
      return isSameDay(evento.dataHora, day);
    }).toList();
    
    // Adicionar recorrências para este dia
    final monthString = '${day.year}-${day.month.toString().padLeft(2, '0')}';
    final recurrences = _recurrencesByMonth[monthString] ?? [];
    
    developer.log('🔍 [_getEventsForDay] Buscando eventos para: ${day.toIso8601String()}', name: 'EventoListScreen');
    developer.log('🔍 [_getEventsForDay] Eventos normais encontrados: ${eventosDoDia.length}', name: 'EventoListScreen');
    developer.log('🔍 [_getEventsForDay] Recorrências disponíveis: ${recurrences.length}', name: 'EventoListScreen');
    developer.log('🔍 [_getEventsForDay] Cache de recorrências: ${_recurrencesByMonth.keys}', name: 'EventoListScreen');
    
    for (final recurrence in recurrences) {
      developer.log('🔍 [_getEventsForDay] Verificando recorrência: ${recurrence.instanceDate.toIso8601String()}', name: 'EventoListScreen');
      if (isSameDay(recurrence.instanceDate, day)) {
        developer.log('✅ [_getEventsForDay] Recorrência encontrada para este dia: ${recurrence.instanceDate.toIso8601String()}', name: 'EventoListScreen');
        
        // Verificar se já existe um evento normal para este dia com o mesmo eventId
        final jaExisteEventoNormal = eventosDoDia.any((evento) => evento.id == recurrence.eventId);
        
        if (jaExisteEventoNormal) {
          developer.log('⚠️ [_getEventsForDay] Evento original já existe para este dia, pulando recorrência', name: 'EventoListScreen');
          continue;
        }
        
        // Buscar o evento original para obter os dados completos
        final eventoOriginal = controller.todos.firstWhere(
          (evento) => evento.id == recurrence.eventId,
          orElse: () => EventoModel(
            id: recurrence.eventId,
            nome: 'Evento não encontrado',
            dataHora: recurrence.instanceDate,
            ministerioId: '',
            isOrdinary: false,
            recorrente: true,
            tipoRecorrencia: RecorrenciaTipo.semanal,
          ),
        );
        
        // Converter EventInstanceModel para EventoModel para exibição
        final eventoRecorrente = EventoModel(
          id: '${recurrence.eventId}_${recurrence.instanceDate.millisecondsSinceEpoch}',
          nome: eventoOriginal.nome,
          dataHora: recurrence.instanceDate,
          ministerioId: eventoOriginal.ministerioId,
          isOrdinary: eventoOriginal.isOrdinary,
          recorrente: true,
          tipoRecorrencia: eventoOriginal.tipoRecorrencia,
          diaSemana: eventoOriginal.diaSemana,
          semanaDoMes: eventoOriginal.semanaDoMes,
          observacoes: eventoOriginal.observacoes,
        );
        eventosDoDia.add(eventoRecorrente);
        developer.log('✅ [_getEventsForDay] Evento recorrente adicionado: ${eventoRecorrente.nome}', name: 'EventoListScreen');
      }
    }
    
    developer.log('📊 [_getEventsForDay] Total de eventos para este dia: ${eventosDoDia.length}', name: 'EventoListScreen');
    return eventosDoDia;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  void _loadEventsForMonth(DateTime focusedDay, EventoController controller) async {
    final monthKey = DateTime(focusedDay.year, focusedDay.month);
    final monthString = '${focusedDay.year}-${focusedDay.month.toString().padLeft(2, '0')}';
    
    developer.log('🔄 [_loadEventsForMonth] Carregando eventos para: $monthString', name: 'EventoListScreen');
    developer.log('🔄 [_loadEventsForMonth] MonthKey: $monthKey', name: 'EventoListScreen');
    developer.log('🔄 [_loadEventsForMonth] Já tem eventos? ${_eventsByMonth.containsKey(monthKey)}', name: 'EventoListScreen');
    developer.log('🔄 [_loadEventsForMonth] Já tem recorrências? ${_recurrencesByMonth.containsKey(monthString)}', name: 'EventoListScreen');
    
    // Se já temos os eventos para este mês, não precisa carregar novamente
    if (_eventsByMonth.containsKey(monthKey) && _recurrencesByMonth.containsKey(monthString)) {
      developer.log('✅ [_loadEventsForMonth] Eventos já carregados para este mês', name: 'EventoListScreen');
      return;
    }
    
    // Carregar recorrências para o mês
    if (!_recurrencesByMonth.containsKey(monthString)) {
      developer.log('🔄 [_loadEventsForMonth] Carregando recorrências para $monthString', name: 'EventoListScreen');
      setState(() {
        _isLoadingRecurrences = true;
      });
      
      try {
        final recurrences = await controller.carregarRecorrencias(
          monthNumber: focusedDay.month,
          year: focusedDay.year,
        );
        
        developer.log('✅ [_loadEventsForMonth] Recorrências carregadas: ${recurrences.length}', name: 'EventoListScreen');
        for (final recurrence in recurrences) {
          developer.log('📅 [_loadEventsForMonth] Instância: ${recurrence.instanceDate.toIso8601String()}', name: 'EventoListScreen');
        }
        
        setState(() {
          _recurrencesByMonth[monthString] = recurrences;
          _isLoadingRecurrences = false;
        });
        
        developer.log('✅ [_loadEventsForMonth] Recorrências salvas no cache', name: 'EventoListScreen');
      } catch (e) {
        developer.log('❌ [_loadEventsForMonth] Erro ao carregar recorrências: $e', name: 'EventoListScreen');
        setState(() {
          _isLoadingRecurrences = false;
        });
        // Log do erro mas não quebra a UI
        print('Erro ao carregar recorrências: $e');
      }
    }
  }

  // Formatar data completa
  String _formatFullDateTime(DateTime dateTime) {
    const days = [
      'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'
    ];
    const months = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
    ];
    
    final dayName = days[dateTime.weekday - 1];
    final day = dateTime.day.toString().padLeft(2, '0');
    final monthName = months[dateTime.month - 1];
    final hour = dateTime.hour.toString().padLeft(2, '0');
    
    return '$dayName, $day de $monthName às ${hour}h';
  }


  // Editar evento
  void _editEvent(EventoModel evento) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventoFormScreen(
          eventoExistente: evento,
        ),
      ),
    );
    // refrescar ao voltar
    final controller = context.read<EventoController>();
    controller.carregarEventos();
  }

  // Mostrar dialog de confirmação de exclusão
  void _showDeleteEventDialog(EventoModel evento, EventoController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Excluir Evento',
                style: context.textStyles.titleLarge?.copyWith(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Você está prestes a excluir o evento:',
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          evento.nome,
                          style: context.textStyles.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.red.shade600, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${evento.dataHora.day.toString().padLeft(2, '0')}/${evento.dataHora.month.toString().padLeft(2, '0')} às ${evento.dataHora.hour.toString().padLeft(2, '0')}:${evento.dataHora.minute.toString().padLeft(2, '0')}',
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Atenção:',
                        style: context.textStyles.bodySmall?.copyWith(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Esta ação não pode ser desfeita.',
                    style: context.textStyles.bodySmall?.copyWith(
                      color: Colors.orange.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: context.colors.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _confirmDeleteEvent(context, evento, controller),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  // Confirmar exclusão do evento (com opções para recorrentes)
  Future<void> _confirmDeleteEvent(BuildContext context, EventoModel evento, EventoController controller) async {
    final pageContext = this.context; // usar o contexto da página, não o do diálogo
    final navigator = Navigator.of(pageContext, rootNavigator: true);
    // Extrair id real do evento (quando vem de recorrência no calendário, id pode ser `${eventId}_${ts}`)
    final String realEventId = evento.id.contains('_') ? evento.id.split('_').first : evento.id;
    
    // Fechar dialog de confirmação
    navigator.pop();
    
    // Se não recorrente: excluir direto
    if (!evento.recorrente) {
      if (!mounted) return;
      showDialog(
        context: pageContext,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Excluindo evento...',
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      );
      try {
        await controller.removerEvento(realEventId);
        // Recarregar recorrências do mês do evento
        try {
          final ed = evento.dataHora.toUtc();
          await controller.carregarRecorrencias(monthNumber: ed.month, year: ed.year);
        } catch (_) {}
        if (mounted) navigator.pop();
        if (mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
            SnackBar(
              content: Text('${evento.nome} foi excluído com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) navigator.pop();
        if (mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir evento: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    // Se recorrente: perguntar o que fazer
    final escolha = await showDialog<String>(
      context: pageContext,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: Text('Excluir recorrência', style: context.textStyles.titleMedium),
        content: Text('Você deseja excluir apenas esta ocorrência, todas as futuras, ou toda a série?', style: context.textStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('one'),
            child: const Text('Somente esta'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('future'),
            child: const Text('Esta e futuras'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('all'),
            child: const Text('Toda a série'),
          ),
        ],
      ),
    );

    if (escolha == null || escolha == 'cancel') return;

    if (!mounted) return;
    showDialog(
      context: pageContext,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Aplicando exclusão...',
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      if (escolha == 'one') {
        // Pular somente esta ocorrência (usa a data do próprio evento como instância-base)
        await controller.pularOcorrencia(eventId: realEventId, instanceDate: evento.dataHora.toUtc());
      } else if (escolha == 'future') {
        // Encerrar série a partir desta data (inclui a data)
        await controller.encerrarSerieApos(eventId: realEventId, fromDate: evento.dataHora.toUtc());
      } else if (escolha == 'all') {
        // Excluir evento inteiro
        await controller.removerEvento(realEventId);
      }

      // Recarregar recorrências do mês do evento para refletir alterações
      final ed = evento.dataHora.toUtc();
      final monthNumber = ed.month;
      final year = ed.year;
      try {
        await controller.carregarRecorrencias(monthNumber: monthNumber, year: year);
      } catch (_) {
        // ignore refresh errors silently
      }

      if (mounted) navigator.pop();
      if (mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          SnackBar(
            content: Text('Exclusão aplicada com sucesso.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) navigator.pop();
      if (mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          SnackBar(
            content: Text('Erro ao aplicar exclusão: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}