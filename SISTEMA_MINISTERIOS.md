# 🏛️ Sistema de Ministérios - Servus App

## 📋 **Visão Geral**

O sistema de ministérios permite gerenciar completamente os ministérios de uma igreja, incluindo criação, edição, listagem e controle de status. O sistema está integrado com o backend REST canônico e segue as melhores práticas de arquitetura Flutter.

## 🏗️ **Arquitetura**

### **1. Modelos (DTOs)**
- **`CreateMinistryDto`**: Para criação de novos ministérios
- **`UpdateMinistryDto`**: Para atualização de ministérios existentes
- **`ListMinistryDto`**: Para filtros e paginação
- **`MinistryResponse`**: Resposta do servidor com dados completos
- **`MinistryListResponse`**: Resposta paginada da listagem

### **2. Serviços**
- **`MinistryService`**: Gerencia todas as operações HTTP com o backend
- **Integração com TokenService**: Headers de contexto e autenticação
- **Tratamento de erros**: Mensagens amigáveis para o usuário

### **3. Controllers**
- **`MinistryController`**: Gerencia o estado da aplicação
- **Provider Pattern**: Notifica mudanças para a UI
- **Estados de loading**: Para melhor UX

### **4. Telas e Widgets**
- **`MinistryListScreen`**: Lista principal com filtros e paginação
- **`MinistryFormDialog`**: Formulário para criar/editar ministérios
- **`MinistryDetailsDialog`**: Visualização detalhada de um ministério

## 🚀 **Funcionalidades**

### **✅ Listagem de Ministérios**
- Paginação automática (20 itens por página)
- Pull-to-refresh para atualizar dados
- Scroll infinito para carregar mais itens
- Indicadores de loading e estados vazios

### **✅ Filtros e Busca**
- Busca por nome do ministério
- Filtro por status (ativo/inativo)
- Contadores de resultados
- Limpeza fácil dos filtros

### **✅ Criação de Ministérios**
- Formulário completo com validação
- Nome obrigatório (mínimo 3 caracteres)
- Descrição opcional (máximo 200 caracteres)
- Funções do ministério (adicionar/remover dinamicamente)
- Status ativo/inativo

### **✅ Edição de Ministérios**
- Edição inline de todos os campos
- Preserva dados existentes
- Validação em tempo real
- Feedback visual das mudanças

### **✅ Gerenciamento de Status**
- Ativar/desativar ministérios
- Indicadores visuais de status
- Confirmação antes de alterações
- Feedback imediato na UI

### **✅ Exclusão de Ministérios**
- Confirmação antes de excluir
- Remoção da lista local
- Feedback de sucesso/erro
- Tratamento de erros do backend

## 🔧 **Como Usar**

### **1. Configuração Inicial**

```dart
// Adicione o provider no seu app
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => MinistryController()),
    // outros providers...
  ],
  child: MyApp(),
)
```

### **2. Navegação para a Tela**

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const MinistryListScreen(),
  ),
);
```

### **3. Uso do Controller**

```dart
// Em um widget
Consumer<MinistryController>(
  builder: (context, controller, child) {
    return Text('Total: ${controller.totalItems}');
  },
)

// Ou usando context.read
final controller = context.read<MinistryController>();
await controller.loadMinistries(refresh: true);
```

## 📱 **Interface do Usuário**

### **🎨 Design System**
- **Cores**: Segue o tema da aplicação
- **Ícones**: Material Design Icons
- **Tipografia**: Hierarquia clara de textos
- **Espaçamento**: Consistente (8px, 16px, 24px)

### **📱 Responsividade**
- **Cards**: Adaptáveis a diferentes tamanhos de tela
- **Diálogos**: Scroll automático para conteúdo longo
- **Formulários**: Validação em tempo real
- **Estados**: Loading, erro, vazio, sucesso

### **♿ Acessibilidade**
- **Labels**: Semânticos e descritivos
- **Contraste**: Segue diretrizes de acessibilidade
- **Navegação**: Suporte a teclado e leitores de tela
- **Feedback**: Mensagens claras e úteis

## 🔐 **Segurança e Permissões**

### **🔑 Autenticação**
- **Tokens**: JWT com refresh automático
- **Headers**: Device ID e contexto de tenant/branch
- **Interceptors**: Renovação automática de tokens

### **👥 Controle de Acesso**
- **Contexto**: Tenant ID e Branch ID obrigatórios
- **Permissões**: Baseadas no role do usuário
- **Validação**: Backend valida permissões

### **🛡️ Validação**
- **Frontend**: Validação em tempo real
- **Backend**: Validação de dados e permissões
- **Sanitização**: Prevenção de XSS e injeção

## 📊 **Integração com Backend**

### **🌐 Rotas REST Canônicas**
```
GET    /tenants/:tenantId/branches/:branchId/ministries
POST   /tenants/:tenantId/branches/:branchId/ministries
GET    /tenants/:tenantId/branches/:branchId/ministries/:id
PATCH  /tenants/:tenantId/branches/:branchId/ministries/:id
DELETE /tenants/:tenantId/branches/:branchId/ministries/:id
```

### **📡 Headers HTTP**
```http
device-id: {uuid}
x-tenant-id: {tenantId}
x-branch-id: {branchId}
x-ministry-id: {ministryId} (opcional)
```

### **📋 Respostas Padrão**
- **Criação**: 201 Created + Location header
- **Listagem**: Paginada com metadata
- **Erros**: Códigos HTTP padrão + mensagens

## 🧪 **Testes e Qualidade**

### **✅ Cobertura de Testes**
- **Unit Tests**: Controllers e serviços
- **Widget Tests**: Telas e diálogos
- **Integration Tests**: Fluxos completos

### **🔍 Validação de Qualidade**
- **Linting**: Dart analyzer sem warnings
- **Formatting**: dart format aplicado
- **Documentation**: Comentários JSDoc
- **Error Handling**: Tratamento robusto de erros

## 🚀 **Próximos Passos**

### **📅 Roadmap**
1. **Eventos**: Integração com sistema de eventos
2. **Voluntários**: Gerenciamento de membros do ministério
3. **Escalas**: Sistema de escalas e horários
4. **Relatórios**: Estatísticas e métricas
5. **Notificações**: Alertas e lembretes

### **🔧 Melhorias Técnicas**
1. **Cache**: Implementar cache local
2. **Offline**: Suporte a modo offline
3. **Sync**: Sincronização em background
4. **Analytics**: Métricas de uso
5. **Performance**: Otimizações de renderização

## 📚 **Recursos Adicionais**

### **🔗 Links Úteis**
- [Flutter Documentation](https://flutter.dev/docs)
- [Provider Package](https://pub.dev/packages/provider)
- [Material Design](https://material.io/design)
- [REST API Guidelines](https://restfulapi.net/)

### **📖 Documentação Relacionada**
- [Sistema de Autenticação](./IMPLEMENTACAO_AUTENTICACAO_FLUTTER.md)
- [Backend REST Canônico](../IMPLEMENTACAO_PADRONIZACAO.md)
- [Arquitetura do App](./ARCHITECTURE.md)

---

## 🎯 **Resumo**

O sistema de ministérios está **100% implementado** e pronto para uso! Ele oferece:

- ✅ **Interface completa** para gerenciar ministérios
- ✅ **Integração total** com o backend REST canônico
- ✅ **UX moderna** com feedback visual e estados de loading
- ✅ **Arquitetura sólida** seguindo padrões Flutter
- ✅ **Segurança robusta** com autenticação e permissões

**Próximo passo recomendado**: Testar o sistema completo e implementar a integração com eventos e voluntários! 🚀 