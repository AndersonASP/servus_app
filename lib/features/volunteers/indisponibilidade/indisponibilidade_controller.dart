import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';

class BloqueioIndisponibilidade {
  final DateTime data;
  final String motivo;
  final List<String> ministerios;

  BloqueioIndisponibilidade({
    required this.data,
    required this.motivo,
    required this.ministerios,
  });

  /// Cria uma cópia do bloqueio com novos valores
  BloqueioIndisponibilidade copyWith({
    DateTime? data,
    String? motivo,
    List<String>? ministerios,
  }) => BloqueioIndisponibilidade(
    data: data ?? this.data,
    motivo: motivo ?? this.motivo,
    ministerios: ministerios ?? this.ministerios,
  );

  @override
  String toString() {
    return 'BloqueioIndisponibilidade(data: $data, motivo: $motivo, ministerios: $ministerios)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BloqueioIndisponibilidade &&
          runtimeType == other.runtimeType &&
          data == other.data &&
          motivo == other.motivo &&
          ministerios == other.ministerios;

  @override
  int get hashCode =>
      data.hashCode ^
      motivo.hashCode ^
      ministerios.hashCode;
}

class IndisponibilidadeController extends ChangeNotifier {
  final List<BloqueioIndisponibilidade> bloqueios = [];
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  List<BloqueioIndisponibilidade> bloqueiosDoDiaSelecionado = [];
  int _maxDiasIndisponiveis = 0; // Será carregado do backend - não usar valor padrão
  
  // Seleção múltipla de dias
  final Set<DateTime> _diasSelecionados = {};
  bool _modoSelecaoMultipla = false;
  
  Set<DateTime> get diasSelecionados => Set.unmodifiable(_diasSelecionados);
  bool get modoSelecaoMultipla => _modoSelecaoMultipla;
  bool get temDiasSelecionados => _diasSelecionados.isNotEmpty;
  
  /// Limite máximo de dias indisponíveis por mês
  int get maxDiasIndisponiveis {
    print('🔍 [IndisponibilidadeController] maxDiasIndisponiveis getter chamado');
    print('🔍 [IndisponibilidadeController] Valor atual: $_maxDiasIndisponiveis');
    return _maxDiasIndisponiveis;
  }
  
  // Serviço para carregar dados do ministério
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _ministeriosDoVoluntario = [];
  
  // Cache para evitar múltiplas requisições
  DateTime? _lastLoadTime;
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  // Flag para evitar múltiplas tentativas de carregamento
  bool _isLoadingMinisterios = false;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setSaving(bool saving) {
    _isSaving = saving;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Carrega os bloqueios do voluntário
  Future<void> carregarBloqueios() async {
    // Verificar cache
    if (_lastLoadTime != null && 
        DateTime.now().difference(_lastLoadTime!) < _cacheDuration) {
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final userId = await TokenService.getUserId();
      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];

      final response = await DioClient.instance.get(
        '/scales/$tenantId/availability/unavailabilities',
        queryParameters: {
          'userId': userId,
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = response.data;
        final List<dynamic> data = responseData['data'] ?? [];
        bloqueios.clear();
        
        for (final item in data) {
          // Processar blockedDates de cada disponibilidade
          if (item['blockedDates'] != null) {
            for (final blockedDate in item['blockedDates']) {
              final ministryName = item['ministryId']?['name'] ?? 'Ministério';
              bloqueios.add(BloqueioIndisponibilidade(
                data: DateTime.parse(blockedDate['date']),
                motivo: blockedDate['reason'] ?? '',
                ministerios: [ministryName],
              ));
            }
          }
        }
        
        _lastLoadTime = DateTime.now();
      } else {
        _setError('Erro ao carregar bloqueios: ${response.statusCode}');
      }
    } catch (e) {
      _setError('Erro ao carregar bloqueios: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Carrega os ministérios do voluntário
  Future<void> carregarMinisteriosDoVoluntario() async {
    // Evitar múltiplas tentativas simultâneas
    if (_isLoadingMinisterios) {
      await Future.delayed(Duration(milliseconds: 100));
      if (_isLoadingMinisterios) {
        return;
      }
    }

    _isLoadingMinisterios = true;
    
    try {
      final userId = await TokenService.getUserId();
      
      if (userId == null) {
        _setError('Usuário não autenticado');
        return;
      }
      
      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];

      if (tenantId == null) {
        _setError('Contexto de autenticação incompleto - TenantId ausente');
        return;
      }
      
      // Usar endpoint simplificado para buscar ministérios do usuário: /ministry-memberships/my-ministries
      final deviceId = await TokenService.getDeviceId();
      final endpoint = '/ministry-memberships/my-ministries';
      
      final response = await DioClient.instance.get(
        endpoint,
        options: Options(headers: {
          'device-id': deviceId,
          'x-tenant-id': tenantId,
          if (branchId != null && branchId.isNotEmpty) 'x-branch-id': branchId,
        }),
      );

      if (response.statusCode == 200) {
        final dynamic responseData = response.data;
        
        // Processar resposta do endpoint /ministry-memberships/my-ministries
        List<dynamic> membershipsList;
        if (responseData is List) {
          membershipsList = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          // Se a resposta vem em formato { data: [...] }
          membershipsList = responseData['data'] as List<dynamic>;
        } else {
          membershipsList = [];
        }
        
        // Extrair ministérios dos memberships (apenas os ativos)
        _ministeriosDoVoluntario = membershipsList
            .where((membership) {
              final isActive = membership['isActive'] == true;
              final hasMinistry = membership['ministry'] != null;
              return isActive && hasMinistry;
            })
            .map((membership) {
              final ministry = membership['ministry'];
              return {
                'id': ministry['_id']?.toString() ?? ministry['id']?.toString() ?? '',
                'name': ministry['name'] ?? 'Ministério sem nome',
                'maxBlockedDays': ministry['maxBlockedDays'] ?? 10, // Valor padrão se não especificado
              };
            })
            .toList();
        
        // Se não encontrou ministérios, manter lista vazia
        if (_ministeriosDoVoluntario.isEmpty) {
          print('⚠️ [IndisponibilidadeController] Nenhum ministério encontrado para o usuário');
        }
        
        notifyListeners();
      } else {
        _setError('Erro ao carregar ministérios: ${response.statusCode}');
      }
    } catch (e) {
      // Em caso de erro, manter lista vazia
      print('⚠️ [IndisponibilidadeController] Erro ao carregar ministérios, mantendo lista vazia');
      _ministeriosDoVoluntario = [];
      notifyListeners();
    } finally {
      _isLoadingMinisterios = false;
    }
  }

  // Verifica se um dia está bloqueado
  bool isDiaBloqueado(DateTime day) {
    return bloqueios.any((b) => isSameDay(b.data, day));
  }

  // Retorna o bloqueio correspondente ao dia (ou null se não existir)
  BloqueioIndisponibilidade? getBloqueio(DateTime day) {
    try {
      return bloqueios.firstWhere((b) => isSameDay(b.data, day));
    } catch (_) {
      return null;
    }
  }

  // Registra ou atualiza um bloqueio no dia
  Future<bool> registrarBloqueio({
    required DateTime dia,
    required String motivo,
    required List<String> ministerios,
    required String tenantId,
    required String userId,
    BuildContext? context,
  }) async {
    if (ministerios.isEmpty) {
      _setError('Selecione pelo menos um ministério');
      return false;
    }
    
    _setSaving(true);
    _clearError();

    try {
      // Obter IDs dos ministérios selecionados
      final List<String> ministryIds = [];
      
      for (final ministryName in ministerios) {
        final ministry = _ministeriosDoVoluntario.firstWhere(
          (m) => m['name'] == ministryName,
          orElse: () => <String, String>{},
        );
        if (ministry.isNotEmpty && ministry['id'] != null) {
          ministryIds.add(ministry['id']!);
        }
      }
      
      // Obter limites dos ministérios já carregados (sem requisições adicionais)
      Map<String, int> limitesPorMinisterio = getMaxBlockedDaysFromLoadedMinistries(ministryIds);
      
      // Validar limites para o dia específico
      for (String ministryName in ministerios) {
        final ministryId = _getMinistryIdFromName(ministryName);
        if (ministryId == null || ministryId.isEmpty) continue;
        
        final limiteDoMinisterio = limitesPorMinisterio[ministryId];
        if (limiteDoMinisterio == null) {
          continue;
        }
        
        // Contar bloqueios existentes para este ministério específico no mês
        final chaveMes = '${dia.year}-${dia.month.toString().padLeft(2, '0')}';
        int bloqueiosExistentesNoMes = 0;
        
        for (final bloqueio in bloqueios) {
          if (bloqueio.ministerios.contains(ministryName)) {
            final bloqueioChaveMes = '${bloqueio.data.year}-${bloqueio.data.month.toString().padLeft(2, '0')}';
            if (bloqueioChaveMes == chaveMes) {
              bloqueiosExistentesNoMes++;
            }
          }
        }
        
        if (bloqueiosExistentesNoMes >= limiteDoMinisterio) {
          final nomeMes = _getNomeMes(dia.month);
          _setError('Limite de $limiteDoMinisterio dias bloqueados já foi atingido no ministério "$ministryName" no mês de $nomeMes/${dia.year}. Você já tem $bloqueiosExistentesNoMes bloqueios.');

          if (context != null && context.mounted) {
            showWarning(
              context,
              'Você já atingiu o limite de bloqueios para o ministério "$ministryName" neste mês.',
              title: 'Limite atingido',
            );
          }

          return false;
        }
      }
      
      // Criar bloqueio único
      try {
        // Criar bloqueios no backend (um para cada ministério)
        for (final ministryId in ministryIds) {
          await DioClient.instance.post(
            '/scales/$tenantId/availability/block-date',
            data: {
              'userId': userId,
              'ministryId': ministryId,
              'date': dia.toIso8601String().split('T')[0],
              'reason': motivo,
            },
          );
        }
        
        // Adicionar bloqueio localmente
        bloqueios.add(BloqueioIndisponibilidade(
          data: dia,
          motivo: motivo,
          ministerios: ministerios,
        ));
        
        notifyListeners();
        
        // Mostrar feedback de sucesso
        if (context != null && context.mounted) {
          final nomeMes = _getNomeMes(dia.month);
          showSuccess(
            context,
            'Bloqueio registrado com sucesso para $nomeMes/${dia.year}!',
            title: 'Bloqueio salvo',
          );
        }
        
        return true;
      } catch (e) {
        _setError('Erro ao bloquear data: $e');
        
        if (context != null && context.mounted) {
          showError(
            context,
            'Erro ao registrar bloqueio: $e',
            title: 'Erro ao salvar',
          );
        }
        
        return false;
      }
    } catch (e) {
      _setError('Erro ao bloquear data: $e');
      
      // Mostrar feedback de erro
      if (context != null && context.mounted) {
        showError(
          context,
          'Erro ao registrar bloqueio: $e',
          title: 'Erro ao salvar',
        );
      }
      
      return false;
    } finally {
      _setSaving(false);
    }
  }

  // Remove um bloqueio específico
  Future<bool> removerBloqueioEspecifico({
    required BloqueioIndisponibilidade bloqueio,
    required String tenantId,
    required String userId,
    BuildContext? context,
  }) async {
    _setSaving(true);
    _clearError();

    try {
      // Obter IDs dos ministérios do bloqueio
      final List<String> ministryIds = [];
      for (final ministryName in bloqueio.ministerios) {
        final ministry = _ministeriosDoVoluntario.firstWhere(
          (m) => m['name'] == ministryName,
          orElse: () => <String, String>{},
        );
        if (ministry.isNotEmpty && ministry['id'] != null) {
          ministryIds.add(ministry['id']!);
        }
      }
      
      // Remover bloqueios no backend (um para cada ministério)
      for (final ministryId in ministryIds) {
        await DioClient.instance.post(
          '/scales/$tenantId/availability/unblock-date',
          data: {
            'userId': userId,
            'ministryId': ministryId,
            'date': bloqueio.data.toIso8601String().split('T')[0],
          },
        );
      }
      
      // Remover bloqueio localmente
      bloqueios.removeWhere((b) => 
        b.data == bloqueio.data && 
        b.motivo == bloqueio.motivo && 
        b.ministerios.toString() == bloqueio.ministerios.toString()
      );
      
      notifyListeners();
      
      // Mostrar feedback de sucesso
      if (context != null && context.mounted) {
        final nomeMes = _getNomeMes(bloqueio.data.month);
        showSuccess(
          context,
          'Bloqueio removido com sucesso para $nomeMes/${bloqueio.data.year}!',
          title: 'Bloqueio removido',
        );
      }
      
      return true;
    } catch (e) {
      _setError('Erro ao remover bloqueio: $e');
      
      // Mostrar feedback de erro
      if (context != null && context.mounted) {
        showError(
          context,
          'Erro ao remover bloqueio: $e',
          title: 'Erro ao remover',
        );
      }
      
      return false;
    } finally {
      _setSaving(false);
    }
  }

  // Seleciona um dia específico
  void selecionarDia(DateTime day) {
    selectedDay = day;
    bloqueiosDoDiaSelecionado = bloqueios.where((b) => isSameDay(b.data, day)).toList();
    notifyListeners();
  }

  // Define o dia focado no calendário
  void setFocusedDay(DateTime day) {
    focusedDay = day;
    notifyListeners();
  }

  // Obtém o ID do ministério pelo nome
  String? _getMinistryIdFromName(String name) {
    try {
      final ministry = _ministeriosDoVoluntario.firstWhere(
        (m) => m['name'] == name,
      );
      return ministry['id'];
    } catch (_) {
      return null;
    }
  }

  // Obtém o nome do mês
  String _getNomeMes(int month) {
    const meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return meses[month - 1];
  }

  // Verifica se duas datas são do mesmo dia
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Obtém limites de bloqueios dos ministérios já carregados (sem requisições adicionais)
  Map<String, int> getMaxBlockedDaysFromLoadedMinistries(List<String> ministryIds) {
    final Map<String, int> limits = {};
    
    for (final ministryId in ministryIds) {
      try {
        final ministry = _ministeriosDoVoluntario.firstWhere(
          (m) => m['id'] == ministryId,
        );
        limits[ministryId] = ministry['maxBlockedDays'] ?? 10;
      } catch (e) {
        limits[ministryId] = 10; // Valor padrão se não encontrado
      }
    }
    
    return limits;
  }

  // Limpa todos os dados
  void limpar() {
    bloqueios.clear();
    selectedDay = null;
    bloqueiosDoDiaSelecionado.clear();
    _clearError();
    notifyListeners();
  }

  // Recarrega todos os dados
  Future<void> recarregar() async {
    await carregarBloqueios();
    await carregarMinisteriosDoVoluntario();
    notifyListeners(); // Notificar a UI após recarregar todos os dados
  }

  // Getter para ministérios do voluntário
  List<Map<String, dynamic>> get ministeriosDoVoluntario {
    return _ministeriosDoVoluntario;
  }

  // Método de teste para forçar carregamento de ministérios
  Future<void> testarCarregamentoMinisterios() async {
    print('🧪 [IndisponibilidadeController] ===== TESTE DE CARREGAMENTO =====');
    _isLoadingMinisterios = false; // Resetar flag
    await carregarMinisteriosDoVoluntario();
    print('🧪 [IndisponibilidadeController] ===== FIM DO TESTE =====');
  }

  // Método para carregar bloqueios existentes (alias para carregarBloqueios)
  Future<void> carregarBloqueiosExistentes() async {
    await carregarBloqueios();
    notifyListeners(); // Notificar a UI após carregar bloqueios
  }

  // Método para limpar seleção
  void limparSelecao() {
    selectedDay = null;
    bloqueiosDoDiaSelecionado.clear();
    notifyListeners();
  }

  // Métodos para seleção múltipla
  void alternarModoSelecaoMultipla() {
    _modoSelecaoMultipla = !_modoSelecaoMultipla;
    if (!_modoSelecaoMultipla) {
      _diasSelecionados.clear();
    }
    notifyListeners();
  }

  void alternarSelecaoDia(DateTime dia) {
    if (_diasSelecionados.contains(dia)) {
      _diasSelecionados.remove(dia);
    } else {
      _diasSelecionados.add(dia);
    }
    notifyListeners();
  }

  void limparSelecaoMultipla() {
    _diasSelecionados.clear();
    notifyListeners();
  }

  bool isDiaSelecionado(DateTime dia) {
    return _diasSelecionados.contains(dia);
  }

  // Criar bloqueios para múltiplos dias
  Future<bool> criarBloqueiosMultiplos({
    required String motivo,
    required List<String> ministerios,
    required String tenantId,
    required String userId,
    BuildContext? context,
  }) async {
    if (_diasSelecionados.isEmpty) {
      _setError('Nenhum dia selecionado');
      return false;
    }

    print('🔍 [IndisponibilidadeController] ===== CRIANDO BLOQUEIOS MÚLTIPLOS =====');
    print('🔍 [IndisponibilidadeController] Dias selecionados: ${_diasSelecionados.length}');
    print('🔍 [IndisponibilidadeController] Motivo: "$motivo"');
    print('🔍 [IndisponibilidadeController] Ministérios: $ministerios');

    _setSaving(true);
    _clearError();

    try {
      // Obter IDs dos ministérios selecionados
      final List<String> ministryIds = [];
      for (final ministryName in ministerios) {
        final ministry = _ministeriosDoVoluntario.firstWhere(
          (m) => m['name'] == ministryName,
          orElse: () => <String, String>{},
        );
        if (ministry.isNotEmpty && ministry['id'] != null) {
          ministryIds.add(ministry['id']!);
        }
      }

      // Obter limites dos ministérios já carregados (sem requisições adicionais)
      Map<String, int> limitesPorMinisterio = getMaxBlockedDaysFromLoadedMinistries(ministryIds);

      // Validar limites para cada dia
      for (DateTime dia in _diasSelecionados) {
        for (String ministryName in ministerios) {
          final ministryId = _getMinistryIdFromName(ministryName);
          if (ministryId == null || ministryId.isEmpty) continue;
          
          final limiteDoMinisterio = limitesPorMinisterio[ministryId];
          if (limiteDoMinisterio == null) continue;
          
          // Contar bloqueios existentes para este ministério específico no mês
          final chaveMes = '${dia.year}-${dia.month.toString().padLeft(2, '0')}';
          int bloqueiosExistentesNoMes = 0;
          
          for (final bloqueio in bloqueios) {
            if (bloqueio.ministerios.contains(ministryName)) {
              final bloqueioChaveMes = '${bloqueio.data.year}-${bloqueio.data.month.toString().padLeft(2, '0')}';
              if (bloqueioChaveMes == chaveMes) {
                bloqueiosExistentesNoMes++;
              }
            }
          }
          
          if (bloqueiosExistentesNoMes >= limiteDoMinisterio) {
            final nomeMes = _getNomeMes(dia.month);
            _setError('Limite de $limiteDoMinisterio dias bloqueados já foi atingido no ministério "$ministryName" no mês de $nomeMes/${dia.year}.');
            
            if (context != null && context.mounted) {
              showWarning(
                context,
                'Limite atingido para o ministério "$ministryName" no mês de $nomeMes/${dia.year}.',
                title: 'Limite atingido',
              );
            }
            
            return false;
          }
        }
      }

      // Criar bloqueios no backend
      int sucessos = 0;
      int falhas = 0;

      for (DateTime dia in _diasSelecionados) {
        try {
          // Criar bloqueios no backend (um para cada ministério)
          for (final ministryId in ministryIds) {
            await DioClient.instance.post(
              '/scales/$tenantId/availability/block-date',
              data: {
                'userId': userId,
                'ministryId': ministryId,
                'date': dia.toIso8601String().split('T')[0],
                'reason': motivo,
              },
            );
          }
          
          // Adicionar bloqueio localmente
          bloqueios.add(BloqueioIndisponibilidade(
            data: dia,
            motivo: motivo,
            ministerios: ministerios,
          ));
          
          sucessos++;
        } catch (e) {
          falhas++;
        }
      }

          notifyListeners();

      // Mostrar feedback
      if (context != null && context.mounted) {
        if (falhas == 0) {
          showSuccess(
            context,
            '$sucessos bloqueio(s) criado(s) com sucesso!',
            title: 'Bloqueios salvos',
          );
              } else {
          showWarning(
            context,
            '$sucessos bloqueio(s) criado(s), $falhas falharam.',
            title: 'Resultado parcial',
          );
        }
      }

      // Limpar seleção múltipla
      _diasSelecionados.clear();
      _modoSelecaoMultipla = false;
      notifyListeners();

      return sucessos > 0;
    } catch (e) {
      print('❌ [IndisponibilidadeController] Erro ao criar bloqueios múltiplos: $e');
      _setError('Erro ao criar bloqueios: $e');
      
      if (context != null && context.mounted) {
        showError(
          context,
          'Erro ao criar bloqueios: $e',
          title: 'Erro ao salvar',
        );
      }
      
      return false;
    } finally {
      _setSaving(false);
    }
  }
}