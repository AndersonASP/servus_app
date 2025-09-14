import 'package:flutter/material.dart';
import 'package:servus_app/core/models/usuario_logado.dart';
import 'package:servus_app/features/ministries/models/ministry_dto.dart';
import 'package:servus_app/features/ministries/services/ministry_service.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/state/auth_state.dart';

class DashboardLiderController extends ChangeNotifier {
  final AuthState auth;
  final ScrollController scrollController = ScrollController();
  final MinistryService _ministryService = MinistryService();

  late UsuarioLogado usuario;
  List<MinistryResponse> ministerios = [];
  MinistryResponse? ministerioSelecionado;

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
    
    // Carrega ministérios da matriz
    await carregarMinisterios();

    if (ministerios.isNotEmpty) {
      ministerioSelecionado = ministerios.first;
      await carregarDadosDoMinisterio(ministerioSelecionado!, notify: false);
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> carregarMinisterios() async {
    try {
      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      
      if (tenantId == null) {
        // print('❌ Contexto de tenant não encontrado');
        return;
      }

      final response = await _ministryService.listMinistries(
        tenantId: tenantId,
        branchId: '', // Ministérios da matriz
        filters: ListMinistryDto(
          page: 1,
          limit: 10, // Limita para o dashboard
          isActive: true,
        ),
      );

      ministerios = response.items;
      // print('✅ Carregados ${ministerios.length} ministérios no dashboard');
    } catch (e) {
      // print('❌ Erro ao carregar ministérios: $e');
      ministerios = [];
    }
  }

  Future<void> carregarDadosDoMinisterio(MinistryResponse ministerio,
      {bool notify = true}) async {
    ministerioSelecionado = ministerio;

    isLoadingVoluntarios = true;
    isLoadingSolicitacoes = true;
    isLoadingModuloLouvor = true;
    if (notify) notifyListeners();


    totalVoluntarios = 18;
    totalSolicitacoesPendentes = 3;
    // Para ministérios da matriz, assumimos que todos os módulos estão ativos
    moduloLouvorAtivo = true;

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