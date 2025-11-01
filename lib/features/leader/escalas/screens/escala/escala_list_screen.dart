import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/leader/escalas/controllers/escala/escala_controller.dart';
// UI simplificada: sem dependências de seleção de voluntários/templates
import 'escala_matrix_screen.dart';
import 'package:servus_app/widgets/app_card.dart';
import 'package:servus_app/widgets/soft_divider.dart';
import 'package:servus_app/widgets/empty_state.dart';
import 'package:servus_app/widgets/loading_skeleton.dart';

class EscalaListScreen extends StatefulWidget {
  const EscalaListScreen({super.key});

  @override
  State<EscalaListScreen> createState() => _EscalaListScreenState();
}

class _EscalaListScreenState extends State<EscalaListScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _carregarEscalas();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Intencionalmente vazio para evitar setState durante o build
  }

  Future<void> _carregarEscalas() async {
    final escalaController = context.read<EscalaController>();
    await escalaController.carregarEscalasDoLider();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final escalaController = context.watch<EscalaController>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header leve
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/leader/dashboard'),
                  ),
                  Expanded(
                    child: Text(
                      'Escalas',
                      style: context.textStyles.titleLarge?.copyWith(
                        color: context.colors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SoftDivider(),
            Expanded(child: _buildListOrEmpty(context, escalaController)),
          ],
        ),
      ),
      floatingActionButton: _buildFabNovo(context),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyState(
      icon: Icons.schedule_outlined,
      title: 'Não há escalas ainda',
      subtitle: 'Crie sua primeira escala para começar a organizar os voluntários',
    );
  }
  Widget _buildListOrEmpty(BuildContext context, EscalaController controller) {
    if (controller.isLoading) {
      return ListView.separated(
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        padding: const EdgeInsets.all(12),
        itemBuilder: (_, __) => const AppCard(child: SkeletonListTile()),
      );
    }
    if (controller.resumo.isEmpty) {
      return _buildEmptyState(context);
    }
    return ListView.separated(
      itemCount: controller.resumo.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      padding: const EdgeInsets.all(12),
      itemBuilder: (_, i) {
        final r = controller.resumo[i];
        final dt = r.dataHora;
        final dataStr = dt != null
            ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
            : '';
        return AppCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_available),
            title: Text(r.nome, style: context.textStyles.titleMedium),
            subtitle: Text(
              [dataStr, if (r.ministryName != null) r.ministryName!].where((e) => e.isNotEmpty).join(' · '),
            ),
            onTap: () {
              // Futuro: abrir detalhes da escala
            },
          ),
        );
      },
    );
  }

  // Removido: picker de voluntários

  Widget _buildFabNovo(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EscalaMatrixScreen()),
        );
      },
      icon: const Icon(Icons.add),
      label: Text(
        'Nova Escala',
        style: context.textStyles.bodyLarge?.copyWith(
          color: context.colors.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: context.colors.primary,
    );
  }

  // Removido: UI da matriz e labels relacionados a template
}
