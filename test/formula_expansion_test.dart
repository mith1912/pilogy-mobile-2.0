import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilogy_app/features/number_detail/presentation/interpretation_article.dart';
import 'package:pilogy_app/features/numerology/domain/api_models.dart';
import 'backend_test_support.dart';

void main() {
  testWidgets('V05 formula opens, closes and survives article rebuilds', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var generation = 0;
    late StateSetter rebuild;
    final result = CalculationResult.fromJson(
      object(fixture('calculation')['data']),
    );
    final article = ArticleResult.fromJson(object(fixture('article')['data']));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: InterpretationArticle(
                  article: article.interpretation,
                  index: result.indices[IndexType.personality]!,
                  onRefresh: () => generation++,
                ),
              );
            },
          ),
        ),
      ),
    );
    // There should be only the page scroll view; article/formula content must
    // not mount internal EditableText scrollables or text-field focus state.
    expect(find.byType(EditableText), findsNothing);
    expect(find.byType(Scrollable), findsOneWidget);
    final tile = find.byKey(const ValueKey('steps-personality'));
    final expression = find.byKey(const ValueKey('step-expression-0'));
    for (var attempt = 0; attempt < 4; attempt++) {
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      // Exercise a rebuild during the expansion animation, not only at rest.
      await tester.pump(const Duration(milliseconds: 40));
      rebuild(() => generation++);
      await tester.pumpAndSettle();
      expect(expression, findsOneWidget);
      expect(tester.widget(expression), isA<Text>());
      expect(find.byType(EditableText), findsNothing);
      expect(find.byType(Scrollable), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(expression, findsNothing);
      expect(tester.takeException(), isNull);
    }
    expect(generation, 4);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
