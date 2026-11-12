import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilogy_app/features/numerology/domain/api_models.dart';
import 'package:pilogy_app/features/numerology/presentation/backend_providers.dart';

void main() {
  testWidgets('resume detects local month/year change without UTC conversion', (
    tester,
  ) async {
    var now = DateTime(2026, 12, 31, 23, 59);
    final container = ProviderContainer(
      overrides: [calendarClockProvider.overrideWithValue(() => now)],
    );
    final subscription = container.listen(
      currentReferenceDateProvider,
      (_, __) {},
    );
    await tester.pump();
    expect(
      container.read(currentReferenceDateProvider).valueOrNull,
      '2026-12-31',
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = DateTime(2027, 1, 1, 0, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(
      container.read(currentReferenceDateProvider).valueOrNull,
      '2027-01-01',
    );
    expect(localCalendarDate(now), '2027-01-01');
    now = DateTime(2027, 2, 1);
    await tester.pump(const Duration(seconds: 30));
    expect(
      container.read(currentReferenceDateProvider).valueOrNull,
      '2027-02-01',
    );
    subscription.close();
    container.dispose();
  });
}
