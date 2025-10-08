import 'package:flutter/material.dart';
import 'package:servus_app/core/models/recurrence_pattern.dart';
import 'package:servus_app/core/theme/context_extension.dart';
import 'package:servus_app/services/recurrence_service.dart';

/// Widget para configuração de recorrência de bloqueios
class RecurrenceConfigWidget extends StatefulWidget {
  final RecurrencePattern? initialPattern;
  final Function(RecurrencePattern?) onPatternChanged;
  final DateTime startDate;

  const RecurrenceConfigWidget({
    super.key,
    this.initialPattern,
    required this.onPatternChanged,
    required this.startDate,
  });

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
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _initializeFromPattern();
  }

  void _initializeFromPattern() {
    if (widget.initialPattern != null) {
      final pattern = widget.initialPattern!;
      _selectedType = pattern.type;
      _dayOfWeek = pattern.dayOfWeek;
      _dayOfMonth = pattern.dayOfMonth;
      _interval = pattern.interval;
      _unit = pattern.unit;
      _endDate = pattern.endDate;
      _maxOccurrences = pattern.maxOccurrences;
    } else {
      // Valores padrão para recorrência semanal
      _dayOfWeek = widget.startDate.weekday % 7; // Converter para formato 0-6
      // Para recorrência mensal, usar o dia da data inicial
      _dayOfMonth = widget.startDate.day;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Switch discreto para ativar recorrência com ícone
        Row(
          children: [
            Icon(
              Icons.repeat,
              color: _selectedType != RecurrenceType.none 
                ? context.colors.primary 
                : context.colors.onSurface.withValues(alpha: 0.6),
              size: 28,
              weight: 700,
            ),
            const SizedBox(width: 12),
            const Text(
              'Recorrência',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: _selectedType != RecurrenceType.none,
                onChanged: (value) {
                  setState(() {
                    _selectedType = value ? RecurrenceType.weekly : RecurrenceType.none;
                    _validationError = null;
                    _updatePattern();
                  });
                },
              ),
            ),
          ],
        ),

        if (_selectedType != RecurrenceType.none) ...[
          const SizedBox(height: 12),
          
          // Seletor de tipo de recorrência
          DropdownButtonFormField<RecurrenceType>(
            initialValue: _selectedType,
            dropdownColor: context.colors.surface,
            decoration: InputDecoration(
              labelText: 'Tipo de Recorrência',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: RecurrenceType.values
                .where((type) => type != RecurrenceType.none)
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(
                        _getTypeLabel(type),
                        style: TextStyle(color: context.colors.onSurface),
                      ),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
                _validationError = null;
                _updatePattern();
              });
            },
          ),

          const SizedBox(height: 12),

          // Configurações específicas por tipo
          ..._buildTypeSpecificConfigs(),

          // Erro de validação
          if (_validationError != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.colors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: context.colors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _validationError!,
                      style: TextStyle(
                        color: context.colors.error,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  List<Widget> _buildTypeSpecificConfigs() {
    switch (_selectedType) {
      case RecurrenceType.weekly:
        return [
          DropdownButtonFormField<int>(
            initialValue: _dayOfWeek,
            dropdownColor: context.colors.surface,
            decoration: InputDecoration(
              labelText: 'Dia da Semana',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: List.generate(7, (index) => DropdownMenuItem(
              value: index,
              child: Text(
                _getDayOfWeekLabel(index),
                style: TextStyle(color: context.colors.onSurface),
              ),
            )),
            onChanged: (value) {
              setState(() {
                _dayOfWeek = value;
                _validationError = null;
                _updatePattern();
              });
            },
          ),
        ];

      case RecurrenceType.monthly:
        return [
          // Para recorrência mensal inteligente, mostrar interpretação
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: context.colors.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: context.colors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getMonthlyInterpretation(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.colors.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ];

      case RecurrenceType.custom:
        return [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Intervalo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: _interval?.toString(),
                  onChanged: (value) {
                    setState(() {
                      _interval = int.tryParse(value);
                      _validationError = null;
                      _updatePattern();
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _unit,
                  dropdownColor: context.colors.onSurface,
                  decoration: InputDecoration(
                    labelText: 'Unidade',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: context.colors.onSurface.withValues(alpha: 0.05),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'weeks', 
                      child: Text(
                        'Semanas',
                        style: TextStyle(color: context.colors.primary),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'months', 
                      child: Text(
                        'Meses',
                        style: TextStyle(color: context.colors.primary),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _unit = value;
                      _validationError = null;
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
    final pattern = _createPattern();
    if (pattern != null) {
      final error = RecurrenceService.validatePattern(pattern);
      if (error != null) {
        setState(() {
          _validationError = error;
        });
        widget.onPatternChanged(null);
        return;
      }
    }
    
    setState(() {
      _validationError = null;
    });
    widget.onPatternChanged(pattern);
  }

  RecurrencePattern? _createPattern() {
    print('🔍 [RecurrenceConfigWidget] ===== CRIANDO PADRÃO =====');
    print('🔍 [RecurrenceConfigWidget] Tipo selecionado: $_selectedType');
    
    if (_selectedType == RecurrenceType.none) {
      print('🔍 [RecurrenceConfigWidget] Tipo NONE - retornando null');
      return null;
    }

    // Para recorrência mensal, usar lógica inteligente
    if (_selectedType == RecurrenceType.monthly) {
      final weekOfMonth = RecurrenceService.getWeekOfMonth(widget.startDate);
      print('🔍 [RecurrenceConfigWidget] MENSAL INTELIGENTE:');
      print('🔍 [RecurrenceConfigWidget] - Data inicial: ${widget.startDate.day}/${widget.startDate.month}/${widget.startDate.year}');
      print('🔍 [RecurrenceConfigWidget] - WeekOfMonth: $weekOfMonth');
      print('🔍 [RecurrenceConfigWidget] - DayOfWeek: ${widget.startDate.weekday}');
      
      final pattern = RecurrencePattern(
        type: _selectedType,
        dayOfWeek: widget.startDate.weekday,
        weekOfMonth: weekOfMonth,
        interval: _interval,
        unit: _unit,
        endDate: _endDate,
        maxOccurrences: _maxOccurrences,
      );
      
      print('🔍 [RecurrenceConfigWidget] Padrão criado: ${pattern.toString()}');
      return pattern;
    }

    print('🔍 [RecurrenceConfigWidget] Padrão tradicional criado');
    print('🔍 [RecurrenceConfigWidget] _dayOfMonth: $_dayOfMonth');
    print('🔍 [RecurrenceConfigWidget] widget.startDate.day: ${widget.startDate.day}');
    return RecurrencePattern(
      type: _selectedType,
      dayOfWeek: _dayOfWeek,
      dayOfMonth: _dayOfMonth,
      interval: _interval,
      unit: _unit,
      endDate: _endDate,
      maxOccurrences: _maxOccurrences,
    );
  }

  String _getMonthlyInterpretation() {
    final weekOfMonth = RecurrenceService.getWeekOfMonth(widget.startDate);
    final weekNames = ['primeira', 'segunda', 'terceira', 'quarta'];
    final weekName = weekNames[weekOfMonth - 1];
    final dayName = _getDayOfWeekLabel(widget.startDate.weekday % 7);
    
    return 'Repetir toda $weekName $dayName do mês';
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

