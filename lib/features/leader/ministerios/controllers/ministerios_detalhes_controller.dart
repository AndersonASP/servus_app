import 'package:flutter/material.dart';
import 'package:servus_app/features/ministries/services/ministry_service.dart';
import 'package:servus_app/features/ministries/services/ministry_membership_service.dart';
import 'package:servus_app/core/auth/services/membership_service.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/features/ministries/models/ministry_dto.dart';

class MinisterioDetalhesController extends ChangeNotifier {
  final String ministerioId;
  final MinistryService _ministryService = MinistryService();
  final MinistryMembershipService _ministryMembershipService = MinistryMembershipService();
  final MembershipService _membershipService = MembershipService();

  bool isLoading = false;
  bool isError = false;
  String errorMessage = '';
  
  // Dados do ministério
  MinistryResponse? ministerio;
  String nomeMinisterio = '';
  String descricao = '';
  List<String> funcoes = [];
  bool isAtivo = true;
  DateTime? dataCriacao;
  DateTime? dataAtualizacao;
  
  // Dados de membros
  int totalMembros = 0;
  int totalVoluntarios = 0;
  int totalLideres = 0;
  
  // Lista de membros
  List<Map<String, dynamic>> membros = [];
  bool isLoadingMembers = false;
  String membersErrorMessage = '';
  int currentPage = 1;
  int totalPages = 1;
  bool hasMoreMembers = false;

  MinisterioDetalhesController({required this.ministerioId});

  Future<void> carregarDados() async {
    try {
      debugPrint('🔍 [MinisterioDetalhesController] carregarDados iniciado para ministério: $ministerioId');
      isLoading = true;
      isError = false;
      errorMessage = '';
      notifyListeners();

      // Obtém contexto atual
      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];
      
      if (tenantId == null) {
        throw Exception('Contexto de tenant não encontrado');
      }

      // Carrega dados do ministério
      final ministryData = await _ministryService.getMinistry(
        tenantId: tenantId,
        branchId: branchId ?? '',
        ministryId: ministerioId,
      );

      ministerio = ministryData;
      nomeMinisterio = ministryData.name;
      descricao = ministryData.description ?? '';
      isAtivo = ministryData.isActive;
      dataCriacao = ministryData.createdAt;
      dataAtualizacao = ministryData.updatedAt;

      // Carrega membros do ministério
      await carregarMembros();

      isLoading = false;
      notifyListeners();
      
    } catch (e) {
      isLoading = false;
      isError = true;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Atualiza o status do ministério
  Future<bool> alterarStatus(bool ativo) async {
    // TODO: Implementar quando necessário
    return true;
  }

  /// Remove o ministério
  Future<bool> removerMinisterio() async {
    // TODO: Implementar quando necessário
    return true;
  }

  /// Carrega a lista de membros do ministério
  Future<void> carregarMembros({bool refresh = false}) async {
    try {
      if (refresh) {
        currentPage = 1;
        membros.clear();
        membersErrorMessage = '';
      }

      // Debug: Log do ID do ministério
      
      // Validar se o ID do ministério é válido (aceita tanto ObjectId 24 chars quanto UUID 36 chars)
      if (ministerioId.isEmpty || (ministerioId.length != 24 && ministerioId.length != 36)) {
        throw Exception('ID do ministério inválido');
      }

      isLoadingMembers = true;
      notifyListeners();

      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];
      
      if (tenantId == null) {
        throw Exception('Contexto de tenant não encontrado');
      }


      final membersResponse = await _membershipService.getMinistryMembers(
        tenantId: tenantId,
        branchId: branchId ?? '',
        ministryId: ministerioId,
        page: currentPage,
        limit: 20,
      );
      
      
      final membersData = membersResponse['members'] as List<dynamic>;

      // Debug: Log dos dados recebidos
      if (membersData.isNotEmpty) {
        debugPrint('📊 [MinisterioDetalhesController] ${membersData.length} membros carregados');
      } else {
        debugPrint('📊 [MinisterioDetalhesController] Nenhum membro encontrado');
      }
        
      if (refresh) {
        membros = membersData.cast<Map<String, dynamic>>();
      } else {
        membros.addAll(membersData.cast<Map<String, dynamic>>());
      }

      // Atualizar estatísticas
      totalMembros = membros.length;
      totalVoluntarios = membros.where((m) => m['role'] == 'Volunteer').length;
      totalLideres = membros.where((m) => m['role'] == 'Leader').length;

      // Verificar se há mais páginas
      hasMoreMembers = membersData.length >= 20;
      if (hasMoreMembers) {
        currentPage++;
      }

      isLoadingMembers = false;
      notifyListeners();
      
    } catch (e) {
      isLoadingMembers = false;
      membersErrorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Carrega mais membros (paginação)
  Future<void> carregarMaisMembros() async {
    if (!isLoadingMembers && hasMoreMembers) {
      await carregarMembros();
    }
  }

  /// Remove um membro do ministério
  Future<bool> removerMembro(String membershipId) async {
    try {
      debugPrint('🗑️ [MinisterioDetalhesController] Iniciando remoção de membro...');
      debugPrint('   - Membership ID: $membershipId');
      debugPrint('   - Ministry ID: $ministerioId');
      
      // Encontrar o membro na lista local para obter o userId
      final membro = membros.firstWhere(
        (m) => m['_id'] == membershipId,
        orElse: () => throw Exception('Membro não encontrado na lista local'),
      );

      // A nova API retorna 'userId' populated, não 'user'
      final user = membro['userId'] ?? membro['user'] ?? {};
      final userId = user['_id'] ?? membro['userId'];
      final memberName = user['name'] ?? 'Membro';
      final memberRole = membro['role'] ?? 'volunteer';
      
      debugPrint('   - User ID: $userId');
      debugPrint('   - Member Name: $memberName');
      debugPrint('   - Member Role: $memberRole');
      
      if (userId == null) {
        throw Exception('ID do usuário não encontrado');
      }

      // Validar permissões antes de tentar remover
      if (memberRole == 'leader') {
        debugPrint('⚠️ [MinisterioDetalhesController] Tentativa de remover líder do ministério');
        // Verificar se há outros líderes no ministério
        final otherLeaders = membros.where((m) => 
          m['_id'] != membershipId && 
          (m['role'] == 'Leader' || m['role'] == 'leader')
        ).length;
        
        if (otherLeaders == 0) {
          throw Exception('Não é possível remover o último líder do ministério. Adicione outro líder antes de remover este.');
        }
      }

      debugPrint('🔗 [MinisterioDetalhesController] Chamando serviço de remoção...');
      await _ministryMembershipService.removeUserFromMinistry(
        userId: userId,
        ministryId: ministerioId,
      );

      debugPrint('✅ [MinisterioDetalhesController] Membro removido com sucesso');
      
      // Remove o membro da lista local
      membros.removeWhere((membro) => membro['_id'] == membershipId);
      
      // Atualizar estatísticas
      totalMembros = (totalMembros - 1).clamp(0, double.infinity).toInt();
      if (memberRole == 'leader' || memberRole == 'Leader') {
        totalLideres = (totalLideres - 1).clamp(0, double.infinity).toInt();
      } else {
        totalVoluntarios = (totalVoluntarios - 1).clamp(0, double.infinity).toInt();
      }
      
      notifyListeners();
      debugPrint('📊 [MinisterioDetalhesController] Estatísticas atualizadas:');
      debugPrint('   - Total Membros: $totalMembros');
      debugPrint('   - Total Líderes: $totalLideres');
      debugPrint('   - Total Voluntários: $totalVoluntarios');
      
      return true;
    } catch (e) {
      debugPrint('❌ [MinisterioDetalhesController] Erro ao remover membro: $e');
      rethrow; // Re-throw para que o UI possa tratar o erro específico
    }
  }

  /// Vincula um membro ao ministério
  Future<bool> vincularMembro(String userId, String role) async {
    try {
      
      final membershipRole = role == 'leader' ? 'leader' : 'volunteer';
      
      await _ministryMembershipService.addUserToMinistry(
        userId: userId,
        ministryId: ministerioId,
        role: membershipRole,
      );
      

      // Aguardar um pouco para garantir que a operação foi concluída
      await Future.delayed(const Duration(seconds: 2));

      // Recarregar a lista de membros
      await carregarMembros(refresh: true);
      
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Atualiza os dados do ministério
  Future<bool> atualizarMinisterio({
    required String nome,
    required String descricao,
    required bool isAtivo,
  }) async {
    // TODO: Implementar quando necessário
    return true;
  }

  /// Adiciona uma função ao ministério
  Future<bool> adicionarFuncao(String nomeFuncao) async {
    // TODO: Implementar quando necessário
    return true;
  }

  /// Remove uma função do ministério
  Future<bool> removerFuncao(String nomeFuncao) async {
    // TODO: Implementar quando necessário
    return true;
  }

  /// Formata uma data para exibição
  String formatarData(DateTime? data) {
    if (data == null) return 'N/A';
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  /// Formata uma hora para exibição
  String formatarHora(DateTime? data) {
    if (data == null) return 'N/A';
    return '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }

  /// Getter para status formatado
  String get statusFormatado => isAtivo ? 'Ativo' : 'Inativo';

  /// Getter para cor do status
  Color get corStatus => isAtivo ? Colors.green : Colors.red;

  /// Getter para ícone do status
  IconData get iconeStatus => isAtivo ? Icons.check_circle : Icons.cancel;
}