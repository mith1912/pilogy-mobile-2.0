import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilogy_app/features/numerology/domain/api_models.dart';
import 'package:pilogy_app/features/numerology/presentation/calculation_explanation.dart';
import 'backend_test_support.dart';

void main() {
  test('ordinary and master values preserve backend values', () {
    for (var value = 1; value <= 9; value++) {
      expect(formatIndexValue(value, value), '$value');
    }
    expect(formatIndexValue(11, 2), '11/2');
    expect(formatIndexValue(22, 4), '22/4');
    expect(formatIndexValue(33, 6), '33/6');
  });
  testWidgets(
    'all nine returned step sequences render without deriving values',
    (tester) async {
      final result = CalculationResult.fromJson(
        object(fixture('calculation')['data']),
      );
      for (final type in IndexType.values) {
        final index = result.indices[type]!;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CalculationExplanation(index: index),
              ),
            ),
          ),
        );
        expect(
          find.byKey(const ValueKey('calculation-final-value')),
          findsOneWidget,
        );
        for (var i = 0; i < index.steps.length; i++) {
          final expression = tester.widget<Text>(
            find.byKey(ValueKey('step-expression-$i')),
          );
          expect(expression.data, calculationStepExpression(index.steps[i]));
          expect(calculationStepTitle(index.steps[i]), isNotEmpty);
        }
        expect(tester.takeException(), isNull);
      }
    },
  );
}
