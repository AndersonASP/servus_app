import 'package:flutter/material.dart';
import 'package:servus_app/core/theme/color_scheme.dart';

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

  // Cores por tipo com gradientes mais bonitos
  final Map<ServusSnackType, List<Color>> gradientColors = {
    ServusSnackType.success: [
      ServusColors.success,
      ServusColors.success.withOpacity(0.8),
    ],
    ServusSnackType.warning: [
      ServusColors.warning,
      ServusColors.warning.withOpacity(0.8),
    ],
    ServusSnackType.error: [
      scheme.error,
      scheme.error.withOpacity(0.8),
    ],
    ServusSnackType.info: [
      scheme.primary,
      scheme.primary.withOpacity(0.8),
    ],
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

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors[type]!,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradientColors[type]![0].withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                overlayEntry.remove();
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Ícone com fundo
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon[type],
                        color: Colors.white,
                        size: 24,
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
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            message,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Botão de fechar
                    GestureDetector(
                      onTap: () {
                        overlayEntry.remove();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  // Remover automaticamente após a duração
  Future.delayed(duration, () {
    if (overlayEntry.mounted) {
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