import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/escalas/controllers/evento/evento_controller.dart';
import 'package:servus_app/features/leader/escalas/controllers/template/template_controller.dart';
import 'package:servus_app/features/leader/escalas/controllers/escala/escala_controller.dart';
import 'package:servus_app/features/leader/escalas/models/evento_model.dart';
import 'package:servus_app/features/leader/escalas/models/template_model.dart';
import 'package:servus_app/features/ministries/services/ministry_functions_service.dart';
import 'package:servus_app/features/ministries/services/member_function_service.dart';
import 'package:servus_app/features/ministries/models/member_function.dart';
import 'package:dio/dio.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:servus_app/widgets/soft_divider.dart';
import 'package:servus_app/widgets/header_section.dart';
import 'dart:developer' as developer;

class EscalaMatrixScreen extends StatefulWidget {
  const EscalaMatrixScreen({super.key});

  @override
  State<EscalaMatrixScreen> createState() => _EscalaMatrixScreenState();
}

class _EscalaMatrixScreenState extends State<EscalaMatrixScreen> {
  final PageController _pageController = PageController();
  final MinistryFunctionsService _functionsService = MinistryFunctionsService();
  final MemberFunctionService _memberFunctionService = MemberFunctionService();
  final Dio _dio = DioClient.instance;

  bool _loading = true;
  List<EventoModel> _eventos = [];
  String? _currentMinistryId; // ministry em uso para geração/listagem de funções/voluntários

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final eventoController = context.read<EventoController>();
    final templateController = context.read<TemplateController>();
    final escalaController = context.read<EscalaController>();

    try {
      await Future.wait([
        eventoController.carregarEventos(),
        templateController.refreshTemplates(),
      ]);

      final hoje = DateTime.now();
      // Incluir eventos futuros (desde hoje até 6 meses à frente)
      final fimDoPeriodo = DateTime(hoje.year, hoje.month + 6, 0);
      final eventosMes = eventoController.todos.where((e) =>
        e.dataHora.isAfter(hoje.subtract(const Duration(days: 1))) &&
        e.dataHora.isBefore(fimDoPeriodo.add(const Duration(days: 1)))
      ).toList();
      
      developer.log('📋 Eventos encontrados: ${eventosMes.length} de ${eventoController.todos.length} total', name: 'EscalaMatrixScreen');

      if (eventosMes.isEmpty) {
        setState(() {
          _eventos = [];
          _loading = false;
        });
        return;
      }

      escalaController.setEventos(eventosMes);
      await _prepareTemplateForEvent(eventosMes.first);

      setState(() {
        _eventos = eventosMes;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _prepareTemplateForEvent(EventoModel evento) async {
    final templateController = context.read<TemplateController>();
    final escalaController = context.read<EscalaController>();

    TemplateModel? template;
    if (evento.templateId != null && evento.templateId!.isNotEmpty) {
      try {
        template = templateController.todos.firstWhere((t) => t.id == evento.templateId);
      } catch (_) {}
    }

    // Determinar ministryId base
    String ministryId = evento.ministerioId;
    if ((ministryId.isEmpty || ministryId == '') && template != null && template.funcoes.isNotEmpty) {
      ministryId = template.funcoes.first.ministerioId;
    }
    if (ministryId.isEmpty || ministryId == '') {
      // Tentar resolver a partir das memberships do líder
      final resolved = await _resolveLeaderMinistryId();
      if (resolved != null && resolved.isNotEmpty) {
        ministryId = resolved;
      }
    }
    _currentMinistryId = ministryId;

    if (template == null) {
      // Pseudo-template: 1 por função do ministério
      try {
        if (ministryId.isEmpty) {
          // Sem ministryId não é possível montar pseudo-template
          escalaController.setTemplate(TemplateModel(nome: 'Escala', funcoes: []));
          return;
        }
        final funcoes = await _functionsService.getMinistryFunctions(ministryId);
        final funcoesTemplate = funcoes.map((f) => FuncaoEscala(
          id: f.functionId, // usar o ID real da função no backend
          nome: f.name,
          ministerioId: ministryId,
          quantidade: 1,
        )).toList();
        template = TemplateModel(nome: 'Escala Livre (auto)', funcoes: funcoesTemplate);
      } catch (_) {
        template = TemplateModel(nome: 'Escala', funcoes: []);
      }
    }

    escalaController.setTemplate(template);
  }

  String _inferMinistryIdFromTemplate(TemplateModel? t) {
    if (_currentMinistryId != null && _currentMinistryId!.isNotEmpty) return _currentMinistryId!;
    if (t == null || t.funcoes.isEmpty) return '';
    return t.funcoes.first.ministerioId;
  }

  Future<String?> _resolveLeaderMinistryId() async {
    try {
      final resp = await _dio.get('/ministry-memberships/me');
      final memberships = (resp.data as List<dynamic>? ?? []);
      final active = memberships
          .where((m) => m['isActive'] == true && m['ministry'] != null)
          .toList();
      if (active.isEmpty) return null;
      if (active.length == 1) {
        return active.first['ministry']['_id']?.toString();
      }
      // múltiplos ministérios: pedir escolha
      final chosen = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) {
          return SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (_, i) {
                final m = active[i];
                final id = m['ministry']['_id']?.toString() ?? '';
                final name = m['ministry']['name']?.toString() ?? 'Ministério';
                return ListTile(
                  leading: const Icon(Icons.church),
                  title: Text(name),
                  onTap: () => Navigator.of(ctx).pop(id),
                );
              },
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemCount: active.length,
            ),
          );
        },
      );
      return chosen;
    } catch (_) {
      return null;
    }
  }

  Future<void> _goTo(int index) async {
    if (index < 0 || index >= _eventos.length) return;
    final currentIndex = context.read<EscalaController>().selectedEventIndex;
    if (index == currentIndex) return;
    
    // Animar a transição com efeito de swipe
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
    
    final escalaController = context.read<EscalaController>();
    escalaController.selecionarEvento(index);
    await _prepareTemplateForEvent(_eventos[index]);
    if (mounted) setState(() {});
  }

  Future<void> _goPrev() async {
    final prev = (context.read<EscalaController>().selectedEventIndex - 1)
        .clamp(0, _eventos.length - 1);
    await _goTo(prev);
  }

  Future<void> _goNext() async {
    final next = (context.read<EscalaController>().selectedEventIndex + 1)
        .clamp(0, _eventos.length - 1);
    await _goTo(next);
  }

  Future<MemberFunction?> _pickVolunteer({
    required String ministryId,
    required String functionId,
  }) async {
    List<MemberFunction> options = [];
    try {
      options = await _memberFunctionService.getApprovedMembersByFunction(
        ministryId: ministryId,
        functionId: functionId,
      );
    } catch (_) {}

    return showModalBottomSheet<MemberFunction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateSheet) {
            List<MemberFunction> filtered = options;
            void updateFilter(String q) {
              filtered = options
                  .where((m) => (m.user?.name ?? '').toLowerCase().contains(q.toLowerCase()))
                  .toList();
              setStateSheet(() {});
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                child: DraggableScrollableSheet(
                  initialChildSize: 0.6,
                  minChildSize: 0.4,
                  maxChildSize: 0.95,
                  expand: false,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Handle e cabeçalho
                          Container(
                            height: 4,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                            margin: const EdgeInsets.only(bottom: 16),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Selecionar Voluntário',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: context.colors.onSurface,
                                      ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Fechar',
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.of(ctx).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Campo de busca
                          TextField(
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Buscar voluntário pelo nome',
                              hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
                              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                              filled: true,
                              fillColor: Colors.grey[100],
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                              ),
                            ),
                            onChanged: updateFilter,
                          ),
                          const SizedBox(height: 12),
                          // Lista / estados
                          Expanded(
                            child: filtered.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
                                        const SizedBox(height: 8),
                                        Text('Nenhum voluntário encontrado', style: Theme.of(context).textTheme.bodyMedium),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    controller: scrollController,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: filtered.length,
                                    itemBuilder: (_, i) {
                                      final m = filtered[i];
                                      final name = m.user?.name ?? 'Sem nome';
                                      return Semantics(
                                        button: true,
                                        label: 'Selecionar voluntário $name',
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.grey[200]!),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(12),
                                              onTap: () => Navigator.of(ctx).pop(m),
                                              child: Padding(
                                                padding: const EdgeInsets.all(12),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 24,
                                                      backgroundColor: Colors.blue.withOpacity(0.1),
                                                      child: Icon(Icons.person, color: Colors.blue[700], size: 24),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            name,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                                  fontSize: 16,
                                                                  fontWeight: FontWeight.w500,
                                                                  color: Colors.black87,
                                                                ),
                                                          ),
                                                          
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final escalaController = context.watch<EscalaController>();
    final slots = escalaController.slots;
    final selected = escalaController.selectedEvent;
    final eventos = _eventos;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : eventos.isEmpty
                ? Center(
                    child: Text('Nenhum evento disponível para o período', style: context.textStyles.bodyMedium),
                  )
                : Column(
                    children: [
                      // Cabeçalho
              HeaderSection(
                leading: IconButton(
                  onPressed: _goPrev,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Evento anterior',
                ),
                title: Text(
                  selected?.nome ?? 'Evento',
                  style: context.textStyles.titleLarge?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: context.colors.onSurface,
                  ),
                ),
                subtitle: selected == null
                    ? null
                    : Text(
                        '${selected.dataHora.day.toString().padLeft(2, '0')}/${selected.dataHora.month.toString().padLeft(2, '0')} ${selected.dataHora.hour.toString().padLeft(2, '0')}:${selected.dataHora.minute.toString().padLeft(2, '0')}',
                        style: context.textStyles.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                trailing: IconButton(
                  onPressed: _goNext,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Próximo evento',
                ),
              ),
                      const SoftDivider(),
                      // Linha de chips
                      
                      // Corpo
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (i) async {
                            escalaController.selecionarEvento(i);
                            await _prepareTemplateForEvent(eventos[i]);
                            setState(() {});
                          },
                          itemCount: eventos.length,
                          itemBuilder: (ctx, pageIndex) {
                            final ministryId = _inferMinistryIdFromTemplate(escalaController.templateSelecionado);
                            // Tabela: cabeçalho + linhas em cartões e card-resumo
                            return Column(
                              children: [
                                // Cabeçalho da tabela
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: Text(
                                          'Função',
                                          style: context.textStyles.labelSmall?.copyWith(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 4,
                                        child: Text(
                                          'Voluntário',
                                          textAlign: TextAlign.right,
                                          style: context.textStyles.labelSmall?.copyWith(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Linhas
                                Expanded(
                                  child: ListView.separated(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                    itemCount: slots.length + 1,
                                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                                    itemBuilder: (_, i) {
                                      if (i == slots.length) {
                                        return null;
                                      }
                                      final s = slots[i];
                                      final assignedUserId = escalaController.getAssignmentFor(eventos[pageIndex].id, s.functionId, s.slotIndex);
                                      final volunteerName = assignedUserId != null
                                          ? (escalaController.getVolunteerName(assignedUserId) ?? assignedUserId)
                                          : null;
                                      return InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () {},
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          curve: Curves.easeOut,
                                          padding: const EdgeInsets.all(16),
                                          constraints: const BoxConstraints(minHeight: 76),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.06),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              // Ícone da função
                                              const SizedBox(width: 2),
                                              CircleAvatar(
                                                radius: 20,
                                                backgroundColor: Colors.blue.withOpacity(0.1),
                                                child: Icon(
                                                  Icons.person_outline,
                                                  color: Colors.blue[700],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              // Nome da função/slot
                                              Expanded(
                                                flex: 4,
                                                child: Text(
                                                  s.label,
                                                  style: context.textStyles.titleMedium?.copyWith(
                                                    color: context.colors.onSurface,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              // Slot de voluntário
                                              Expanded(
                                                flex: 7,
                                                child: Container(
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    color: context.colors.surface,
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: Colors.grey[300]!),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const SizedBox(width: 12),
                                                      Icon(
                                                        Icons.search,
                                                        size: 20,
                                                        color: Colors.grey[700],
                                                        semanticLabel: 'Buscar voluntário',
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: GestureDetector(
                                                          behavior: HitTestBehavior.opaque,
                                                          onTap: () async {
                                                            final chosen = await _pickVolunteer(ministryId: ministryId, functionId: s.functionId);
                                                            if (chosen != null) {
                                                              escalaController.assignVolunteer(
                                                                eventId: eventos[pageIndex].id,
                                                                functionId: s.functionId,
                                                                slotIndex: s.slotIndex,
                                                                volunteerUserId: chosen.userId,
                                                                volunteerName: chosen.user?.name,
                                                              );
                                                            }
                                                          },
                                                          child: Text(
                                                            volunteerName ?? 'Selecionar voluntário',
                                                            overflow: TextOverflow.ellipsis,
                                                            style: context.textStyles.bodyMedium?.copyWith(
                                                              color: volunteerName == null
                                                                  ? Colors.grey[500]
                                                                  : context.colors.onSurface,
                                                              fontStyle: volunteerName == null ? FontStyle.italic : FontStyle.normal,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      if (volunteerName != null) ...[
                                                        IconButton(
                                                          icon: const Icon(Icons.close),
                                                          tooltip: 'Remover voluntário',
                                                          onPressed: () {
                                                            escalaController.assignVolunteer(
                                                              eventId: eventos[pageIndex].id,
                                                              functionId: s.functionId,
                                                              slotIndex: s.slotIndex,
                                                              volunteerUserId: null,
                                                            );
                                                          },
                                                        ),
                                                      ] else ...[
                                                        const SizedBox(width: 8),
                                                      ],
                                                    ],
                                                  ),
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
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
      floatingActionButton: Consumer<EscalaController>(
        builder: (context, ctrl, _) {
          return Padding(
            padding: const EdgeInsets.only(right: 0, bottom: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // FAB secundário (auto)
                FloatingActionButton(
                  onPressed: null, // habilitar quando definirmos a lógica de auto-atribuição
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: context.colors.secondary,
                  foregroundColor: context.colors.onSecondary,
                  child: const Icon(Icons.auto_awesome),
                ),
                const SizedBox(width: 12),
                // FAB principal (salvar)
                FloatingActionButton.extended(
                onPressed: ctrl.isLoading
                    ? null
                    : () async {
                        final evento = ctrl.selectedEvent;
                        if (evento == null) return;
                        try {
                          await ctrl.salvarEscalacaoPorEvento(evento.id);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Escala salva com sucesso!'),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } catch (_) {}
                      },
                icon: ctrl.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  ctrl.isLoading ? 'Salvando...' : 'Salvar Escala',
                  style: context.textStyles.bodyLarge?.copyWith(
                    color: context.colors.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: context.colors.primary,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              ],
            ),
          );
        },
      ),
    );
  }
}


