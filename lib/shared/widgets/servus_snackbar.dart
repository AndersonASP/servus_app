import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

enum ServusSnackType { success, warning, error, info }

class ServusSnackQueue {
  static final List<_QueuedSnack> _queue = [];
  static bool _isProcessing = false;

  static void addToQueue({
    required BuildContext context,
    required String message,
    ServusSnackType type = ServusSnackType.info,
    Duration duration = const Duration(seconds: 5),
    String? title,
  }) {
    _queue.add(_QueuedSnack(
      context: context,
      message: message,
      type: type,
      duration: duration,
      title: title,
    ));
    
    if (!_isProcessing) {
      _processQueue();
    }
  }

  static Future<void> _processQueue() async {
    if (_queue.isEmpty) {
      _isProcessing = false;
      return;
    }

    _isProcessing = true;
    final snack = _queue.removeAt(0);
    
    await _showSnackWithAnimation(
      context: snack.context,
      message: snack.message,
      type: snack.type,
      duration: snack.duration,
      title: snack.title,
    );

    // Aguardar um pouco antes de processar a próxima
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Processar próxima notificação
    _processQueue();
  }
}

class _QueuedSnack {
  final BuildContext context;
  final String message;
  final ServusSnackType type;
  final Duration duration;
  final String? title;

  _QueuedSnack({
    required this.context,
    required this.message,
    required this.type,
    required this.duration,
    this.title,
  });
}

void showServusSnack(
  BuildContext context, {
  required String message,
  ServusSnackType type = ServusSnackType.info,
  Duration duration = const Duration(seconds: 5),
  String? title,
}) {
  // Adicionar à fila em vez de mostrar imediatamente
  ServusSnackQueue.addToQueue(
    context: context,
    message: message,
    type: type,
    duration: duration,
    title: title,
  );
}

Future<void> _showSnackWithAnimation({
  required BuildContext context,
  required String message,
  ServusSnackType type = ServusSnackType.info,
  Duration duration = const Duration(seconds: 5),
  String? title,
}) async {
  // Verificar se o contexto ainda está montado
  if (!context.mounted) {
    return;
  }

  final theme = Theme.of(context);
  final scheme = theme.colorScheme;

  // Cores sólidas por tipo
  final Map<ServusSnackType, Color> solidColors = {
    ServusSnackType.success: Colors.green,
    ServusSnackType.warning: Colors.amber,
    ServusSnackType.error: Colors.red,
    ServusSnackType.info: scheme.primary,
  };

  final Map<ServusSnackType, IconData> icon = {
    ServusSnackType.success: Icons.check_circle_rounded,
    ServusSnackType.warning: Icons.warning_amber_rounded,
    ServusSnackType.error: Icons.error_rounded,
    ServusSnackType.info: Icons.info_rounded,
  };

  // Verificar novamente se o contexto ainda está montado antes de mostrar o SnackBar
  if (!context.mounted) {
    return;
  }

  // Usar Overlay para aparecer sobre modais
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;
  
  // Controladores de animação
  final AnimationController animationController = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: _TickerProvider(),
  );
  
  final Animation<double> slideAnimation = Tween<double>(
    begin: -1.0, // Começa fora da tela (acima)
    end: 0.0,    // Termina na posição normal
  ).animate(CurvedAnimation(
    parent: animationController,
    curve: Curves.easeOutCubic,
  ));
  
  final Animation<double> fadeAnimation = Tween<double>(
    begin: 0.0,  // Começa transparente
    end: 1.0,    // Termina opaco
  ).animate(CurvedAnimation(
    parent: animationController,
    curve: Curves.easeOut,
  ));

  overlayEntry = OverlayEntry(
    builder: (context) => AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final snackHeight = MediaQuery.of(context).padding.top + 80;
        
        return Positioned(
          top: slideAnimation.value * snackHeight, // Animação de slide
          left: 0,
          right: 0,
          child: Opacity(
            opacity: fadeAnimation.value, // Animação de fade
            child: Container(
              // Altura = status bar + altura do conteúdo
              height: snackHeight,
              decoration: BoxDecoration(
                color: solidColors[type], // Cor sólida baseada no tipo
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: solidColors[type]!.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Área que cobre o notch/dynamic island (sem conteúdo)
                  SizedBox(height: MediaQuery.of(context).padding.top),
                  
                  // Conteúdo da mensagem (abaixo do notch)
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        onTap: () async {
                          // Animação de saída
                          await animationController.reverse();
                          overlayEntry.remove();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Ícone com fundo
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  icon[type],
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              
                              // Conteúdo
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (title != null) ...[
                                      Text(
                                        title,
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                    ],
                                    Text(
                                      message,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Botão de fechar
                              GestureDetector(
                                onTap: () async {
                                  // Animação de saída
                                  await animationController.reverse();
                                  overlayEntry.remove();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  overlay.insert(overlayEntry);

  // Iniciar animação de entrada
  animationController.forward();

  // Remover automaticamente após a duração
  Future.delayed(duration, () async {
    if (overlayEntry.mounted) {
      // Animação de saída
      await animationController.reverse();
      overlayEntry.remove();
    }
  });
}


// Métodos convenientes para uso direto
void showSuccess(BuildContext context, String message, {String? title}) {
  showServusSnack(
    context,
    message: message,
    type: ServusSnackType.success,
    title: title ?? 'Sucesso!',
  );
}

void showError(BuildContext context, String message, {String? title}) {
  showServusSnack(
    context,
    message: message,
    type: ServusSnackType.error,
    title: title ?? 'Erro',
  );
}

void showWarning(BuildContext context, String message, {String? title}) {
  showServusSnack(
    context,
    message: message,
    type: ServusSnackType.warning,
    title: title ?? 'Atenção',
  );
}

void showInfo(BuildContext context, String message, {String? title}) {
  showServusSnack(
    context,
    message: message,
    type: ServusSnackType.info,
    title: title ?? 'Informação',
  );
}

// Métodos específicos para operações CRUD
void showCreateSuccess(BuildContext context, String itemName) {
  showSuccess(
    context, 
    '$itemName criado com sucesso!',
    title: 'Criação Concluída',
  );
}

void showUpdateSuccess(BuildContext context, String itemName) {
  showSuccess(
    context, 
    '$itemName atualizado com sucesso!',
    title: 'Atualização Concluída',
  );
}

void showDeleteSuccess(BuildContext context, String itemName) {
  showSuccess(
    context, 
    '$itemName removido com sucesso!',
    title: 'Remoção Concluída',
  );
}

void showCreateError(BuildContext context, String itemName) {
  showError(
    context, 
    'Não foi possível criar $itemName. Verifique os dados e tente novamente.',
    title: 'Erro na Criação',
  );
}

void showUpdateError(BuildContext context, String itemName) {
  showError(
    context, 
    'Não foi possível atualizar $itemName. Tente novamente.',
    title: 'Erro na Atualização',
  );
}

void showDeleteError(BuildContext context, String itemName) {
  showError(
    context, 
    'Não foi possível remover $itemName. Tente novamente.',
    title: 'Erro na Remoção',
  );
}

void showLoadError(BuildContext context, String itemName) {
  showError(
    context, 
    'Não foi possível carregar $itemName. Verifique sua conexão.',
    title: 'Erro no Carregamento',
  );
}

void showNetworkError(BuildContext context) {
  showError(
    context, 
    'Verifique sua conexão com a internet e tente novamente.',
    title: 'Sem Conexão',
  );
}

void showAuthError(BuildContext context) {
  showError(
    context, 
    'Sua sessão expirou. Faça login novamente.',
    title: 'Sessão Expirada',
  );
}

void showValidationError(BuildContext context, String message) {
  showWarning(
    context, 
    message,
    title: 'Dados Inválidos',
  );
}

// Métodos específicos para tenants
void showTenantCreateSuccess(BuildContext context, String tenantName) {
  showSuccess(
    context, 
    'A igreja "$tenantName" foi criada com sucesso!',
    title: 'Igreja Criada',
  );
}

void showTenantCreateError(BuildContext context, String tenantName, String error) {
  showError(
    context, 
    'Não foi possível criar a igreja "$tenantName". $error',
    title: 'Erro na Criação da Igreja',
  );
}

// Métodos específicos para usuários
void showUserCreateSuccess(BuildContext context, String userName, String role) {
  final roleText = _translateRole(role);
  showSuccess(
    context, 
    'O usuário "$userName" foi criado como $roleText.',
    title: 'Usuário Criado',
  );
}

void showUserCreateError(BuildContext context, String userName, String error) {
  showError(
    context, 
    'Não foi possível criar o usuário "$userName". $error',
    title: 'Erro na Criação do Usuário',
  );
}

// Método auxiliar para traduzir roles
String _translateRole(String role) {
  const translations = {
    'servus_admin': 'Administrador do Servus',
    'tenant_admin': 'Administrador da Igreja',
    'branch_admin': 'Administrador da Filial',
    'leader': 'Líder de Ministério',
    'volunteer': 'Voluntário',
  };
  return translations[role] ?? role;
}

// TickerProvider personalizado para animações
class _TickerProvider extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick);
  }
}