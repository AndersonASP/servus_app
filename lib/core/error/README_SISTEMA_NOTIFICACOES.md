# Sistema Robusto de Notificações de Erro - Servus

## 📋 Visão Geral

O sistema de notificações de erro do Servus foi completamente refatorado para proporcionar uma experiência consistente e amigável ao usuário. O novo sistema centraliza o tratamento de erros tanto no frontend (Flutter) quanto no backend (NestJS).

## 🎯 Objetivos Alcançados

- ✅ **Consistência**: Todas as notificações seguem o mesmo padrão visual e de comportamento
- ✅ **Mensagens Amigáveis**: Erros técnicos são convertidos em mensagens compreensíveis
- ✅ **Centralização**: Um único ponto para gerenciar todos os tipos de erro
- ✅ **Robustez**: Sistema resiliente que funciona mesmo quando o contexto não está disponível
- ✅ **Preparação para Observabilidade**: Estrutura pronta para integração com ferramentas de monitoramento

## 🏗️ Arquitetura

### Frontend (Flutter)

```
NotificationService (Singleton)
├── ErrorInterceptor (Dio)
├── RetryInterceptor (Dio)
└── ServusSnackbar (UI)
```

### Backend (NestJS)

```
GlobalExceptionFilter
├── ErrorResponseDto
├── ValidationErrorResponseDto
├── ConflictErrorResponseDto
└── ValidateDtoPipe
```

## 🚀 Como Usar

### Frontend - NotificationService

#### 1. Tratamento Automático (Recomendado)

O `ErrorInterceptor` já trata automaticamente todos os erros HTTP:

```dart
// Não precisa fazer nada - o interceptor cuida de tudo
final response = await dio.post('/api/users', data: userData);
```

#### 2. Tratamento Manual

Para casos específicos onde você quer controle total:

```dart
import 'package:servus_app/core/error/notification_service.dart';

class UserService {
  final NotificationService _notificationService = NotificationService();

  Future<void> createUser(UserData data) async {
    try {
      await _api.createUser(data);
      _notificationService.showCreateSuccess('Usuário');
    } catch (e) {
      if (e is DioException) {
        _notificationService.handleDioError(e, customMessage: 'Erro ao criar usuário');
      } else {
        _notificationService.handleGenericError(e);
      }
      rethrow;
    }
  }
}
```

#### 3. Métodos Específicos por Tipo de Erro

```dart
// Erro de validação
_notificationService.handleValidationError('Email deve ser válido');

// Erro de autenticação
_notificationService.handleAuthError();

// Erro de permissão
_notificationService.handlePermissionError();

// Erro de recurso não encontrado
_notificationService.handleNotFoundError(resourceName: 'Usuário');

// Erro de conflito (duplicação)
_notificationService.handleConflictError(conflictType: 'email');

// Erro de servidor
_notificationService.handleServerError();

// Erro de rede
_notificationService.handleNetworkError();
```

### Backend - Respostas Padronizadas

#### 1. Erros Automáticos

O `GlobalExceptionFilter` trata automaticamente todas as exceções:

```typescript
// Em qualquer controller - o filtro cuida de tudo
@Post()
async createUser(@Body() createUserDto: CreateUserDto) {
  // Se houver erro de validação, será automaticamente convertido
  // para ValidationErrorResponseDto
  return this.userService.create(createUserDto);
}
```

#### 2. Erros Personalizados

Para casos específicos:

```typescript
import { ConflictException } from '@nestjs/common';
import { ConflictErrorResponseDto } from '../common/dto/error-response.dto';

@Post()
async createUser(@Body() createUserDto: CreateUserDto) {
  const existingUser = await this.userService.findByEmail(createUserDto.email);
  
  if (existingUser) {
    throw new ConflictException(
      new ConflictErrorResponseDto(
        'Já existe um usuário com este email. Use um email diferente.',
        'DUPLICATE_EMAIL',
        'email'
      )
    );
  }
  
  return this.userService.create(createUserDto);
}
```

## 📊 Tipos de Resposta de Erro

### ErrorResponseDto (Padrão)

```json
{
  "message": "Email já está em uso. Use um email diferente.",
  "code": "DUPLICATE_EMAIL",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "path": "/api/users"
}
```

### ValidationErrorResponseDto (Validação)

```json
{
  "message": "Dados inválidos. Verifique as informações fornecidas.",
  "code": "VALIDATION_ERROR",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "path": "/api/users",
  "validationErrors": {
    "email": ["Email deve ser um endereço válido"],
    "password": ["Senha deve ter pelo menos 8 caracteres"]
  }
}
```

### ConflictErrorResponseDto (Conflito)

```json
{
  "message": "Já existe um usuário com este email. Use um email diferente.",
  "code": "DUPLICATE_EMAIL",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "path": "/api/users",
  "conflictType": "DUPLICATE_EMAIL",
  "field": "email"
}
```

## 🔧 Migração de Código Existente

### Antes (Código Antigo)

```dart
// Serviço antigo
try {
  final response = await _dio.post('/api/users', data: data);
  if (context != null) {
    showCreateSuccess(context, 'Usuário');
  }
} catch (e) {
  if (context != null) {
    showCreateError(context, 'usuário');
  }
  throw Exception('Erro: $e');
}
```

### Depois (Código Novo)

```dart
// Serviço novo
try {
  final response = await _dio.post('/api/users', data: data);
  _notificationService.showCreateSuccess('Usuário');
} catch (e) {
  if (e is DioException) {
    _notificationService.handleDioError(e, customMessage: 'Erro ao criar usuário');
  } else {
    _notificationService.showCreateError('usuário');
  }
  rethrow;
}
```

## 🎨 Interface do Usuário

### ServusSnackbar

O sistema usa o `ServusSnackbar` existente, que já possui:

- ✅ **Fila de notificações**: Evita sobreposição
- ✅ **Animações suaves**: Entrada e saída animadas
- ✅ **Design consistente**: Segue o padrão visual do app
- ✅ **Tipos visuais**: Success, Warning, Error, Info
- ✅ **Responsivo**: Funciona em diferentes tamanhos de tela

### Tipos de Notificação

- 🔴 **Error**: Erros críticos (500, 401, 403, etc.)
- 🟡 **Warning**: Avisos e validações (400, 409, etc.)
- 🟢 **Success**: Operações bem-sucedidas
- 🔵 **Info**: Informações gerais

## 🚨 Códigos de Erro Padronizados

### Frontend

- `VALIDATION_ERROR`: Erro de validação
- `DUPLICATE_EMAIL`: Email duplicado
- `DUPLICATE_NAME`: Nome duplicado
- `UNAUTHORIZED`: Não autorizado
- `FORBIDDEN`: Sem permissão
- `NOT_FOUND`: Recurso não encontrado
- `TOO_MANY_REQUESTS`: Muitas tentativas
- `INTERNAL_SERVER_ERROR`: Erro interno

### Backend

- `VALIDATION_ERROR`: Erro de validação
- `DUPLICATE_EMAIL`: Email duplicado
- `DUPLICATE_NAME`: Nome duplicado
- `UNAUTHORIZED`: Token expirado/inválido
- `FORBIDDEN`: Sem permissão
- `NOT_FOUND`: Recurso não encontrado
- `CONFLICT`: Conflito de dados
- `TOO_MANY_REQUESTS`: Rate limit excedido
- `INTERNAL_SERVER_ERROR`: Erro interno

## 🔍 Debugging e Logs

### Frontend

```dart
// Logs automáticos no ErrorNotificationService
debugPrint('❌ [ErrorNotificationService] Contexto não disponível para mostrar Erro');
debugPrint('❌ [ErrorNotificationService] Mensagem: Email já está em uso');
```

### Backend

```typescript
// Logs automáticos no GlobalExceptionFilter
this.logger.error(
  `Erro 409 em POST /api/users: Já existe um usuário com este email`,
  exception.stack
);
```

## 🚀 Próximos Passos

1. **Migração Gradual**: Migrar serviços existentes para o novo sistema
2. **Testes**: Adicionar testes unitários para o ErrorNotificationService
3. **Observabilidade**: Integrar com ferramentas como Sentry ou Bugsnag
4. **Métricas**: Adicionar métricas de erro para monitoramento
5. **Internacionalização**: Preparar mensagens para múltiplos idiomas

## 📝 Notas Importantes

- ⚠️ **ErrorNotificationService** é diferente do sistema de notificações push do celular
- 🔄 **Compatibilidade**: O sistema antigo continua funcionando durante a migração
- 🎯 **Performance**: Sistema otimizado com singleton e cache de contexto
- 🛡️ **Segurança**: Detalhes técnicos são filtrados em produção
- 📱 **Responsivo**: Funciona em todas as plataformas (iOS, Android, Web)

## 🤝 Contribuição

Para adicionar novos tipos de erro ou melhorar o sistema:

1. Adicione o novo tipo em `ErrorNotificationService`
2. Crie o DTO correspondente no backend
3. Atualize o `GlobalExceptionFilter` se necessário
4. Documente o novo tipo neste arquivo
5. Adicione testes unitários

---

**Sistema implementado com sucesso! 🎉**

O Servus agora possui um sistema robusto e consistente de notificações de erro que melhora significativamente a experiência do usuário e facilita a manutenção do código.
