import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/volunteers/indisponibilidade/bloqueios/controller/bloqueio_controller.dart';

class BloqueioScreen extends StatefulWidget {
  final Function(String, List<String>) onConfirmar;
  final String? motivoInicial;
  final List<String> ministeriosDisponiveis;

  const BloqueioScreen({
    super.key,
    required this.onConfirmar,
    required this.ministeriosDisponiveis,
    this.motivoInicial,
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
                icon: Icon(Icons.arrow_back, color: context.colors.onSurface),
                onPressed: () => context.pop(),
              ),
              centerTitle: false,
              title: Text(
                isEdicao ? 'Editar Bloqueio' : 'Novo Bloqueio',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.onSurface,
                    ),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Form(
                      key: formKey,
                      child: TextFormField(
                        controller: controller.motivoController,
                        maxLines: 1,
                        validator: controller.validarMotivo,
                        decoration: InputDecoration(
                          hintText: 'Ex: Vou tirar férias em Acapulco',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (controller.mostrarMensagemInfo)
                      Text(
                        'Apenas seu líder poderá ver o motivo da indisponibilidade.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontStyle: FontStyle.italic,
                              fontSize: 10,
                            ),
                      ),
                    const SizedBox(height: 16),
                    const Text('Selecione os ministérios:'),
                    ...controller.ministeriosSelecionados.entries.map(
                      (entry) => CheckboxListTile(
                        value: entry.value,
                        title: Text(entry.key),
                        onChanged: (value) {
                          controller.atualizarMinisterio(
                              entry.key, value ?? false);
                          controller.erroMinisterios = false;
                          controller.notifyListeners();
                        },
                      ),
                    ),
                    if (controller.erroMinisterios)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, top: 4),
                        child: Text(
                          'Selecione ao menos um ministério.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancelar',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final sucesso =
                                controller.validarFormulario(formKey);
                            if (sucesso) {
                              widget.onConfirmar(
                                controller.motivoController.text.trim(),
                                controller.ministeriosSelecionados.entries
                                    .where((e) => e.value)
                                    .map((e) => e.key)
                                    .toList(),
                              );
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4058DB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isEdicao ? 'Salvar alterações' : 'Confirmar',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
