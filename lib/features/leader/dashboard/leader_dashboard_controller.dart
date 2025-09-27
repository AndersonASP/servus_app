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
    
    // 🔍 LOGS DETALHADOS PARA DEBUG DO DASHBOARD
    print('🎯 [LeaderDashboard] ===== INICIALIZAÇÃO DO DASHBOARD =====');
    print('🔍 [LeaderDashboard] Usuário logado:');
    print('   - Nome: ${usuario.nome}');
    print('   - Email: ${usuario.email}');
    print('   - Role: ${usuario.role}');
    print('   - É líder: ${usuario.isLider}');
    print('   - É voluntário: ${usuario.isVoluntario}');
    print('   - Ministério principal ID: ${usuario.primaryMinistryId}');
    print('   - Ministério principal nome: ${usuario.primaryMinistryName}');
    print('   - Tenant ID: ${usuario.tenantId}');
    print('   - Branch ID: ${usuario.branchId}');
    print('🔍 [LeaderDashboard] Total de ministérios: ${usuario.ministerios.length}');
    
    // 🆕 Para líderes, carrega o ministério principal diretamente
    if (usuario.isLider && usuario.primaryMinistryId != null) {
      print('🎯 [LeaderDashboard] USUÁRIO É LÍDER COM MINISTÉRIO PRINCIPAL');
      print('   - Ministério principal ID: ${usuario.primaryMinistryId}');
      print('   - Ministério principal nome: ${usuario.primaryMinistryName}');
      
      try {
        // Carrega o ministério principal diretamente
        print('🔍 [LeaderDashboard] Iniciando carregamento do ministério principal...');
        final primaryMinistry = await _carregarMinisterioPrincipal();
        if (primaryMinistry != null) {
          ministerioSelecionado = primaryMinistry;
          print('✅ [LeaderDashboard] Ministério principal carregado com sucesso:');
          print('   - ID: ${primaryMinistry.id}');
          print('   - Nome: ${primaryMinistry.name}');
          print('   - Descrição: ${primaryMinistry.description}');
          print('🔍 [LeaderDashboard] Carregando dados do ministério...');
          await carregarDadosDoMinisterio(ministerioSelecionado!, notify: false);
          print('✅ [LeaderDashboard] Dados do ministério carregados');
        } else {
          print('⚠️ [LeaderDashboard] PROBLEMA: Ministério principal não encontrado!');
          print('   - primaryMinistryId: ${usuario.primaryMinistryId}');
          print('   - Tentando fallback...');
          // Fallback: carrega ministérios da matriz
          await carregarMinisterios();
          if (ministerios.isNotEmpty) {
            ministerioSelecionado = ministerios.first;
            print('⚠️ [LeaderDashboard] Usando primeiro ministério da lista como fallback: ${ministerioSelecionado!.name}');
            await carregarDadosDoMinisterio(ministerioSelecionado!, notify: false);
          }
        }
      } catch (e) {
        print('❌ [LeaderDashboard] ERRO ao carregar ministério principal: $e');
        print('🔍 [LeaderDashboard] Tentando fallback...');
        // Fallback: carrega ministérios da matriz
        await carregarMinisterios();
        if (ministerios.isNotEmpty) {
          ministerioSelecionado = ministerios.first;
          print('⚠️ [LeaderDashboard] Fallback: usando primeiro ministério: ${ministerioSelecionado!.name}');
          await carregarDadosDoMinisterio(ministerioSelecionado!, notify: false);
        }
      }
    } else {
      print('🔍 [LeaderDashboard] Usuário não é líder ou não tem ministério principal');
      print('   - É líder: ${usuario.isLider}');
      print('   - Tem primaryMinistryId: ${usuario.primaryMinistryId != null}');
      print('🔍 [LeaderDashboard] Carregando lista normal de ministérios...');
      // Para outros roles, carrega ministérios da matriz normalmente
      await carregarMinisterios();
      if (ministerios.isNotEmpty) {
        ministerioSelecionado = ministerios.first;
        print('🔍 [LeaderDashboard] Usando primeiro ministério da lista: ${ministerioSelecionado!.name}');
        await carregarDadosDoMinisterio(ministerioSelecionado!, notify: false);
      }
    }
    
    print('🎯 [LeaderDashboard] ===== FIM DA INICIALIZAÇÃO DO DASHBOARD =====');

    isLoading = false;
    notifyListeners();
  }

  /// 🆕 Carrega o ministério principal do usuário líder
  Future<MinistryResponse?> _carregarMinisterioPrincipal() async {
    try {
      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      
      if (tenantId == null || usuario.primaryMinistryId == null) {
        return null;
      }

      print('🔍 [LeaderDashboard] Carregando ministério principal: ${usuario.primaryMinistryId}');
      
      // Primeiro tenta carregar como ministério da matriz (sem branchId)
      try {
        final response = await _ministryService.getMinistry(
          tenantId: tenantId,
          branchId: '', // Ministério da matriz
          ministryId: usuario.primaryMinistryId!,
        );
        
        print('✅ [LeaderDashboard] Ministério principal encontrado na matriz: ${response.name}');
        return response;
      } catch (e) {
        print('🔍 [LeaderDashboard] Ministério não encontrado na matriz, tentando filiais...');
        
        // Se não encontrou na matriz, tenta nas filiais
        // Por enquanto, vamos usar o método getLeaderMinistryV2 que já funciona
        final leaderMinistry = await _ministryService.getLeaderMinistryV2(
          tenantId: tenantId,
          branchId: '', // Vai buscar em todas as filiais
        );
        
        if (leaderMinistry != null) {
          print('✅ [LeaderDashboard] Ministério principal encontrado via getLeaderMinistryV2: ${leaderMinistry.name}');
          return leaderMinistry;
        } else {
          print('❌ [LeaderDashboard] Ministério principal não encontrado');
          return null;
        }
      }
    } catch (e) {
      print('❌ [LeaderDashboard] Erro ao carregar ministério principal: $e');
      return null;
    }
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
      final ministryId = usuario.primaryMinistryId;
      
      if (tenantId == null || ministryId == null) {
        totalVoluntarios = 0;
        return;
      }

      print('🔍 [LeaderDashboard] Carregando dados de voluntários...');
      print('   - TenantId: $tenantId');
      print('   - MinistryId: $ministryId');

      // 🆕 CORREÇÃO: Usar o endpoint correto de voluntários
      final response = await _dio.get('/users/tenants/$tenantId/ministries/$ministryId/volunteers', queryParameters: {
        'page': '1',
        'limit': '1000', // Buscar todos para contar
      });

      print('🔍 [LeaderDashboard] Resposta recebida: ${response.statusCode}');
      print('🔍 [LeaderDashboard] Dados: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final pagination = data['pagination'] as Map<String, dynamic>?;
        final total = pagination?['total'] ?? 0;
        
        print('🔍 [LeaderDashboard] Total de voluntários encontrados: $total');
        totalVoluntarios = total;
      } else {
        print('❌ [LeaderDashboard] Erro na resposta: ${response.statusCode}');
        totalVoluntarios = 0;
      }
    } catch (e) {
      print('❌ [LeaderDashboard] Erro ao carregar voluntários: $e');
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