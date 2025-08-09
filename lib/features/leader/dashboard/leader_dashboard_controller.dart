import 'package:flutter/material.dart';
import 'package:servus_app/core/enums/ministry_module.dart';
import 'package:servus_app/core/models/ministerio.dart';
import 'package:servus_app/core/models/usuario_logado.dart';
import 'package:servus_app/state/auth_state.dart';

class DashboardLiderController extends ChangeNotifier {
  final AuthState auth;
  final ScrollController scrollController = ScrollController();

  late UsuarioLogado usuario;
  late List<Ministerio> ministerios;
  Ministerio? ministerioSelecionado;

  bool isLoading = true;

  bool isLoadingVoluntarios = false;
  bool isLoadingSolicitacoes = false;
  bool isLoadingModuloLouvor = false;

  int totalVoluntarios = 0;
  int totalSolicitacoesPendentes = 0;
  bool moduloLouvorAtivo = false;

  DashboardLiderController({required this.auth});

  Future<void> init() async {
    usuario = auth.usuario!;
    ministerios = usuario.ministerios;

    if (ministerios.isNotEmpty) {
      ministerioSelecionado = ministerios.first;
      await carregarDadosDoMinisterio(ministerioSelecionado!, notify: false);
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> carregarDadosDoMinisterio(Ministerio ministerio,
      {bool notify = true}) async {
    ministerioSelecionado = ministerio;

    isLoadingVoluntarios = true;
    isLoadingSolicitacoes = true;
    isLoadingModuloLouvor = true;
    if (notify) notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    totalVoluntarios = 18;
    totalSolicitacoesPendentes = 3;
    moduloLouvorAtivo =
        ministerio.modulosAtivos.contains(MinistryModule.louvor);

    isLoadingVoluntarios = false;
    isLoadingSolicitacoes = false;
    isLoadingModuloLouvor = false;
    if (notify) notifyListeners();
  }

  void scrollToCard(BuildContext context, int index) {
    const double cardWidth = 140;
    const double spacing = 12;
    final double visibleWidth = MediaQuery.of(context).size.width - 32;

    final double targetOffset = index * (cardWidth + spacing);
    final double currentOffset = scrollController.offset;

    final double adjustedOffset = targetOffset < currentOffset
        ? (targetOffset - spacing)
            .clamp(0, scrollController.position.maxScrollExtent)
        : (targetOffset - (visibleWidth - cardWidth - spacing))
            .clamp(0, scrollController.position.maxScrollExtent);

    scrollController.animateTo(
      adjustedOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void disposeController() {
    scrollController.dispose();
    super.dispose();
  }
}