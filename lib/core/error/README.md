# Sistema de Tratamento de Erros

Este documento explica como usar o novo sistema centralizado de tratamento de erros do Servus App.

## Visão Geral

O `ErrorHandlerService` foi criado para substituir as mensagens de erro técnicas por mensagens amigáveis ao usuário. Ele converte automaticamente erros técnicos (como códigos HTTP, exceções de rede, etc.) em mensagens claras e compreensíveis.

## Como Usar

### 1. Importar o Serviço

```dart
import 'package:servus_app/core/error/error_handler_service.dart';
```

### 2. Tratamento de Erros Genéricos

```dart
try {
  // Sua operação aqui
} catch (e) {
  ErrorHandlerService().handleError(
    context, 
    e,
    customMessage: 'Mensagem personalizada (opcional)',
    onRetry: () => _retryOperation(), // Opcional
  );
}
```

### 3. Tratamento de Erros de Rede

```dart
try {
  // Operação de rede
} catch (e) {
  ErrorHandlerService().handleNetworkError(
    context,
    customMessage: 'Mensagem personalizada (opcional)',
    onRetry: () => _retryOperation(), // Opcional
  );
}
```

### 4. Tratamento de Erros de Autenticação

```dart
try {
  // Operação que requer autenticação
} catch (e) {
  ErrorHandlerService().handleAuthError(
    context,
    customMessage: 'Mensagem personalizada (opcional)',
    onRetry: () => _retryOperation(), // Opcional
  );
}
```

### 5. Tratamento de Erros de Validação

```dart
if (email.isEmpty) {
  ErrorHandlerService().handleValidationError(
    context,
    'Por favor, digite um endereço de email válido.',
    title: 'Email Obrigatório',
  );
  return;
}
```

### 6. Tratamento de Erros de Servidor

```dart
try {
  // Operação que pode falhar no servidor
} catch (e) {
  ErrorHandlerService().handleServerError(
    context,
    customMessage: 'Mensagem personalizada (opcional)',
    onRetry: () => _retryOperation(), // Opcional
  );
}
```

### 7. Tratamento de Erros de Permissão

```dart
try {
  // Operação que requer permissões
} catch (e) {
  ErrorHandlerService().handlePermissionError(
    context,
    customMessage: 'Mensagem personalizada (opcional)',
  );
}
```

### 8. Tratamento de Erros de Recurso Não Encontrado

```dart
try {
  // Busca por recurso
} catch (e) {
  ErrorHandlerService().handleNotFoundError(
    context,
    customMessage: 'Mensagem personalizada (opcional)',
  );
}
```

### 9. Exibir Diálogo de Erro

```dart
ErrorHandlerService().showErrorDialog(
  context,
  'Mensagem de erro',
  title: 'Título do Erro',
  retryText: 'Tentar Novamente',
  onRetry: () => _retryOperation(),
);
```

### 10. Logging de Erros

```dart
try {
  // Operação
} catch (e) {
  ErrorHandlerService().logError(e, context: 'nome da operação');
  // Tratar erro...
}
```

## Tipos de Erro Tratados Automaticamente

### Erros de Rede
- `SocketException`
- `TimeoutException`
- `Connection refused`
- `Network is unreachable`

### Erros de Timeout
- `Connection timeout`
- `Send timeout`
- `Receive timeout`

### Códigos HTTP
- **400**: Dados inválidos
- **401**: Sessão expirada
- **403**: Sem permissão
- **404**: Recurso não encontrado
- **409**: Conflito (item já existe)
- **422**: Dados inválidos
- **429**: Muitas tentativas
- **500-504**: Servidor indisponível

## Migração de Código Existente

### Antes (Código Antigo)
```dart
try {
  // Operação
} catch (e) {
  showError(context, 'Erro ao processar: $e');
}
```

### Depois (Código Novo)
```dart
try {
  // Operação
} catch (e) {
  ErrorHandlerService().handleError(context, e);
}
```

## Benefícios

1. **Mensagens Amigáveis**: Converte erros técnicos em mensagens compreensíveis
2. **Consistência**: Todas as mensagens seguem o mesmo padrão
3. **Centralização**: Um local para gerenciar todos os tipos de erro
4. **Logging**: Registra erros para debug sem expor detalhes técnicos ao usuário
5. **Flexibilidade**: Permite mensagens personalizadas quando necessário
6. **UX Melhorada**: Oferece opções de retry quando apropriado

## Exemplos de Mensagens

### Antes
- "Exception: SocketException: Failed host lookup"
- "Error 500: Internal Server Error"
- "DioException: Connection timeout"

### Depois
- "Verifique sua conexão com a internet e tente novamente."
- "O servidor está temporariamente indisponível. Tente novamente em alguns minutos."
- "A operação demorou muito para ser concluída. Verifique sua conexão e tente novamente."
