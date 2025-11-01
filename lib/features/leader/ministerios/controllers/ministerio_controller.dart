import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/features/ministries/services/ministry_service.dart';
import 'package:servus_app/features/ministries/services/ministry_functions_service.dart';
import 'package:servus_app/features/ministries/models/ministry_dto.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/services/local_storage_service.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';
import 'package:servus_app/state/auth_state.dart';
import 'package:servus_app/core/enums/user_role.dart';

class MinisterioController extends ChangeNotifier {
  final MinistryService _ministryService = MinistryService();
  final MinistryFunctionsService _functionsService = MinistryFunctionsService();
  
  // Controllers dos campos
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController descricaoController = TextEditingController();
  final TextEditingController funcaoController = TextEditingController();
  
  // Campo para limite de bloqueios
  int maxBlockedDays = 10;
  
  // Estados
  bool ativo = true;
  bool isSaving = false;
  bool isEditing = false;
  String? ministerioId; // Para edição
  
  // Lista de funções
  List<String> funcoes = [];
  
  // Validação
  String? nomeError;
  String? descricaoError;
  String? funcaoError;

  // Contexto
  String? _tenantId;
  String? _branchId;

  MinisterioController() {
    // Adiciona listener para o campo de função
    funcaoController.addListener(() {
      notifyListeners();
    });
    
    // Carrega contexto automaticamente
    _loadContext();
  }

  /// Verifica se o contexto está disponível
  bool get hasValidContext {
    // Para servus_admin, não precisa de contexto
    if (_isServusAdmin) return true;
    
    // Para outros usuários, precisa de tenantId
    return _tenantId != null && _tenantId!.isNotEmpty;
  }

  /// Verifica se é usuário servus_admin
  bool get _isServusAdmin {
    // Aqui você pode implementar verificação do role do usuário
    // Por enquanto, vamos verificar se não tem tenant (indicativo de servus_admin)
    return _tenantId == null || _tenantId!.isEmpty;
  }

  /// Obtém o contexto atual
  Map<String, String?> get currentContext {
    if (_isServusAdmin) {
      return {
        'tenantId': null,
        'branchId': null,
        'isServusAdmin': 'true',
      };
    }
    
    return {
      'tenantId': _tenantId,
      'branchId': _branchId,
      'isServusAdmin': 'false',
    };
  }

  /// Carrega contexto de segurança do JWT
  Future<void> _loadContext() async {
    try {
      
      // 🆕 Primeiro, tenta carregar claims de segurança do storage
      await TokenService.loadSecurityClaims();
      
      // Se tem claims válidos, usa eles
      if (TokenService.hasTenantContext) {
        _tenantId = TokenService.tenantId;
        _branchId = TokenService.branchId;
        
        return;
      }
      
      // 🆕 Se não tem claims, tenta carregar do storage antigo (fallback)
      await _loadContextFromLocalStorage();
      
    } catch (e) {
    }
  }

  /// Carrega contexto do LocalStorage
  Future<void> _loadContextFromLocalStorage() async {
    try {
      final infoBasica = await LocalStorageService.getInfoBasica();
      final tenantId = infoBasica['tenantId'];
      final branchId = infoBasica['branchId'];
      
      
      if (tenantId != null && branchId != null && tenantId.isNotEmpty && branchId.isNotEmpty) {
        _tenantId = tenantId;
        _branchId = branchId;
        
        // Salva no TokenService para uso futuro
        await TokenService.saveContext(
          tenantId: tenantId,
          branchId: branchId,
        );
        
      } else {
      }
    } catch (e) {
    }
  }



  /// Inicializa o controller para edição
  void initializeForEdit(MinistryResponse ministerio) {
    isEditing = true;
    ministerioId = ministerio.id;
    nomeController.text = ministerio.name;
    descricaoController.text = ministerio.description ?? '';
    ativo = ministerio.isActive;
    funcoes = List.from(ministerio.ministryFunctions);
    
    // Carregar limite de bloqueios do campo do ministério
    maxBlockedDays = ministerio.maxBlockedDays ?? 10; // Fallback para valor padrão
    debugPrint('🔍 [MinisterioController] Limite de bloqueios carregado para edição: $maxBlockedDays dias');
    
    notifyListeners();
  }

  /// Inicializa o controller para líder editar seu próprio ministério
  void initializeForLeader() {
    isEditing = true;
    loadLeaderMinistry();
  }

  /// Carrega o ministério do líder atual
  Future<void> loadLeaderMinistry() async {
    try {
      await _loadContext();
      
      if (_tenantId == null || _tenantId!.isEmpty) {
        throw Exception('Contexto inválido: tenantId="$_tenantId"');
      }

      // Buscar o ministério do líder atual usando endpoints existentes
      final leaderMinistry = await _ministryService.getLeaderMinistryV2(
        tenantId: _tenantId!,
        branchId: _branchId ?? '',
      );

      if (leaderMinistry != null) {
        ministerioId = leaderMinistry.id;
        nomeController.text = leaderMinistry.name;
        descricaoController.text = leaderMinistry.description ?? '';
        funcoes = List.from(leaderMinistry.ministryFunctions);
        ativo = leaderMinistry.isActive;
        notifyListeners();
      } else {
        throw Exception('Ministério do líder não encontrado');
      }
    } catch (e) {
      debugPrint('Erro ao carregar ministério do líder: $e');
      // Limpar campos em caso de erro
      ministerioId = null;
      nomeController.clear();
      descricaoController.clear();
      funcoes.clear();
      ativo = true;
      notifyListeners();
    }
  }

  /// Adiciona uma nova função
  void adicionarFuncao() {
    final funcao = funcaoController.text.trim();
    if (funcao.isNotEmpty && !funcoes.contains(funcao)) {
      funcoes.add(funcao);
      funcaoController.clear();
      funcaoError = null;
      notifyListeners();
    }
  }

  /// Adiciona múltiplas funções separadas por vírgula
  void adicionarFuncoes() {
    final texto = funcaoController.text.trim();
    if (texto.isEmpty) return;

    // Separar por vírgula e limpar espaços
    final funcoesTexto = texto.split(',').map((f) => f.trim()).where((f) => f.isNotEmpty).toList();
    
    if (funcoesTexto.isEmpty) return;

    int adicionadas = 0;
    for (final funcao in funcoesTexto) {
      if (!funcoes.contains(funcao)) {
        funcoes.add(funcao);
        adicionadas++;
      }
    }

    if (adicionadas > 0) {
      funcaoController.clear();
      funcaoError = null;
      notifyListeners();
    }
  }

  /// Remove uma função
  void removerFuncao(String funcao) {
    funcoes.remove(funcao);
    notifyListeners();
  }

  /// Atualiza o limite de dias bloqueados
  void updateMaxBlockedDays(int newLimit) {
    maxBlockedDays = newLimit;
    notifyListeners();
  }

  /// Valida os campos
  bool _validarCampos() {
    bool isValid = true;
    
    // Validação do nome
    if (nomeController.text.trim().isEmpty) {
      nomeError = 'Nome é obrigatório';
      isValid = false;
    } else if (nomeController.text.trim().length < 3) {
      nomeError = 'Nome deve ter pelo menos 3 caracteres';
      isValid = false;
    } else {
      nomeError = null;
    }
    
    // Validação da descrição
    if (descricaoController.text.trim().isNotEmpty && 
        descricaoController.text.trim().length < 10) {
      descricaoError = 'Descrição deve ter pelo menos 10 caracteres';
      isValid = false;
    } else {
      descricaoError = null;
    }
    
    // Validação das funções
    if (funcoes.isEmpty) {
      funcaoError = 'Adicione pelo menos uma função';
      isValid = false;
    } else {
      funcaoError = null;
    }
    
    notifyListeners();
    return isValid;
  }

  /// Salva o ministério (criação ou edição)
  Future<bool> salvarMinisterio(BuildContext context) async {
    if (!_validarCampos()) return false;

    // Verifica se o contexto está disponível
    if (!hasValidContext) {
      await _loadContext();
      
      if (!hasValidContext) {
        _showContextError(context);
        return false;
      }
    }

    try {
      isSaving = true;
      notifyListeners();

      if (isEditing) {
      }

      // Validação específica por tipo de usuário
      if (_isServusAdmin) {
        // Para servus_admin, pode criar ministérios globais
      } else {
        // Usuário normal precisa de tenantId
        if (_tenantId == null || _tenantId!.isEmpty) {
          throw Exception('Contexto inválido: tenantId="$_tenantId"');
        }
      }

      bool success;
      
      if (isEditing) {
        // Atualização
        final updateData = UpdateMinistryDto(
          name: nomeController.text.trim(),
          description: descricaoController.text.trim().isEmpty ? null : descricaoController.text.trim(),
          ministryFunctions: funcoes,
          isActive: ativo,
          maxBlockedDays: maxBlockedDays,
        );
        
        debugPrint('🔍 [MinisterioController] Dados para atualização:');
        debugPrint('🔍 [MinisterioController] - Nome: ${updateData.name}');
        debugPrint('🔍 [MinisterioController] - Descrição: ${updateData.description}');
        debugPrint('🔍 [MinisterioController] - Funções: ${updateData.ministryFunctions}');
        debugPrint('🔍 [MinisterioController] - Ativo: ${updateData.isActive}');
        debugPrint('🔍 [MinisterioController] - MaxBlockedDays: ${updateData.maxBlockedDays}');
        debugPrint('🔍 [MinisterioController] - JSON: ${updateData.toJson()}');
        
        
        if (_isServusAdmin) {
          // TODO: Implementar atualização global para servus_admin
          throw Exception('Atualização global não implementada para servus_admin');
        } else {
          // 🆕 CORREÇÃO: Trata corretamente o branchId
          String? branchIdParaAPI;
          if (_branchId != null && _branchId!.isNotEmpty) {
            branchIdParaAPI = _branchId;
          } else {
            // Para usuários da matriz, não passa branchId na URL
            // O backend deve tratar isso como ministério da matriz
          }
          
          // 🆕 CORREÇÃO: Sincronizar funções do ministério
          try {
            // Primeiro, criar/atualizar as funções na lista atual
            if (funcoes.isNotEmpty) {
              await _functionsService.bulkUpsertFunctions(
                ministerioId!,
                funcoes,
              );
            }
            
            // TODO: Implementar lógica para desativar funções que não estão mais na lista
            // Por enquanto, o backend não tem endpoint para remover funções do ministério
            // As funções removidas continuarão aparecendo na aba, mas inativas
          } catch (e) {
            // Continua mesmo se der erro, pois as funções podem já existir
          }
          
          await _ministryService.updateMinistry(
            tenantId: _tenantId!,
            branchId: branchIdParaAPI ?? '', // Passa string vazia se for matriz
            ministryId: ministerioId!,
            ministryData: updateData,
          );
        }
        
        success = true;
      } else {
        // Criação
        final createData = CreateMinistryDto(
          name: nomeController.text.trim(),
          description: descricaoController.text.trim().isEmpty ? null : descricaoController.text.trim(),
          ministryFunctions: funcoes,
          isActive: ativo,
          maxBlockedDays: maxBlockedDays,
        );
        
        debugPrint('🔍 [MinisterioController] Dados para criação:');
        debugPrint('🔍 [MinisterioController] - Nome: ${createData.name}');
        debugPrint('🔍 [MinisterioController] - Descrição: ${createData.description}');
        debugPrint('🔍 [MinisterioController] - Funções: ${createData.ministryFunctions}');
        debugPrint('🔍 [MinisterioController] - Ativo: ${createData.isActive}');
        debugPrint('🔍 [MinisterioController] - MaxBlockedDays: ${createData.maxBlockedDays}');
        debugPrint('🔍 [MinisterioController] - JSON: ${createData.toJson()}');
        
        
        if (_isServusAdmin) {
          // TODO: Implementar criação global para servus_admin
          throw Exception('Criação global não implementada para servus_admin');
        } else {
          // 🆕 CORREÇÃO: Trata corretamente o branchId
          String? branchIdParaAPI;
          if (_branchId != null && _branchId!.isNotEmpty) {
            branchIdParaAPI = _branchId;
          } else {
            // Para usuários da matriz, não passa branchId na URL
            // O backend deve tratar isso como ministério da matriz
          }
          
          await _ministryService.createMinistry(
            tenantId: _tenantId!,
            branchId: branchIdParaAPI ?? '', // Passa string vazia se for matriz
            ministryData: createData,
          );
        }
        
        success = true;
      }

      isSaving = false;
      notifyListeners();
      
      if (success) {
        if (context.mounted) {
          // Redirecionamento condicional por papel: líder volta para detalhes do seu ministério
          try {
            final authState = context.read<AuthState>();
            final role = authState.usuario?.role;
            final isLeader = role == UserRole.leader;

            if (isLeader && isEditing && ministerioId != null && ministerioId!.isNotEmpty) {
              context.go('/leader/ministerio-detalhes/${ministerioId!}?t=${DateTime.now().millisecondsSinceEpoch}');
            } else {
              context.go('/leader/ministerio/lista?refresh=true&t=${DateTime.now().millisecondsSinceEpoch}');
            }
          } catch (_) {
            // Fallback seguro caso não consiga ler o AuthState
            context.go('/leader/ministerio/lista?refresh=true&t=${DateTime.now().millisecondsSinceEpoch}');
          }
        }
      }
      
      return success;
    } catch (e) {
      isSaving = false;
      notifyListeners();
      
      if (e is Exception) {
      }
      
      // Mostra erro específico para o usuário
      if (context.mounted) {
        String errorMessage = 'Erro ao salvar ministério';
        
        if (e.toString().contains('Contexto inválido')) {
          errorMessage = 'Erro: Contexto de usuário não encontrado. Faça login novamente.';
        } else if (e.toString().contains('Rota não encontrada')) {
          errorMessage = 'Erro: Backend não está funcionando. Verifique a conexão.';
        } else if (e.toString().contains('Ministério não encontrado')) {
          errorMessage = 'Erro: Ministério não encontrado no sistema.';
        } else if (e.toString().contains('Não autorizado')) {
          errorMessage = 'Erro: Você não tem permissão para criar ministérios.';
        } else if (e.toString().contains('não implementada para servus_admin')) {
          errorMessage = 'Erro: Funcionalidade não disponível para administradores globais.';
        }
        
        showError(context, errorMessage);
      }
      
      return false;
    }
  }

  /// Mostra erro de contexto
  void _showContextError(BuildContext context) {
    if (context.mounted) {
      showAuthError(context);
    }
  }

  /// Toggle do status ativo/inativo
  void toggleAtivo(bool value) {
    ativo = value;
    notifyListeners();
  }

  /// Reseta o controller
  void reset() {
    nomeController.clear();
    descricaoController.clear();
    funcaoController.clear();
    ativo = true;
    funcoes.clear();
    isEditing = false;
    ministerioId = null;
    nomeError = null;
    descricaoError = null;
    funcaoError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    nomeController.dispose();
    descricaoController.dispose();
    funcaoController.dispose();
    super.dispose();
  }
}