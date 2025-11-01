import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/escalas/controllers/template/template_controller.dart';
import 'package:servus_app/features/leader/escalas/models/template_model.dart';
import 'package:servus_app/features/ministries/models/ministry_function.dart';
import 'package:servus_app/shared/widgets/fab_safe_scroll_view.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';

class TemplateFormScreen extends StatefulWidget {
  final TemplateModel? templateExistente;
  final bool returnToEscalaForm;
  final String? initialMinistryId;

  const TemplateFormScreen({
    super.key, 
    this.templateExistente,
    this.returnToEscalaForm = false,
    this.initialMinistryId,
  });

  @override
  State<TemplateFormScreen> createState() => _TemplateFormScreenState();
}

class _TemplateFormScreenState extends State<TemplateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController observacoesController = TextEditingController();

  // Estado para controle de ministério e funções
  String? ministerioSelecionado;
  List<MinistryFunction> funcoesDisponiveis = [];
  Map<String, int> quantidadesFuncoes = {}; // ministryFunctionId -> quantidade

  @override
  void initState() {
    super.initState();
    final template = widget.templateExistente;
    if (template != null) {
      nomeController.text = template.nome;
      observacoesController.text = template.observacoes ?? '';
      // Dados do template existente serão carregados em _inicializarMinisterio()
    }
    _inicializarMinisterio();
  }

  void _inicializarMinisterio() async {
    final controller = context.read<TemplateController>();
    await controller.refreshMinisterios();
    
    debugPrint('Ministérios carregados: ${controller.ministerios.length}');
    debugPrint('Ministérios: ${controller.ministerios.map((m) => m.name).toList()}');
    
    if (mounted) {
      setState(() {
        if (widget.templateExistente != null && widget.templateExistente!.funcoes.isNotEmpty) {
          // Template existente: usar ministério das funções
          ministerioSelecionado = widget.templateExistente!.funcoes.first.ministerioId;
          debugPrint('Ministério do template existente: $ministerioSelecionado');
          _carregarFuncoesDoMinisterio(ministerioSelecionado!);
        } else if (widget.initialMinistryId != null && widget.initialMinistryId!.isNotEmpty) {
          // Pré-seleção recebida da tela anterior
          ministerioSelecionado = widget.initialMinistryId;
          debugPrint('Ministério pré-selecionado recebido: $ministerioSelecionado');
          _carregarFuncoesDoMinisterio(widget.initialMinistryId!);
        } else if (controller.ministerios.length == 1) {
          // Template novo: Se líder de apenas um ministério, seleciona automaticamente
          ministerioSelecionado = controller.ministerios.first.id;
          debugPrint('Ministério selecionado automaticamente: ${controller.ministerios.first.name}');
          _carregarFuncoesDoMinisterio(controller.ministerios.first.id);
        } else if (controller.ministerios.length > 1) {
          debugPrint('Múltiplos ministérios encontrados: ${controller.ministerios.map((m) => m.name).toList()}');
        } else {
          debugPrint('Nenhum ministério encontrado para o usuário');
        }
      });
    }
  }

  void _carregarFuncoesDoMinisterio(String ministryId) async {
    final controller = context.read<TemplateController>();
    try {
      final funcoes = await controller.getFuncoesDoMinisterio(ministryId);
      if (mounted) {
        setState(() {
          funcoesDisponiveis = funcoes;
          // Inicializar quantidades
          quantidadesFuncoes.clear();
          for (final funcao in funcoes) {
            // Se é um template existente, carregar quantidades salvas
            if (widget.templateExistente != null) {
              debugPrint('🔍 [TemplateForm] Buscando função: ${funcao.name} (ID: ${funcao.functionId})');
              debugPrint('🔍 [TemplateForm] Funções do template: ${widget.templateExistente!.funcoes.map((f) => '${f.nome}:${f.quantidade} (ID: ${f.id})').toList()}');
              
              // Primeiro tenta mapear por nome (templates novos)
              FuncaoEscala? funcaoTemplate = widget.templateExistente!.funcoes
                  .where((f) => f.nome == funcao.name)
                  .firstOrNull;
              
              // Se não encontrou por nome, tenta mapear por ID (templates antigos)
              if (funcaoTemplate == null) {
                funcaoTemplate = widget.templateExistente!.funcoes
                    .where((f) => f.id == funcao.functionId)
                    .firstOrNull;
                debugPrint('🔍 [TemplateForm] Mapeamento por ID: ${funcaoTemplate?.nome} com quantidade: ${funcaoTemplate?.quantidade}');
              } else {
                debugPrint('🔍 [TemplateForm] Mapeamento por nome: ${funcaoTemplate.nome} com quantidade: ${funcaoTemplate.quantidade}');
              }
              
              quantidadesFuncoes[funcao.functionId] = funcaoTemplate?.quantidade ?? 0;
            } else {
              // Template novo, inicializar com 0
              quantidadesFuncoes[funcao.functionId] = 0;
            }
          }
          
          debugPrint('🔍 [TemplateForm] Quantidades finais: $quantidadesFuncoes');
        });
      }
    } catch (e) {
      if (mounted) {
        ServusSnackQueue.addToQueue(
          context: context,
          message: 'Erro ao carregar funções: $e',
          type: ServusSnackType.error,
        );
      }
    }
  }

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      // Verificar se pelo menos uma função tem quantidade > 0
      final funcoesComQuantidade = quantidadesFuncoes.entries
          .where((entry) => entry.value > 0)
          .toList();
      
      if (funcoesComQuantidade.isEmpty) {
        ServusSnackQueue.addToQueue(
          context: context,
          message: 'Selecione pelo menos uma função com quantidade maior que zero',
          type: ServusSnackType.warning,
        );
        return;
      }

      // Criar lista de funções para o template
      final List<FuncaoEscala> funcoesTemplate = [];
      for (final entry in funcoesComQuantidade) {
        final funcao = funcoesDisponiveis.firstWhere((f) => f.functionId == entry.key);
        funcoesTemplate.add(FuncaoEscala(
          nome: funcao.name,
          ministerioId: ministerioSelecionado ?? '',
          quantidade: entry.value,
        ));
      }

      final template = TemplateModel(
        id: widget.templateExistente?.id,
        nome: nomeController.text,
        funcoes: funcoesTemplate,
        observacoes: observacoesController.text,
      );

      final controller = context.read<TemplateController>();
      try {
        if (widget.templateExistente == null) {
          await controller.adicionarTemplate(template);
        } else {
          await controller.atualizarTemplate(template);
        }
        // Navegação baseada na origem
        if (widget.returnToEscalaForm) {
          Navigator.pop(context, true); // Retorna com resultado para escala_form
        } else {
          Navigator.pop(context); // Fluxo normal para listagem
        }
        
        ServusSnackQueue.addToQueue(
          context: context,
          message: widget.templateExistente == null 
              ? 'Template criado com sucesso!' 
              : 'Template atualizado com sucesso!',
          type: ServusSnackType.success,
        );
      } catch (e) {
        ServusSnackQueue.addToQueue(
          context: context,
          message: 'Erro ao salvar template: $e',
          type: ServusSnackType.error,
        );
      }
    }
  }

  void _incrementarQuantidade(String functionId) {
    setState(() {
      final quantidadeAtual = quantidadesFuncoes[functionId] ?? 0;
      if (quantidadeAtual < 50) {
        quantidadesFuncoes[functionId] = quantidadeAtual + 1;
      }
    });
  }

  void _decrementarQuantidade(String functionId) {
    setState(() {
      final quantidadeAtual = quantidadesFuncoes[functionId] ?? 0;
      if (quantidadeAtual > 0) {
        quantidadesFuncoes[functionId] = quantidadeAtual - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          widget.templateExistente == null ? 'Novo Template' : 'Editar Template',
          style: context.textStyles.titleLarge?.copyWith(
            color: context.colors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: Consumer<TemplateController>(
        builder: (context, controller, _) {
          return FloatingActionButton.extended(
            onPressed: controller.isLoading ? null : _salvar,
            backgroundColor: context.colors.primary,
            foregroundColor: context.colors.onPrimary,
            label: Text(
              controller.isLoading ? 'Salvando...' : 'Salvar', 
              style: context.textStyles.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.onPrimary,
              )
            ),
            icon: controller.isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.check),
          );
        },
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
                
                // Nome do template
                TextFormField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: 'Nome do template'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                
                // Observações
                TextFormField(
                  controller: observacoesController,
                  decoration: const InputDecoration(labelText: 'Observações'),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                
                // Seleção de ministério (apenas se múltiplos)
                Consumer<TemplateController>(
                  builder: (context, controller, _) {
                    if (controller.isLoadingMinistries) {
                      return const Column(
                        children: [
                          SizedBox(height: 16),
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('Carregando ministérios...'),
                          SizedBox(height: 24),
                        ],
                      );
                    }
                    
                    if (controller.ministerios.length > 1) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ministério',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: ministerioSelecionado,
                            decoration: const InputDecoration(
                              hintText: 'Selecione um ministério',
                            ),
                            items: controller.ministerios
                                .map((m) => DropdownMenuItem(
                                  value: m.id,
                                  child: Text(m.name),
                                ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                ministerioSelecionado = value;
                                if (value != null) {
                                  _carregarFuncoesDoMinisterio(value);
                                }
                              });
                            },
                            validator: (value) =>
                                value == null ? 'Selecione um ministério' : null,
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    } else if (controller.ministerios.length == 1) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ministério',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.church, color: context.colors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  controller.ministerios.first.name,
                                  style: context.textStyles.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    } else {
                      return const Column(
                        children: [
                          SizedBox(height: 16),
                          Text('Nenhum ministério encontrado'),
                          SizedBox(height: 24),
                        ],
                      );
                    }
                  },
                ),
                
                // Funções disponíveis
                if (ministerioSelecionado != null && funcoesDisponiveis.isNotEmpty) ...[
                   Text(
                    'Funções Disponíveis',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.onSurface),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ajuste a quantidade de voluntários para cada função:',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  // Lista de funções
                  ...funcoesDisponiveis.map((funcao) {
                    final quantidade = quantidadesFuncoes[funcao.functionId] ?? 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              funcao.name,
                              style: context.textStyles.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: quantidade > 0 
                                    ? () => _decrementarQuantidade(funcao.functionId)
                                    : null,
                                icon: Icon(
                                  Icons.remove,
                                  color: context.colors.onPrimary,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: quantidade > 0 
                                      ? context.colors.errorContainer 
                                      : Colors.grey.shade200,
                                  foregroundColor: quantidade > 0 
                                      ? context.colors.onErrorContainer 
                                      : Colors.grey,
                                ),
                              ),
                              Container(
                                width: 50,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  quantidade.toString(),
                                  textAlign: TextAlign.center,
                                  style: context.textStyles.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.colors.primary,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: quantidade < 50 
                                    ? () => _incrementarQuantidade(funcao.functionId)
                                    : null,
                                icon: const Icon(Icons.add),
                                style: IconButton.styleFrom(
                                  backgroundColor: quantidade < 50 
                                      ? context.colors.primaryContainer 
                                      : Colors.grey.shade200,
                                  foregroundColor: quantidade < 50 
                                      ? context.colors.onPrimaryContainer 
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  
                  const SizedBox(height: 24),
                  Text(
                    'Funções com quantidade 0 não serão salvas no template.',
                    style: context.textStyles.bodySmall?.copyWith(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ] else if (ministerioSelecionado != null && funcoesDisponiveis.isEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Nenhuma função encontrada para este ministério.'),
                ],
                
                const SizedBox(height: 100), // Espaço extra no final para o FAB
              ],
            ),
          ),
        ),
      ),
    );
  }
}