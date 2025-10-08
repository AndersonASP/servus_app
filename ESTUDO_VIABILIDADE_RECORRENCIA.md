# 📋 Estudo de Viabilidade: Recorrência de Bloqueios

## 🎯 Objetivo
Implementar funcionalidade de recorrência para bloqueios de indisponibilidade, permitindo que voluntários criem bloqueios que se repetem automaticamente em intervalos regulares.

## 📊 Análise da Situação Atual

### Estrutura Atual
- **Modelo de Dados**: `BloqueioIndisponibilidade` com campos simples (data, motivo, ministérios)
- **API**: Endpoints específicos para bloquear/desbloquear datas individuais
- **Backend**: Schema `VolunteerAvailability` com array de `blockedDates`
- **Frontend**: Interface simples para seleção de data única

### Limitações Identificadas
1. **Trabalho Manual**: Usuários precisam bloquear cada data individualmente
2. **Propensão a Erros**: Fácil esquecer de bloquear datas futuras
3. **UX Ineficiente**: Processo repetitivo para bloqueios regulares
4. **Sem Padrões**: Não há suporte para padrões de recorrência

## 🚀 Proposta de Solução

### 1. Tipos de Recorrência Propostos

#### A) Recorrência Semanal
- **Exemplo**: "Toda segunda-feira"
- **Casos de Uso**: Aulas, reuniões fixas, compromissos regulares
- **Implementação**: Campo `dayOfWeek` (0-6)

#### B) Recorrência Quinzenal
- **Exemplo**: "A cada 15 dias"
- **Casos de Uso**: Plantões médicos, turnos alternados
- **Implementação**: Campo `interval` + `startDate`

#### C) Recorrência Mensal
- **Exemplo**: "Todo dia 15 do mês"
- **Casos de Uso**: Pagamentos, compromissos mensais
- **Implementação**: Campo `dayOfMonth` (1-31)

#### D) Recorrência Personalizada
- **Exemplo**: "A cada 3 semanas"
- **Casos de Uso**: Necessidades específicas
- **Implementação**: Campo `customInterval` + `unit`

### 2. Estrutura de Dados Proposta

#### Frontend (Dart)
```dart
enum RecurrenceType {
  none,
  weekly,
  biweekly,
  monthly,
  custom,
}

class RecurrencePattern {
  final RecurrenceType type;
  final int? dayOfWeek; // 0-6 (domingo-sábado)
  final int? dayOfMonth; // 1-31
  final int? interval; // intervalo personalizado
  final String? unit; // 'weeks', 'months'
  final DateTime? endDate; // data limite opcional
  final int? maxOccurrences; // limite de ocorrências
}

class BloqueioIndisponibilidade {
  final DateTime data;
  final String motivo;
  final List<String> ministerios;
  final RecurrencePattern? recurrence; // NOVO
  final bool isRecurring; // NOVO
  final String? parentId; // NOVO - ID do bloqueio pai
}
```

#### Backend (TypeScript)
```typescript
enum RecurrenceType {
  NONE = 'none',
  WEEKLY = 'weekly',
  BIWEEKLY = 'biweekly',
  MONTHLY = 'monthly',
  CUSTOM = 'custom',
}

interface RecurrencePattern {
  type: RecurrenceType;
  dayOfWeek?: number; // 0-6
  dayOfMonth?: number; // 1-31
  interval?: number;
  unit?: 'weeks' | 'months';
  endDate?: Date;
  maxOccurrences?: number;
}

interface BlockedDate {
  date: Date;
  reason: string;
  isBlocked: boolean;
  createdAt: Date;
  recurrence?: RecurrencePattern; // NOVO
  parentId?: string; // NOVO
  isGenerated?: boolean; // NOVO - se foi gerado automaticamente
}
```

### 3. Fluxo de Implementação

#### Fase 1: Backend (2-3 semanas)
1. **Atualizar Schema**:
   - Adicionar campos de recorrência ao `VolunteerAvailability`
   - Criar índices para consultas eficientes

2. **Serviços**:
   - `RecurrenceService`: Gerar datas baseadas em padrões
   - `RecurrenceValidator`: Validar limites e conflitos
   - Atualizar `VolunteerAvailabilityService`

3. **APIs**:
   - `POST /scales/:tenantId/availability/block-recurring`
   - `PUT /scales/:tenantId/availability/recurrence/:id`
   - `DELETE /scales/:tenantId/availability/recurrence/:id`

#### Fase 2: Frontend (2-3 semanas)
1. **Modelos**:
   - Atualizar `BloqueioIndisponibilidade`
   - Criar `RecurrencePattern`

2. **UI/UX**:
   - Toggle "Bloqueio Recorrente" na tela de bloqueio
   - Seletor de tipo de recorrência
   - Configuração de parâmetros específicos
   - Preview das datas que serão bloqueadas

3. **Serviços**:
   - Atualizar `ScalesAdvancedService`
   - Implementar lógica de geração de datas

#### Fase 3: Integração e Testes (1-2 semanas)
1. **Testes**:
   - Casos de uso de cada tipo de recorrência
   - Validação de limites mensais
   - Performance com muitos bloqueios

2. **Otimizações**:
   - Cache de bloqueios gerados
   - Lazy loading de datas futuras

## 📈 Benefícios Esperados

### Para Usuários
- **Eficiência**: Redução de 80% no tempo para criar bloqueios regulares
- **Conveniência**: Interface intuitiva para padrões comuns
- **Precisão**: Menos erros por esquecimento

### Para o Sistema
- **Escalabilidade**: Suporte a padrões complexos
- **Flexibilidade**: Fácil adição de novos tipos de recorrência
- **Manutenibilidade**: Código bem estruturado e testável

## ⚠️ Riscos e Mitigações

### Riscos Técnicos
1. **Performance**: Muitos bloqueios gerados
   - **Mitigação**: Geração sob demanda, cache inteligente

2. **Complexidade**: Lógica de recorrência complexa
   - **Mitigação**: Implementação incremental, testes abrangentes

3. **Compatibilidade**: Dados existentes
   - **Mitigação**: Migração gradual, campos opcionais

### Riscos de Negócio
1. **Adoção**: Usuários podem não usar
   - **Mitigação**: UX intuitiva, documentação clara

2. **Limites**: Conflito com limites mensais
   - **Mitigação**: Validação inteligente, sugestões

## 💰 Estimativa de Esforço

### Desenvolvimento
- **Backend**: 3 semanas (1 dev sênior)
- **Frontend**: 3 semanas (1 dev sênior)
- **Testes**: 1 semana (1 QA)
- **Total**: 7 semanas

### Recursos Necessários
- 1 Desenvolvedor Backend (NestJS/TypeScript)
- 1 Desenvolvedor Frontend (Flutter/Dart)
- 1 QA/Tester
- 1 Designer UX (consultoria)

## 🎯 Próximos Passos

### Imediatos (Semana 1)
1. **Aprovação**: Validar proposta com stakeholders
2. **Design**: Criar mockups da interface
3. **Arquitetura**: Definir detalhes técnicos

### Curto Prazo (Semanas 2-4)
1. **Backend**: Implementar schema e serviços
2. **Frontend**: Criar modelos e UI básica
3. **Testes**: Implementar testes unitários

### Médio Prazo (Semanas 5-7)
1. **Integração**: Conectar frontend e backend
2. **Testes**: Testes de integração e E2E
3. **Deploy**: Implementação em produção

## 📋 Critérios de Sucesso

### Técnicos
- [ ] Todos os tipos de recorrência funcionando
- [ ] Performance < 2s para gerar 12 meses de bloqueios
- [ ] Zero bugs críticos em produção

### Negócio
- [ ] 70% dos usuários ativos usando recorrência
- [ ] Redução de 50% no tempo de criação de bloqueios
- [ ] Feedback positivo > 4.0/5.0

## 🔄 Alternativas Consideradas

### 1. Bloqueios em Lote
- **Prós**: Implementação simples
- **Contras**: Não resolve o problema de recorrência

### 2. Templates de Bloqueios
- **Prós**: Flexibilidade
- **Contras**: Complexidade de uso

### 3. Integração com Calendário Externo
- **Prós**: Sincronização automática
- **Contras**: Dependência externa, complexidade

## 📊 Conclusão

A implementação de recorrência de bloqueios é **VIÁVEL** e **RECOMENDADA** pelos seguintes motivos:

1. **Alto Impacto**: Resolve problema real dos usuários
2. **Tecnicamente Viável**: Arquitetura atual suporta a extensão
3. **ROI Positivo**: Benefícios superam custos de desenvolvimento
4. **Escalável**: Base sólida para futuras funcionalidades

**Recomendação**: Prosseguir com a implementação seguindo o cronograma proposto.

## 🏗️ Arquitetura Proposta

```
┌─────────────────────────────────────────────────────────────────┐
│                        FRONTEND (Flutter)                       │
├─────────────────────────────────────────────────────────────────┤
│  BloqueioScreen                                                 │
│  ├── Toggle "Bloqueio Recorrente"                              │
│  ├── RecurrenceTypeSelector                                     │
│  ├── RecurrenceConfigWidget                                     │
│  └── DatePreviewWidget                                          │
│                                                                 │
│  IndisponibilidadeController                                    │
│  ├── registrarBloqueioRecorrente()                              │
│  ├── gerarDatasRecorrentes()                                    │
│  └── validarLimitesRecorrencia()                                │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                        API LAYER                                │
├─────────────────────────────────────────────────────────────────┤
│  ScalesAdvancedService                                           │
│  ├── blockRecurringDate()                                       │
│  ├── updateRecurrencePattern()                                  │
│  └── deleteRecurrencePattern()                                  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                        BACKEND (NestJS)                         │
├─────────────────────────────────────────────────────────────────┤
│  ScalesAdvancedController                                       │
│  ├── POST /availability/block-recurring                        │
│  ├── PUT /availability/recurrence/:id                           │
│  └── DELETE /availability/recurrence/:id                        │
│                                                                 │
│  VolunteerAvailabilityService                                   │
│  ├── blockRecurringDate()                                       │
│  ├── generateRecurringDates()                                   │
│  └── validateRecurrenceLimits()                                 │
│                                                                 │
│  RecurrenceService (NOVO)                                       │
│  ├── calculateNextOccurrence()                                  │
│  ├── generateDateSeries()                                        │
│  └── validateRecurrencePattern()                               │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                        DATABASE (MongoDB)                       │
├─────────────────────────────────────────────────────────────────┤
│  VolunteerAvailability Collection                               │
│  ├── blockedDates[]                                             │
│  │   ├── date: Date                                             │
│  │   ├── reason: string                                          │
│  │   ├── recurrence?: RecurrencePattern                         │
│  │   ├── parentId?: string                                      │
│  │   └── isGenerated?: boolean                                  │
│  └── ...                                                        │
└─────────────────────────────────────────────────────────────────┘
```

## 🔄 Fluxo de Funcionamento

```
1. USUÁRIO seleciona data e marca "Bloqueio Recorrente"
   │
   ▼
2. SISTEMA exibe opções de recorrência (semanal, mensal, etc.)
   │
   ▼
3. USUÁRIO configura padrão de recorrência
   │
   ▼
4. SISTEMA gera preview das datas que serão bloqueadas
   │
   ▼
5. USUÁRIO confirma criação do bloqueio recorrente
   │
   ▼
6. BACKEND salva padrão de recorrência e gera datas iniciais
   │
   ▼
7. SISTEMA agenda geração automática de datas futuras
   │
   ▼
8. USUÁRIO pode editar/excluir recorrência a qualquer momento
```
