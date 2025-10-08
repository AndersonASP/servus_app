import 'package:flutter/material.dart';
import 'package:servus_app/services/scales_advanced_service.dart';
import 'package:servus_app/services/recurrence_service.dart';
import 'package:servus_app/state/auth_state.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';
import 'package:servus_app/core/models/recurrence_pattern.dart';
import 'package:dio/dio.dart';
import 'package:servus_app/features/ministries/services/ministry_service.dart';

class BloqueioIndisponibilidade {
  final DateTime data;
  final String motivo;
  final List<String> ministerios; // Manter como List<String> para compatibilidade com a UI
  
  // Campos para recorrência
  final RecurrencePattern? recurrence;
  final bool isRecurring;
  final String? parentId; // ID do bloqueio pai (para bloqueios gerados automaticamente)

  BloqueioIndisponibilidade({
    required this.data,
    required this.motivo,
    required this.ministerios,
    this.recurrence,
    this.isRecurring = false,
    this.parentId,
  });

  /// Cria uma cópia do bloqueio com novos valores
  BloqueioIndisponibilidade copyWith({
    DateTime? data,
    String? motivo,
    List<String>? ministerios,
    RecurrencePattern? recurrence,
    bool? isRecurring,
    String? parentId,
  }) => BloqueioIndisponibilidade(
    data: data ?? this.data,
    motivo: motivo ?? this.motivo,
    ministerios: ministerios ?? this.ministerios,
    recurrence: recurrence ?? this.recurrence,
    isRecurring: isRecurring ?? this.isRecurring,
    parentId: parentId ?? this.parentId,
  );

  @override
  String toString() {
    return 'BloqueioIndisponibilidade(data: $data, motivo: $motivo, ministerios: $ministerios, isRecurring: $isRecurring)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BloqueioIndisponibilidade &&
          runtimeType == other.runtimeType &&
          data == other.data &&
          motivo == other.motivo &&
          ministerios == other.ministerios &&
          recurrence == other.recurrence &&
          isRecurring == other.isRecurring &&
          parentId == other.parentId;

  @override
  int get hashCode =>
      data.hashCode ^
      motivo.hashCode ^
      ministerios.hashCode ^
      recurrence.hashCode ^
      isRecurring.hashCode ^
      parentId.hashCode;
}

class IndisponibilidadeController extends ChangeNotifier {
  final List<BloqueioIndisponibilidade> bloqueios = [];
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  List<BloqueioIndisponibilidade> bloqueiosDoDiaSelecionado = [];
  int _maxDiasIndisponiveis = 0; // Será carregado do backend - não usar valor padrão
  
  /// Limite máximo de dias indisponíveis por mês
  int get maxDiasIndisponiveis {
    print('🔍 [IndisponibilidadeController] maxDiasIndisponiveis getter chamado');
    print('🔍 [IndisponibilidadeController] Valor atual: $_maxDiasIndisponiveis');
    return _maxDiasIndisponiveis;
  }
  
  // Serviço para carregar dados do ministério
  final MinistryService _ministryService = MinistryService();
  
  // Cache para limites de bloqueios por ministério
  final Map<String, int> _ministryLimits = {};
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  dynamic _ministeriosDoVoluntario = <Map<String, String>>[];
  
  // Cache para evitar múltiplas requisições
  DateTime? _lastLoadTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  List<Map<String, String>> get ministeriosDoVoluntario {
    if (_ministeriosDoVoluntario is List<String>) {
      // Converter lista antiga para nova estrutura
      return [];
    }
    return (_ministeriosDoVoluntario as List).cast<Map<String, String>>();
  }

  // Define o dia em foco (exibido no calendário)
  void setFocusedDay(DateTime day, {bool notify = true}) {
    focusedDay = day;
    if (notify) notifyListeners();
  }

  // Seleciona um dia e atualiza os bloqueios exibidos
  void selecionarDia(DateTime day) {
    selectedDay = day;
    bloqueiosDoDiaSelecionado = bloqueios.where((b) => isSameDay(b.data, day)).toList();
    notifyListeners();
    print('🔍 [IndisponibilidadeController] Dia selecionado: $day');
    print('🔍 [IndisponibilidadeController] Bloqueios encontrados: ${bloqueiosDoDiaSelecionado.length}');
  }

  // Limpa a seleção de dia
  void limparSelecao() {
    selectedDay = null;
    bloqueiosDoDiaSelecionado.clear();
    notifyListeners();
  }

  void abrirTelaDeBloqueio(BuildContext context, DateTime dia) {
    final bloqueio = getBloqueio(dia);
    Navigator.pushNamed(
      context,
      '/bloqueio',
      arguments: {
        'dia': dia,
        'bloqueioExistente': bloqueio,
        'controller': this,
      },
    );
  }

  // Verifica se duas datas são o mesmo dia (sem considerar hora)
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Verifica se o dia está bloqueado
  bool isDiaBloqueado(DateTime day) {
    print('🔍 [IndisponibilidadeController] Verificando se dia está bloqueado: $day');
    print('🔍 [IndisponibilidadeController] Total de bloqueios: ${bloqueios.length}');
    print('🔍 [IndisponibilidadeController] Bloqueios: ${bloqueios.map((b) => '${b.data.day}/${b.data.month}/${b.data.year}').join(', ')}');
    
    final result = bloqueios.any((b) => isSameDay(b.data, day));
    print('🔍 [IndisponibilidadeController] Resultado: $result');
    
    return result;
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
    RecurrencePattern? recurrencePattern,
    BuildContext? context,
  }) async {
    print('🔍 [IndisponibilidadeController] ===== REGISTRAR BLOQUEIO INICIADO =====');
    print('🔍 [IndisponibilidadeController] Dia: $dia');
    print('🔍 [IndisponibilidadeController] Motivo: "$motivo"');
    print('🔍 [IndisponibilidadeController] Ministérios: $ministerios');
    print('🔍 [IndisponibilidadeController] TenantId: $tenantId');
    print('🔍 [IndisponibilidadeController] UserId: $userId');
    print('🔍 [IndisponibilidadeController] Context recebido: ${context != null ? "SIM" : "NÃO"}');
    print('🔍 [IndisponibilidadeController] Context mounted: ${context?.mounted ?? "N/A"}');
    print('🔍 [IndisponibilidadeController] Recorrência: ${recurrencePattern?.type ?? 'Nenhuma'}');
    
    if (ministerios.isEmpty) {
      print('❌ [IndisponibilidadeController] Nenhum ministério selecionado');
      _setError('Selecione pelo menos um ministério');
      return false;
    }
    
    _setSaving(true);
    _clearError();

    try {
      // Obter IDs dos ministérios selecionados
      final List<String> ministryIds = [];
      print('🔍 [IndisponibilidadeController] Ministérios selecionados: $ministerios');
      print('🔍 [IndisponibilidadeController] Ministérios do voluntário: $_ministeriosDoVoluntario');
      
      for (final ministryName in ministerios) {
        final ministry = _ministeriosDoVoluntario.firstWhere(
          (m) => m['name'] == ministryName,
          orElse: () => <String, String>{},
        );
        print('🔍 [IndisponibilidadeController] Ministério encontrado para "$ministryName": $ministry');
        if (ministry.isNotEmpty && ministry['id'] != null) {
          ministryIds.add(ministry['id']!);
          print('🔍 [IndisponibilidadeController] ID adicionado: ${ministry['id']}');
        }
      }
      
      print('🔍 [IndisponibilidadeController] IDs dos ministérios: $ministryIds');
      
      // Carregar limites dos ministérios selecionados
      print('🔍 [IndisponibilidadeController] ===== CARREGANDO LIMITE DOS MINISTÉRIOS =====');
      print('🔍 [IndisponibilidadeController] IDs dos ministérios para carregar limite: $ministryIds');
      Map<String, int> limitesPorMinisterio = await getMaxBlockedDaysForMinistries(ministryIds);
      print('🔍 [IndisponibilidadeController] Limites carregados por ministério: $limitesPorMinisterio');
      print('🔍 [IndisponibilidadeController] ===== FIM DO CARREGAMENTO DE LIMITE =====');
      
      // Se há padrão de recorrência, gerar todas as datas
      List<DateTime> datasParaBloquear = [dia];
      if (recurrencePattern != null && recurrencePattern.type != RecurrenceType.none) {
        print('🔍 [IndisponibilidadeController] ===== GERANDO RECORRÊNCIA =====');
        print('🔍 [IndisponibilidadeController] Padrão recebido: ${recurrencePattern.toString()}');
        print('🔍 [IndisponibilidadeController] Tipo: ${recurrencePattern.type}');
        print('🔍 [IndisponibilidadeController] DayOfWeek: ${recurrencePattern.dayOfWeek}');
        print('🔍 [IndisponibilidadeController] DayOfMonth: ${recurrencePattern.dayOfMonth}');
        print('🔍 [IndisponibilidadeController] WeekOfMonth: ${recurrencePattern.weekOfMonth}');
        print('🔍 [IndisponibilidadeController] MaxOccurrences: ${recurrencePattern.maxOccurrences}');
        print('🔍 [IndisponibilidadeController] EndDate: ${recurrencePattern.endDate}');
        print('🔍 [IndisponibilidadeController] Data inicial: ${dia.day}/${dia.month}/${dia.year}');
        
        // Validar padrão antes de gerar
        final validationError = RecurrenceService.validatePattern(recurrencePattern);
        if (validationError != null) {
          print('❌ [IndisponibilidadeController] Erro na validação do padrão: $validationError');
          _setError('Padrão de recorrência inválido: $validationError');
          return false;
        }
        
        datasParaBloquear = RecurrenceService.generateDateSeries(
          dia,
          recurrencePattern,
          maxDates: 12, // Limite razoável para evitar spam
        );
        print('🔍 [IndisponibilidadeController] Datas geradas: ${datasParaBloquear.length}');
        for (int i = 0; i < datasParaBloquear.length; i++) {
          print('🔍 [IndisponibilidadeController] Data ${i + 1}: ${datasParaBloquear[i].day}/${datasParaBloquear[i].month}/${datasParaBloquear[i].year}');
        }
      } else {
        print('🔍 [IndisponibilidadeController] Sem recorrência - bloqueio único');
        print('🔍 [IndisponibilidadeController] RecurrencePattern é null: ${recurrencePattern == null}');
        if (recurrencePattern != null) {
          print('🔍 [IndisponibilidadeController] Tipo é none: ${recurrencePattern.type == RecurrenceType.none}');
        }
      }
      
      // Verificar limite de dias bloqueados por mês
      print('🔍 [IndisponibilidadeController] ===== VERIFICAÇÃO DE LIMITE NO REGISTRAR BLOQUEIO =====');
      print('🔍 [IndisponibilidadeController] Limite atual: $_maxDiasIndisponiveis');
      print('🔍 [IndisponibilidadeController] Datas para bloquear: ${datasParaBloquear.length}');
      
      Map<String, int> bloqueiosPorMes = {};
      
      // Contar bloqueios existentes por mês
      for (final bloqueio in bloqueios) {
        if (bloqueio.isRecurring) {
          // Para bloqueios recorrentes, contar apenas o bloqueio principal
          final chaveMes = '${bloqueio.data.year}-${bloqueio.data.month.toString().padLeft(2, '0')}';
          bloqueiosPorMes[chaveMes] = (bloqueiosPorMes[chaveMes] ?? 0) + 1;
        } else {
          // Para bloqueios únicos, contar por mês
          final chaveMes = '${bloqueio.data.year}-${bloqueio.data.month.toString().padLeft(2, '0')}';
          bloqueiosPorMes[chaveMes] = (bloqueiosPorMes[chaveMes] ?? 0) + 1;
        }
      }
      
      print('🔍 [IndisponibilidadeController] ===== INICIANDO VALIDAÇÃO DE LIMITE =====');
      print('🔍 [IndisponibilidadeController] Ministérios para validar: $ministerios');
      print('🔍 [IndisponibilidadeController] Limites por ministério: $limitesPorMinisterio');
      
      for (String ministryName in ministerios) {
        final ministryId = _getMinistryIdFromName(ministryName);
        if (ministryId == null || ministryId.isEmpty) continue;
        
        final limiteDoMinisterio = limitesPorMinisterio[ministryId];
        if (limiteDoMinisterio == null) {
          print('⚠️ [IndisponibilidadeController] Limite não encontrado para ministério $ministryName ($ministryId)');
          continue;
        }
        
        print('🔍 [IndisponibilidadeController] Verificando limite para $ministryName: $limiteDoMinisterio dias');
        
        // Contar bloqueios existentes para este ministério específico no mês
        Map<String, int> bloqueiosPorMesPorMinisterio = {};
        for (final bloqueio in bloqueios) {
          if (bloqueio.ministerios.contains(ministryName)) {
            final chaveMes = '${bloqueio.data.year}-${bloqueio.data.month.toString().padLeft(2, '0')}';
            bloqueiosPorMesPorMinisterio[chaveMes] = (bloqueiosPorMesPorMinisterio[chaveMes] ?? 0) + 1;
          }
        }
        
        // Verificar se algum mês excederia o limite para este ministério
        for (DateTime dataParaBloquear in datasParaBloquear) {
          final chaveMes = '${dataParaBloquear.year}-${dataParaBloquear.month.toString().padLeft(2, '0')}';
          final bloqueiosExistentesNoMes = bloqueiosPorMesPorMinisterio[chaveMes] ?? 0;
          final novosBloqueiosNoMes = datasParaBloquear.where((d) => 
            d.year == dataParaBloquear.year && d.month == dataParaBloquear.month
          ).length;
          
          if (bloqueiosExistentesNoMes + novosBloqueiosNoMes > limiteDoMinisterio) {
            final nomeMes = _getNomeMes(dataParaBloquear.month);
            print('❌ [IndisponibilidadeController] Limite do ministério $ministryName seria excedido no mês $nomeMes/${dataParaBloquear.year}');
            print('❌ [IndisponibilidadeController] Bloqueios existentes: $bloqueiosExistentesNoMes');
            print('❌ [IndisponibilidadeController] Novos bloqueios: $novosBloqueiosNoMes');
            print('❌ [IndisponibilidadeController] Limite do ministério: $limiteDoMinisterio');
            print('❌ [IndisponibilidadeController] Total seria: ${bloqueiosExistentesNoMes + novosBloqueiosNoMes}');
            
            _setError('Limite de $limiteDoMinisterio dias bloqueados seria excedido no ministério "$ministryName" no mês de $nomeMes/${dataParaBloquear.year}. Você já tem $bloqueiosExistentesNoMes bloqueios e tentaria adicionar $novosBloqueiosNoMes novos.');

            if (context != null && context.mounted) {
              print('🔔 [IndisponibilidadeController] Exibindo ServusSnackbar de aviso');
              showWarning(
                context,
                'Limite de dias bloqueados excedido no ministério "$ministryName". Remova alguns bloqueios existentes para adicionar novos.',
                title: 'Limite de bloqueios excedido',
              );
              print('🔔 [IndisponibilidadeController] ServusSnackbar exibido');
            } else {
              print('⚠️ [IndisponibilidadeController] Context não disponível para exibir ServusSnackbar');
            }

            return false;
          }
        }
      }
      
      print('✅ [IndisponibilidadeController] Validação de limite por ministério concluída com sucesso');
      print('🔍 [IndisponibilidadeController] ===== INICIANDO CRIAÇÃO DOS BLOQUEIOS =====');

      // Bloquear TODAS as datas para CADA ministério selecionado
      bool allSuccess = true;
      List<String> failedMinistries = [];
      List<DateTime> datasProcessadasComSucesso = [];
      
      print('🔍 [IndisponibilidadeController] Ministérios disponíveis: $_ministeriosDoVoluntario');
      print('🔍 [IndisponibilidadeController] Ministérios selecionados: $ministerios');
      
      for (String ministryName in ministerios) {
        final ministryId = _getMinistryIdFromName(ministryName);
        print('🔍 [IndisponibilidadeController] Processando ministério: $ministryName (ID: $ministryId)');
        
        if (ministryId == null || ministryId.isEmpty) {
          print('❌ [IndisponibilidadeController] ID inválido para ministério: $ministryName');
          print('❌ [IndisponibilidadeController] Ministérios disponíveis: ${_ministeriosDoVoluntario.map((m) => '${m['name']}:${m['id']}').join(', ')}');
          failedMinistries.add(ministryName);
          allSuccess = false;
          continue;
        }

        // Processar cada data para este ministério
        for (DateTime dataParaBloquear in datasParaBloquear) {
          final dataAjustada = DateTime(dataParaBloquear.year, dataParaBloquear.month, dataParaBloquear.day);
          
          try {
            print('🔍 [IndisponibilidadeController] Bloqueando data ${dataAjustada.day}/${dataAjustada.month}/${dataAjustada.year} para $ministryName...');
            
            final response = await ScalesAdvancedService.blockDate(
              tenantId: tenantId,
              userId: userId,
              ministryId: ministryId,
              date: dataAjustada.toIso8601String().split('T')[0],
              reason: motivo,
            );

            print('🔍 [IndisponibilidadeController] Resposta da API para $ministryName em ${dataAjustada.day}/${dataAjustada.month}: ${response['success']}');

            if (response['success'] != true) {
              print('❌ [IndisponibilidadeController] Falha para ministério $ministryName em ${dataAjustada.day}/${dataAjustada.month}: ${response['message']}');
              failedMinistries.add('$ministryName (${dataAjustada.day}/${dataAjustada.month})');
              allSuccess = false;
            } else {
              print('✅ [IndisponibilidadeController] Sucesso para ministério $ministryName em ${dataAjustada.day}/${dataAjustada.month}');
              if (!datasProcessadasComSucesso.contains(dataAjustada)) {
                datasProcessadasComSucesso.add(dataAjustada);
              }
            }
          } catch (e) {
            print('❌ [IndisponibilidadeController] Erro para ministério $ministryName em ${dataAjustada.day}/${dataAjustada.month}: $e');
            failedMinistries.add('$ministryName (${dataAjustada.day}/${dataAjustada.month})');
            allSuccess = false;
          }
        }
      }

      if (allSuccess) {
        print('✅ [IndisponibilidadeController] Todos os bloqueios processados com sucesso');
        // Atualizar estado local - adicionar todos os bloqueios processados
        for (DateTime dataProcessada in datasProcessadasComSucesso) {
          // Remover bloqueios existentes para esta data
          bloqueios.removeWhere((b) => isSameDay(b.data, dataProcessada));
          
          // Adicionar novo bloqueio
          bloqueios.add(BloqueioIndisponibilidade(
            data: dataProcessada,
            motivo: motivo,
            ministerios: ministerios,
            recurrence: recurrencePattern,
            isRecurring: recurrencePattern != null && recurrencePattern.type != RecurrenceType.none,
            parentId: dataProcessada == dia ? null : 'parent_${dia.millisecondsSinceEpoch}', // Primeira data é o pai
          ));
        }
        
        print('✅ [IndisponibilidadeController] ${datasProcessadasComSucesso.length} bloqueios adicionados localmente');
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
        
        print('🔍 [IndisponibilidadeController] Resultado final: allSuccess=$allSuccess, failedMinistries=$failedMinistries');
        
        print('✅ [IndisponibilidadeController] ===== REGISTRAR BLOQUEIO CONCLUÍDO COM SUCESSO =====');
        print('🔔 [IndisponibilidadeController] Retornando TRUE - bloqueio criado com sucesso');
        return true;
      } else {
        print('❌ [IndisponibilidadeController] Falha em alguns bloqueios: $failedMinistries');
        _setError('Falha ao bloquear algumas datas: ${failedMinistries.join(', ')}');
        
        // Mostrar feedback de erro
        if (context != null && context.mounted) {
          showError(
            context,
            'Falha ao registrar bloqueio: ${failedMinistries.join(', ')}',
            title: 'Erro ao salvar',
          );
        }
        
        return false;
      }
    } catch (e) {
      print('❌ [IndisponibilidadeController] ===== ERRO NO REGISTRAR BLOQUEIO =====');
      print('❌ [IndisponibilidadeController] Erro: $e');
      print('❌ [IndisponibilidadeController] Stack trace: ${StackTrace.current}');
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
      print('🔍 [IndisponibilidadeController] Finalizando registrarBloqueio...');
      _setSaving(false);
      print('🔍 [IndisponibilidadeController] ===== FIM DO REGISTRAR BLOQUEIO =====');
    }
  }

  // Remove um bloqueio específico
  Future<bool> removerBloqueioEspecifico({
    required BloqueioIndisponibilidade bloqueio,
    required String tenantId,
    required String userId,
  }) async {
    print('🔍 [IndisponibilidadeController] ===== REMOVENDO BLOQUEIO ESPECÍFICO =====');
    print('🔍 [IndisponibilidadeController] Bloqueio: ${bloqueio.data} - ${bloqueio.motivo}');
    
    _setLoading(true);
    _clearError();

    try {
      final dataAjustada = DateTime(bloqueio.data.year, bloqueio.data.month, bloqueio.data.day);
      
      // Remover bloqueio para cada ministério
      bool allSuccess = true;
      List<String> failedMinistries = [];
      
      for (String ministryName in bloqueio.ministerios) {
        final ministryId = _getMinistryIdFromName(ministryName);
        print('🔍 [IndisponibilidadeController] Desbloqueando ministério: $ministryName (ID: $ministryId)');
        
        if (ministryId == null || ministryId.isEmpty) {
          print('❌ [IndisponibilidadeController] ID inválido para ministério: $ministryName');
          failedMinistries.add(ministryName);
          allSuccess = false;
          continue;
        }

        try {
          final response = await ScalesAdvancedService.unblockDate(
            tenantId: tenantId,
            userId: userId,
            ministryId: ministryId,
            date: dataAjustada.toIso8601String().split('T')[0],
          );

          if (response['success'] != true) {
            print('❌ [IndisponibilidadeController] Falha ao desbloquear ministério $ministryName: ${response['message']}');
            failedMinistries.add(ministryName);
            allSuccess = false;
          } else {
            print('✅ [IndisponibilidadeController] Ministério $ministryName desbloqueado com sucesso');
          }
        } catch (e) {
          print('❌ [IndisponibilidadeController] Erro ao desbloquear ministério $ministryName: $e');
          failedMinistries.add(ministryName);
          allSuccess = false;
        }
      }

      if (allSuccess) {
        // Remover bloqueio da lista local
        bloqueios.remove(bloqueio);
        // Atualizar lista de bloqueios do dia selecionado
        if (selectedDay != null) {
          bloqueiosDoDiaSelecionado = bloqueios.where((b) => isSameDay(b.data, selectedDay!)).toList();
        }
        notifyListeners();
        print('✅ [IndisponibilidadeController] Bloqueio removido com sucesso');
        return true;
      } else {
        print('❌ [IndisponibilidadeController] Falha em alguns ministérios: $failedMinistries');
        _setError('Falha ao desbloquear data para: ${failedMinistries.join(', ')}');
        return false;
      }
    } catch (e) {
      print('❌ [IndisponibilidadeController] Erro ao remover bloqueio: $e');
      _setError('Erro ao remover bloqueio: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Remove o bloqueio de um dia
  Future<bool> removerBloqueio({
    required DateTime day,
    required String tenantId,
    required String userId,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final dataAjustada = DateTime(day.year, day.month, day.day);
      
      // Usar o primeiro ministério disponível para desbloqueio
      final ministryId = _ministeriosDoVoluntario.isNotEmpty 
          ? _ministeriosDoVoluntario.first['id'] 
          : null;
      
      if (ministryId == null || ministryId.isEmpty) {
        _setError('Nenhum ministério disponível para desbloqueio');
        return false;
      }
      
      // Chamar API para desbloquear data
      final response = await ScalesAdvancedService.unblockDate(
        tenantId: tenantId,
        userId: userId,
        ministryId: ministryId,
        date: dataAjustada.toIso8601String().split('T')[0],
      );

      if (response['success'] == true) {
        // Atualizar estado local
        bloqueios.removeWhere((b) => isSameDay(b.data, dataAjustada));
        notifyListeners();
        return true;
      } else {
        _setError('Erro ao desbloquear data no servidor');
        return false;
      }
    } catch (e) {
      _setError('Erro ao desbloquear data: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Exportar ou salvar os bloqueios (mock)
  void salvarIndisponibilidade() {
    for (var b in bloqueios) {
      debugPrint(
          "Bloqueio: ${b.data} | Motivo: ${b.motivo} | Ministérios: ${b.ministerios.join(', ')}");
    }
  }

  // Lista de dias bloqueados (útil para o calendário)
  List<DateTime> get diasBloqueados => bloqueios.map((b) => b.data).toList();

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

  /// Obtém o ID do ministério pelo nome
  String? _getMinistryIdFromName(String ministryName) {
    try {
      print('🔍 [IndisponibilidadeController] Buscando ID para ministério: "$ministryName"');
      print('🔍 [IndisponibilidadeController] Ministérios disponíveis: ${_ministeriosDoVoluntario.map((m) => '${m['name']}:${m['id']}').join(', ')}');
      
      final ministry = _ministeriosDoVoluntario.firstWhere(
        (m) => m['name'] == ministryName,
        orElse: () => {'id': '', 'name': ''},
      );
      
      print('🔍 [IndisponibilidadeController] Ministério encontrado: ${ministry['name']} (ID: ${ministry['id']})');
      
      final id = ministry['id']?.isNotEmpty == true ? ministry['id'] : null;
      print('🔍 [IndisponibilidadeController] ID retornado: $id');
      
      return id;
    } catch (e) {
      print('⚠️ [IndisponibilidadeController] Ministério não encontrado: $ministryName');
      print('⚠️ [IndisponibilidadeController] Erro: $e');
      return null;
    }
  }

  /// Carregar bloqueios existentes do voluntário
  Future<void> carregarBloqueiosExistentes() async {
    print('🔍 [IndisponibilidadeController] ===== INICIANDO CARREGAMENTO DE BLOQUEIOS =====');
    
    _setLoading(true);
    _clearError();

    try {
      final context = await TokenService.getContext();
      print('🔍 [IndisponibilidadeController] Context obtido para bloqueios: $context');
      
      final tenantId = context['tenantId'];
      final userId = context['userId'];
      
      print('🔍 [IndisponibilidadeController] TenantId: $tenantId');
      print('🔍 [IndisponibilidadeController] UserId: $userId');

      if (tenantId == null || userId == null) {
        throw Exception('Tenant ID ou User ID não encontrado');
      }

      print('🔍 [IndisponibilidadeController] Chamando ScalesAdvancedService.getVolunteerUnavailabilities...');
      final response = await ScalesAdvancedService.getVolunteerUnavailabilities(
        tenantId: tenantId,
        userId: userId,
      );
      
      print('🔍 [IndisponibilidadeController] Resposta recebida: $response');
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> availabilityData = response['data'];
        print('🔍 [IndisponibilidadeController] Registros de disponibilidade encontrados: ${availabilityData.length}');
        
        // Limpar bloqueios existentes
        bloqueios.clear();
        
        // Processar cada registro de disponibilidade
        for (var availability in availabilityData) {
          try {
            final ministryName = availability['ministryId']?['name'] ?? 'Ministério';
            final blockedDates = availability['blockedDates'] ?? [];
            
            print('🔍 [IndisponibilidadeController] Processando ministério: $ministryName');
            print('🔍 [IndisponibilidadeController] Bloqueios encontrados: ${blockedDates.length}');
            
            // Processar cada data bloqueada
            for (var blockedDate in blockedDates) {
              try {
                final dateStr = blockedDate['date'];
                final reason = blockedDate['reason'] ?? '';
                final isBlocked = blockedDate['isBlocked'] ?? true;
                
                if (dateStr != null && isBlocked) {
                  final date = DateTime.parse(dateStr);
                  
                  // Verificar se já existe um bloqueio para esta data
                  final existingBlockIndex = bloqueios.indexWhere((b) => isSameDay(b.data, date));
                  
                  if (existingBlockIndex >= 0) {
                    // Adicionar ministério ao bloqueio existente
                    if (!bloqueios[existingBlockIndex].ministerios.contains(ministryName)) {
                      bloqueios[existingBlockIndex].ministerios.add(ministryName);
                    }
                  } else {
                    // Criar novo bloqueio
                    bloqueios.add(BloqueioIndisponibilidade(
                      data: date,
                      motivo: reason,
                      ministerios: [ministryName],
                    ));
                  }
                  
                  print('✅ [IndisponibilidadeController] Bloqueio processado: $date - $reason - $ministryName');
                }
              } catch (e) {
                print('⚠️ [IndisponibilidadeController] Erro ao processar data bloqueada: $e');
                print('⚠️ [IndisponibilidadeController] Dados da data: $blockedDate');
              }
            }
          } catch (e) {
            print('⚠️ [IndisponibilidadeController] Erro ao processar disponibilidade: $e');
            print('⚠️ [IndisponibilidadeController] Dados da disponibilidade: $availability');
          }
        }
        
        print('✅ [IndisponibilidadeController] Total de bloqueios carregados: ${bloqueios.length}');
        notifyListeners();
      } else {
        print('⚠️ [IndisponibilidadeController] Nenhum bloqueio encontrado ou resposta inválida');
        print('⚠️ [IndisponibilidadeController] Resposta: $response');
      }
      
      print('✅ [IndisponibilidadeController] ===== CARREGAMENTO DE BLOQUEIOS CONCLUÍDO =====');
      
      // Carregar limite dos ministérios após carregar os dados
      await _carregarLimiteDosMinisterios();
      
    } catch (e) {
      print('❌ [IndisponibilidadeController] ===== ERRO NO CARREGAMENTO DE BLOQUEIOS =====');
      print('❌ [IndisponibilidadeController] Erro ao carregar bloqueios: $e');
      print('❌ [IndisponibilidadeController] Stack trace: ${StackTrace.current}');
      _setError('Erro ao carregar bloqueios: $e');
    } finally {
      print('🔍 [IndisponibilidadeController] Finalizando carregamento de bloqueios...');
      _setLoading(false);
      print('🔍 [IndisponibilidadeController] ===== FIM DO CARREGAMENTO DE BLOQUEIOS =====');
    }
  }

  /// Carrega os limites dos ministérios do voluntário
  /// 🆕 NOVA ESTRATÉGIA: Armazena limites por ministério em vez de um único limite global
  Future<void> _carregarLimiteDosMinisterios() async {
    try {
      print('🔍 [IndisponibilidadeController] ===== CARREGANDO LIMITE DOS MINISTÉRIOS =====');
      
      if (_ministeriosDoVoluntario.isEmpty) {
        print('⚠️ [IndisponibilidadeController] Nenhum ministério encontrado para carregar limite');
        _setError('Nenhum ministério encontrado para carregar limite');
        return;
      }
      
      // Obter IDs dos ministérios
      final List<String> ministryIds = [];
      for (final ministry in _ministeriosDoVoluntario) {
        if (ministry['id'] != null) {
          ministryIds.add(ministry['id']!);
        }
      }
      
      if (ministryIds.isEmpty) {
        print('⚠️ [IndisponibilidadeController] Nenhum ID de ministério válido encontrado');
        _setError('Nenhum ID de ministério válido encontrado');
        return;
      }
      
      print('🔍 [IndisponibilidadeController] IDs dos ministérios para carregar limite: $ministryIds');
      
      // Carregar limites dos ministérios (agora retorna um mapa)
      final limitesPorMinisterio = await getMaxBlockedDaysForMinistries(ministryIds);
      
      // Armazenar os limites por ministério
      _ministryLimits.clear();
      _ministryLimits.addAll(limitesPorMinisterio);
      
      // Para compatibilidade, manter o menor limite como padrão global
      final limites = limitesPorMinisterio.values.toList();
      _maxDiasIndisponiveis = limites.reduce((a, b) => a < b ? a : b);
      
      print('✅ [IndisponibilidadeController] Limites carregados por ministério: $limitesPorMinisterio');
      print('✅ [IndisponibilidadeController] Limite global (menor): $_maxDiasIndisponiveis dias');
      print('🔍 [IndisponibilidadeController] ===== FIM DO CARREGAMENTO DE LIMITE =====');
      
    } catch (e) {
      print('❌ [IndisponibilidadeController] Erro ao carregar limite dos ministérios: $e');
      print('❌ [IndisponibilidadeController] Stack trace: ${StackTrace.current}');
      _setError('Erro ao carregar limite dos ministérios: $e');
    }
  }

  /// Obtém o nome do mês em português
  String _getNomeMes(int mes) {
    const nomesMeses = [
      '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return nomesMeses[mes];
  }

  /// Obtém o limite de dias bloqueados para um ministério específico
  Future<int> getMaxBlockedDaysForMinistry(String ministryId) async {
    try {
      // Verificar cache primeiro
      if (_ministryLimits.containsKey(ministryId)) {
        print('🔍 [IndisponibilidadeController] Usando limite do cache para ministério $ministryId: ${_ministryLimits[ministryId]} dias');
        return _ministryLimits[ministryId]!;
      }
      
      print('🔍 [IndisponibilidadeController] Carregando limite do ministério: $ministryId');
      
      final context = await TokenService.getContext();
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];
      
      if (tenantId == null) {
        print('❌ [IndisponibilidadeController] TenantId não encontrado');
        throw Exception('TenantId não encontrado');
      }
      
      // Usar o novo endpoint público para obter apenas o maxBlockedDays
      final blockConfig = await _ministryService.getBlockConfig(
        tenantId: tenantId,
        branchId: branchId ?? '',
        ministryId: ministryId,
      );
      
      final limit = blockConfig['maxBlockedDays'];
      if (limit == null) {
        throw Exception('maxBlockedDays não encontrado no ministério');
      }
      
      // Armazenar no cache
      _ministryLimits[ministryId] = limit;
      
      print('✅ [IndisponibilidadeController] Limite carregado para ministério $ministryId: $limit dias');
      return limit;
      
    } catch (e) {
      print('❌ [IndisponibilidadeController] Erro ao carregar limite do ministério $ministryId: $e');
      throw Exception('Erro ao carregar limite do ministério: $e');
    }
  }
  
  /// Obtém o limite de dias bloqueados para múltiplos ministérios
  /// 🆕 NOVA ESTRATÉGIA: Retorna um mapa com os limites de cada ministério
  Future<Map<String, int>> getMaxBlockedDaysForMinistries(List<String> ministryIds) async {
    print('🔍 [IndisponibilidadeController] ===== getMaxBlockedDaysForMinistries INICIADO =====');
    print('🔍 [IndisponibilidadeController] IDs recebidos: $ministryIds');
    
    if (ministryIds.isEmpty) {
      print('❌ [IndisponibilidadeController] Lista vazia - nenhum ministério fornecido');
      throw Exception('Nenhum ministério fornecido para carregar limite');
    }
    
    try {
      print('🔍 [IndisponibilidadeController] Carregando limites para ${ministryIds.length} ministérios');
      
      // Carregar limites para todos os ministérios
      final Map<String, int> ministryLimits = {};
      for (final ministryId in ministryIds) {
        print('🔍 [IndisponibilidadeController] Carregando limite para ministério: $ministryId');
        final limit = await getMaxBlockedDaysForMinistry(ministryId);
        ministryLimits[ministryId] = limit;
        print('🔍 [IndisponibilidadeController] Limite obtido para $ministryId: $limit dias');
      }
      
      print('✅ [IndisponibilidadeController] Limites carregados: $ministryLimits');
      print('🔍 [IndisponibilidadeController] ===== getMaxBlockedDaysForMinistries CONCLUÍDO =====');
      return ministryLimits;
      
    } catch (e) {
      print('❌ [IndisponibilidadeController] Erro ao carregar limites dos ministérios: $e');
      print('❌ [IndisponibilidadeController] Stack trace: ${StackTrace.current}');
      throw Exception('Erro ao carregar limites dos ministérios: $e');
    }
  }
  Future<void> carregarMinisteriosDoVoluntario(AuthState authState) async {
    print('🔍 [IndisponibilidadeController] ===== INICIANDO CARREGAMENTO =====');
    print('🔍 [IndisponibilidadeController] AuthState: ${authState.usuario?.nome}');
    
    // Verificar cache
    if (_lastLoadTime != null && 
        DateTime.now().difference(_lastLoadTime!) < _cacheDuration &&
        _ministeriosDoVoluntario.isNotEmpty) {
      print('✅ [IndisponibilidadeController] Usando cache - dados ainda válidos');
      // Mesmo usando cache, carregar o limite dos ministérios
      await _carregarLimiteDosMinisterios();
      return;
    }
    
    _setLoading(true);
    _clearError();

    try {
      print('🔍 [IndisponibilidadeController] Carregando ministérios do voluntário...');
      
      final context = await TokenService.getContext();
      print('🔍 [IndisponibilidadeController] Context obtido: $context');
      
      final tenantId = context['tenantId'];
      final branchId = context['branchId'];
      
      print('🔍 [IndisponibilidadeController] TenantId: $tenantId');
      print('🔍 [IndisponibilidadeController] BranchId: $branchId');

      if (tenantId == null) {
        throw Exception('Tenant ID não encontrado');
      }

      final dio = DioClient.instance;
      
      print('🔍 [IndisponibilidadeController] Fazendo requisição para /auth/me/context...');
      print('🔍 [IndisponibilidadeController] Headers: X-Tenant-ID: $tenantId, X-Branch-ID: $branchId');
      
      // Buscar contexto do usuário logado usando o endpoint /auth/me/context
      final response = await dio.get(
        '/auth/me/context',
        options: Options(
          headers: {
            'X-Tenant-ID': tenantId,
            if (branchId != null && branchId.isNotEmpty) 'X-Branch-ID': branchId,
          },
        ),
      );
      
      print('🔍 [IndisponibilidadeController] Resposta recebida - Status: ${response.statusCode}');
      print('🔍 [IndisponibilidadeController] Resposta recebida - Headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        print('✅ [IndisponibilidadeController] Resposta recebida com sucesso');
        final Map<String, dynamic> userContext = response.data;
        print('🔍 [IndisponibilidadeController] UserContext completo: $userContext');
        print('🔍 [IndisponibilidadeController] Tipo da resposta: ${userContext.runtimeType}');
        print('🔍 [IndisponibilidadeController] Chaves da resposta: ${userContext.keys.toList()}');
        
        // Verificar se a resposta tem a estrutura esperada
        if (!userContext.containsKey('tenants')) {
          print('❌ [IndisponibilidadeController] Resposta não contém chave "tenants"');
          print('❌ [IndisponibilidadeController] Estrutura da resposta: ${userContext.keys.toList()}');
          throw Exception('Resposta da API não contém a estrutura esperada');
        }
        
        // A estrutura correta é: userContext['tenants'][0]['memberships']
        final List<dynamic> tenants = userContext['tenants'] ?? [];
        print('🔍 [IndisponibilidadeController] Tenants encontrados: ${tenants.length}');
        
        if (tenants.isEmpty) {
          print('⚠️ [IndisponibilidadeController] Nenhum tenant encontrado na resposta');
          _ministeriosDoVoluntario = <Map<String, String>>[];
          notifyListeners();
          return;
        }
        
        final List<Map<String, String>> ministries = [];
        
        // Processar todos os tenants
        for (int i = 0; i < tenants.length; i++) {
          final tenant = tenants[i];
          print('🔍 [IndisponibilidadeController] Processando tenant $i: ${tenant['name'] ?? 'Sem nome'}');
          print('🔍 [IndisponibilidadeController] Tenant $i completo: $tenant');
          
          if (!tenant.containsKey('memberships')) {
            print('⚠️ [IndisponibilidadeController] Tenant $i não contém chave "memberships"');
            continue;
          }
          
          final List<dynamic> memberships = tenant['memberships'] ?? [];
          print('🔍 [IndisponibilidadeController] Memberships no tenant $i: ${memberships.length}');
          
          for (int j = 0; j < memberships.length; j++) {
            final membership = memberships[j];
            print('🔍 [IndisponibilidadeController] Processando membership $j: $membership');
            
            if (membership['ministry'] != null) {
              final ministryId = membership['ministry']['_id'] ?? membership['ministry']['id'];
              final ministryName = membership['ministry']['name'] ?? 'Ministério';
              
              if (ministryId != null) {
                ministries.add({
                  'id': ministryId,
                  'name': ministryName,
                });
                print('✅ [IndisponibilidadeController] Ministério adicionado: $ministryName (ID: $ministryId)');
              } else {
                print('⚠️ [IndisponibilidadeController] Ministério sem ID: $ministryName');
              }
            } else {
              print('⚠️ [IndisponibilidadeController] Membership $j sem ministério: $membership');
            }
          }
        }
        
        _ministeriosDoVoluntario = ministries;
        print('✅ [IndisponibilidadeController] Ministérios carregados: ${ministries.length}');
        print('📋 [IndisponibilidadeController] Ministérios: ${ministries.map((m) => m['name']).join(', ')}');
        print('📋 [IndisponibilidadeController] Detalhes dos ministérios: ${ministries.map((m) => '${m['name']}:${m['id']}').join(', ')}');
        
        // Se não encontrou ministérios, verificar se o usuário tem memberships
        if (ministries.isEmpty) {
          print('⚠️ [IndisponibilidadeController] Nenhum ministério encontrado!');
          print('⚠️ [IndisponibilidadeController] Verificando se o usuário tem memberships...');
          
          for (int i = 0; i < tenants.length; i++) {
            final tenant = tenants[i];
            final List<dynamic> memberships = tenant['memberships'] ?? [];
            print('⚠️ [IndisponibilidadeController] Tenant $i tem ${memberships.length} memberships');
            
            for (int j = 0; j < memberships.length; j++) {
              final membership = memberships[j];
              print('⚠️ [IndisponibilidadeController] Membership $j: role=${membership['role']}, ministry=${membership['ministry']}');
            }
          }
        }
      } else {
        print('❌ [IndisponibilidadeController] Erro na resposta: ${response.statusCode}');
        print('❌ [IndisponibilidadeController] Dados da resposta: ${response.data}');
        throw Exception('Erro ao buscar contexto do usuário: ${response.statusCode}');
      }
      
      // Marcar cache como válido
      _lastLoadTime = DateTime.now();
      
      // Carregar limite dos ministérios após carregar os dados
      await _carregarLimiteDosMinisterios();
      
      notifyListeners();
      print('✅ [IndisponibilidadeController] ===== CARREGAMENTO CONCLUÍDO COM SUCESSO =====');
    } catch (e) {
      print('❌ [IndisponibilidadeController] ===== ERRO NO CARREGAMENTO =====');
      print('❌ [IndisponibilidadeController] Erro ao carregar ministérios: $e');
      print('❌ [IndisponibilidadeController] Stack trace: ${StackTrace.current}');
      _setError('Erro ao carregar ministérios: $e');
      
      // Em caso de erro, usar lista vazia para evitar problemas na interface
      _ministeriosDoVoluntario = <Map<String, String>>[];
      notifyListeners();
    } finally {
      print('🔍 [IndisponibilidadeController] Finalizando carregamento...');
      _setLoading(false);
      print('🔍 [IndisponibilidadeController] ===== FIM DO CARREGAMENTO =====');
    }
  }
}
