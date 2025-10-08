import 'package:flutter_test/flutter_test.dart';
import 'package:servus_app/core/models/recurrence_pattern.dart';
import 'package:servus_app/services/recurrence_service.dart';

void main() {
  group('RecurrenceService Tests', () {
    test('Gera datas semanais corretamente', () {
      final startDate = DateTime(2024, 1, 1); // Segunda-feira
      final pattern = RecurrencePattern(
        type: RecurrenceType.weekly,
        dayOfWeek: 1, // Segunda-feira
      );
      
      final dates = RecurrenceService.generateDateSeries(startDate, pattern, maxDates: 4);
      
      expect(dates.length, 4);
      expect(dates[0], DateTime(2024, 1, 1));
      expect(dates[1], DateTime(2024, 1, 8));
      expect(dates[2], DateTime(2024, 1, 15));
      expect(dates[3], DateTime(2024, 1, 22));
    });

    test('Gera datas quinzenais corretamente', () {
      final startDate = DateTime(2024, 1, 1);
      final pattern = RecurrencePattern(type: RecurrenceType.biweekly);
      
      final dates = RecurrenceService.generateDateSeries(startDate, pattern, maxDates: 3);
      
      expect(dates.length, 3);
      expect(dates[0], DateTime(2024, 1, 1));
      expect(dates[1], DateTime(2024, 1, 15));
      expect(dates[2], DateTime(2024, 1, 29));
    });

    test('Gera datas mensais corretamente', () {
      final startDate = DateTime(2024, 1, 15);
      final pattern = RecurrencePattern(
        type: RecurrenceType.monthly,
        dayOfMonth: 15,
      );
      
      final dates = RecurrenceService.generateDateSeries(startDate, pattern, maxDates: 3);
      
      expect(dates.length, 3);
      expect(dates[0], DateTime(2024, 1, 15));
      expect(dates[1], DateTime(2024, 2, 15));
      expect(dates[2], DateTime(2024, 3, 15));
    });

    test('Valida padrões corretamente', () {
      // Padrão válido
      final validPattern = RecurrencePattern(
        type: RecurrenceType.weekly,
        dayOfWeek: 1,
      );
      expect(RecurrenceService.validatePattern(validPattern), isNull);
      
      // Padrão inválido - falta dia da semana
      final invalidPattern = RecurrencePattern(
        type: RecurrenceType.weekly,
      );
      expect(RecurrenceService.validatePattern(invalidPattern), isNotNull);
    });

    test('Gera preview corretamente', () {
      final startDate = DateTime(2024, 1, 1);
      final pattern = RecurrencePattern(type: RecurrenceType.weekly);
      
      final preview = RecurrenceService.generatePreview(startDate, pattern, previewCount: 3);
      
      expect(preview.length, 3);
      expect(preview[0], DateTime(2024, 1, 1));
      expect(preview[1], DateTime(2024, 1, 8));
      expect(preview[2], DateTime(2024, 1, 15));
    });

    test('Respeita limite de ocorrências', () {
      final startDate = DateTime(2024, 1, 1);
      final pattern = RecurrencePattern(
        type: RecurrenceType.weekly,
        maxOccurrences: 2,
      );
      
      final dates = RecurrenceService.generateDateSeries(startDate, pattern, maxDates: 10);
      
      expect(dates.length, 2);
    });

    test('Respeita data limite', () {
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 20);
      final pattern = RecurrencePattern(type: RecurrenceType.weekly);
      
      final dates = RecurrenceService.generateDateSeries(
        startDate, 
        pattern, 
        maxDates: 10,
        endDate: endDate,
      );
      
      // Deve gerar apenas 3 datas: 1/1, 8/1, 15/1 (22/1 já passa do limite)
      expect(dates.length, 3);
      expect(dates.last.isBefore(endDate) || dates.last.isAtSameMomentAs(endDate), isTrue);
    });
  });
}
