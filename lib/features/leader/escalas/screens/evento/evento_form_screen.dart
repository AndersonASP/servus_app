import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/escalas/controllers/evento/evento_controller.dart';
import 'package:servus_app/features/leader/escalas/models/evento_model.dart';
import 'package:servus_app/shared/widgets/app_notifier/app_notifier.dart';

class EventoFormScreen extends StatefulWidget {
  final EventoModel? eventoExistente;

  const EventoFormScreen({super.key, this.eventoExistente});

  @override
  State<EventoFormScreen> createState() => _EventoFormScreenState();
}

class _EventoFormScreenState extends State<EventoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController observacoesController = TextEditingController();
  final TextEditingController dataHoraController = TextEditingController();

  DateTime? dataHora;
  String? ministerioSelecionado;
  RecorrenciaTipo recorrenciaSelecionada = RecorrenciaTipo.nenhum;
  int? diaSemanaSelecionado;
  int? semanaDoMesSelecionada;

  final List<String> ministeriosMock = [
    'Louvor',
    'Mídia',
    'Acolhimento',
    'Diaconato',
  ];

  @override
  void initState() {
    super.initState();
    final evento = widget.eventoExistente;
    if (evento != null) {
      nomeController.text = evento.nome;
      observacoesController.text = evento.observacoes ?? '';
      dataHora = evento.dataHora;
      ministerioSelecionado = evento.ministerioId;
      recorrenciaSelecionada = evento.tipoRecorrencia;
      diaSemanaSelecionado = evento.diaSemana;
      semanaDoMesSelecionada = evento.semanaDoMes;
      _atualizarDataHoraController();
    }
  }

  void _atualizarDataHoraController() {
    if (dataHora != null) {
      dataHoraController.text =
          '${dataHora!.day}/${dataHora!.month} às ${dataHora!.hour.toString().padLeft(2, '0')}:${dataHora!.minute.toString().padLeft(2, '0')}';
    }
  }

  void _salvar() {
  if (_formKey.currentState!.validate() && dataHora != null) {
    final novoEvento = EventoModel(
      id: widget.eventoExistente?.id,
      nome: nomeController.text,
      dataHora: dataHora!,
      ministerioId: ministerioSelecionado!,
      recorrente: recorrenciaSelecionada != RecorrenciaTipo.nenhum,
      tipoRecorrencia: recorrenciaSelecionada,
      diaSemana: recorrenciaSelecionada == RecorrenciaTipo.semanal
          ? diaSemanaSelecionado
          : null,
      semanaDoMes: recorrenciaSelecionada == RecorrenciaTipo.mensal
          ? semanaDoMesSelecionada
          : null,
      observacoes: observacoesController.text,
    );

    final controller = context.read<EventoController>();
    final isNovo = widget.eventoExistente == null;

    if (isNovo) {
      controller.adicionarEvento(novoEvento);
    } else {
      controller.atualizarEvento(novoEvento);
    }

    // Mostra notificação
    AppNotifier.show(
      context,
      message: isNovo ? 'Evento criado com sucesso!' : 'Evento atualizado!',
      type: NotificationType.success,
    );

    context.pop(); // volta à tela anterior
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.eventoExistente == null ? 'Novo Evento' : 'Editar Evento',
            style: context.textStyles.titleLarge?.copyWith(
              color: context.colors.onSurface,
              fontWeight: FontWeight.bold,
            )),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _salvar,
        icon: const Icon(Icons.check),
        label: Text(
          widget.eventoExistente == null ? 'Salvar' : 'Atualizar',
          style: context.textStyles.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colors.onPrimary,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nomeController,
                style: TextStyle(
                    color:
                        context.colors.onSurface), // 👈 cor do valor digitado
                decoration: InputDecoration(
                  labelText: 'Nome do evento',
                  labelStyle: TextStyle(
                      color: context.colors.onSurface), // 👈 cor do label
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: context.colors.onSurface), // 👈 borda normal
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: context.colors.primary,
                        width: 2.0), // 👈 borda ativa
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: ministerioSelecionado,
                decoration: InputDecoration(
                  labelText: 'Ministério',
                  // herdando padrão global, mas pode customizar aqui se quiser:
                  labelStyle: TextStyle(color: context.colors.onSurface),
                ),
                items: ministeriosMock
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(
                          m,
                          style: TextStyle(
                              color: context
                                  .colors.onSurface), // cor dos itens da lista
                        ),
                      ),
                    )
                    .toList(),
                style: TextStyle(
                  color: context.colors.onSurface, // valor selecionado no campo
                  fontSize: 16,
                ),
                iconEnabledColor: context.colors.primary, // seta do dropdown
                dropdownColor:
                    context.colors.surface, // cor do fundo do menu suspenso
                onChanged: (value) {
                  setState(() => ministerioSelecionado = value);
                },
                validator: (value) =>
                    value == null ? 'Selecione um ministério' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: dataHoraController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Data e hora'),
                onTap: () async {
                  final data = await showDatePicker(
                    context: context,
                    initialDate: dataHora ?? DateTime.now(),
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2030),
                  );

                  if (data != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime:
                          TimeOfDay.fromDateTime(dataHora ?? DateTime.now()),
                    );
                    if (time != null) {
                      setState(() {
                        dataHora = DateTime(
                          data.year,
                          data.month,
                          data.day,
                          time.hour,
                          time.minute,
                        );
                        _atualizarDataHoraController();
                      });
                    }
                  }
                },
                validator: (_) =>
                    dataHora == null ? 'Selecione uma data e hora' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<RecorrenciaTipo>(
                value: recorrenciaSelecionada,
                decoration: const InputDecoration(labelText: 'Recorrência'),
                style: TextStyle(
                  color: context.colors.onSurface, // valor selecionado
                  fontSize: 16,
                ),
                iconEnabledColor: context.colors.primary,
                dropdownColor: context.colors.surface, // fundo da lista
                items: RecorrenciaTipo.values.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(
                      tipo.name,
                      style: TextStyle(
                          color: context
                              .colors.onSurface), // cor dos itens da lista
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    recorrenciaSelecionada = value ?? RecorrenciaTipo.nenhum;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (recorrenciaSelecionada == RecorrenciaTipo.semanal)
                DropdownButtonFormField<int>(
                  value: diaSemanaSelecionado,
                  decoration: const InputDecoration(labelText: 'Dia da semana'),
                  style: TextStyle(
                    color: context.colors.onSurface, // valor selecionado
                    fontSize: 16,
                  ),
                  iconEnabledColor: context.colors.primary,
                  dropdownColor: context.colors.surface,
                  items: List.generate(7, (i) {
                    const dias = [
                      'Domingo',
                      'Segunda',
                      'Terça',
                      'Quarta',
                      'Quinta',
                      'Sexta',
                      'Sábado'
                    ];
                    return DropdownMenuItem(
                      value: i,
                      child: Text(
                        dias[i],
                        style: TextStyle(
                            color: context.colors.onSurface), // itens da lista
                      ),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      diaSemanaSelecionado = value;
                    });
                  },
                ),
              if (recorrenciaSelecionada == RecorrenciaTipo.mensal)
                DropdownButtonFormField<int>(
                  value: semanaDoMesSelecionada,
                  decoration: const InputDecoration(labelText: 'Semana do mês'),
                  items: List.generate(5, (i) {
                    final texto = '${i + 1}ª semana';
                    return DropdownMenuItem(value: i + 1, child: Text(texto));
                  }),
                  onChanged: (value) {
                    setState(() {
                      semanaDoMesSelecionada = value;
                    });
                  },
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: observacoesController,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
