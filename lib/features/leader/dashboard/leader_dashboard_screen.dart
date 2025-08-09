import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/dashboard/leader_dashboard_controller.dart';
import 'package:servus_app/features/leader/dashboard/widgets/aniversariantes_widget.dart';
import 'package:servus_app/features/leader/dashboard/widgets/drawer_menu_lider_widget.dart';
import 'package:servus_app/features/leader/dashboard/widgets/escala_mensal_widget.dart';
import 'package:servus_app/state/auth_state.dart';

class DashboardLiderScreen extends StatefulWidget {
  const DashboardLiderScreen({super.key});

  @override
  State<DashboardLiderScreen> createState() => _DashboardLiderScreenState();
}

class _DashboardLiderScreenState extends State<DashboardLiderScreen> {
  late final DashboardLiderController controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthState>(context, listen: false);
    controller = DashboardLiderController(auth: auth);
    controller.init();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    controller.dispose();
    super.dispose();
  }

  void _scrollToCard(int index) {
    const double cardWidth = 160;
    const double spacing = 12;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double totalCardWidth = cardWidth + spacing;

    final double targetOffset =
        (index * totalCardWidth) - (screenWidth / 2 - cardWidth / 2);

    final double clampedOffset = targetOffset.clamp(
      0,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Consumer<DashboardLiderController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            drawer: DrawerMenuLider(
              onTrocarModo: () {
                context.pop(context); // Fecha o Drawer
                context.go('/volunteer/dashboard');
              },
              ministerioSelecionado: controller.ministerioSelecionado,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        const DrawerButton(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Olá, ${controller.usuario.nome.split(' ').first}!',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                        fontSize: 25,
                                        fontWeight: FontWeight.w800,
                                        color: context.colors.onSurface),
                              ),
                            ],
                          ),
                        ),
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            const Icon(Icons.notifications_none, size: 30),
                            Positioned(
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Text(
                                  '15',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    if (controller.usuario.isAdmin)
                      // Substituir esta parte no DashboardLiderScreen
                      if (controller.usuario.isAdmin)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ministérios',
                              style: context.textStyles.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.colors.onSurface,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                context.push('/leader/ministerio/lista');
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Ver todos',
                                    style: context.textStyles.bodyLarge
                                        ?.copyWith(
                                            color: context.colors.onSurface,
                                            fontSize: 15),
                                  ),
                                  const SizedBox(width: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 1), // Ajuste fino
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      size:
                                          14, // ligeiramente maior para igualar altura do texto
                                      color: context.colors.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.ministerios.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          if (index == controller.ministerios.length) {
                            return GestureDetector(
                              onTap: () {
                                context.push('/leader/ministerio/form');
                              },
                              child: Container(
                                width: 140,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: context.colors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(Icons.add_circle_outline,
                                      size: 36, color: context.colors.primary),
                                ),
                              ),
                            );
                          }

                          final ministerio = controller.ministerios[index];
                          final isSelected =
                              controller.ministerioSelecionado != null &&
                                  ministerio.id ==
                                      controller.ministerioSelecionado!.id;

                          return GestureDetector(
                            onTap: () {
                              controller.carregarDadosDoMinisterio(ministerio);
                              _scrollToCard(index);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: 140,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? context.colors.primary
                                    : context.colors.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.groups,
                                      color: isSelected
                                          ? Colors.white
                                          : context.colors.onSurface),
                                  const SizedBox(height: 8),
                                  Text(
                                    ministerio.nome,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : context.colors.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),
                    // Métricas
                    Row(
                      children: [
                        Expanded(
                          child: _infoCard(
                            title: 'Voluntários ativos',
                            value: controller.totalVoluntarios.toString(),
                            isLoading: controller.isLoadingVoluntarios,
                            icon: Icons.people,
                            iconColor: context.colors.primary,
                            onTap: () {
                              context.push(
                                '/leader/dashboard/voluntarios',
                                extra: controller.ministerioSelecionado,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _infoCard(
                            title: 'Solicitações de troca',
                            value: controller.totalSolicitacoesPendentes
                                .toString(),
                            isLoading: controller.isLoadingSolicitacoes,
                            icon: Icons.change_circle,
                            iconColor: context.colors.primary,
                            onTap: () {
                              context.push(
                                '/leader/dashboard/solicitacao-troca',
                                extra: controller.ministerioSelecionado,
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const EscalasResumoWidget(
                      ministerioId: '2',
                    ),
                    const SizedBox(height: 12),
                    AniversariantesWidget(
                      aniversariantes: [
                        Aniversariante(
                          nome: 'João Silva',
                          fotoUrl:
                              'https://randomuser.me/api/portraits/men/1.jpg',
                          dia: 12,
                        ),
                        Aniversariante(
                          nome: 'Maria Oliveira',
                          fotoUrl:
                              'https://randomuser.me/api/portraits/women/2.jpg',
                          dia: 18,
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

  Widget _infoCard({
    required String title,
    required String value,
    required bool isLoading,
    IconData? icon,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final cardContent = isLoading
        ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.textStyles.labelLarge?.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (icon != null)
                    Icon(icon, color: iconColor ?? context.colors.primary),
                  if (icon != null) const SizedBox(width: 6),
                  Text(
                    value,
                    style: context.textStyles.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: context.colors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: cardContent,
      ),
    );
  }
}
