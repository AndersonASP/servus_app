import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/volunteers/dashboard/escala/escala_card/escala_card_screen.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final DashboardController controller = DashboardController();

  late Future<List<Map<String, dynamic>>> _futureEscalas;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _futureEscalas = controller.fetchEscalas();
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    _futureEscalas = controller.fetchEscalas();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFFDFDFD),
          drawer: Drawer(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Meu perfil'),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Preferências'),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Notificações'),
                    onTap: () {},
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Sair'),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, size: 30),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Olá, Anderson Alves!',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                          fontSize: 25,
                                          fontWeight: FontWeight.w800,
                                          color: context.colors.primary)),
                              RichText(
                                text: TextSpan(
                                  style: context.textStyles.bodyLarge?.copyWith(
                                    fontSize: 14,
                                    color: context.colors.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  children: const [
                                    TextSpan(text: 'Você tem '),
                                    TextSpan(
                                      text: '4',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                    TextSpan(text: ' escalas este mês'),
                                  ],
                                ),
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
                                child: const Text('15',
                                    style: TextStyle(
                                        fontSize: 8,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _futureEscalas,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
                          return SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        } else if (snapshot.hasError) {
                          return const Text('Erro ao carregar escalas');
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.asset('assets/images/sem_escalas.svg', width: 150, height: 150),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Descanse um pouco!',
                                    style: context.textStyles.bodyLarge?.copyWith(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: context.colors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Você ainda não foi escalado para nenhum evento.',
                                    style: context.textStyles.bodyLarge?.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: context.colors.primary.withOpacity(0.6),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final escalas = snapshot.data!;
                        final proximaEscala = escalas.first;
                        final outrasEscalas = escalas.sublist(1);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('sua próxima escala',
                                style: context.textStyles.bodyLarge?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: context.colors.onSurface,
                                )),
                            const SizedBox(height: 12),
                            EscalaCardWidget(
                              index: proximaEscala['index'] ?? 0,
                              diasRestantes: proximaEscala['diasRestantes'],
                              dia: proximaEscala['dia'],
                              mes: proximaEscala['mes'],
                              horario: proximaEscala['horario'],
                              diaSemana: proximaEscala['diaSemana'],
                              nomeEvento: proximaEscala['nomeEvento'],
                              funcoes: List<String>.from(proximaEscala['funcoes']),
                              statusLabel: proximaEscala['status'],
                              statusColor: proximaEscala['cor'],
                              controller: controller,
                            ),
                            const SizedBox(height: 24),
                            if (outrasEscalas.isNotEmpty) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('o que vem por aí',
                                      style: context.textStyles.bodyLarge?.copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: context.colors.onSurface,
                                      )),
                                  Icon(Icons.filter_alt_outlined, color: context.colors.primary),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Column(
                                children: List.generate(
                                  outrasEscalas.length,
                                  (index) {
                                    final escala = outrasEscalas[index];
                                    return EscalaCardWidget(
                                      index: escala['index'] ?? index + 1,
                                      diasRestantes: escala['diasRestantes'],
                                      dia: escala['dia'],
                                      mes: escala['mes'],
                                      nomeEvento: escala['nomeEvento'],
                                      horario: escala['horario'],
                                      diaSemana: escala['diaSemana'],
                                      funcoes: List<String>.from(escala['funcoes']),
                                      statusLabel: escala['status'],
                                      statusColor: escala['cor'],
                                      controller: controller,
                                    );
                                  },
                                ),
                              ),
                            ] else ...[
                              const Center(child: Text('Não há outras escalas')),
                              const SizedBox(height: 12),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/logo_servus.png', width: 100),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}