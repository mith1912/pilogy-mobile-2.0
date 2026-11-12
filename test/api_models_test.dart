import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilogy_app/core/network/api_failure.dart';
import 'package:pilogy_app/features/numerology/domain/api_models.dart';
import 'backend_test_support.dart';

void main() {
  test(
    'all nine indices, masters, versions, steps and Vietnamese are preserved',
    () {
      final raw = object(fixture('calculation')['data']);
      final result = CalculationResult.fromJson(raw);
      expect(result.indices.length, 9);
      expect(result.indices[IndexType.personality]!.value, 11);
      expect(result.indices[IndexType.personality]!.baseValue, 2);
      expect(result.referenceDate, '2026-11-08');
      expect(result.calculationVersion, 'v1');
      expect(result.contentVersion, 'v1.0.0-draft');
      expect(jsonEncode(result.json), jsonEncode(raw));
      for (final t in IndexType.values) {
        expect(result.indices[t]!.steps, isNotEmpty);
        expect(result.interpretations[t]!.value, result.indices[t]!.value);
      }
      expect(formatIndexValue(11, 2), '11/2');
      expect(formatIndexValue(22, 4), '22/4');
      expect(formatIndexValue(33, 6), '33/6');
      expect(formatIndexValue(8, 8), '8');
    },
  );
  test('full articles retain sections and optional fields', () {
    final article = ArticleResult.fromJson(object(fixture('article')['data']));
    expect(article.interpretation.value, 11);
    expect(article.interpretation.strengths, isNotEmpty);
    expect(article.interpretation.periodFocus, isNull);
  });
  test('rejects missing indices and mismatched summaries', () {
    final raw = object(fixture('calculation')['data']);
    object(raw['indices']).remove('lifePath');
    expect(() => CalculationResult.fromJson(raw), throwsA(isA<ApiFailure>()));
  });
  test(
    'date-only serialization retains explicitly selected calendar fields',
    () {
      expect(localCalendarDate(DateTime(2026, 12, 1)), '2026-12-01');
      expect(calendarDate('2026-11-08'), '2026-11-08');
      expect(() => calendarDate('2026-02-30'), throwsA(isA<ApiFailure>()));
    },
  );
}
