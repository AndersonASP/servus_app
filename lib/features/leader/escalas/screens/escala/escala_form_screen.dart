import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:servus_app/services/auth_context_service.dart';
import '../../controllers/escala/escala_controller.dart';
import '../../models/escala_model.dart';
import '../../models/template_model.dart';
import '../../controllers/evento/evento_controller.dart';
import '../../controllers/template/template_controller.dart';
import 'package:servus_app/features/ministries/models/ministry_function.dart';
import 'package:servus_app/features/ministries/services/ministry_functions_service.dart';
import 'package:servus_app/features/ministries/services/member_function_service.dart';
import 'package:servus_app/features/ministries/models/member_function.dart';
import 'package:servus_app/core/error/notification_service.dart';
import 'package:servus_app/services/scales_advanced_service.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import '../../models/evento_model.dart';

class EscalaFormScreen extends StatefulWidget {
  const EscalaFormScreen({super.key});

  @override
  State<EscalaFormScreen> createState() => _EscalaFormScreenState();
}

class _EscalaFormScreenState extends State<EscalaFormScreen> {
  String? eventoIdSelecionado;
  String? templateIdSelecionado;
  String nomeEscala = '';
  String? descricaoEscala;
  int _currentStep = 0;
  String? _eventMinistryId;
  TemplateModel? _pseudoTemplate;

  // Mapa para armazenar seleções de voluntários por função e slot
  // Chave: "functionId_slotIndex" (ex: "func123_0", "func123_1")
  final Map<String, String?> selecaoVoluntariosPorFuncao = {};
  final _formKey = GlobalKey<FormState>();
  
  // Serviços
  final MinistryFunctionsService _functionsService = MinistryFunctionsService();
  final MemberFunctionService _memberFunctionService = MemberFunctionService();
  final Dio _dio = DioClient.instance;
  final AuthContextService _auth = AuthContextService.instance;
  
  // Cache de funções do ministério para buscar nomes
  Map<String, MinistryFunction> _funcoesCache = {};
  
  // Cache de voluntários por função
  Map<String, List<MemberFunction>> _voluntariosPorFuncao = {};
  
  // Cache de TODOS os voluntários do ministério (para modo flexível)
  List<MemberFunction> _todosVoluntariosMinisterio = [];
  
  // Estados de carregamento
  Map<String, bool> _carregandoVoluntarios = {};
  bool _carregandoTodosVoluntarios = false;
  
  // Modo flexível - permite atribuir voluntários de outras funções
  bool _modoFlexivel = false;

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    print('🔄 [EscalaFormScreen] Carregando dados iniciais...');
    final eventoController = context.read<EventoController>();
    final templateController = context.read<TemplateController>();
    
    try {
      // Carregar eventos e templates
      await Future.wait([
        eventoController.carregarEventos(),
        templateController.refreshTemplates(),
      ]);
      
      print('✅ [EscalaFormScreen] Dados carregados:');
      print('   - Eventos: ${eventoController.todos.length}');
      print('   - Templates: ${templateController.todos.length}');
      
      // Log dos templates carregados
      for (final template in templateController.todos) {
        print('   - Template: ${template.nome} (${template.funcoes.length} funções)');
        for (final funcao in template.funcoes) {
          print('     * ${funcao.nome} (ID: ${funcao.id}, MinistryId: ${funcao.ministerioId})');
        }
      }
    } catch (e) {
      print('❌ [EscalaFormScreen] Erro ao carregar dados: $e');
    }
  }

  Future<void> _prepararParaPassoEscala() async {
    try {
      if (templateIdSelecionado != null) {
        final templateController = context.read<TemplateController>();
        final template = templateController.todos.firstWhere(
          (t) => t.id == templateIdSelecionado,
          orElse: () => TemplateModel(nome: '', funcoes: []),
        );
        if (template.funcoes.isNotEmpty) {
          final ministryId = template.funcoes.first.ministerioId;
          await _carregarFuncoesDoMinisterio(ministryId);
          await _carregarTodosVoluntariosMinisterio(ministryId);
          for (final funcao in template.funcoes) {
            await _carregarVoluntariosPorFuncao(ministryId, funcao.id);
          }
        }
        _pseudoTemplate = null;
        return;
      }

      if (_eventMinistryId != null && _eventMinistryId!.isNotEmpty) {
        final funcoes = await _functionsService.getMinistryFunctions(_eventMinistryId!);
        final funcoesTemplate = funcoes.map((f) => FuncaoEscala(
          nome: f.name,
          ministerioId: _eventMinistryId!,
          quantidade: 1,
        )).toList();
        _pseudoTemplate = TemplateModel(
          nome: 'Escala Livre (1 por função)',
          funcoes: funcoesTemplate,
        );
        await _carregarFuncoesDoMinisterio(_eventMinistryId!);
        await _carregarTodosVoluntariosMinisterio(_eventMinistryId!);
        for (final funcao in funcoesTemplate) {
          await _carregarVoluntariosPorFuncao(_eventMinistryId!, funcao.id);
        }
      }
    } catch (e) {
      NotificationService().handleGenericError(e);
    }
  }

  /// Carrega as funções do ministério para buscar nomes corretos
  Future<void> _carregarFuncoesDoMinisterio(String ministryId) async {
    print('🔄 [EscalaFormScreen] Carregando funções do ministério: $ministryId');
    
    try {
      final funcoes = await _functionsService.getMinistryFunctions(ministryId);
      print('✅ [EscalaFormScreen] Funções carregadas: ${funcoes.length}');
      
      _funcoesCache.clear();
      for (final funcao in funcoes) {
        _funcoesCache[funcao.functionId] = funcao;
        print('   - ${funcao.name} (${funcao.functionId})');
      }
    } catch (e) {
      print('❌ [EscalaFormScreen] Erro ao carregar funções: $e');
      NotificationService().handleGenericError(e);
    }
  }

  /// Busca o nome da função pelo ID
  String _getNomeFuncao(String functionId) {
    final funcao = _funcoesCache[functionId];
    return funcao?.name ?? 'Função sem nome';
  }

  /// Carrega TODOS os voluntários do ministério (para modo flexível)
  Future<void> _carregarTodosVoluntariosMinisterio(String ministryId) async {
    if (_carregandoTodosVoluntarios) return;
    
    print('🔄 [EscalaFormScreen] Carregando TODOS os voluntários do ministério: $ministryId');
    
    setState(() {
      _carregandoTodosVoluntarios = true;
    });

    try {
      // Buscar todos os voluntários do ministério usando o endpoint existente
      final response = await _dio.get(
        '/users/tenants/${_auth.tenantId}/ministries/$ministryId/volunteers',
        queryParameters: {
          'page': 1,
          'limit': 1000, // Buscar todos
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final users = data['users'] as List<dynamic>? ?? [];
        
        print('✅ [EscalaFormScreen] Todos os voluntários carregados: ${users.length}');
        
        _todosVoluntariosMinisterio.clear();
        
        for (final user in users) {
          // Para cada usuário, buscar suas funções aprovadas
          final functions = user['functions'] as List<dynamic>? ?? [];
          for (final func in functions) {
            if (func['status'] == 'aprovado') {
              _todosVoluntariosMinisterio.add(
                MemberFunction(
                  id: func['_id'] ?? '',
                  userId: user['_id'] ?? '',
                  ministryId: ministryId,
                  functionId: func['function']['_id'] ?? '',
                  status: MemberFunctionStatus.approved,
                  tenantId: _auth.tenantId ?? '',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  user: MemberFunctionUser(
                    id: user['_id'] ?? '',
                    name: user['name'] ?? 'Nome não informado',
                    email: user['email'] ?? '',
                  ),
                  function: MemberFunctionFunction(
                    id: func['function']['_id'] ?? '',
                    name: func['function']['name'] ?? '',
                    description: func['function']['description'],
                  ),
                ),
              );
            }
          }
        }
        
        print('✅ [EscalaFormScreen] Voluntários processados: ${_todosVoluntariosMinisterio.length}');
        for (final v in _todosVoluntariosMinisterio) {
          print('   - ${v.user?.name} (${v.function?.name})');
        }
        
        // Limpar seleções inválidas após carregar todos os voluntários
        _limparSelecoesInvalidas();
      }
    } catch (e) {
      print('❌ [EscalaFormScreen] Erro ao carregar todos os voluntários: $e');
      NotificationService().handleGenericError(e);
      _todosVoluntariosMinisterio = [];
    } finally {
      setState(() {
        _carregandoTodosVoluntarios = false;
      });
    }
  }

  /// Carrega voluntários aprovados para uma função específica
  Future<void> _carregarVoluntariosPorFuncao(String ministryId, String functionId) async {
    if (_carregandoVoluntarios[functionId] == true) return;
    
    print('🔄 [EscalaFormScreen] Carregando voluntários para função: $functionId');
    print('   - MinistryId: $ministryId');
    print('   - FunctionId: $functionId');
    
    setState(() {
      _carregandoVoluntarios[functionId] = true;
    });

    try {
      final voluntarios = await _memberFunctionService.getApprovedMembersByFunction(
        ministryId: ministryId,
        functionId: functionId,
      );
      
      print('✅ [EscalaFormScreen] Voluntários carregados: ${voluntarios.length}');
      for (final v in voluntarios) {
        print('   - ${v.user?.name} (${v.userId})');
      }
      
      _voluntariosPorFuncao[functionId] = voluntarios;
      
      // Limpar seleções inválidas após carregar voluntários
      _limparSelecoesInvalidas();
    } catch (e) {
      print('❌ [EscalaFormScreen] Erro ao carregar voluntários: $e');
      NotificationService().handleGenericError(e);
      _voluntariosPorFuncao[functionId] = [];
    } finally {
      setState(() {
        _carregandoVoluntarios[functionId] = false;
      });
    }
  }

  /// Busca voluntários para uma função específica (com suporte ao modo flexível)
  List<MemberFunction> _getVoluntariosPorFuncao(String functionId) {
    final voluntariosAprovados = _voluntariosPorFuncao[functionId] ?? [];
    
    // Se o modo flexível está ativo, usar todos os voluntários do ministério
    if (_modoFlexivel) {
      print('🔄 [EscalaFormScreen] Modo flexível ativo - usando todos os voluntários do ministério');
      
      // Remover duplicatas baseado no userId para evitar valores duplicados no dropdown
      final Map<String, MemberFunction> voluntariosUnicos = {};
      for (final voluntario in _todosVoluntariosMinisterio) {
        voluntariosUnicos[voluntario.userId] = voluntario;
      }
      
      return voluntariosUnicos.values.toList();
    }
    
    return voluntariosAprovados;
  }

  /// Limpa seleções inválidas quando a lista de voluntários muda
  void _limparSelecoesInvalidas() {
    final keysToRemove = <String>[];
    
    for (final entry in selecaoVoluntariosPorFuncao.entries) {
      if (entry.value != null) {
        // Extrair functionId da chave (formato: "functionId_slotIndex")
        final parts = entry.key.split('_');
        if (parts.length == 2) {
          final functionId = parts[0];
          final voluntariosDisponiveis = _getVoluntariosDisponiveis(functionId, entry.key);
          
          // Se o voluntário selecionado não está mais disponível, remover a seleção
          if (!voluntariosDisponiveis.any((v) => v.userId == entry.value)) {
            keysToRemove.add(entry.key);
          }
        }
      }
    }
    
    for (final key in keysToRemove) {
      selecaoVoluntariosPorFuncao.remove(key);
    }
    
    if (keysToRemove.isNotEmpty) {
      print('🧹 [EscalaFormScreen] Removidas ${keysToRemove.length} seleções inválidas');
      setState(() {});
    }
  }

  /// Retorna lista de voluntários disponíveis para uma função específica
  /// (excluindo voluntários já selecionados em outros slots)
  List<MemberFunction> _getVoluntariosDisponiveis(String functionId, String currentSlotKey) {
    final todosVoluntarios = _getVoluntariosPorFuncao(functionId);
    final voluntariosJaSelecionados = <String>{};
    
    // Coletar todos os voluntários já selecionados (exceto o slot atual)
    for (final entry in selecaoVoluntariosPorFuncao.entries) {
      if (entry.key != currentSlotKey && entry.value != null) {
        voluntariosJaSelecionados.add(entry.value!);
      }
    }
    
    // Filtrar voluntários já selecionados
    return todosVoluntarios.where((voluntario) => 
      !voluntariosJaSelecionados.contains(voluntario.userId)
    ).toList();
  }


  /// Verifica se está carregando voluntários para uma função
  bool _isCarregandoVoluntarios(String functionId) {
    return _carregandoVoluntarios[functionId] ?? false;
  }

  /// Verifica se um voluntário está indisponível na data do evento
  Future<bool> _isVoluntarioIndisponivel(String userId, DateTime eventDate) async {
    try {
      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      
      final response = await ScalesAdvancedService.getVolunteerUnavailabilities(
        tenantId: tenantId ?? '',
        userId: userId,
      );
      
      if (response['data'] != null) {
        final List<dynamic> data = response['data'];
        
        // Verificar se há bloqueio na data do evento
        for (final item in data) {
          if (item['blockedDates'] != null) {
            for (final blockedDate in item['blockedDates']) {
              final blockedDateStr = blockedDate['date'];
              if (blockedDateStr == eventDate.toIso8601String().split('T')[0]) {
                return true; // Voluntário está indisponível
              }
            }
          }
        }
      }
      
      return false; // Voluntário está disponível
    } catch (e) {
      print('❌ [EscalaFormScreen] Erro ao verificar indisponibilidade: $e');
      return false; // Em caso de erro, considerar disponível
    }
  }

  /// Gera escala automaticamente atribuindo voluntários disponíveis
  Future<void> _gerarEscalaAutomaticamente() async {
    if (templateIdSelecionado == null) {
      NotificationService().showWarning('Selecione um template primeiro');
      return;
    }

    if (eventoIdSelecionado == null) {
      NotificationService().showWarning('Selecione um evento primeiro');
      return;
    }

    final templateController = context.read<TemplateController>();
    final template = templateController.todos.firstWhere(
      (t) => t.id == templateIdSelecionado,
      orElse: () => TemplateModel(nome: '', funcoes: []),
    );

    if (template.funcoes.isEmpty) {
      NotificationService().showWarning('Template não possui funções');
      return;
    }

    // Obter data do evento
    final eventoController = context.read<EventoController>();
    final evento = eventoController.todos.firstWhere(
      (e) => e.id == eventoIdSelecionado,
      orElse: () => EventoModel(nome: '', dataHora: DateTime.now(), ministerioId: ''),
    );

    // Limpar seleções atuais
    selecaoVoluntariosPorFuncao.clear();
    
    // Lista de voluntários já selecionados para evitar duplicatas
    final voluntariosJaSelecionados = <String>{};
    int voluntariosIndisponiveis = 0;
    
    // Gerar escala automaticamente
    for (final funcao in template.funcoes) {
      final functionId = funcao.id;
      final voluntariosDisponiveis = _getVoluntariosPorFuncao(functionId);
      
      // Filtrar voluntários já selecionados e indisponíveis
      final voluntariosLivres = <MemberFunction>[];
      
      for (final voluntario in voluntariosDisponiveis) {
        if (!voluntariosJaSelecionados.contains(voluntario.userId)) {
          // Verificar indisponibilidade
          final isIndisponivel = await _isVoluntarioIndisponivel(voluntario.userId, evento.dataHora);
          if (!isIndisponivel) {
            voluntariosLivres.add(voluntario);
          } else {
            voluntariosIndisponiveis++;
            print('⚠️ [EscalaFormScreen] Voluntário ${voluntario.user?.name} indisponível em ${evento.dataHora.day}/${evento.dataHora.month}');
          }
        }
      }
      
      // Atribuir voluntários para cada slot da função
      for (int slotIndex = 0; slotIndex < funcao.quantidade; slotIndex++) {
        if (slotIndex < voluntariosLivres.length) {
          final voluntario = voluntariosLivres[slotIndex];
          final slotKey = '${functionId}_$slotIndex';
          
          selecaoVoluntariosPorFuncao[slotKey] = voluntario.userId;
          voluntariosJaSelecionados.add(voluntario.userId);
        }
      }
    }
    
    setState(() {});
    
    final totalAtribuicoes = selecaoVoluntariosPorFuncao.length;
    final totalNecessario = template.funcoes.fold(0, (sum, f) => sum + f.quantidade);
    
    if (totalAtribuicoes < totalNecessario) {
      String mensagem = 'Escala gerada parcialmente: $totalAtribuicoes de $totalNecessario posições preenchidas.';
      if (voluntariosIndisponiveis > 0) {
        mensagem += ' $voluntariosIndisponiveis voluntários estão indisponíveis nesta data.';
      } else {
        mensagem += ' Não há voluntários suficientes disponíveis.';
      }
      
      NotificationService().showWarning(mensagem);
    } else {
      String mensagem = 'Escala gerada automaticamente com sucesso! $totalAtribuicoes voluntários atribuídos.';
      if (voluntariosIndisponiveis > 0) {
        mensagem += ' ($voluntariosIndisponiveis voluntários estavam indisponíveis)';
      }
      
      NotificationService().showSuccess(mensagem);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (eventoIdSelecionado == null) {
      NotificationService().showWarning('Selecione um evento');
      return;
    }

    // Verificar se há voluntários selecionados
    final escalados = <Escalado>[];
    for (final entry in selecaoVoluntariosPorFuncao.entries) {
      if (entry.value != null) {
        final parts = entry.key.split('_');
        if (parts.length == 2) {
          final functionId = parts[0];
          escalados.add(Escalado(
            funcaoId: functionId,
            voluntarioId: entry.value!,
          ));
        }
      }
    }

    if (escalados.isEmpty) {
      NotificationService().showWarning('Selecione pelo menos um voluntário para a escala');
      return;
    }

    // Mostrar diálogo de confirmação
    final confirmar = await _mostrarDialogoConfirmacao();
    if (!confirmar) return;

    await _criarEscala(escalados);
  }

  Future<bool> _mostrarDialogoConfirmacao() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: context.colors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Publicar Escala',
                style: context.textStyles.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurface,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ao confirmar, a escala será criada e publicada imediatamente. Todos os voluntários selecionados serão notificados automaticamente.',
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.colors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: context.colors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A escala será publicada imediatamente e os voluntários receberão uma notificação sobre sua participação.',
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: context.colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: context.colors.onPrimary,
              ),
              child: const Text('Publicar'),
            ),
          ],
        );
      },
        ) ?? false;
  }

  Future<void> _mostrarDialogoCriarOutra() async {
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: context.colors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Escala Criada!',
                style: context.textStyles.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurface,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sua escala foi criada e publicada com sucesso! Todos os voluntários foram notificados.',
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.colors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.help_outline,
                      color: context.colors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Deseja criar outra escala?',
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Não, voltar à lista',
                style: TextStyle(
                  color: context.colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: context.colors.onPrimary,
              ),
              child: const Text('Sim, criar outra'),
            ),
          ],
        );
      },
    );

    if (resultado == true) {
      // Criar outra escala - resetar o formulário e voltar ao início
      _resetarFormulario();
    } else {
      // Voltar para a listagem
      Navigator.pop(context);
    }
  }

  void _resetarFormulario() {
    setState(() {
      eventoIdSelecionado = null;
      templateIdSelecionado = null;
      nomeEscala = '';
      descricaoEscala = null;
      _currentStep = 0;
      selecaoVoluntariosPorFuncao.clear();
      _voluntariosPorFuncao.clear();
      _carregandoVoluntarios.clear();
      _todosVoluntariosMinisterio.clear();
      _modoFlexivel = false;
    });
  }

  Future<void> _criarEscala(List<Escalado> escalados) async {
    final novaEscala = EscalaModel(
      eventoId: eventoIdSelecionado!,
      templateId: templateIdSelecionado,
      escalados: escalados,
    );

    try {
      final escalaController = context.read<EscalaController>();

      // Derivar ministryId a partir do template selecionado ou usar um padrão
      String? ministryId;
      DateTime? eventDate;
      try {
        if (templateIdSelecionado != null) {
          final templateControllerLocal = context.read<TemplateController>();
          final template = templateControllerLocal.todos.firstWhere((t) => t.id == templateIdSelecionado);
          if (template.funcoes.isNotEmpty) {
            ministryId = template.funcoes.first.ministerioId;
          }
        }
        // Se não há template, usar ministryId do contexto do usuário
        if (ministryId == null) {
          ministryId = _auth.tenantId; // Fallback para tenantId
        }
      } catch (_) {}

      try {
        final eventoControllerLocal = context.read<EventoController>();
        final evento = eventoControllerLocal.todos.firstWhere((e) => e.id == eventoIdSelecionado);
        eventDate = evento.dataHora;
      } catch (_) {}

      await escalaController.adicionar(
        novaEscala,
        overrideMinistryId: ministryId,
        overrideEventDate: eventDate,
      );
      
      // Mostrar mensagem de sucesso antes de fechar a tela
      NotificationService().showSuccess('Escala criada e publicada com sucesso! Todos os voluntários foram notificados.');
      
      // Aguardar um pouco para a mensagem aparecer antes de mostrar diálogo
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _mostrarDialogoCriarOutra();
        }
      });
    } catch (e) {
      // O erro já foi tratado no controller
      print('❌ [EscalaFormScreen] Erro ao salvar escala: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventoController = context.watch<EventoController>();
    final templateController = context.watch<TemplateController>();

    final eventos = eventoController.todos.where((evento) {
      final hoje = DateTime.now();
      final fimDoMes = DateTime(hoje.year, hoje.month + 1, 0);
      
      // Incluir eventos do dia atual até o final do mês corrente
      return evento.dataHora.isAfter(hoje.subtract(const Duration(days: 1))) &&
             evento.dataHora.isBefore(fimDoMes.add(const Duration(days: 1)));
    }).toList();
    final templates = templateController.todos;

    final templateSelecionado = templateIdSelecionado != null
        ? templates.firstWhere(
            (t) => t.id == templateIdSelecionado,
            orElse: () => TemplateModel(nome: '', funcoes: []),
          )
        : (_pseudoTemplate ?? TemplateModel(nome: '', funcoes: []));
    

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            _currentStep == 0 ? Icons.arrow_back : Icons.arrow_back,
            color: context.colors.onSurface,
          ),
          onPressed: () {
            if (_currentStep == 0) {
              Navigator.pop(context);
            } else {
              setState(() {
                _currentStep--;
              });
              if (_currentStep < 1) {
                _pseudoTemplate = null;
              }
            }
          },
        ),
        title: Text(
          'Criar Nova Escala',
          style: context.textStyles.titleLarge?.copyWith(
            color: context.colors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Stepper Header - Fora da área branca
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Step 1
                  _buildStepIndicator(0, 'Evento'),
                  Expanded(child: _buildStepConnector(0)),
                  // Step 2
                  _buildStepIndicator(1, 'Escala'),
                ],
              ),
            ),
            
            // Step Content - Direto no fundo da tela
            Expanded(
              child: SingleChildScrollView(
                child: _buildStepContent(context, eventos, templates, templateSelecionado),
              ),
            ),
          ],
        ),
      ),
        floatingActionButton: _currentStep == 1
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Botão de gerar automaticamente
                FloatingActionButton(
                  onPressed: _gerarEscalaAutomaticamente,
                  backgroundColor: context.colors.secondary,
                  foregroundColor: context.colors.onSecondary,
                  heroTag: "auto_generate",
                  child: const Icon(Icons.auto_awesome),
                ),
                const SizedBox(width: 16),
                // Botão principal de salvar
                Consumer<EscalaController>(
                  builder: (context, escalaController, child) {
                    return FloatingActionButton.extended(
                      onPressed: escalaController.isLoading ? null : _salvar,
                      icon: escalaController.isLoading 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  context.colors.onPrimary,
                                ),
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        escalaController.isLoading ? 'Salvando...' : 'Criar Escala',
                        style: context.textStyles.bodyLarge?.copyWith(
                          color: context.colors.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: context.colors.primary,
                      heroTag: "save",
                    );
                  },
                ),
              ],
            )
          : Consumer<EscalaController>(
              builder: (context, escalaController, child) {
                return FloatingActionButton.extended(
                  onPressed: escalaController.isLoading ? null : _getFloatingActionButtonAction(),
                  icon: escalaController.isLoading 
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              context.colors.onPrimary,
                            ),
                          ),
                        )
                      : Icon(_getFloatingActionButtonIcon()),
                  label: Text(
                    escalaController.isLoading ? 'Salvando...' : _getFloatingActionButtonLabel(),
                    style: context.textStyles.bodyLarge?.copyWith(
                      color: context.colors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: context.colors.primary,
                  heroTag: "continue",
                );
              },
            ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String label) {
    final isActive = _currentStep == stepIndex;
    final isCompleted = _currentStep > stepIndex;
    
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted 
              ? context.colors.primary 
              : (isActive ? context.colors.primary : context.colors.outline.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: isCompleted 
              ? Icon(Icons.check, color: context.colors.onPrimary, size: 16)
              : Text(
                  '${stepIndex + 1}',
                  style: TextStyle(
                    color: isActive ? context.colors.onPrimary : context.colors.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive 
                ? context.colors.primary 
                : context.colors.onSurface.withValues(alpha: 0.6),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStepConnector(int stepIndex) {
    final isCompleted = _currentStep > stepIndex;
    return Container(
      height: 2,
      color: isCompleted 
        ? context.colors.primary 
        : context.colors.outline.withValues(alpha: 0.3),
    );
  }

  Widget _buildStepContent(BuildContext context, List<dynamic> eventos, List<TemplateModel> templates, TemplateModel templateSelecionado) {
    switch (_currentStep) {
      case 0:
        return _buildEventStep(context, eventos);
      case 1:
        return _buildScaleStep(context, templateSelecionado);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEventStep(BuildContext context, List<dynamic> eventos) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text(
          'Selecione o Evento',
          style: context.textStyles.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Escolha o evento para o qual você deseja criar a escala',
          style: context.textStyles.bodyMedium?.copyWith(
            color: context.colors.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Nome da Escala',
            hintText: 'Ex: Escala do Culto de Domingo',
            prefixIcon: const Icon(Icons.title),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Digite o nome da escala';
            }
            return null;
          },
          onChanged: (value) => nomeEscala = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Descrição (opcional)',
            hintText: 'Detalhes adicionais sobre a escala',
            prefixIcon: const Icon(Icons.description),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          maxLines: 2,
          onChanged: (value) => descricaoEscala = value,
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          value: eventoIdSelecionado,
          decoration: InputDecoration(
            labelText: 'Evento',
            hintText: 'Selecione o evento',
            prefixIcon: const Icon(Icons.event),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          dropdownColor: context.colors.surface,
          items: eventos.map<DropdownMenuItem<String>>((e) => DropdownMenuItem<String>(
            value: e.id,
            child: Text(
              '${e.nome} - ${e.dataHora?.day}/${e.dataHora?.month}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: context.colors.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          )).toList(),
          onChanged: (value) {
            setState(() {
              eventoIdSelecionado = value;
              try {
                final eventoSel = context.read<EventoController>().todos.firstWhere((e) => e.id == value);
                _eventMinistryId = eventoSel.ministerioId;
                templateIdSelecionado = eventoSel.templateId;
              } catch (_) {
                _eventMinistryId = null;
                templateIdSelecionado = null;
              }
              _pseudoTemplate = null;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Selecione um evento';
            }
            return null;
          },
        ),
        ],
      ),
    );
  }

  // Removido: passo de template não é mais utilizado no fluxo

  Widget _buildScaleStep(BuildContext context, TemplateModel templateSelecionado) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text(
          'Preencher Escala',
          style: context.textStyles.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          templateIdSelecionado == null 
              ? 'Adicione voluntários para sua escala livre'
              : 'Atribua voluntários para cada função do template',
          style: context.textStyles.bodyMedium?.copyWith(
            color: context.colors.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 24),
        
        // Toggle para modo flexível
        if (templateIdSelecionado != null && templateSelecionado.funcoes.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: context.colors.outline.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.swap_horiz,
                  color: context.colors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modo Flexível',
                        style: context.textStyles.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Permite selecionar voluntários de outras funções',
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _modoFlexivel,
                  onChanged: (value) {
                    setState(() {
                      _modoFlexivel = value;
                    });
                  },
                  activeColor: context.colors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        if (templateIdSelecionado == null) ...[
          // Escala Livre - permitir adicionar funções manualmente
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(
                color: context.colors.outline.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 48,
                  color: context.colors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Escala Livre',
                  style: context.textStyles.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Funcionalidade em desenvolvimento.\nPor enquanto, use um template existente.',
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentStep = 1;
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Voltar e Escolher Template'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: context.colors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ] else if (templateSelecionado.funcoes.isNotEmpty) ...[
          // Layout em duas colunas: Função (esquerda) | Voluntário (direita)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: context.colors.outline.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Cabeçalho
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text(
                          'Função',
                          style: context.textStyles.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colors.onSurface,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 7,
                        child: Text(
                          'Voluntário',
                          textAlign: TextAlign.right,
                          style: context.textStyles.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Linhas por função/slot
                ...templateSelecionado.funcoes.expand((f) {
                  final functionId = f.id;
                  final nomeFuncao = _getNomeFuncao(functionId);
                  return List.generate(f.quantidade, (slotIndex) {
                    final slotKey = '${functionId}_$slotIndex';
                    final labelEsquerda = f.quantidade > 1
                        ? '$nomeFuncao  #${slotIndex + 1}'
                        : nomeFuncao;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: context.colors.outline.withValues(alpha: 0.15)),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Coluna esquerda: Função
                          Expanded(
                            flex: 5,
                            child: Row(
                              children: [
                                Icon(Icons.person, size: 18, color: context.colors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    labelEsquerda,
                                    style: context.textStyles.bodyMedium?.copyWith(
                                      color: context.colors.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Coluna direita: Dropdown de voluntário
                          Expanded(
                            flex: 7,
                            child: DropdownButtonFormField<String>(
                              value: _getVoluntariosDisponiveis(functionId, slotKey).any((v) => v.userId == selecaoVoluntariosPorFuncao[slotKey])
                                  ? selecaoVoluntariosPorFuncao[slotKey]
                                  : null,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                hintText: 'Selecionar voluntário',
                              ),
                              dropdownColor: context.colors.surface,
                              items: _isCarregandoVoluntarios(functionId)
                                  ? [DropdownMenuItem(
                                      value: null,
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text('Carregando voluntários...', style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.6))),
                                        ],
                                      ),
                                    )]
                                  : _getVoluntariosDisponiveis(functionId, slotKey).isEmpty
                                      ? [DropdownMenuItem(
                                          value: null,
                                          child: Row(
                                            children: [
                                              Icon(Icons.info_outline, size: 16, color: context.colors.onSurface.withValues(alpha: 0.6)),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Todos os voluntários já foram selecionados',
                                                  style: TextStyle(
                                                    color: context.colors.onSurface.withValues(alpha: 0.6),
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )]
                                      : _getVoluntariosDisponiveis(functionId, slotKey)
                                          .map((voluntario) => DropdownMenuItem(
                                                value: voluntario.userId,
                                                child: Text(
                                                  voluntario.user?.name ?? 'Nome não informado',
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ))
                                          .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selecaoVoluntariosPorFuncao[slotKey] = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) return 'Selecione um voluntário';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  });
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(
                color: context.colors.outline.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 48,
                  color: context.colors.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Template sem funções',
                  style: context.textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Este template não possui funções definidas.',
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
        
        ],
      ),
    );
  }

  VoidCallback? _getFloatingActionButtonAction() {
    switch (_currentStep) {
      case 0:
        return eventoIdSelecionado != null ? () async {
          final eventoController = context.read<EventoController>();
          bool temTemplate = false;
          try {
            final e = eventoController.todos.firstWhere((ev) => ev.id == eventoIdSelecionado);
            temTemplate = (e.templateId != null && e.templateId!.isNotEmpty);
          } catch (_) {}

          if (temTemplate) {
            await _prepararParaPassoEscala();
            setState(() {
              _currentStep = 1;
            });
          } else {
            await _prepararParaPassoEscala();
            setState(() {
              _currentStep = 1;
            });
          }
        } : null;
      case 1:
        return _salvar;
      default:
        return null;
    }
  }

  IconData _getFloatingActionButtonIcon() {
    switch (_currentStep) {
      case 0:
        return Icons.arrow_forward;
      case 1:
        return Icons.check;
      default:
        return Icons.arrow_forward;
    }
  }

  String _getFloatingActionButtonLabel() {
    switch (_currentStep) {
      case 0:
        return 'Continuar';
      case 1:
        return 'Criar Escala';
      default:
        return 'Continuar';
    }
  }
}
