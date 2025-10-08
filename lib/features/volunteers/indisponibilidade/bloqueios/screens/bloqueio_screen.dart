import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/core/models/recurrence_pattern.dart';
import 'package:servus_app/features/volunteers/indisponibilidade/bloqueios/controller/bloqueio_controller.dart';
import 'package:servus_app/features/volunteers/indisponibilidade/widgets/recurrence_config_widget.dart';

class BloqueioScreen extends StatefulWidget {
  final Function(String, List<String>, RecurrencePattern?, BloqueioController) onConfirmar;
  final String? motivoInicial;
  final List<String>? ministeriosIniciais;
  final List<Map<String, String>> ministeriosDisponiveis;
  final DateTime? selectedDate;

  const BloqueioScreen({
    super.key,
    required this.onConfirmar,
    required this.ministeriosDisponiveis,
    this.motivoInicial,
    this.ministeriosIniciais,
    this.selectedDate,
  });

  @override
  State<BloqueioScreen> createState() => _BloqueioScreenState();
}

class _BloqueioScreenState extends State<BloqueioScreen> {
  final BloqueioController controller = BloqueioController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  RecurrencePattern? _recurrencePattern;

  @override
  void initState() {
    super.initState();
    print('🔍 [BloqueioScreen] ===== BLOQUEIO SCREEN ABERTA =====');
    print('🔍 [BloqueioScreen] initState chamado');
    print('🔍 [BloqueioScreen] Ministérios disponíveis recebidos: ${widget.ministeriosDisponiveis}');
    print('🔍 [BloqueioScreen] Quantidade de ministérios: ${widget.ministeriosDisponiveis.length}');
    print('🔍 [BloqueioScreen] Tipo dos ministérios: ${widget.ministeriosDisponiveis.runtimeType}');
    
    controller.inicializar(
      motivoInicial: widget.motivoInicial,
      ministeriosIniciais: widget.ministeriosIniciais,
      todosMinisterios: widget.ministeriosDisponiveis,
    );
    
    print('🔍 [BloqueioScreen] Controller inicializado');
    print('🔍 [BloqueioScreen] Ministérios no controller após inicialização: ${controller.ministeriosSelecionados.keys.toList()}');
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Consumer<BloqueioController>(
        builder: (context, controller, _) {
          final isEdicao = widget.motivoInicial != null;

          return Scaffold(
            appBar: AppBar(
              backgroundColor: context.theme.scaffoldBackgroundColor,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: context.colors.onSurface,
                ),
                onPressed: () => context.pop(),
              ),
              title: Text(
                isEdicao ? 'Editar Bloqueio' : 'Novo Bloqueio',
                style: context.theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurface,
                ),
              ),
            ),
            body: Form(
              key: formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campo de motivo
                    Text(
                      'Motivo do bloqueio',
                      style: context.theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.motivoController,
                      decoration: InputDecoration(
                        hintText: 'Digite o motivo do bloqueio...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: context.colors.surface,
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, digite o motivo do bloqueio';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Seleção de ministérios
                    Text(
                      'Ministérios',
                      style: context.theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    if (controller.mostrarMensagemInfo)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.colors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: context.colors.onPrimaryContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Selecione os ministérios para os quais este bloqueio se aplica',
                                style: context.theme.textTheme.bodySmall?.copyWith(
                                  color: context.colors.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 12),
                    
                    // Lista de ministérios
                    ...controller.ministeriosSelecionados.entries.map((entry) {
                      final nomeMinisterio = entry.key;
                      final isSelecionado = entry.value;
                      
                      return CheckboxListTile(
                        title: Text(nomeMinisterio),
                        value: isSelecionado,
                        onChanged: (value) {
                          controller.toggleMinisterio(nomeMinisterio);
                        },
                        activeColor: context.colors.primary,
                      );
                    }).toList(),
                    
                    if (controller.erroMinisterios)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Selecione pelo menos um ministério',
                          style: context.theme.textTheme.bodySmall?.copyWith(
                            color: context.colors.error,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Configuração de recorrência
                    RecurrenceConfigWidget(
                      initialPattern: _recurrencePattern,
                      startDate: widget.selectedDate ?? DateTime.now(),
                      onPatternChanged: (pattern) {
                        setState(() {
                          _recurrencePattern = pattern;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 100), // Espaço para o botão flutuante
                  ],
                ),
              ),
            ),
            floatingActionButton: Consumer<BloqueioController>(
              builder: (context, controller, child) {
                return FloatingActionButton.extended(
                  onPressed: controller.isLoading ? null : () async {
                    print('🔍 [BloqueioScreen] ===== BOTÃO CONFIRMAR CLICADO =====');
                    print('🔍 [BloqueioScreen] Motivo: "${controller.motivoController.text}"');
                    print('🔍 [BloqueioScreen] Motivo length: ${controller.motivoController.text.length}');
                    print('🔍 [BloqueioScreen] Ministérios selecionados: ${controller.ministeriosSelecionados.entries.where((e) => e.value).map((e) => e.key).toList()}');
                    print('🔍 [BloqueioScreen] Todos os ministérios: ${controller.ministeriosSelecionados}');
                    
                    try {
                      final sucesso = controller.validarFormulario(formKey);
                      print('🔍 [BloqueioScreen] Validação: $sucesso');
                      print('🔍 [BloqueioScreen] Erro ministérios: ${controller.erroMinisterios}');
                      
                      if (sucesso) {
                        print('✅ [BloqueioScreen] Validação passou, chamando onConfirmar');
                        
                        // Ativar loading
                        controller.setLoading(true);
                        
                        final motivo = controller.motivoController.text.trim();
                        final ministerios = controller.ministeriosSelecionados.entries
                            .where((e) => e.value)
                            .map((e) => e.key)
                            .toList();
                        
                        print('🔍 [BloqueioScreen] Chamando onConfirmar com:');
                        print('🔍 [BloqueioScreen] - Motivo: "$motivo"');
                        print('🔍 [BloqueioScreen] - Recorrência: ${_recurrencePattern?.toString() ?? "Nenhuma"}');
                        print('🔍 [BloqueioScreen] ===== CHAMANDO onConfirmar =====');
                        
                        await widget.onConfirmar(motivo, ministerios, _recurrencePattern, controller);
                        print('✅ [BloqueioScreen] onConfirmar concluído com sucesso');
                        
                        // Navigator.pop será chamado pelo IndisponibilidadeScreen após sucesso
                        print('🔍 [BloqueioScreen] Aguardando Navigator.pop do IndisponibilidadeScreen');
                      } else {
                        print('❌ [BloqueioScreen] Validação falhou');
                        print('❌ [BloqueioScreen] Motivo válido: ${controller.motivoController.text.trim().isNotEmpty}');
                        print('❌ [BloqueioScreen] Ministérios válidos: ${!controller.erroMinisterios}');
                      }
                    } catch (e) {
                      print('❌ [BloqueioScreen] Erro no onPressed: $e');
                      print('❌ [BloqueioScreen] Stack trace: ${StackTrace.current}');
                      // Desativar loading em caso de erro
                      controller.setLoading(false);
                    }
                    
                    print('🔍 [BloqueioScreen] ===== FIM DO BOTÃO CONFIRMAR =====');
                  },
                  backgroundColor: controller.isLoading ? Colors.grey : const Color(0xFF4058DB),
                  icon: controller.isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        isEdicao ? Icons.save : Icons.check,
                        color: Colors.white,
                      ),
                  label: Text(
                    controller.isLoading 
                      ? 'Salvando...' 
                      : (isEdicao ? 'Salvar alterações' : 'Confirmar'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}