import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:servus_app/core/models/usuario_logado.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:servus_app/features/ministries/models/ministry_dto.dart';
import 'package:servus_app/features/ministries/services/ministry_service.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/state/auth_state.dart';

class DashboardLiderController extends ChangeNotifier {
  final AuthState auth;
  final ScrollController scrollController = ScrollController();
  final MinistryService _ministryService = MinistryService();
  final Dio _dio = DioClient.instance;

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
    } catch (e) {
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

    try {
      // Carregar dados reais de voluntários
      await _loadVolunteersData();
      
      // Carregar dados de solicitações (mantendo mock por enquanto)
      totalSolicitacoesPendentes = 3;
      
      // Para ministérios da matriz, assumimos que todos os módulos estão ativos
      moduloLouvorAtivo = true;
    } catch (e) {
      debugPrint('Erro ao carregar dados do ministério: $e');
      // Fallback para dados mockados em caso de erro
      totalVoluntarios = 0;
      totalSolicitacoesPendentes = 0;
    } finally {
      isLoadingVoluntarios = false;
      isLoadingSolicitacoes = false;
      isLoadingModuloLouvor = false;
      if (notify) notifyListeners();
    }
  }

  Future<void> _loadVolunteersData() async {
    try {
      final tenantId = usuario.tenantId;
      if (tenantId == null) {
        totalVoluntarios = 0;
        return;
      }

      // Buscar voluntários aprovados através das submissões de formulários
      final response = await _dio.get('/forms/submissions', queryParameters: {
        'tenantId': tenantId,
        'status': 'approved',
        'limit': '1000', // Buscar todos para contar
      });

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final submissions = data['data'] as List<dynamic>? ?? [];
        
        // Filtrar apenas submissões do ministério selecionado se houver
        final filteredSubmissions = ministerioSelecionado != null
            ? submissions.where((submission) {
                final preferredMinistry = submission['preferredMinistry'];
                return preferredMinistry != null && 
                       preferredMinistry['_id'] == ministerioSelecionado!.id;
              }).toList()
            : submissions;
        
        totalVoluntarios = filteredSubmissions.length;
      } else {
        totalVoluntarios = 0;
      }
    } catch (e) {
      debugPrint('Erro ao carregar voluntários: $e');
      totalVoluntarios = 0;
    }
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

  /// Atualiza todos os dados do dashboard
  Future<void> refreshDashboard() async {
    isLoading = true;
    notifyListeners();
    
    try {
      // Recarrega ministérios
      await carregarMinisterios();
      
      // Se há ministério selecionado, recarrega os dados
      if (ministerioSelecionado != null) {
        await carregarDadosDoMinisterio(ministerioSelecionado!, notify: false);
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void disposeController() {
    scrollController.dispose();
    super.dispose();
  }
}