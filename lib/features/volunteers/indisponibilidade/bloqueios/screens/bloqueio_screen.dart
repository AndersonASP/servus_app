import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/volunteers/indisponibilidade/bloqueios/controller/bloqueio_controller.dart';

class BloqueioScreen extends StatefulWidget {
  final Function(String, List<String>, BloqueioController) onConfirmar;
  final String? motivoInicial;
  final List<String>? ministeriosIniciais;
  final List<Map<String, dynamic>> ministeriosDisponiveis;
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

  @override
  void initState() {
    super.initState();
    
    controller.inicializar(
      motivoInicial: widget.motivoInicial,
      ministeriosIniciais: widget.ministeriosIniciais,
      todosMinisterios: widget.ministeriosDisponiveis,
    );
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
              centerTitle: false,
              title: Text(
                isEdicao ? 'Editar Bloqueio' : 'Novo Bloqueio',
                style: context.theme.textTheme.titleLarge?.copyWith(
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
                    Consumer<BloqueioController>(
                      builder: (context, controller, _) {
                        if (controller.ministeriosSelecionados.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Nenhum ministério disponível',
                              style: TextStyle(
                                color: context.colors.onSurface.withValues(alpha: 0.6),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          );
                        }
                        
                        return Column(
                          children: controller.ministeriosSelecionados.entries.map((entry) {
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
                        );
                      },
                    ),
                    
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
                  ],
                ),
              ),
            ),
            floatingActionButton: Consumer<BloqueioController>(
              builder: (context, controller, child) {
                return FloatingActionButton.extended(
                  onPressed: controller.isLoading ? null : () async {
                    try {
                      final sucesso = controller.validarFormulario(formKey);
                      
                      if (sucesso) {
                        // Ativar loading
                        controller.setLoading(true);
                        
                        final motivo = controller.motivoController.text.trim();
                        final ministerios = controller.ministeriosSelecionados.entries
                            .where((e) => e.value)
                            .map((e) => e.key)
                            .toList();
                        
                        await widget.onConfirmar(motivo, ministerios, controller);
                      }
                    } catch (e) {
                      // Desativar loading em caso de erro
                      controller.setLoading(false);
                    }
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