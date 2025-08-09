import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/enums/ministry_module.dart';
import 'package:servus_app/core/permissions/feature_visibility_service.dart';
import 'package:servus_app/core/theme/color_scheme.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/volunteers/dashboard/escala/escala_detalhes/escala_detalhes_controller.dart';
import 'package:servus_app/state/auth_state.dart';

class EscalaDetalheScreen extends StatelessWidget {
  const EscalaDetalheScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.read<AuthState>().usuario;

    final possuiModuloLouvor = usuario != null &&
        FeatureVisibilityService.isDisponivelParaUsuario(
          modulo: MinistryModule.louvor,
          ministeriosDoUsuario: usuario.ministerios,
        );

    return ChangeNotifierProvider(
      create: (_) => EscalaDetalhesController(),
      builder: (context, _) {
        return DefaultTabController(
          length: possuiModuloLouvor ? 4 : 3,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: context.theme.scaffoldBackgroundColor,
              title: Text(
                'Detalhes da escala',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.onSurface,
                      fontSize: 20,
                    ),
              ),
              centerTitle: false,
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            body: Column(
              children: [
                /// Cabeçalho
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quarta da graça',
                        style: TextStyle(
                          color: context.colors.primary,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '22:11 | Quinta-feira | 24 de julho de 2025',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const Text(
                        'daqui a 2 dias',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),

                      /// Tabs
                      Container(
                        decoration: BoxDecoration(
                          color: context.colors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TabBar(
                          indicatorColor: context.colors.primary,
                          labelColor: context.colors.primary,
                          unselectedLabelColor: context.colors.onSurface,
                          tabs: [
                            const Tab(
                                icon: Icon(Icons.info_outline),
                                text: 'Detalhes'),
                            if (possuiModuloLouvor)
                              const Tab(
                                  icon: Icon(Icons.music_note),
                                  text: 'Músicas'),
                            const Tab(
                                icon: Icon(Icons.group), text: 'Participantes'),
                            const Tab(
                                icon: Icon(Icons.schedule), text: 'Roteiro'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                /// Conteúdo Tabs
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildDetalhesTab(context),
                      if (possuiModuloLouvor) _buildMusicasTab(),
                      _buildParticipantesTab(context),
                      _buildRoteiroTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ------------------------------
  /// ABA DETALHES
  /// ------------------------------
  Widget _buildDetalhesTab(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Informações adicionais da escala',
                style: context.textStyles.bodyLarge
                    ?.copyWith(color: context.colors.onSurface),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _abrirDialogTrocaEscala(context),
              icon: const Icon(Icons.change_circle),
              label: Text(
                'Solicitar troca de escala',
                style: context.textStyles.bodyLarge
                    ?.copyWith(color: context.colors.onPrimary),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ServusColors.error,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// ------------------------------
  /// DIALOG PARA SOLICITAÇÃO DE TROCA
  /// ------------------------------
  void _abrirDialogTrocaEscala(BuildContext context) {
    final controller = context.read<EscalaDetalhesController>();
    final textController = controller.trocaVoluntarioController;

    String? errorText;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                "Solicitar troca de escala",
                style: context.textStyles.titleLarge?.copyWith(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              content: TextField(
                controller: textController,
                decoration: InputDecoration(
                  hintText: "Indicar voluntário para trocar",
                  errorText: errorText, // Exibe a mensagem de erro
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && errorText != null) {
                    setState(() {
                      errorText = null;
                    });
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    controller.clearTroca();
                    context.pop();
                  },
                  child: Text(
                    "Cancelar",
                    style: context.textStyles.bodyLarge
                        ?.copyWith(color: context.colors.error),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (controller.isValidTroca) {
                      final nome = controller.voluntarioSelecionado;
                      context.pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: ServusColors.success,
                          content: Text(
                            "Solicitação enviada para $nome.",
                            style: context.textStyles.bodyLarge?.copyWith(
                              color: context.colors.onPrimary,
                            ),
                          ),
                        ),
                      );
                      controller.clearTroca();
                    } else {
                      // Atualiza o estado para exibir a mensagem de erro no campo
                      setState(() {
                        errorText = "Informe um voluntário antes de enviar.";
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: context.colors.onPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Enviar",
                    style: context.textStyles.bodyLarge?.copyWith(
                      color: context.colors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// ------------------------------
  /// ABA PARTICIPANTES
  /// ------------------------------
  Widget _buildParticipantesTab(BuildContext context) {
    final controller = context.watch<EscalaDetalhesController>();
    final participantes = controller.participantes;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: participantes.length,
      itemBuilder: (context, index) {
        final participante = participantes[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(participante['imagem']!),
              radius: 25,
            ),
            title: Text(
              participante['nome']!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(participante['funcao']!),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  participante['confirmado']!
                      ? Icons.check_circle
                      : Icons.cancel,
                  color:
                      participante['confirmado']! ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  participante['confirmado']! ? 'Confirmado' : 'Pendente',
                  style: TextStyle(
                    color:
                        participante['confirmado']! ? Colors.green : Colors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMusicasTab() {
    return const Center(child: Text('Nenhuma música adicionada.'));
  }

  Widget _buildRoteiroTab() {
    return const Center(child: Text('Nenhum roteiro disponível.'));
  }
}
