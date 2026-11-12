import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilogy_app/app/router.dart';
import 'package:pilogy_app/core/config/app_orientation.dart';
import 'package:pilogy_app/core/network/api_failure.dart';
import 'package:pilogy_app/core/design_system/app_theme.dart';
import 'package:pilogy_app/features/discover/presentation/discover_cards.dart';
import 'package:pilogy_app/features/discover/presentation/discover_quotes.dart';
import 'package:pilogy_app/features/numerology/data/backend_repositories.dart';
import 'package:pilogy_app/features/numerology/domain/api_models.dart';
import 'package:pilogy_app/features/numerology/presentation/backend_providers.dart';
import 'package:pilogy_app/features/profiles/data/local_profile_repository.dart';
import 'package:pilogy_app/features/profiles/domain/profile_repository.dart';
import 'package:pilogy_app/features/profiles/domain/user_profile.dart';
import 'package:pilogy_app/features/profiles/presentation/profiles_view_model.dart';
import 'backend_test_support.dart';

UserProfile _profile(String id, String name) => UserProfile(
  id: id,
  fullName: name,
  birthDate: '1990-05-20',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

class _Profiles extends Fake implements ProfileRepository {
  _Profiles(this.profiles)
    : selected = profiles.isEmpty ? null : profiles.first;
  final List<UserProfile> profiles;
  UserProfile? selected;
  @override
  Future<ProfileSnapshot> getSnapshot() async =>
      ProfileSnapshot(profiles, selected);
  @override
  Future<void> selectProfile(String? id) async {
    selected = id == null ? null : profiles.firstWhere((p) => p.id == id);
  }
}

class _Calculations extends Fake implements NumerologyRepository {
  final streams = <String, StreamController<DataSnapshot<CalculationResult>>>{};
  final tokens = <String, CancelToken?>{};
  @override
  Stream<DataSnapshot<CalculationResult>> watch({
    required String profileId,
    required String referenceDate,
    String locale = 'vi',
    CancelToken? cancelToken,
  }) {
    tokens[profileId] = cancelToken;
    return (streams[profileId] ??= StreamController.broadcast()).stream;
  }
}

CalculationResult _result({String date = '2026-11-08', int lifePath = 8}) {
  final raw = object(fixture('calculation')['data']);
  raw['referenceDate'] = date;
  for (final value in object(raw['indices']).values) {
    if (object(value).containsKey('referenceDate'))
      object(value)['referenceDate'] = date;
  }
  object(object(raw['indices'])['lifePath'])['value'] = lifePath;
  object(object(raw['indices'])['lifePath'])['baseValue'] = lifePath;
  object(object(raw['interpretations'])['lifePath'])['value'] = lifePath;
  object(object(raw['interpretations'])['lifePath'])['baseValue'] = lifePath;
  return CalculationResult.fromJson(raw);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Profiles profiles;
  late _Calculations calculations;
  late ProviderContainer container;
  late GoRouter router;

  Future<void> setupHost(String location, {bool multiple = true}) async {
    profiles = _Profiles([
      _profile('a', 'Nguyễn Minh Anh'),
      if (multiple) _profile('b', 'Trần Hoàng Nam'),
    ]);
    calculations = _Calculations();
    container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(profiles),
        numerologyRepositoryProvider.overrideWithValue(calculations),
        selectedReferenceDateProvider.overrideWith((ref) => '2026-11-08'),
      ],
    );
    // Hold the real profile view model through test startup, without SQLite/platform plugins.
    final subscription = container.listen(
      profilesViewModelProvider,
      (_, __) {},
    );
    await container.read(profilesViewModelProvider.future);
    router = createRouter(initialLocation: location);
    addTearDown(() async {
      subscription.close();
      router.dispose();
      container.dispose();
      for (final stream in calculations.streams.values) {
        await stream.close();
      }
    });
  }

  Widget host({
    double textScale = 1,
    EdgeInsets safePadding = EdgeInsets.zero,
    double keyboard = 0,
  }) => UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      theme: AppTheme.light(useGoogleFonts: false),
      routerConfig: router,
      builder:
          (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: textScale,
              padding:
                  keyboard > 0 ? safePadding.copyWith(bottom: 0) : safePadding,
              viewPadding: safePadding,
              viewInsets: EdgeInsets.only(bottom: keyboard),
            ),
            child: child!,
          ),
    ),
  );

  Future<void> emit(
    WidgetTester tester,
    DataSnapshot<CalculationResult> snapshot, {
    String id = 'a',
  }) async {
    calculations.streams[id]!.add(snapshot);
    await tester.pump();
    await tester.pump();
  }

  test('startup requests portrait-up only', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await configurePortraitOrientation();
    expect(calls.single.method, 'SystemChrome.setPreferredOrientations');
    expect(calls.single.arguments, ['DeviceOrientation.portraitUp']);
  });

  test(
    'curated reflections and presentation name formatting are stable inputs',
    () {
      expect(discoverQuotes.length, inInclusiveRange(15, 20));
      expect(discoverQuotes.toSet().length, discoverQuotes.length);
      expect(discoverGreetingName('Nguyễn Minh Anh'), 'Minh Anh');
      expect(discoverGreetingName('  An  '), 'An');
    },
  );

  for (final width in [360.0, 390.0, 430.0]) {
    testWidgets(
      'V01 fixed actions remain visible while scrolling at ${width.toInt()}dp',
      (tester) async {
        await setupHost('/welcome');
        await tester.binding.setSurfaceSize(Size(width, 580));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          host(safePadding: const EdgeInsets.only(top: 24, bottom: 24)),
        );
        await tester.pumpAndSettle();
        final actions = find.byKey(const ValueKey('welcome-actions'));
        final start = find.byKey(const ValueKey('welcome-start'));
        final restore = find.byKey(const ValueKey('welcome-restore'));
        final before = tester.getRect(actions);
        expect(tester.getRect(start).bottom, lessThanOrEqualTo(580));
        expect(tester.getRect(restore).bottom, lessThanOrEqualTo(580 - 24));
        expect(
          find.ancestor(of: actions, matching: find.byType(Scrollable)),
          findsNothing,
        );
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(tester.getRect(actions), before);
        expect(start.hitTestable(), findsOneWidget);
        expect(restore.hitTestable(), findsOneWidget);
        await tester.pumpWidget(
          host(
            safePadding: const EdgeInsets.only(top: 24, bottom: 24),
            keyboard: 180,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.getRect(restore).bottom, lessThanOrEqualTo(580 - 180));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets(
      'V03 core row, Master display and four-line description at ${width.toInt()}dp',
      (tester) async {
        await setupHost('/discover');
        await tester.binding.setSurfaceSize(Size(width, 820));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(host());
        await tester.pump();
        await emit(
          tester,
          DataSnapshot(data: _result(), freshness: DataFreshness.fresh),
        );
        expect(find.byKey(const ValueKey('result-profile')), findsNothing);
        expect(find.text('Xin Chào, Minh Anh'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('discover-updated-notice')),
          findsNothing,
        );
        final description = tester.widget<Text>(
          find.byKey(const ValueKey('life-path-description')),
        );
        expect(description.maxLines, 4);
        expect(description.overflow, TextOverflow.ellipsis);
        expect(
          find.descendant(
            of: find.byType(DiscoverLifePathCard),
            matching: find.byType(Chip),
          ),
          findsNothing,
        );
        final core = find.byKey(const ValueKey('discover-core-row'));
        await tester.ensureVisible(core);
        await tester.pumpAndSettle();
        final soul = tester.getRect(
          find.byKey(const ValueKey('detail-soulUrge')),
        );
        final personality = tester.getRect(
          find.byKey(const ValueKey('detail-personality')),
        );
        final expression = tester.getRect(
          find.byKey(const ValueKey('detail-expression')),
        );
        expect(soul.top, personality.top);
        expect(personality.top, expression.top);
        expect(soul.right, lessThan(personality.left));
        expect(personality.right, lessThan(expression.left));
        expect(find.text('11/2'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'refresh notice is transient and quote survives state/theme rebuilds',
    (tester) async {
      await setupHost('/discover');
      await tester.pumpWidget(host());
      await tester.pump();
      final result = _result();
      await emit(
        tester,
        DataSnapshot(data: result, freshness: DataFreshness.fresh),
      );
      final quote =
          tester
              .widget<Text>(find.byKey(const ValueKey('discover-quote')))
              .data;
      expect(
        find.byKey(const ValueKey('discover-updated-notice')),
        findsNothing,
      );
      final refresh =
          tester
              .widget<RefreshIndicator>(find.byType(RefreshIndicator))
              .onRefresh();
      await tester.pump();
      await emit(
        tester,
        DataSnapshot(
          data: result,
          freshness: DataFreshness.cached,
          refreshing: true,
        ),
      );
      expect(
        find.byKey(const ValueKey('discover-updated-notice')),
        findsNothing,
      );
      await emit(
        tester,
        DataSnapshot(data: result, freshness: DataFreshness.fresh),
      );
      await refresh;
      expect(
        find.byKey(const ValueKey('discover-updated-notice')),
        findsOneWidget,
      );
      await tester.pumpWidget(host(textScale: 1.1));
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('discover-quote'))).data,
        quote,
      );
      await tester.pump(const Duration(milliseconds: 3300));
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        find.byKey(const ValueKey('discover-updated-notice')),
        findsNothing,
      );
      await emit(
        tester,
        DataSnapshot(data: result, freshness: DataFreshness.fresh),
      );
      expect(
        find.byKey(const ValueKey('discover-updated-notice')),
        findsNothing,
      );
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('discover-quote'))).data,
        quote,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('multiple profiles switch without old results', (tester) async {
    await setupHost('/discover');
    await tester.pumpWidget(host());
    await tester.pump();
    await emit(
      tester,
      DataSnapshot(data: _result(), freshness: DataFreshness.fresh),
    );
    await tester.tap(find.byKey(const ValueKey('discover-profile-switcher')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('select-profile-b')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(profiles.selected!.id, 'b');
    expect(calculations.tokens['a']!.isCancelled, isTrue);
    expect(find.byKey(const ValueKey('number-lifePath')), findsNothing);
    await emit(
      tester,
      DataSnapshot(data: _result(lifePath: 9), freshness: DataFreshness.fresh),
      id: 'b',
    );
    expect(find.text('Xin Chào, Hoàng Nam'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('number-lifePath'))).data,
      '9',
    );
    calculations.streams['a']!.add(
      DataSnapshot(data: _result(), freshness: DataFreshness.fresh),
    );
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('number-lifePath'))).data,
      '9',
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('offline without cache retains greeting and session reflection', (
    tester,
  ) async {
    await setupHost('/discover');
    await tester.pumpWidget(host());
    await tester.pump();
    final quote =
        tester.widget<Text>(find.byKey(const ValueKey('discover-quote'))).data;
    await emit(
      tester,
      const DataSnapshot(
        freshness: DataFreshness.missing,
        error: ApiFailure(ApiFailureKind.connection),
      ),
    );
    expect(find.text('Xin Chào, Minh Anh'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('discover-quote'))).data,
      quote,
    );
    expect(find.byKey(const ValueKey('discover-data-state')), findsOneWidget);
    expect(find.byKey(const ValueKey('number-lifePath')), findsNothing);
    expect(find.byKey(const ValueKey('discover-updated-notice')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('single-profile header and effective reference year', (
    tester,
  ) async {
    await setupHost('/discover', multiple: false);
    await tester.pumpWidget(host());
    await tester.pump();
    await emit(
      tester,
      DataSnapshot(
        data: _result(date: '2027-01-01'),
        freshness: DataFreshness.fresh,
      ),
    );
    expect(
      find.byKey(const ValueKey('discover-profile-switcher')),
      findsNothing,
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('discover-cycle-year')))
          .data,
      'Năm 2027',
    );
    expect(find.text('Tháng 1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
