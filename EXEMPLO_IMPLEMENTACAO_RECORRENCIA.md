# 💻 Exemplo de Implementação - Recorrência de Bloqueios

## 🎯 Demonstração Prática

Este arquivo contém exemplos de código para demonstrar como implementar a funcionalidade de recorrência de bloqueios.

## 📱 Frontend (Flutter/Dart)

### 1. Modelos de Dados

```dart
// lib/core/models/recurrence_pattern.dart
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

  const RecurrencePattern({
    required this.type,
    this.dayOfWeek,
    this.dayOfMonth,
    this.interval,
    this.unit,
    this.endDate,
    this.maxOccurrences,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'dayOfWeek': dayOfWeek,
    'dayOfMonth': dayOfMonth,
    'interval': interval,
    'unit': unit,
    'endDate': endDate?.toIso8601String(),
    'maxOccurrences': maxOccurrences,
  };

  factory RecurrencePattern.fromJson(Map<String, dynamic> json) => RecurrencePattern(
    type: RecurrenceType.values.firstWhere((e) => e.name == json['type']),
    dayOfWeek: json['dayOfWeek'],
    dayOfMonth: json['dayOfMonth'],
    interval: json['interval'],
    unit: json['unit'],
    endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    maxOccurrences: json['maxOccurrences'],
  );
}

// Atualização do modelo existente
class BloqueioIndisponibilidade {
  final DateTime data;
  final String motivo;
  final List<String> ministerios;
  final RecurrencePattern? recurrence; // NOVO
  final bool isRecurring; // NOVO
  final String? parentId; // NOVO - ID do bloqueio pai

  BloqueioIndisponibilidade({
    required this.data,
    required this.motivo,
    required this.ministerios,
    this.recurrence,
    this.isRecurring = false,
    this.parentId,
  });
}
```

### 2. Widget de Configuração de Recorrência

```dart
// lib/features/volunteers/indisponibilidade/widgets/recurrence_config_widget.dart
class RecurrenceConfigWidget extends StatefulWidget {
  final RecurrencePattern? initialPattern;
  final Function(RecurrencePattern?) onPatternChanged;

  const RecurrenceConfigWidget({
    Key? key,
    this.initialPattern,
    required this.onPatternChanged,
  }) : super(key: key);

  @override
  State<RecurrenceConfigWidget> createState() => _RecurrenceConfigWidgetState();
}

class _RecurrenceConfigWidgetState extends State<RecurrenceConfigWidget> {
  RecurrenceType _selectedType = RecurrenceType.none;
  int? _dayOfWeek;
  int? _dayOfMonth;
  int? _interval;
  String? _unit;
  DateTime? _endDate;
  int? _maxOccurrences;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle para ativar recorrência
        SwitchListTile(
          title: const Text('Bloqueio Recorrente'),
          subtitle: const Text('Repetir este bloqueio automaticamente'),
          value: _selectedType != RecurrenceType.none,
          onChanged: (value) {
            setState(() {
              _selectedType = value ? RecurrenceType.weekly : RecurrenceType.none;
              _updatePattern();
            });
          },
        ),

        if (_selectedType != RecurrenceType.none) ...[
          const SizedBox(height: 16),
          
          // Seletor de tipo de recorrência
          DropdownButtonFormField<RecurrenceType>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Tipo de Recorrência',
              border: OutlineInputBorder(),
            ),
            items: RecurrenceType.values
                .where((type) => type != RecurrenceType.none)
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(_getTypeLabel(type)),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
                _updatePattern();
              });
            },
          ),

          const SizedBox(height: 16),

          // Configurações específicas por tipo
          ..._buildTypeSpecificConfigs(),
        ],
      ],
    );
  }

  List<Widget> _buildTypeSpecificConfigs() {
    switch (_selectedType) {
      case RecurrenceType.weekly:
        return [
          DropdownButtonFormField<int>(
            value: _dayOfWeek,
            decoration: const InputDecoration(
              labelText: 'Dia da Semana',
              border: OutlineInputBorder(),
            ),
            items: List.generate(7, (index) => DropdownMenuItem(
              value: index,
              child: Text(_getDayOfWeekLabel(index)),
            )),
            onChanged: (value) {
              setState(() {
                _dayOfWeek = value;
                _updatePattern();
              });
            },
          ),
        ];

      case RecurrenceType.monthly:
        return [
          DropdownButtonFormField<int>(
            value: _dayOfMonth,
            decoration: const InputDecoration(
              labelText: 'Dia do Mês',
              border: OutlineInputBorder(),
            ),
            items: List.generate(31, (index) => DropdownMenuItem(
              value: index + 1,
              child: Text('Dia ${index + 1}'),
            )),
            onChanged: (value) {
              setState(() {
                _dayOfMonth = value;
                _updatePattern();
              });
            },
          ),
        ];

      case RecurrenceType.custom:
        return [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Intervalo',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _interval = int.tryParse(value);
                      _updatePattern();
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _unit,
                  decoration: const InputDecoration(
                    labelText: 'Unidade',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'weeks', child: Text('Semanas')),
                    DropdownMenuItem(value: 'months', child: Text('Meses')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _unit = value;
                      _updatePattern();
                    });
                  },
                ),
              ),
            ],
          ),
        ];

      default:
        return [];
    }
  }

  void _updatePattern() {
    if (_selectedType == RecurrenceType.none) {
      widget.onPatternChanged(null);
      return;
    }

    final pattern = RecurrencePattern(
      type: _selectedType,
      dayOfWeek: _dayOfWeek,
      dayOfMonth: _dayOfMonth,
      interval: _interval,
      unit: _unit,
      endDate: _endDate,
      maxOccurrences: _maxOccurrences,
    );

    widget.onPatternChanged(pattern);
  }

  String _getTypeLabel(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.weekly:
        return 'Semanal';
      case RecurrenceType.biweekly:
        return 'Quinzenal';
      case RecurrenceType.monthly:
        return 'Mensal';
      case RecurrenceType.custom:
        return 'Personalizado';
      default:
        return 'Nenhum';
    }
  }

  String _getDayOfWeekLabel(int day) {
    const days = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
    return days[day];
  }
}
```

### 3. Widget de Preview de Datas

```dart
// lib/features/volunteers/indisponibilidade/widgets/date_preview_widget.dart
class DatePreviewWidget extends StatelessWidget {
  final DateTime startDate;
  final RecurrencePattern pattern;
  final int previewCount;

  const DatePreviewWidget({
    Key? key,
    required this.startDate,
    required this.pattern,
    this.previewCount = 6,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dates = _generatePreviewDates();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview das Datas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'As seguintes datas serão bloqueadas:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ...dates.map((date) => ListTile(
              leading: const Icon(Icons.calendar_today, size: 20),
              title: Text(_formatDate(date)),
              subtitle: Text(_getDayOfWeek(date)),
              dense: true,
            )),
            if (dates.length == previewCount)
              Text(
                '... e mais datas seguindo o padrão',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<DateTime> _generatePreviewDates() {
    final dates = <DateTime>[];
    DateTime currentDate = startDate;
    
    for (int i = 0; i < previewCount; i++) {
      dates.add(currentDate);
      currentDate = _getNextOccurrence(currentDate);
    }
    
    return dates;
  }

  DateTime _getNextOccurrence(DateTime currentDate) {
    switch (pattern.type) {
      case RecurrenceType.weekly:
        return currentDate.add(const Duration(days: 7));
      case RecurrenceType.biweekly:
        return currentDate.add(const Duration(days: 14));
      case RecurrenceType.monthly:
        return DateTime(
          currentDate.year + (currentDate.month == 12 ? 1 : 0),
          currentDate.month == 12 ? 1 : currentDate.month + 1,
          currentDate.day,
        );
      case RecurrenceType.custom:
        if (pattern.unit == 'weeks') {
          return currentDate.add(Duration(days: 7 * (pattern.interval ?? 1)));
        } else if (pattern.unit == 'months') {
          return DateTime(
            currentDate.year + (currentDate.month + (pattern.interval ?? 1) - 1) ~/ 12,
            ((currentDate.month - 1 + (pattern.interval ?? 1)) % 12) + 1,
            currentDate.day,
          );
        }
        return currentDate;
      default:
        return currentDate;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getDayOfWeek(DateTime date) {
    const days = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    return days[date.weekday % 7];
  }
}
```

## 🔧 Backend (NestJS/TypeScript)

### 1. DTOs para Recorrência

```typescript
// src/modules/scales/dto/recurrence.dto.ts
export enum RecurrenceType {
  NONE = 'none',
  WEEKLY = 'weekly',
  BIWEEKLY = 'biweekly',
  MONTHLY = 'monthly',
  CUSTOM = 'custom',
}

export class RecurrencePatternDto {
  @IsEnum(RecurrenceType)
  type: RecurrenceType;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(6)
  dayOfWeek?: number; // 0-6 (domingo-sábado)

  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(31)
  dayOfMonth?: number; // 1-31

  @IsOptional()
  @IsNumber()
  @Min(1)
  interval?: number;

  @IsOptional()
  @IsString()
  @IsIn(['weeks', 'months'])
  unit?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;

  @IsOptional()
  @IsNumber()
  @Min(1)
  maxOccurrences?: number;
}

export class BlockRecurringDateDto {
  @IsString()
  userId: string;

  @IsString()
  ministryId: string;

  @IsDateString()
  startDate: string;

  @IsString()
  reason: string;

  @ValidateNested()
  @Type(() => RecurrencePatternDto)
  recurrence: RecurrencePatternDto;
}
```

### 2. Serviço de Recorrência

```typescript
// src/modules/scales/services/recurrence.service.ts
import { Injectable } from '@nestjs/common';
import { RecurrencePatternDto, RecurrenceType } from '../dto/recurrence.dto';

@Injectable()
export class RecurrenceService {
  /**
   * Gera uma série de datas baseada no padrão de recorrência
   */
  generateDateSeries(
    startDate: Date,
    pattern: RecurrencePatternDto,
    maxDates: number = 12,
  ): Date[] {
    const dates: Date[] = [];
    let currentDate = new Date(startDate);

    for (let i = 0; i < maxDates; i++) {
      dates.push(new Date(currentDate));
      currentDate = this.getNextOccurrence(currentDate, pattern);
    }

    return dates;
  }

  /**
   * Calcula a próxima ocorrência baseada no padrão
   */
  getNextOccurrence(currentDate: Date, pattern: RecurrencePatternDto): Date {
    const nextDate = new Date(currentDate);

    switch (pattern.type) {
      case RecurrenceType.WEEKLY:
        nextDate.setDate(nextDate.getDate() + 7);
        break;

      case RecurrenceType.BIWEEKLY:
        nextDate.setDate(nextDate.getDate() + 14);
        break;

      case RecurrenceType.MONTHLY:
        nextDate.setMonth(nextDate.getMonth() + 1);
        break;

      case RecurrenceType.CUSTOM:
        if (pattern.unit === 'weeks') {
          nextDate.setDate(nextDate.getDate() + (7 * (pattern.interval || 1)));
        } else if (pattern.unit === 'months') {
          nextDate.setMonth(nextDate.getMonth() + (pattern.interval || 1));
        }
        break;

      default:
        break;
    }

    return nextDate;
  }

  /**
   * Valida se o padrão de recorrência é válido
   */
  validatePattern(pattern: RecurrencePatternDto): { isValid: boolean; error?: string } {
    switch (pattern.type) {
      case RecurrenceType.WEEKLY:
        if (pattern.dayOfWeek === undefined) {
          return { isValid: false, error: 'Dia da semana é obrigatório para recorrência semanal' };
        }
        break;

      case RecurrenceType.MONTHLY:
        if (pattern.dayOfMonth === undefined) {
          return { isValid: false, error: 'Dia do mês é obrigatório para recorrência mensal' };
        }
        break;

      case RecurrenceType.CUSTOM:
        if (!pattern.interval || !pattern.unit) {
          return { isValid: false, error: 'Intervalo e unidade são obrigatórios para recorrência personalizada' };
        }
        break;
    }

    return { isValid: true };
  }

  /**
   * Verifica se uma data específica corresponde ao padrão
   */
  matchesPattern(date: Date, pattern: RecurrencePatternDto, startDate: Date): boolean {
    switch (pattern.type) {
      case RecurrenceType.WEEKLY:
        return date.getDay() === pattern.dayOfWeek;

      case RecurrenceType.MONTHLY:
        return date.getDate() === pattern.dayOfMonth;

      case RecurrenceType.BIWEEKLY:
        const daysDiff = Math.floor((date.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24));
        return daysDiff % 14 === 0;

      case RecurrenceType.CUSTOM:
        // Implementar lógica para recorrência personalizada
        return this.matchesCustomPattern(date, pattern, startDate);

      default:
        return false;
    }
  }

  private matchesCustomPattern(date: Date, pattern: RecurrencePatternDto, startDate: Date): boolean {
    if (pattern.unit === 'weeks') {
      const daysDiff = Math.floor((date.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24));
      return daysDiff % (7 * (pattern.interval || 1)) === 0;
    } else if (pattern.unit === 'months') {
      const monthsDiff = (date.getFullYear() - startDate.getFullYear()) * 12 + 
                        (date.getMonth() - startDate.getMonth());
      return monthsDiff % (pattern.interval || 1) === 0 && date.getDate() === startDate.getDate();
    }
    return false;
  }
}
```

### 3. Atualização do Controller

```typescript
// src/modules/scales/controllers/scales-advanced.controller.ts
@Post('availability/block-recurring')
@RequiresPerm([
  PERMS.MANAGE_ALL_TENANTS,
  PERMS.MANAGE_BRANCH_SCALES,
  PERMS.MANAGE_MINISTRY_SCALES,
  PERMS.VIEW_SCALES,
  PERMS.UPDATE_OWN_AVAILABILITY,
])
async blockRecurringDate(
  @Param('tenantId') tenantId: string,
  @Body() body: BlockRecurringDateDto,
  @Req() req: any,
  @Res() res: any,
) {
  const currentUserId = req.user?.sub;

  // Verificar permissões (mesmo código do blockDate existente)
  if (body.userId !== currentUserId) {
    const hasAdminPerms = req.user?.permissions?.some((perm: string) =>
      [PERMS.MANAGE_ALL_TENANTS, PERMS.MANAGE_BRANCH_SCALES, PERMS.MANAGE_MINISTRY_SCALES].includes(perm as any),
    );

    if (!hasAdminPerms) {
      return res.status(HttpStatus.FORBIDDEN).json({
        success: false,
        message: 'Você só pode bloquear suas próprias datas',
        error: 'Forbidden',
        statusCode: 403,
      });
    }
  }

  try {
    const result = await this.volunteerAvailabilityService.blockRecurringDate(
      tenantId,
      body.userId,
      body.ministryId,
      new Date(body.startDate),
      body.reason,
      body.recurrence,
    );

    return res.status(HttpStatus.CREATED).json({
      success: true,
      data: result,
      message: 'Bloqueio recorrente criado com sucesso',
    });
  } catch (error) {
    console.error('Erro ao criar bloqueio recorrente:', error);
    return res.status(HttpStatus.BAD_REQUEST).json({
      success: false,
      message: error.message || 'Erro ao criar bloqueio recorrente',
      error: error.name || 'BadRequest',
      statusCode: HttpStatus.BAD_REQUEST,
    });
  }
}
```

## 🧪 Exemplo de Uso

### Frontend
```dart
// Exemplo de uso no BloqueioScreen
class BloqueioScreen extends StatefulWidget {
  // ... código existente
}

class _BloqueioScreenState extends State<BloqueioScreen> {
  RecurrencePattern? _recurrencePattern;
  bool _showPreview = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Bloqueio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ... campos existentes (data, motivo, ministérios)
            
            // Widget de configuração de recorrência
            RecurrenceConfigWidget(
              initialPattern: _recurrencePattern,
              onPatternChanged: (pattern) {
                setState(() {
                  _recurrencePattern = pattern;
                  _showPreview = pattern != null;
                });
              },
            ),

            // Preview das datas
            if (_showPreview && _recurrencePattern != null)
              DatePreviewWidget(
                startDate: widget.selectedDate,
                pattern: _recurrencePattern!,
              ),

            const SizedBox(height: 24),

            // Botão de confirmação
            ElevatedButton(
              onPressed: _confirmarBloqueio,
              child: Text(_recurrencePattern != null 
                ? 'Criar Bloqueio Recorrente' 
                : 'Criar Bloqueio'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarBloqueio() async {
    if (_recurrencePattern != null) {
      // Chamar método para bloqueio recorrente
      await controller.registrarBloqueioRecorrente(
        dia: widget.selectedDate,
        motivo: _motivoController.text,
        ministerios: _ministeriosSelecionados,
        recurrence: _recurrencePattern!,
        tenantId: usuario.tenantId ?? '',
        userId: usuario.email,
      );
    } else {
      // Chamar método existente para bloqueio único
      await controller.registrarBloqueio(
        dia: widget.selectedDate,
        motivo: _motivoController.text,
        ministerios: _ministeriosSelecionados,
        tenantId: usuario.tenantId ?? '',
        userId: usuario.email,
      );
    }
  }
}
```

## 📊 Benefícios da Implementação

1. **Flexibilidade**: Suporte a múltiplos tipos de recorrência
2. **Usabilidade**: Interface intuitiva com preview das datas
3. **Escalabilidade**: Arquitetura extensível para novos tipos
4. **Manutenibilidade**: Código bem estruturado e testável
5. **Performance**: Geração eficiente de datas futuras

## 🔄 Próximos Passos

1. **Implementar modelos** de dados no frontend
2. **Criar widgets** de configuração e preview
3. **Atualizar controller** para suportar recorrência
4. **Implementar serviços** de recorrência no backend
5. **Testes** abrangentes de todos os cenários
6. **Deploy** e monitoramento em produção
