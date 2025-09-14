import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:servus_app/features/ministries/services/ministry_service.dart';
import 'package:servus_app/features/ministries/services/ministry_functions_service.dart';
import 'package:servus_app/features/ministries/models/ministry_dto.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/services/local_storage_service.dart';
import 'package:servus_app/core/services/feedback_service.dart';

class MinisterioController extends ChangeNotifier {
  final MinistryService _ministryService = MinistryService();
  final MinistryFunctionsService _functionsService = MinistryFunctionsService();
  
  // Controllers dos campos
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController descricaoController = TextEditingController();
  final TextEditingController funcaoController = TextEditingController();
  
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
      // print('🔍 Carregando contexto de segurança...');
      
      // 🆕 Primeiro, tenta carregar claims de segurança do storage
      await TokenService.loadSecurityClaims();
      
      // Se tem claims válidos, usa eles
      if (TokenService.hasTenantContext) {
        _tenantId = TokenService.tenantId;
        _branchId = TokenService.branchId;
        
        // print('✅ Contexto carregado dos claims de segurança:');
        // print('   - Tenant ID: $_tenantId');
        // print('   - Branch ID: $_branchId');
        return;
      }
      
      // 🆕 Se não tem claims, tenta carregar do storage antigo (fallback)
      // print('⚠️ Claims não encontrados, tentando storage antigo...');
      await _loadContextFromLocalStorage();
      
    } catch (e) {
      // print('❌ Erro ao carregar contexto: $e');
    }
  }

  /// Carrega contexto do LocalStorage
  Future<void> _loadContextFromLocalStorage() async {
    try {
      final infoBasica = await LocalStorageService.getInfoBasica();
      final tenantId = infoBasica['tenantId'];
      final branchId = infoBasica['branchId'];
      
      // print('🔍 LocalStorage: tenantId=$tenantId, branchId=$branchId');
      
      if (tenantId != null && branchId != null && tenantId.isNotEmpty && branchId.isNotEmpty) {
        _tenantId = tenantId;
        _branchId = branchId;
        
        // Salva no TokenService para uso futuro
        await TokenService.saveContext(
          tenantId: tenantId,
          branchId: branchId,
        );
        
        // print('✅ Contexto carregado do LocalStorage e salvo no TokenService');
      } else {
        // print('⚠️ LocalStorage não tem contexto válido');
      }
    } catch (e) {
      // print('❌ Erro ao carregar contexto do LocalStorage: $e');
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
    notifyListeners();
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
      // print('❌ Contexto não disponível - tentando recarregar...');
      await _loadContext();
      
      if (!hasValidContext) {
        _showContextError(context);
        return false;
      }
    }

    try {
      isSaving = true;
      notifyListeners();

      // print('🚀 Salvando ministério com contexto: $_tenantId, $_branchId');
      // print('📝 Dados do ministério:');
      // print('   - Nome: ${nomeController.text.trim()}');
      // print('   - Descrição: ${descricaoController.text.trim()}');
      // print('   - Funções: ${funcoes.join(', ')}');
      // print('   - Ativo: $ativo');
      // print('   - Modo: ${isEditing ? 'Edição' : 'Criação'}');
      if (isEditing) {
        // print('   - ID para edição: $ministerioId');
      }

      // Validação específica por tipo de usuário
      if (_isServusAdmin) {
        // print('👑 Usuário servus_admin - operação global');
        // Para servus_admin, pode criar ministérios globais
      } else {
        // Usuário normal precisa de tenantId
        if (_tenantId == null || _tenantId!.isEmpty) {
          throw Exception('Contexto inválido: tenantId="$_tenantId"');
        }
        // print('🏢 Usuário com tenant: $_tenantId');
        // print('🏪 Branch: ${_branchId ?? 'matriz'}');
      }

      bool success;
      
      if (isEditing) {
        // Atualização
        // print('🔄 Atualizando ministério existente...');
        final updateData = UpdateMinistryDto(
          name: nomeController.text.trim(),
          description: descricaoController.text.trim().isEmpty ? null : descricaoController.text.trim(),
          ministryFunctions: funcoes,
          isActive: ativo,
        );
        
        // print('📤 Dados de atualização: ${updateData.toJson()}');
        
        if (_isServusAdmin) {
          // TODO: Implementar atualização global para servus_admin
          throw Exception('Atualização global não implementada para servus_admin');
        } else {
          // 🆕 CORREÇÃO: Trata corretamente o branchId
          String? branchIdParaAPI;
          if (_branchId != null && _branchId!.isNotEmpty) {
            branchIdParaAPI = _branchId;
            // print('🏪 Usando branch específica: $branchIdParaAPI');
          } else {
            // print('🏢 Usuário da matriz - sem branch específica');
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
            // print('✅ Funções sincronizadas na tabela function');
          } catch (e) {
            // print('⚠️ Erro ao sincronizar funções: $e');
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
        // print('✅ Ministério atualizado com sucesso!');
      } else {
        // Criação
        // print('🆕 Criando novo ministério...');
        final createData = CreateMinistryDto(
          name: nomeController.text.trim(),
          description: descricaoController.text.trim().isEmpty ? null : descricaoController.text.trim(),
          ministryFunctions: funcoes,
          isActive: ativo,
        );
        
        // print('📤 Dados de criação: ${createData.toJson()}');
        
        if (_isServusAdmin) {
          // TODO: Implementar criação global para servus_admin
          throw Exception('Criação global não implementada para servus_admin');
        } else {
          // 🆕 CORREÇÃO: Trata corretamente o branchId
          String? branchIdParaAPI;
          if (_branchId != null && _branchId!.isNotEmpty) {
            branchIdParaAPI = _branchId;
            // print('🏪 Usando branch específica: $branchIdParaAPI');
          } else {
            // print('🏢 Usuário da matriz - sem branch específica');
            // Para usuários da matriz, não passa branchId na URL
            // O backend deve tratar isso como ministério da matriz
          }
          
          await _ministryService.createMinistry(
            tenantId: _tenantId!,
            branchId: branchIdParaAPI ?? '', // Passa string vazia se for matriz
            ministryData: createData,
            context: context,
          );
        }
        
        success = true;
        // print('✅ Ministério criado com sucesso!');
      }

      isSaving = false;
      notifyListeners();
      
      if (success) {
        // Navega de volta para a lista com parâmetro para forçar refresh
        if (context.mounted) {
          // print('🔄 Navegando para lista de ministérios...');
          context.go('/leader/ministerio/lista?refresh=true');
        }
      }
      
      return success;
    } catch (e) {
      isSaving = false;
      notifyListeners();
      
      // print('❌ Erro ao salvar ministério: $e');
      // print('🔍 Detalhes do erro:');
      // print('   - Tipo: ${e.runtimeType}');
      // print('   - Mensagem: ${e.toString()}');
      if (e is Exception) {
        // print('   - Exception: $e');
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
        
        FeedbackService.showError(context, errorMessage);
      }
      
      return false;
    }
  }

  /// Mostra erro de contexto
  void _showContextError(BuildContext context) {
    if (context.mounted) {
      FeedbackService.showAuthError(context);
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