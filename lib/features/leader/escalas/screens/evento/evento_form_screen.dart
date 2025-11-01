import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/escalas/controllers/evento/evento_controller.dart';
import 'package:servus_app/features/leader/escalas/models/evento_model.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';
import 'package:servus_app/shared/widgets/fab_safe_scroll_view.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import 'package:servus_app/features/leader/escalas/controllers/template/template_controller.dart';
import 'package:servus_app/features/leader/escalas/models/template_model.dart';
import 'package:servus_app/features/leader/escalas/screens/template/template_form_screen.dart';

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
  
  // Variáveis para ministérios
  List<Map<String, dynamic>> _availableMinistries = [];
  String? _selectedMinistryId;
  bool _isLoadingMinistries = false;
  bool _isTenantAdmin = false;

  // Template
  List<TemplateModel> _templates = [];
  String? _selectedTemplateId;
  bool _isLoadingTemplates = false;


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
      _selectedMinistryId = evento.ministerioId.isNotEmpty ? evento.ministerioId : null;
    }
    
    // Carregar ministérios do usuário logado
    _loadUserMinistries();
  }

  /// Carrega os ministérios onde o usuário logado está vinculado
  Future<void> _loadUserMinistries() async {
    try {
      setState(() {
        _isLoadingMinistries = true;
      });

      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];
      final userRole = context['userRole'];

      if (tenantId == null) {
        throw Exception('Tenant ID não encontrado');
      }

      // Verificar se é tenant admin
      final isTenantAdmin = userRole == 'tenant_admin';
      setState(() {
        _isTenantAdmin = isTenantAdmin;
      });

      // Se for tenant admin, não precisa carregar ministérios (cria eventos globais)
      if (isTenantAdmin) {
        setState(() {
          _isLoadingMinistries = false;
        });
        developer.log('✅ Usuário é tenant admin - eventos globais', name: 'EventoFormScreen');
        return;
      }

      final dio = DioClient.instance;
      
      // Buscar ministérios do usuário logado usando o endpoint /ministry-memberships/me
      final response = await dio.get(
        '/ministry-memberships/me',
        options: Options(
          headers: {
            'X-Tenant-ID': tenantId,
            if (branchId != null && branchId.isNotEmpty) 'X-Branch-ID': branchId,
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> memberships = response.data;
        final List<Map<String, dynamic>> ministries = [];
        
        for (final membership in memberships) {
          if (membership['ministry'] != null && membership['isActive'] == true) {
            ministries.add({
              'id': membership['ministry']['_id'],
              'name': membership['ministry']['name'],
              'role': membership['role'],
            });
          }
        }
        
        setState(() {
          _availableMinistries = ministries;
          _isLoadingMinistries = false;
        });
        
        developer.log('✅ Ministérios carregados: ${ministries.length}', name: 'EventoFormScreen');
      } else {
        throw Exception('Erro ao buscar ministérios: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('❌ Erro ao carregar ministérios: $e', name: 'EventoFormScreen');
      setState(() {
        _isLoadingMinistries = false;
      });
      if (mounted) {
        showError(context, 'Erro ao carregar ministérios: $e');
      }
    }
  }

  Future<void> _loadTemplatesForMinistry(String ministryId) async {
    try {
      setState(() {
        _isLoadingTemplates = true;
      });
      final controller = context.read<TemplateController>();
      await controller.refreshTemplates();
      final filtered = controller.todos.where((t) => t.funcoes.any((f) => f.ministerioId == ministryId)).toList();
      setState(() {
        _templates = filtered;
        _isLoadingTemplates = false;
        // Reset seleção se não pertence mais
        if (_selectedTemplateId != null && !_templates.any((t) => t.id == _selectedTemplateId)) {
          _selectedTemplateId = null;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingTemplates = false;
      });
      if (mounted) {
        showError(context, 'Erro ao carregar templates: $e');
      }
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
          ministerioId: _selectedMinistryId ?? '', // Ministério selecionado
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
            templateId: _selectedTemplateId,
          );
        } else {
          developer.log('✏️ Atualizando evento existente', name: 'EventoFormScreen');
          await controller.atualizarEvento(novoEvento);
        }

        // Mostra notificação
        if (mounted) {
          if (isNovo) {
            developer.log('✅ Evento criado com sucesso', name: 'EventoFormScreen');
            showCreateSuccess(context, 'Evento');
          } else {
            developer.log('✅ Evento atualizado com sucesso', name: 'EventoFormScreen');
            showUpdateSuccess(context, 'Evento');
          }
          context.pop(); // volta à tela anterior
        }
      } catch (e) {
        developer.log('❌ Erro ao salvar evento: $e', name: 'EventoFormScreen');
        if (mounted) {
          showError(context, 'Erro ao salvar evento: $e');
        }
      }
    } else {
      developer.log('❌ Validação do formulário falhou', name: 'EventoFormScreen');
      developer.log('📝 Form válido: ${_formKey.currentState?.validate()}', name: 'EventoFormScreen');
      developer.log('📅 Data selecionada: $dataSelecionada', name: 'EventoFormScreen');
      developer.log('⏰ Horário selecionado: $horarioSelecionado', name: 'EventoFormScreen');
      developer.log('🔄 Validação recorrência: $validacaoRecorrencia', name: 'EventoFormScreen');
      
      if (mounted) {
        if (!validacaoRecorrencia && erroRecorrencia != null) {
          showError(context, erroRecorrencia);
        } else if (dataSelecionada == null) {
          showError(context, 'Selecione uma data para o evento');
        } else if (horarioSelecionado == null) {
          showError(context, 'Selecione um horário para o evento');
        }
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
        backgroundColor: context.colors.primary,
        foregroundColor: context.colors.onPrimary,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: FabSafeScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
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
              
              const SizedBox(height: 24),
              
              // Observações
              TextFormField(
                controller: observacoesController,
                decoration: context.premiumInputDecoration(
                  labelText: 'Observações',
                ),
                maxLines: 3,
              ),
              
              const SizedBox(height: 32),
              
              // Seletor de ministério
              _buildMinistrySelector(),

              const SizedBox(height: 24),

              // Seletor de template (opcional)
              if (!_isTenantAdmin) _buildTemplateSelector(),
              
              const SizedBox(height: 32),
              
              // Seletor de data e horário (100% da largura)
              GestureDetector(
                onTap: widget.eventoExistente != null ? null : _selectDateTime, // Bloqueado na edição
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: widget.eventoExistente != null 
                        ? context.colors.surface.withValues(alpha: 0.5) // Cinza quando bloqueado
                        : context.colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.eventoExistente != null 
                          ? context.colors.outline.withValues(alpha: 0.2) // Borda mais clara quando bloqueado
                          : context.colors.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 40,
                        color: widget.eventoExistente != null 
                            ? context.colors.onSurface.withValues(alpha: 0.5) // Ícone mais claro quando bloqueado
                            : context.colors.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        dataSelecionada != null && horarioSelecionado != null
                            ? _formatarDataHora(dataSelecionada!, horarioSelecionado!)
                            : 'Toque para selecionar data e horário',
                        style: context.textStyles.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: widget.eventoExistente != null 
                              ? context.colors.onSurface.withValues(alpha: 0.5) // Texto mais claro quando bloqueado
                              : context.colors.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (dataSelecionada != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _obterDiaSemana(dataSelecionada!),
                          style: context.textStyles.bodySmall?.copyWith(
                            color: widget.eventoExistente != null 
                                ? context.colors.onSurfaceVariant.withValues(alpha: 0.5) // Texto mais claro quando bloqueado
                                : context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (widget.eventoExistente != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Data não pode ser alterada na edição',
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant.withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Opções de recorrência (100% da largura)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: widget.eventoExistente != null 
                      ? context.colors.surface.withValues(alpha: 0.5) // Cinza quando bloqueado
                      : context.colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.eventoExistente != null 
                        ? context.colors.outline.withValues(alpha: 0.2) // Borda mais clara quando bloqueado
                        : context.colors.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.repeat,
                      size: 40,
                      color: widget.eventoExistente != null 
                          ? context.colors.onSurface.withValues(alpha: 0.5) // Ícone mais claro quando bloqueado
                          : context.colors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Recorrência',
                      style: context.textStyles.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.eventoExistente != null 
                            ? context.colors.onSurface.withValues(alpha: 0.5) // Texto mais claro quando bloqueado
                            : context.colors.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Botões de recorrência
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildRecorrenciaChip('Evento único', RecorrenciaTipo.nenhum),
                        _buildRecorrenciaChip('Diário', RecorrenciaTipo.diario),
                        _buildRecorrenciaChip('Semanal', RecorrenciaTipo.semanal),
                        _buildRecorrenciaChip('Mensal', RecorrenciaTipo.mensal),
                      ],
                    ),
                    if (widget.eventoExistente != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Recorrência não pode ser alterada na edição',
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant.withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    
                    // Opções específicas de recorrência dentro do card (apenas se não estiver editando)
                    if (recorrenciaSelecionada == RecorrenciaTipo.semanal && widget.eventoExistente == null) ...[
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
                              decoration: BoxDecoration(
                                color: isSelected ? context.colors.primary : context.colors.surface,
                                border: Border.all(
                                  color: isSelected ? context.colors.primary : context.colors.outline.withValues(alpha: 0.3),
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: context.colors.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ] : null,
                              ),
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
                    
                    if (recorrenciaSelecionada == RecorrenciaTipo.mensal && widget.eventoExistente == null) ...[
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
                  ],
                ),
              ),
              
              
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
                  onTap: widget.eventoExistente != null ? null : () async { // Bloqueado na edição
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
                      border: Border.all(
                        color: widget.eventoExistente != null 
                            ? context.colors.outline.withValues(alpha: 0.2) // Borda mais clara quando bloqueado
                            : context.colors.outline.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color: widget.eventoExistente != null 
                          ? context.colors.surface.withValues(alpha: 0.5) // Cinza quando bloqueado
                          : context.colors.surface,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_available,
                          color: widget.eventoExistente != null 
                              ? context.colors.onSurface.withValues(alpha: 0.5) // Ícone mais claro quando bloqueado
                              : context.colors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            dataLimiteRecorrencia != null
                                ? 'Até ${dataLimiteRecorrencia!.day}/${dataLimiteRecorrencia!.month}/${dataLimiteRecorrencia!.year}'
                                : 'Toque para definir data limite',
                            style: context.textStyles.bodyMedium?.copyWith(
                              color: widget.eventoExistente != null 
                                  ? context.colors.onSurface.withValues(alpha: 0.5) // Texto mais claro quando bloqueado
                                  : (dataLimiteRecorrencia != null 
                                      ? context.colors.onSurface 
                                      : context.colors.onSurfaceVariant),
                            ),
                          ),
                        ),
                        if (dataLimiteRecorrencia != null && widget.eventoExistente == null)
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
                  widget.eventoExistente != null 
                      ? 'Data limite não pode ser alterada na edição'
                      : 'Opcional: define quando a recorrência deve parar',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: widget.eventoExistente != null 
                        ? context.colors.onSurfaceVariant.withValues(alpha: 0.7)
                        : context.colors.onSurfaceVariant,
                    fontStyle: widget.eventoExistente != null ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
              
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Método para selecionar data e horário
  Future<void> _selectDateTime() async {
    if (!mounted) return;
    
    // Selecionar data
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
    final data = await showDatePicker(
      context: context,
      initialDate: dataSelecionada ?? hojeSemHora,
      firstDate: hojeSemHora,
      lastDate: DateTime(2030),
    );
    
    if (data != null && mounted) {
      // Selecionar horário
      final horario = await showTimePicker(
        context: context,
        initialTime: horarioSelecionado ?? TimeOfDay.now(),
      );
      
      if (horario != null && mounted) {
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
  }

  /// Widget para seleção de ministério
  Widget _buildMinistrySelector() {
    // Se for tenant admin, não mostrar seletor de ministério
    if (_isTenantAdmin) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.outline.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(16),
          color: context.colors.surface,
        ),
        child: Row(
          children: [
            Icon(
              Icons.admin_panel_settings,
              color: context.colors.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Evento global - disponível para todos os ministérios',
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ministério',
          style: context.textStyles.titleMedium?.copyWith(
            color: context.colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Selecione o ministério relacionado ao evento',
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        
        if (_isLoadingMinistries)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: context.colors.outline.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(16),
              color: context.colors.surface,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Carregando ministérios...',
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else if (_availableMinistries.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: context.colors.outline.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(16),
              color: context.colors.surface,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: context.colors.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nenhum ministério encontrado. Você precisa estar vinculado a pelo menos um ministério.',
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: _availableMinistries.asMap().entries.map((entry) {
              final index = entry.key;
              final ministry = entry.value;
              final ministryId = ministry['id'] ?? '';
              final ministryName = ministry['name'] ?? 'Ministério';
              final ministryRole = ministry['role'] ?? '';
              final isSelected = _selectedMinistryId == ministryId;
              
              return Padding(
                padding: EdgeInsets.only(bottom: index < _availableMinistries.length - 1 ? 12 : 0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMinistryId = isSelected ? null : ministryId;
                      _selectedTemplateId = null;
                    });
                    if (!isSelected) {
                      _loadTemplatesForMinistry(ministryId);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? context.colors.primary : context.colors.surface,
                      border: Border.all(
                        color: isSelected ? context.colors.primary : context.colors.outline.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: context.colors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ] : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                      Icon(
                        Icons.church,
                        size: 16,
                        color: isSelected ? context.colors.onPrimary : context.colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ministryName,
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: isSelected ? context.colors.onPrimary : context.colors.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (ministryRole.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? context.colors.onPrimary.withValues(alpha: 0.2)
                                : context.colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ministryRole,
                            style: context.textStyles.bodySmall?.copyWith(
                              color: isSelected ? context.colors.onPrimary : context.colors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                  ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildTemplateSelector() {
    if (_selectedMinistryId == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.outline.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(16),
          color: context.colors.surface,
        ),
        child: Row(
          children: [
            Icon(Icons.copy, color: context.colors.onSurfaceVariant, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Selecione um ministério para escolher um template (opcional).',
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Template (opcional)',
          style: context.textStyles.titleMedium?.copyWith(
            color: context.colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingTemplates)
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Carregando templates...'
              ),
            ],
          )
        else ...[
          DropdownButtonFormField<String>(
            value: _selectedTemplateId,
            decoration: InputDecoration(
              labelText: 'Template vinculado',
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
            dropdownColor: context.colors.surface,
            items: _templates.map((t) => DropdownMenuItem<String>(
              value: t.id,
              child: Text(
                '${t.nome} (${t.funcoes.length} funções)',
                style: context.textStyles.bodyMedium?.copyWith(color: context.colors.onSurface),
              ),
            )).toList(),
            onChanged: (value) {
              setState(() {
                _selectedTemplateId = value;
              });
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TemplateFormScreen(
                      returnToEscalaForm: true,
                      initialMinistryId: _selectedMinistryId,
                    ),
                  ),
                );
                if (created == true && _selectedMinistryId != null) {
                  await _loadTemplatesForMinistry(_selectedMinistryId!);
                }
              },
              icon: Icon(Icons.add, color: context.colors.primary),
              label: Text(
                'Criar novo template',
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildRecorrenciaChip(String label, RecorrenciaTipo tipo) {
    final isSelected = recorrenciaSelecionada == tipo;
    final isEditing = widget.eventoExistente != null;
    
    return GestureDetector(
      onTap: isEditing ? null : () { // Desabilitado na edição
        setState(() {
          recorrenciaSelecionada = tipo;
          // Se mudou para semanal e há uma data selecionada, definir o dia da semana automaticamente
          if (tipo == RecorrenciaTipo.semanal && dataSelecionada != null && diaSemanaSelecionado == null) {
            diaSemanaSelecionado = dataSelecionada!.weekday % 7; // Converte weekday (1-7) para (0-6)
          }
        });
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 80), // Largura mínima
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isEditing 
              ? context.colors.surface.withValues(alpha: 0.3) // Cinza quando desabilitado
              : (isSelected ? context.colors.primary : context.colors.surface),
          border: Border.all(
            color: isEditing 
                ? context.colors.outline.withValues(alpha: 0.2) // Borda mais clara quando desabilitado
                : (isSelected ? context.colors.primary : context.colors.outline.withValues(alpha: 0.3)),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected && !isEditing ? [
            BoxShadow(
              color: context.colors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: context.textStyles.bodyMedium?.copyWith(
            color: isEditing 
                ? context.colors.onSurface.withValues(alpha: 0.5) // Texto mais claro quando desabilitado
                : (isSelected ? context.colors.onPrimary : context.colors.onSurfaceVariant),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
