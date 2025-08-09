import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/volunteers/dashboard/escala/escala_card/escala_card_screen.dart';
import 'package:servus_app/features/volunteers/dashboard/widgets/drawer_menu_voluntario.dart';
import 'package:servus_app/state/auth_state.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late final DashboardController controller;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthState>(context, listen: false);
    controller = DashboardController(auth: auth);
    controller.init();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    controller.init().then((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Consumer<DashboardController>(
        builder: (context, controller, _) {
          return controller.isLoading && !controller.isInitialized
              ? const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                )
              : Stack(
                  children: [
                    Scaffold(
                      backgroundColor: context.theme.scaffoldBackgroundColor,
                      drawer: DrawerMenuVoluntario(
                        nome: controller.usuario.nome,
                        email: controller.usuario.email,
                        onTapPerfil: () => {context.push('/perfil')},
                        onTrocarModo: () {
                          context.go('/leader/dashboard');
                        },
                        exibirTrocaModo: true,
                      ),
                      body: SafeArea(
                        child: RefreshIndicator(
                          onRefresh: _handleRefresh,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const DrawerButton(),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  'Olá, ${controller.usuario.nome.split(' ').first}!',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.copyWith(
                                                          fontSize: 25,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color: context.colors
                                                              .onSurface)),
                                              RichText(
                                                text: TextSpan(
                                                  style: context
                                                      .textStyles.bodyLarge
                                                      ?.copyWith(
                                                    fontSize: 14,
                                                    color: context
                                                        .colors.onSurface,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  children: [
                                                    const TextSpan(
                                                        text: 'Você tem '),
                                                    TextSpan(
                                                      text: controller
                                                          .qtdEscalas
                                                          .toString(),
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w800),
                                                    ),
                                                    const TextSpan(
                                                        text:
                                                            ' escalas este mês'),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Stack(
                                          alignment: Alignment.topRight,
                                          children: [
                                            const Icon(Icons.notifications_none,
                                                size: 30),
                                            Positioned(
                                              right: 0,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Text('15',
                                                    style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w700)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    if (controller.escalas.isEmpty) ...[
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.6,
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SvgPicture.asset(
                                                  'assets/images/sem_escalas.svg',
                                                  width: 150,
                                                  height: 150),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Descanse um pouco!',
                                                style: context
                                                    .textStyles.bodyLarge
                                                    ?.copyWith(
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.w800,
                                                  color: context.colors.primary,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Você ainda não foi escalado para nenhum evento.',
                                                style: context
                                                    .textStyles.bodyLarge
                                                    ?.copyWith(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: context.colors.primary
                                                      .withValues(alpha: 0.6),
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      Text('sua próxima escala',
                                          style: context.textStyles.bodyLarge
                                              ?.copyWith(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: context.colors.onSurface,
                                          )),
                                      const SizedBox(height: 12),
                                      EscalaCardWidget(
                                        index:
                                            controller.escalas.first['index'] ??
                                                0,
                                        diasRestantes: controller
                                            .escalas.first['diasRestantes'],
                                        dia: controller.escalas.first['dia'],
                                        mes: controller.escalas.first['mes'],
                                        horario:
                                            controller.escalas.first['horario'],
                                        diaSemana: controller
                                            .escalas.first['diaSemana'],
                                        nomeEvento: controller
                                            .escalas.first['nomeEvento'],
                                        funcoes: List<String>.from(controller
                                            .escalas.first['funcoes']),
                                        statusLabel:
                                            controller.escalas.first['status'],
                                        statusColor:
                                            controller.escalas.first['cor'],
                                        controller: controller,
                                      ),
                                      const SizedBox(height: 24),
                                      if (controller.escalas.length > 1) ...[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('o que vem por aí',
                                                style: context
                                                    .textStyles.bodyLarge
                                                    ?.copyWith(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      context.colors.onSurface,
                                                )),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Column(
                                          children: List.generate(
                                            controller.escalas.length - 1,
                                            (index) {
                                              final escala =
                                                  controller.escalas[index + 1];
                                              return EscalaCardWidget(
                                                index: escala['index'] ??
                                                    index + 1,
                                                diasRestantes:
                                                    escala['diasRestantes'],
                                                dia: escala['dia'],
                                                mes: escala['mes'],
                                                nomeEvento:
                                                    escala['nomeEvento'],
                                                horario: escala['horario'],
                                                diaSemana: escala['diaSemana'],
                                                funcoes: List<String>.from(
                                                    escala['funcoes']),
                                                statusLabel: escala['status'],
                                                statusColor: escala['cor'],
                                                controller: controller,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ],
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }
}
