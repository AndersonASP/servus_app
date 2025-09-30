import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/escalas/controllers/evento/evento_controller.dart';
import 'package:servus_app/features/leader/escalas/models/evento_model.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';
import 'dart:developer' as developer;

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


  DateTime? dataSelecionada;
  TimeOfDay? horarioSelecionado;
  RecorrenciaTipo recorrenciaSelecionada = RecorrenciaTipo.nenhum;
  int? diaSemanaSelecionado;
  int? semanaDoMesSelecionada;
  DateTime? dataLimiteRecorrencia;


  @override
  void initState() {
    super.initState();
    final evento = widget.eventoExistente;
    if (evento != null) {
      nomeController.text = evento.nome;
      observacoesController.text = evento.observacoes ?? '';
      dataSelecionada = evento.dataHora;
      horarioSelecionado = TimeOfDay.fromDateTime(evento.dataHora);
      recorrenciaSelecionada = evento.tipoRecorrencia;
      diaSemanaSelecionado = evento.diaSemana;
      semanaDoMesSelecionada = evento.semanaDoMes;
      dataLimiteRecorrencia = evento.dataLimiteRecorrencia;
    }
  }

  void _salvar() async {
    developer.log('💾 Iniciando salvamento do evento', name: 'EventoFormScreen');
    developer.log('📱 Contexto atual: ${context.toString()}', name: 'EventoFormScreen');
    
    // Validações adicionais
    bool validacaoRecorrencia = true;
    String? erroRecorrencia;
    
    if (recorrenciaSelecionada == RecorrenciaTipo.semanal && diaSemanaSelecionado == null) {
      validacaoRecorrencia = false;
      erroRecorrencia = 'Selecione um dia da semana para eventos semanais';
    } else if (recorrenciaSelecionada == RecorrenciaTipo.mensal && semanaDoMesSelecionada == null) {
      validacaoRecorrencia = false;
      erroRecorrencia = 'Selecione uma semana do mês para eventos mensais';
    }
    
    developer.log('🔍 Validações: form=${_formKey.currentState?.validate()}, data=$dataSelecionada, hora=$horarioSelecionado, recorrência=$validacaoRecorrencia', name: 'EventoFormScreen');
    
    if (_formKey.currentState!.validate() && dataSelecionada != null && horarioSelecionado != null && validacaoRecorrencia) {
      developer.log('✅ Validação do formulário passou', name: 'EventoFormScreen');
      
      final controller = context.read<EventoController>();
      developer.log('🎮 Controller obtido: ${controller.toString()}', name: 'EventoFormScreen');
      
      final isNovo = widget.eventoExistente == null;
      
      developer.log('📝 Modo: ${isNovo ? "Novo evento" : "Editar evento"}', name: 'EventoFormScreen');

      try {
        final dataHoraCompleta = DateTime(
          dataSelecionada!.year,
          dataSelecionada!.month,
          dataSelecionada!.day,
          horarioSelecionado!.hour,
          horarioSelecionado!.minute,
        );
        
        developer.log('📅 Data/hora completa: ${dataHoraCompleta.toIso8601String()}', name: 'EventoFormScreen');
        developer.log('🔄 Tipo recorrência: $recorrenciaSelecionada', name: 'EventoFormScreen');
        developer.log('📅 Dia da semana selecionado: $diaSemanaSelecionado', name: 'EventoFormScreen');
        developer.log('📅 Dia da semana da data: ${dataSelecionada!.weekday % 7}', name: 'EventoFormScreen');
        developer.log('📅 Semana do mês: $semanaDoMesSelecionada', name: 'EventoFormScreen');

        final novoEvento = EventoModel(
          id: widget.eventoExistente?.id,
          nome: nomeController.text,
          dataHora: dataHoraCompleta,
          ministerioId: '', // Ministério não obrigatório
          recorrente: recorrenciaSelecionada != RecorrenciaTipo.nenhum,
          tipoRecorrencia: recorrenciaSelecionada,
          diaSemana: recorrenciaSelecionada == RecorrenciaTipo.semanal
              ? diaSemanaSelecionado
              : null,
          semanaDoMes: recorrenciaSelecionada == RecorrenciaTipo.mensal
              ? semanaDoMesSelecionada
              : null,
          dataLimiteRecorrencia: recorrenciaSelecionada != RecorrenciaTipo.nenhum
              ? dataLimiteRecorrencia
              : null,
          observacoes: observacoesController.text,
        );
        
        developer.log('📦 EventoModel criado: ${novoEvento.nome}', name: 'EventoFormScreen');

        if (isNovo) {
          developer.log('➕ Salvando novo evento', name: 'EventoFormScreen');
          await controller.adicionarEvento(
            novoEvento.copyWith(),
          );
        } else {
          developer.log('✏️ Atualizando evento existente', name: 'EventoFormScreen');
          await controller.atualizarEvento(novoEvento);
        }

        // Mostra notificação
        if (isNovo) {
          developer.log('✅ Evento criado com sucesso', name: 'EventoFormScreen');
          showCreateSuccess(context, 'Evento');
        } else {
          developer.log('✅ Evento atualizado com sucesso', name: 'EventoFormScreen');
          showUpdateSuccess(context, 'Evento');
        }

        context.pop(); // volta à tela anterior
      } catch (e) {
        developer.log('❌ Erro ao salvar evento: $e', name: 'EventoFormScreen');
        showError(context, 'Erro ao salvar evento: $e');
      }
    } else {
      developer.log('❌ Validação do formulário falhou', name: 'EventoFormScreen');
      developer.log('📝 Form válido: ${_formKey.currentState?.validate()}', name: 'EventoFormScreen');
      developer.log('📅 Data selecionada: $dataSelecionada', name: 'EventoFormScreen');
      developer.log('⏰ Horário selecionado: $horarioSelecionado', name: 'EventoFormScreen');
      developer.log('🔄 Validação recorrência: $validacaoRecorrencia', name: 'EventoFormScreen');
      
      if (!validacaoRecorrencia && erroRecorrencia != null) {
        showError(context, erroRecorrencia);
      } else if (dataSelecionada == null) {
        showError(context, 'Selecione uma data para o evento');
      } else if (horarioSelecionado == null) {
        showError(context, 'Selecione um horário para o evento');
      }
    }
  }

  String _formatarDataHora(DateTime data, TimeOfDay horario) {
    const meses = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
    ];
    
    return '${data.day} de ${meses[data.month - 1]} de ${data.year} às ${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}h';
  }

  String _obterDiaSemana(DateTime data) {
    const diasSemana = [
      'Domingo', 'Segunda-feira', 'Terça-feira', 'Quarta-feira',
      'Quinta-feira', 'Sexta-feira', 'Sábado'
    ];
    return diasSemana[data.weekday % 7];
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.eventoExistente == null ? 'Nova programação' : 'Editar programação',
            style: context.textStyles.titleLarge?.copyWith(
              color: context.colors.onSurface,
            )),
        centerTitle: false,
        backgroundColor: context.colors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 100), // Padding inferior aumentado
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
              const SizedBox(height: 20), // Espaço extra no topo
              // Nome do evento
              TextFormField(
                controller: nomeController,
                style: TextStyle(color: context.colors.onSurface),
                decoration: InputDecoration(
                  labelText: 'Nome do evento',
                  labelStyle: TextStyle(color: context.colors.onSurface),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: context.colors.outline.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: context.colors.primary, width: 2.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo obrigatório' : null,
              ),
              
              const SizedBox(height: 32),
              
              // Seletor de data e horário
              GestureDetector(
                onTap: () async {
                  // Selecionar data
                  final hoje = DateTime.now();
                  final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
                  final data = await showDatePicker(
                    context: context,
                    initialDate: dataSelecionada ?? hojeSemHora,
                    firstDate: hojeSemHora,
                    lastDate: DateTime(2030),
                  );
                  if (data != null) {
                    // Selecionar horário
                    final horario = await showTimePicker(
                      context: context,
                      initialTime: horarioSelecionado ?? TimeOfDay.now(),
                    );
                    if (horario != null) {
                      setState(() {
                        dataSelecionada = data;
                        horarioSelecionado = horario;
                        // Se recorrência semanal está selecionada e não há dia da semana definido,
                        // definir automaticamente baseado na data selecionada
                        if (recorrenciaSelecionada == RecorrenciaTipo.semanal && diaSemanaSelecionado == null) {
                          diaSemanaSelecionado = data.weekday % 7; // Converte weekday (1-7) para (0-6)
                        }
                      });
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: context.premiumCardDecoration(),
                  child: Column(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 48,
                        color: context.colors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        dataSelecionada != null && horarioSelecionado != null
                            ? _formatarDataHora(dataSelecionada!, horarioSelecionado!)
                            : 'Toque para selecionar data e horário',
                        style: context.textStyles.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (dataSelecionada != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _obterDiaSemana(dataSelecionada!),
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Opções de recorrência
              Text(
                'Recorrência',
                style: context.textStyles.titleMedium?.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              
              // Botões de recorrência
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildRecorrenciaChip('Evento único', RecorrenciaTipo.nenhum),
                  _buildRecorrenciaChip('Diário', RecorrenciaTipo.diario),
                  _buildRecorrenciaChip('Semanal', RecorrenciaTipo.semanal),
                  _buildRecorrenciaChip('Mensal', RecorrenciaTipo.mensal),
                ],
              ),
              
              // Opções específicas de recorrência
              if (recorrenciaSelecionada == RecorrenciaTipo.semanal) ...[
                const SizedBox(height: 16),
                Text(
                  'Repetir em:',
                  style: context.textStyles.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(7, (i) {
                    const dias = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
                    final isSelected = diaSemanaSelecionado == i;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          diaSemanaSelecionado = i;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: context.premiumChipDecoration(isSelected: isSelected),
                        child: Text(
                          dias[i],
                          style: context.textStyles.bodySmall?.copyWith(
                            color: isSelected ? context.colors.onPrimary : context.colors.onSurfaceVariant,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
              
              if (recorrenciaSelecionada == RecorrenciaTipo.mensal) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: semanaDoMesSelecionada,
                  decoration: InputDecoration(
                    labelText: 'Semana do mês',
                    labelStyle: TextStyle(color: context.colors.onSurface),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: context.colors.outline.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: context.colors.primary, width: 2.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    filled: true,
                    fillColor: context.colors.surface,
                  ),
                  dropdownColor: context.colors.surface,
                  style: TextStyle(color: context.colors.onSurface),
                  items: List.generate(4, (i) {
                    final texto = i == 3 ? 'Última semana' : '${i + 1}ª semana';
                    return DropdownMenuItem<int>(
                      value: i + 1,
                      child: Text(
                        texto,
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: context.colors.onSurface,
                        ),
                      ),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      semanaDoMesSelecionada = value;
                    });
                  },
                ),
              ],
              
              // Data limite para recorrência
              if (recorrenciaSelecionada != RecorrenciaTipo.nenhum) ...[
                const SizedBox(height: 24),
                Text(
                  'Data limite da recorrência',
                  style: context.textStyles.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final hoje = DateTime.now();
                    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
                    final dataLimite = await showDatePicker(
                      context: context,
                      initialDate: dataLimiteRecorrencia ?? hojeSemHora.add(const Duration(days: 30)),
                      firstDate: hojeSemHora,
                      lastDate: DateTime(2030),
                    );
                    if (dataLimite != null) {
                      setState(() {
                        dataLimiteRecorrencia = dataLimite;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: context.colors.outline.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(16),
                      color: context.colors.surface,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_available,
                          color: context.colors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            dataLimiteRecorrencia != null
                                ? 'Até ${dataLimiteRecorrencia!.day}/${dataLimiteRecorrencia!.month}/${dataLimiteRecorrencia!.year}'
                                : 'Toque para definir data limite',
                            style: context.textStyles.bodyMedium?.copyWith(
                              color: dataLimiteRecorrencia != null 
                                  ? context.colors.onSurface 
                                  : context.colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (dataLimiteRecorrencia != null)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                dataLimiteRecorrencia = null;
                              });
                            },
                            icon: Icon(
                              Icons.clear,
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Opcional: define quando a recorrência deve parar',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Observações
              TextFormField(
                controller: observacoesController,
                decoration: context.premiumInputDecoration(
                  labelText: 'Observações',
                ),
                maxLines: 3,
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecorrenciaChip(String label, RecorrenciaTipo tipo) {
    final isSelected = recorrenciaSelecionada == tipo;
    return GestureDetector(
      onTap: () {
        setState(() {
          recorrenciaSelecionada = tipo;
          // Se mudou para semanal e há uma data selecionada, definir o dia da semana automaticamente
          if (tipo == RecorrenciaTipo.semanal && dataSelecionada != null && diaSemanaSelecionado == null) {
            diaSemanaSelecionado = dataSelecionada!.weekday % 7; // Converte weekday (1-7) para (0-6)
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: context.premiumChipDecoration(isSelected: isSelected),
        child: Text(
          label,
          style: context.textStyles.bodyMedium?.copyWith(
            color: isSelected ? context.colors.onPrimary : context.colors.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
