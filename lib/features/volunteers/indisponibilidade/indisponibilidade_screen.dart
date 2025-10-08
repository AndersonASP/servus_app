import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/features/volunteers/indisponibilidade/bloqueios/controller/bloqueio_controller.dart';
import 'package:servus_app/features/volunteers/indisponibilidade/bloqueios/screens/bloqueio_screen.dart';
import 'package:servus_app/shared/widgets/calendar_widget.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';
import 'package:servus_app/state/auth_state.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'indisponibilidade_controller.dart';

class IndisponibilidadeScreen extends StatefulWidget {
  const IndisponibilidadeScreen({super.key});

  @override
  State<IndisponibilidadeScreen> createState() => _IndisponibilidadeScreenState();
}

class _IndisponibilidadeScreenState extends State<IndisponibilidadeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        print('🔍 [IndisponibilidadeScreen] ===== INICIANDO CARREGAMENTO NO INITSTATE =====');
        final controller = Provider.of<IndisponibilidadeController>(context, listen: false);
        
        print('🔍 [IndisponibilidadeScreen] Carregando ministérios do voluntário...');
        print('🔍 [IndisponibilidadeScreen] Chamando carregarMinisteriosDoVoluntario()...');
        await controller.carregarMinisteriosDoVoluntario();
        print('🔍 [IndisponibilidadeScreen] carregarMinisteriosDoVoluntario() concluído');
        print('🔍 [IndisponibilidadeScreen] Ministérios carregados. Quantidade: ${controller.ministeriosDoVoluntario.length}');
        print('🔍 [IndisponibilidadeScreen] Ministérios: ${controller.ministeriosDoVoluntario}');
        print('🔍 [IndisponibilidadeScreen] Limite atual: ${controller.maxDiasIndisponiveis}');
        
        print('🔍 [IndisponibilidadeScreen] Carregando bloqueios existentes...');
        await controller.carregarBloqueiosExistentes();
        print('🔍 [IndisponibilidadeScreen] Bloqueios carregados. Limite final: ${controller.maxDiasIndisponiveis}');
        
        print('✅ [IndisponibilidadeScreen] ===== CARREGAMENTO CONCLUÍDO =====');
      } catch (e) {
        print('❌ [IndisponibilidadeScreen] Erro no initState: $e');
        print('❌ [IndisponibilidadeScreen] Stack trace: ${StackTrace.current}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<IndisponibilidadeController>(context);
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Indisponibilidade',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.onSurface,
              ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: context.colors.onSurface,
                        ),
                    children: [
                      const TextSpan(text: 'Toque nos dias em que você '),
                      TextSpan(
                        text: 'não',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: context.colors.error,
                        ),
                      ),
                      const TextSpan(text: ' poderá servir.'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: TableCalendar(
                        locale: 'pt_BR',
                        firstDay: DateTime.utc(today.year, today.month - 3, 1),
                        lastDay: DateTime.utc(today.year, today.month + 3, 31),
                        focusedDay: controller.focusedDay,
                        onPageChanged: (newFocusedDay) {
                          controller.setFocusedDay(newFocusedDay);
                        },
                        enabledDayPredicate: (day) {
                          final now = DateTime.now();
                          final todayOnlyDate =
                              DateTime(now.year, now.month, now.day);
                          final currentDayOnly =
                              DateTime(day.year, day.month, day.day);
                          return !currentDayOnly.isBefore(todayOnlyDate);
                        },
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: TextStyle(
                            color: context.colors.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        calendarStyle: buildCalendarStyle(context),
                        selectedDayPredicate: (day) =>
                            controller.isDiaBloqueado(day),
                        onDaySelected: (selectedDay, focusedDay) async {
                          controller.setFocusedDay(focusedDay);
                          
                          if (controller.isDiaBloqueado(selectedDay)) {
                            // Se o dia já está bloqueado, abre o bottom sheet diretamente
                            controller.selecionarDia(selectedDay);
                            _mostrarBottomSheetBloqueio(context, controller);
        } else {
          // Se o dia não está bloqueado, abre a tela para criar novo bloqueio
          print('🔍 [IndisponibilidadeScreen] Abrindo tela para criar bloqueio');
          print('🔍 [IndisponibilidadeScreen] Ministérios disponíveis: ${controller.ministeriosDoVoluntario}');
          print('🔍 [IndisponibilidadeScreen] Quantidade de ministérios: ${controller.ministeriosDoVoluntario.length}');
          
          // Verificar se os ministérios foram carregados
          if (controller.ministeriosDoVoluntario.isEmpty) {
            print('⚠️ [IndisponibilidadeScreen] Ministérios não carregados ainda, tentando carregar...');
            try {
              // Usar método de teste que força o carregamento
              await controller.testarCarregamentoMinisterios();
              print('✅ [IndisponibilidadeScreen] Ministérios carregados após tentativa');
            } catch (e) {
              print('❌ [IndisponibilidadeScreen] Erro ao carregar ministérios: $e');
            }
            
            // Verificar novamente após tentar carregar
            if (controller.ministeriosDoVoluntario.isEmpty) {
              print('❌ [IndisponibilidadeScreen] Ministérios ainda não carregados após tentativa');
              return;
            }
          }
          
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BloqueioScreen(
                                  selectedDate: selectedDay,
                                  onConfirmar: (motivo, ministerios, bloqueioController) async {
                                    print('🔍 [IndisponibilidadeScreen] ===== onConfirmar CHAMADO =====');
                                    print('🔍 [IndisponibilidadeScreen] Motivo: "$motivo"');
                                    print('🔍 [IndisponibilidadeScreen] Ministérios: $ministerios');
                                    print('🔍 [IndisponibilidadeScreen] Data selecionada: ${selectedDay.day}/${selectedDay.month}/${selectedDay.year}');
                                    
                                    final authState = Provider.of<AuthState>(context, listen: false);
                                    final usuario = authState.usuario;
                                    
                                    if (usuario != null) {
                                      print('🔍 [IndisponibilidadeScreen] Usuário encontrado: ${usuario.email}');
                                      
                                      // Obter o ID do usuário do token
                                      final userId = await TokenService.getUserId();
                                      if (userId == null) {
                                        print('❌ [IndisponibilidadeScreen] Não foi possível obter o ID do usuário');
                                        return;
                                      }
                                      
                                      print('🔍 [IndisponibilidadeScreen] UserId obtido: $userId');
                                      print('🔍 [IndisponibilidadeScreen] TenantId: ${usuario.tenantId}');
                                      
                                      print('🔍 [IndisponibilidadeScreen] ===== CHAMANDO registrarBloqueio =====');
                                      final resultado = await controller.registrarBloqueio(
                                        dia: selectedDay,
                                        motivo: motivo,
                                        ministerios: ministerios,
                                        tenantId: usuario.tenantId ?? '',
                                        userId: userId,
                                        context: context, // 🆕 ADICIONADO: Passar context para exibir ServusSnackbar
                                      );
                                      
                                      print('🔍 [IndisponibilidadeScreen] Resultado do registrarBloqueio: $resultado');
                                      
                                      if (resultado) {
                                        print('✅ [IndisponibilidadeScreen] Bloqueio criado com sucesso!');
                                        
                            
                                        
                                        // Fechar a tela apenas após sucesso
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          print('✅ [IndisponibilidadeScreen] Navigator.pop chamado após sucesso');
                                        }
                                      } else {
                                        print('❌ [IndisponibilidadeScreen] Falha ao criar bloqueio');
                                        // Não fechar a tela se houve falha
                                      }
                                      
                                      // Desativar loading após operação concluída
                                      bloqueioController.setLoading(false);
                                    } else {
                                      print('❌ [IndisponibilidadeScreen] Usuário não encontrado');
                                    }
                                    
                                    print('🔍 [IndisponibilidadeScreen] ===== FIM onConfirmar =====');
                                  },
                                  ministeriosDisponiveis: controller.ministeriosDoVoluntario,
                                ),
                              ),
                            );
                          }
                        },
                        calendarFormat: CalendarFormat.month,
                        availableGestures: AvailableGestures.all,
                      ),
                ),
                const SizedBox(height: 24),
                
                // Cards removidos - agora o clique direto no dia bloqueado abre o bottom sheet
              ],
            ),
          ),
        ),
      ),
    );
  }


  void _mostrarBottomSheetBloqueio(BuildContext context, IndisponibilidadeController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle do bottom sheet
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Título
            Text(
              'Detalhes do Bloqueio',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            // Lista de bloqueios
            if (controller.bloqueiosDoDiaSelecionado.isEmpty)
              Center(
                child: Text(
                  'Nenhum bloqueio encontrado',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: context.colors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              )
            else
              ...controller.bloqueiosDoDiaSelecionado.map((bloqueio) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Data
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: context.colors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Data: ${bloqueio.data.day}/${bloqueio.data.month}/${bloqueio.data.year}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: context.colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Motivo
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: context.colors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Motivo: ${bloqueio.motivo}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: context.colors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Ministérios
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.group, color: context.colors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ministérios: ${bloqueio.ministerios.join(', ')}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: context.colors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Botões de ação
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop(); // Fecha o bottom sheet
                            _abrirTelaEdicao(context, controller, bloqueio);
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Editar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop(); // Fecha o bottom sheet
                            _removerBloqueio(context, controller, bloqueio);
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Excluir'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colors.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              )),
            
            // Espaço para evitar que o teclado cubra os botões
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  void _abrirTelaEdicao(BuildContext context, IndisponibilidadeController controller, bloqueio) {
    final authState = Provider.of<AuthState>(context, listen: false);
    final usuario = authState.usuario;
    
    // Verificar se os ministérios foram carregados
    if (controller.ministeriosDoVoluntario.isEmpty) {
      print('⚠️ [IndisponibilidadeScreen] Ministérios não carregados para edição');
      return;
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BloqueioScreen(
          selectedDate: bloqueio.data,
          onConfirmar: (motivo, ministerios, bloqueioController) async {
            if (usuario != null) {
              await _executarEdicaoBloqueio(context, controller, bloqueio, motivo, ministerios, usuario, bloqueioController);
            }
          },
          motivoInicial: bloqueio.motivo,
          ministeriosIniciais: bloqueio.ministerios,
          ministeriosDisponiveis: controller.ministeriosDoVoluntario,
        ),
      ),
    );
  }

  Future<void> _executarEdicaoBloqueio(BuildContext context, IndisponibilidadeController controller, bloqueio, String motivo, List<String> ministerios, usuario, BloqueioController bloqueioController) async {
    try {
      print('🔍 [IndisponibilidadeScreen] Iniciando edição do bloqueio...');
      
      // Obter o ID do usuário do token
      final userId = await TokenService.getUserId();
      if (userId == null) {
        print('❌ [IndisponibilidadeScreen] Não foi possível obter o ID do usuário');
        return;
      }
      
      // Primeiro remove o bloqueio existente
      final sucessoRemocao = await controller.removerBloqueioEspecifico(
        bloqueio: bloqueio,
        tenantId: usuario.tenantId ?? '',
        userId: userId,
      );
      
      print('🔍 [IndisponibilidadeScreen] Resultado da remoção: $sucessoRemocao');
      
      if (sucessoRemocao) {
        // Depois cria o novo bloqueio
        final sucessoCriacao = await controller.registrarBloqueio(
          dia: bloqueio.data,
          motivo: motivo,
          ministerios: ministerios,
          tenantId: usuario.tenantId ?? '',
          userId: userId,
          context: context, // 🆕 ADICIONADO: Passar context para exibir ServusSnackbar
        );
        
        print('🔍 [IndisponibilidadeScreen] Resultado da criação: $sucessoCriacao');
        
        if (sucessoCriacao) {
          // Recarrega os bloqueios para garantir consistência
          await controller.carregarBloqueiosExistentes();
          // Atualiza a seleção do dia
          controller.selecionarDia(bloqueio.data);
          
          // Fechar a tela apenas após sucesso
          if (context.mounted) {
            Navigator.pop(context);
            print('✅ [IndisponibilidadeScreen] Navigator.pop chamado após edição');
          }
          
          print('✅ [IndisponibilidadeScreen] Edição concluída com sucesso');
        } else {
          print('❌ [IndisponibilidadeScreen] Falha ao criar novo bloqueio');
          if (context.mounted) {
            showWarning(
              context,
              'Falha ao salvar as alterações do bloqueio. Tente novamente.',
              title: 'Erro na Edição',
            );
          }
        }
      } else {
        print('❌ [IndisponibilidadeScreen] Falha ao remover bloqueio existente');
        if (context.mounted) {
          showWarning(
            context,
            'Falha ao remover o bloqueio existente. Tente novamente.',
            title: 'Erro na Edição',
          );
        }
      }
    } catch (e) {
      print('❌ [IndisponibilidadeScreen] Erro durante a edição: $e');
      if (context.mounted) {
        showWarning(
          context,
          'Ocorreu um erro durante a edição. Tente novamente.',
          title: 'Erro',
        );
      }
    } finally {
      // Desativar loading após operação concluída
      bloqueioController.setLoading(false);
    }
  }

  void _removerBloqueio(BuildContext context, IndisponibilidadeController controller, bloqueio) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Remoção', style: context.theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colors.onSurface,
          ),),
          content: Text('Deseja realmente remover o bloqueio do dia ${bloqueio.data.day}/${bloqueio.data.month}/${bloqueio.data.year}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _executarRemocaoBloqueio(context, controller, bloqueio);
              },
              child: Text('Remover', style: context.theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.error,
              ),),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executarRemocaoBloqueio(BuildContext context, IndisponibilidadeController controller, bloqueio) async {
    final authState = Provider.of<AuthState>(context, listen: false);
    final usuario = authState.usuario;
    
    if (usuario != null) {
      try {
        print('🔍 [IndisponibilidadeScreen] Iniciando remoção do bloqueio...');
        
        // Obter o ID do usuário do token
        final userId = await TokenService.getUserId();
        if (userId == null) {
          print('❌ [IndisponibilidadeScreen] Não foi possível obter o ID do usuário');
          return;
        }
        
        final sucesso = await controller.removerBloqueioEspecifico(
          bloqueio: bloqueio,
          tenantId: usuario.tenantId ?? '',
          userId: userId,
        );
        
        print('🔍 [IndisponibilidadeScreen] Resultado da remoção: $sucesso');
        
        if (sucesso) {
          // Recarrega os bloqueios para garantir consistência
          await controller.carregarBloqueiosExistentes();
          // Limpa a seleção se não há mais bloqueios no dia
          if (controller.bloqueiosDoDiaSelecionado.isEmpty) {
            controller.limparSelecao();
          }
          print('✅ [IndisponibilidadeScreen] Remoção concluída com sucesso');
        } else {
          print('❌ [IndisponibilidadeScreen] Falha na remoção');
          if (context.mounted) {
            showWarning(
              context,
              'Falha ao remover o bloqueio. Tente novamente.',
              title: 'Erro na Remoção',
            );
          }
        }
      } catch (e) {
        print('❌ [IndisponibilidadeScreen] Erro durante a remoção: $e');
        if (context.mounted) {
          showWarning(
            context,
            'Ocorreu um erro durante a remoção. Tente novamente.',
            title: 'Erro',
          );
        }
      }
    }
  }
}
