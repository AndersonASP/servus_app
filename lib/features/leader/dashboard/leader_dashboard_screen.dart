import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/core/widgets/shimmer_widget.dart';
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

class _DashboardLiderScreenState extends State<DashboardLiderScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  late final DashboardLiderController controller;
  final ScrollController _scrollController = ScrollController();
  
  // Controllers para animações
  late final AnimationController _animationController;
  late final AnimationController _staggerController;
  List<Animation<double>> _cardAnimations = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final auth = Provider.of<AuthState>(context, listen: false);
    controller = DashboardLiderController(auth: auth);
    
    // Inicializar animações
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _cardAnimations = List.generate(4, (index) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _staggerController,
        curve: Interval(
          index * 0.15,
          0.6 + (index * 0.15),
          curve: Curves.easeOutCubic,
        ),
      ));
    });
    
    controller.init().then((_) {
      _animationController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _staggerController.forward();
        }
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Atualiza o dashboard quando o app volta ao foco
      controller.refreshDashboard();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _animationController.dispose();
    _staggerController.dispose();
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
            return Scaffold(
              backgroundColor: context.theme.scaffoldBackgroundColor,
              body: const ShimmerDashboard(),
            );
          }

          return Scaffold(
            drawer: DrawerMenuLider(
              onTrocarModo: () {
                context.pop(context); // Fecha o Drawer
                context.go('/volunteer/dashboard');
              },
              ministerioSelecionado: null, // TODO: Converter MinistryResponse para Ministerio
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                await controller.refreshDashboard();
              },
              child: SafeArea(
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
                                      ministerio.name,
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
                            child: _cardAnimations.isNotEmpty
                                ? AnimatedBuilder(
                                    animation: _cardAnimations[0],
                                    builder: (context, child) {
                                      return Transform.translate(
                                        offset: Offset(0, 20 * (1 - _cardAnimations[0].value)),
                                        child: Opacity(
                                          opacity: _cardAnimations[0].value,
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
                                      );
                                    },
                                  )
                                : _infoCard(
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
                            child: _cardAnimations.length > 1
                                ? AnimatedBuilder(
                                    animation: _cardAnimations[1],
                                    builder: (context, child) {
                                      return Transform.translate(
                                        offset: Offset(0, 20 * (1 - _cardAnimations[1].value)),
                                        child: Opacity(
                                          opacity: _cardAnimations[1].value,
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
                                      );
                                    },
                                  )
                                : _infoCard(
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

                      const SizedBox(height: 24),
                      
                      // Card de Filiais
                      if (controller.usuario.isAdmin)
                        _cardAnimations.length > 2
                            ? AnimatedBuilder(
                                animation: _cardAnimations[2],
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0, 20 * (1 - _cardAnimations[2].value)),
                                    child: Opacity(
                                      opacity: _cardAnimations[2].value,
                                      child: _infoCard(
                                        title: 'Filiais',
                                        value: 'Gerenciar',
                                        isLoading: false,
                                        icon: Icons.business,
                                        iconColor: context.colors.primary,
                                        onTap: () {
                                          context.push('/leader/branches');
                                        },
                                      ),
                                    ),
                                  );
                                },
                              )
                            : _infoCard(
                                title: 'Filiais',
                                value: 'Gerenciar',
                                isLoading: false,
                                icon: Icons.business,
                                iconColor: context.colors.primary,
                                onTap: () {
                                  context.push('/leader/branches');
                                },
                              ),

                      const SizedBox(height: 12),

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
          ));
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

  Widget _buildLoadingScreen(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header shimmer
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 200,
                        height: 25,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 150,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Cards shimmer
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Single card shimmer
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
