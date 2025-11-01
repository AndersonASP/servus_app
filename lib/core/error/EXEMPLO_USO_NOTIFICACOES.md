# 📱 Sistema Centralizado de Notificações - Exemplos de Uso

## 🎯 Visão Geral

O `NotificationService` agora centraliza **TODAS** as notificações (sucesso, warning, erro, info) no `ServusSnackbar`, proporcionando uma experiência uniforme em todo o app.

## 🚀 Métodos Disponíveis

### 1. **Notificações Básicas**

```dart
final notificationService = NotificationService();

// ✅ Sucesso
notificationService.showSuccess('Operação realizada com sucesso!');
notificationService.showSuccess('Dados salvos!', title: 'Sucesso');

// ⚠️ Warning
notificationService.showWarning('Verifique os dados fornecidos');
notificationService.showWarning('Item já existe', title: 'Atenção');

// ❌ Erro
notificationService.showError('Ocorreu um erro inesperado');
notificationService.showError('Falha na operação', title: 'Erro');

// ℹ️ Informação
notificationService.showInfo('Processo iniciado');
notificationService.showInfo('Sincronização em andamento', title: 'Info');
```

### 2. **Tratamento de Erros HTTP**

```dart
// 🔄 DioException (automático baseado no status code)
try {
  await apiCall();
} catch (e) {
  if (e is DioException) {
    notificationService.handleDioError(e, customMessage: 'Erro ao salvar dados');
  } else {
    notificationService.handleGenericError(e);
  }
}

// 📋 Erros específicos
notificationService.handleValidationError('Email inválido');
notificationService.handleAuthError(customMessage: 'Sessão expirada');
notificationService.handlePermissionError(customMessage: 'Sem permissão');
notificationService.handleNotFoundError(resourceName: 'Usuário');
notificationService.handleConflictError(conflictType: 'email');
notificationService.handleServerError(customMessage: 'Servidor indisponível');
notificationService.handleNetworkError(customMessage: 'Sem conexão');
```

## 🎨 Tipos de Notificação

### **ServusSnackType.success** 🟢
- **Cor**: Verde
- **Ícone**: ✅
- **Uso**: Operações bem-sucedidas

### **ServusSnackType.warning** 🟡
- **Cor**: Amarelo/Laranja
- **Ícone**: ⚠️
- **Uso**: Avisos, validações, conflitos

### **ServusSnackType.error** 🔴
- **Cor**: Vermelho
- **Ícone**: ❌
- **Uso**: Erros críticos, falhas

### **ServusSnackType.info** 🔵
- **Cor**: Azul
- **Ícone**: ℹ️
- **Uso**: Informações gerais

## 📝 Exemplos Práticos

### **1. CRUD Operations**

```dart
class UserService {
  final ErrorNotificationService _notificationService = ErrorNotificationService();

  Future<void> createUser(User user) async {
    try {
      await api.createUser(user);
      _notificationService.showSuccess('Usuário criado com sucesso!');
    } catch (e) {
      if (e is DioException) {
        _notificationService.handleDioError(e, customMessage: 'Erro ao criar usuário');
      } else {
        _notificationService.handleGenericError(e);
      }
    }
  }

  Future<void> updateUser(User user) async {
    try {
      await api.updateUser(user);
      _notificationService.showSuccess('Usuário atualizado com sucesso!');
    } catch (e) {
      if (e is DioException) {
        _notificationService.handleDioError(e, customMessage: 'Erro ao atualizar usuário');
      } else {
        _notificationService.handleGenericError(e);
      }
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await api.deleteUser(id);
      _notificationService.showSuccess('Usuário removido com sucesso!');
    } catch (e) {
      if (e is DioException) {
        _notificationService.handleDioError(e, customMessage: 'Erro ao remover usuário');
      } else {
        _notificationService.handleGenericError(e);
      }
    }
  }
}
```

### **2. Validação de Formulários**

```dart
class FormController {
  final ErrorNotificationService _notificationService = ErrorNotificationService();

  void validateEmail(String email) {
    if (!email.contains('@')) {
      _notificationService.showWarning('Email inválido', title: 'Dados Inválidos');
      return;
    }
    // Continua validação...
  }

  void submitForm() async {
    try {
      await api.submitForm(formData);
      _notificationService.showSuccess('Formulário enviado com sucesso!');
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 422) {
        _notificationService.handleValidationError('Dados inválidos no formulário');
      } else {
        _notificationService.handleGenericError(e);
      }
    }
  }
}
```

### **3. Autenticação**

```dart
class AuthService {
  final ErrorNotificationService _notificationService = ErrorNotificationService();

  Future<void> login(String email, String password) async {
    try {
      await api.login(email, password);
      _notificationService.showSuccess('Login realizado com sucesso!');
    } catch (e) {
      if (e is DioException) {
        switch (e.response?.statusCode) {
          case 401:
            _notificationService.handleAuthError(customMessage: 'Email ou senha incorretos');
            break;
          case 403:
            _notificationService.handlePermissionError(customMessage: 'Conta bloqueada');
            break;
          default:
            _notificationService.handleDioError(e, customMessage: 'Erro ao fazer login');
        }
      } else {
        _notificationService.handleGenericError(e);
      }
    }
  }
}
```

### **4. Upload de Arquivos**

```dart
class FileService {
  final ErrorNotificationService _notificationService = ErrorNotificationService();

  Future<void> uploadFile(File file) async {
    try {
      _notificationService.showInfo('Enviando arquivo...', title: 'Upload');
      await api.uploadFile(file);
      _notificationService.showSuccess('Arquivo enviado com sucesso!');
    } catch (e) {
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout) {
          _notificationService.handleNetworkError(customMessage: 'Timeout no upload');
        } else {
          _notificationService.handleDioError(e, customMessage: 'Erro ao enviar arquivo');
        }
      } else {
        _notificationService.handleGenericError(e);
      }
    }
  }
}
```

## 🔧 Configuração

### **Inicialização (main.dart)**

```dart
class ServusApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  ServusApp({super.key, required this.authState}) {
    // ✅ Inicializar o serviço com a chave do navigator
    ErrorNotificationService.initialize(navigatorKey);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ✅ Usar a mesma chave
      // ... resto da configuração
    );
  }
}
```

## 🎯 Benefícios

1. **Consistência**: Todas as notificações seguem o mesmo padrão visual
2. **Centralização**: Um único ponto para gerenciar notificações
3. **Simplicidade**: API simples e intuitiva
4. **Flexibilidade**: Suporte a diferentes tipos de notificação
5. **Manutenibilidade**: Fácil de manter e atualizar
6. **UX**: Experiência uniforme para o usuário

## 🚨 Importante

- **NÃO** use `showServusSnack` diretamente nos serviços
- **SEMPRE** use `ErrorNotificationService` para notificações
- **MANTENHA** a consistência visual em todo o app
- **TESTE** diferentes cenários de erro para garantir boa UX
