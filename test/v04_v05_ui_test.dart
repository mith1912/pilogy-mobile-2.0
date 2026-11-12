import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilogy_app/app/router.dart';
import 'package:pilogy_app/core/design_system/app_theme.dart';
import 'package:pilogy_app/features/numerology/data/backend_repositories.dart';
import 'package:pilogy_app/features/numerology/domain/api_models.dart';
import 'package:pilogy_app/features/numerology/presentation/backend_providers.dart';
import 'package:pilogy_app/features/profiles/data/local_profile_repository.dart';
import 'package:pilogy_app/features/profiles/domain/profile_repository.dart';
import 'package:pilogy_app/features/profiles/domain/user_profile.dart';
import 'package:pilogy_app/features/profiles/presentation/profiles_view_model.dart';
import 'backend_test_support.dart';

class _Profiles extends Fake implements ProfileRepository {
  _Profiles({bool multiple = true})
    : profiles = [
        UserProfile(
          id: 'a',
          fullName: 'Nguyễn Minh Anh',
          birthDate: '1990-05-20',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        if (multiple)
          UserProfile(
            id: 'b',
            fullName: 'Trần Hoàng Nam',
            birthDate: '1990-05-20',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
      ];
  final List<UserProfile> profiles;
  String selected = 'a';
  @override
  Future<ProfileSnapshot> getSnapshot() async =>
      ProfileSnapshot(profiles, profiles.firstWhere((p) => p.id == selected));
  @override
  Future<void> selectProfile(String? id) async {
    selected = id!;
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

class _Articles extends Fake implements InterpretationRepository {
  final streams = <int, StreamController<DataSnapshot<ArticleResult>>>{};
  final tokens = <int, CancelToken?>{};
  @override
  Stream<DataSnapshot<ArticleResult>> watch({
    required IndexType type,
    required int value,
    String locale = 'vi',
    String? contentVersion,
    CancelToken? cancelToken,
  }) {
    tokens[value] = cancelToken;
    return (streams[value] ??= StreamController.broadcast()).stream;
  }
}

CalculationResult _calculation({int personality = 11}) {
  final raw = object(fixture('calculation')['data']);
  if (personality != 11) {
    for (final key in ['indices', 'interpretations']) {
      final item = object(object(raw[key])['personality']);
      item['value'] = personality;
      item['baseValue'] = personality;
    }
  }
  return CalculationResult.fromJson(raw);
}

ArticleResult _article({int value = 11}) {
  final raw = object(fixture('article')['data']);
  if (value != 11) {
    final article = object(raw['interpretation']);
    article['value'] = value;
    article['baseValue'] = value;
    article['title'] = 'Bài luận giải B';
  }
  return ArticleResult.fromJson(raw);
}

Future<void> _frames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump();
}

void main() {
  late _Profiles profiles;
  late _Calculations calculations;
  late _Articles articles;
  late ProviderContainer container;
  late GoRouter router;
  Future<void> setup(String path, {bool multiple = true}) async {
    profiles = _Profiles(multiple: multiple);
    calculations = _Calculations();
    articles = _Articles();
    container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(profiles),
        numerologyRepositoryProvider.overrideWithValue(calculations),
        interpretationRepositoryProvider.overrideWithValue(articles),
        selectedReferenceDateProvider.overrideWith((ref) => '2026-11-08'),
      ],
    );
    final subscription = container.listen(
      profilesViewModelProvider,
      (_, __) {},
    );
    await container.read(profilesViewModelProvider.future);
    router = createRouter(initialLocation: path);
    addTearDown(() async {
      subscription.close();
      router.dispose();
      container.dispose();
      for (final stream in calculations.streams.values) {
        await stream.close();
      }
      for (final stream in articles.streams.values) {
        await stream.close();
      }
    });
  }

  Widget host({double scale = 1}) => UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light(useGoogleFonts: false),
      builder:
          (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: scale),
            child: child!,
          ),
    ),
  );
  Future<void> emitCalculation(
    WidgetTester tester, {
    String id = 'a',
    int personality = 11,
    bool refreshing = false,
  }) async {
    calculations.streams[id]!.add(
      DataSnapshot(
        data: _calculation(personality: personality),
        freshness: refreshing ? DataFreshness.cached : DataFreshness.fresh,
        refreshing: refreshing,
      ),
    );
    await _frames(tester);
  }

  Future<void> emitArticle(
    WidgetTester tester, {
    int value = 11,
    bool refreshing = false,
  }) async {
    articles.streams[value]!.add(
      DataSnapshot(
        data: _article(value: value),
        freshness: refreshing ? DataFreshness.cached : DataFreshness.fresh,
        refreshing: refreshing,
      ),
    );
    await _frames(tester);
  }

  for (final width in [360.0, 390.0, 430.0]) {
    testWidgets(
      'V04 source groups, quick access and real values at ${width.toInt()}dp',
      (tester) async {
        await setup('/analysis');
        await tester.binding.setSurfaceSize(Size(width, 820));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(host());
        await _frames(tester);
        await emitCalculation(tester);
        expect(find.text('Bản Đồ Thần Số Học'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('analysis-profile-switcher')),
          findsOneWidget,
        );
        expect(find.text('Biểu Đồ Ngày Sinh'), findsOneWidget);
        expect(find.text('Chu Kỳ Cá Nhân'), findsOneWidget);
        expect(find.text('Nhóm Chỉ Số Cốt Lõi'), findsOneWidget);
        expect(find.text('Nhóm Chỉ Số Bổ Trợ'), findsOneWidget);
        expect(find.text('Chỉ Số Tiềm Thức & Tâm Linh'), findsOneWidget);
        expect(find.text('Chu Kỳ Rung Động Hiện Tại'), findsNothing);
        expect(find.textContaining('94%'), findsNothing);
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('number-personality')))
              .data,
          '11/2',
        );
        expect(
          tester.getTopLeft(find.text('Nhóm Chỉ Số Cốt Lõi')).dy,
          lessThan(tester.getTopLeft(find.text('Nhóm Chỉ Số Bổ Trợ')).dy),
        );
        expect(
          find.byKey(const ValueKey('analysis-updated-notice')),
          findsNothing,
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('analysis-cycles')),
        );
        await tester.tap(find.byKey(const ValueKey('analysis-cycles')));
        await _frames(tester);
        expect(find.text('Năm cá nhân 8'), findsOneWidget);
        expect(find.text('Tháng cá nhân 1'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets(
      'V05 own hero-first hierarchy, full article and step rendering at ${width.toInt()}dp',
      (tester) async {
        await setup('/number-detail?type=personality');
        await tester.binding.setSurfaceSize(Size(width, 820));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(host());
        await _frames(tester);
        await emitCalculation(tester);
        await emitArticle(tester);
        expect(
          find.byKey(const ValueKey('detail-profile-switcher')),
          findsOneWidget,
        );
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('article-number')))
              .data,
          '11/2',
        );
        final keys = [
          'detail-hero',
          'detail-formula',
          'detail-meaning',
          'detail-strengths',
          'detail-challenges',
          'detail-advice',
        ];
        for (var i = 1; i < keys.length; i++) {
          expect(
            tester.getTopLeft(find.byKey(ValueKey(keys[i - 1]))).dy,
            lessThan(tester.getTopLeft(find.byKey(ValueKey(keys[i]))).dy),
          );
        }
        final article = _article().interpretation;
        for (final paragraph in [
          article.summary,
          article.essence,
          article.relationships,
          article.careerAndGrowth,
          article.lifeLesson,
          article.reflection,
          article.affirmation,
          article.suggestedAction,
        ]) {
          final finder = find.widgetWithText(Text, paragraph);
          expect(finder, findsOneWidget);
          expect(tester.widget<Text>(finder).maxLines, isNull);
        }
        await tester.ensureVisible(
          find.byKey(const ValueKey('steps-personality')),
        );
        await tester.tap(find.byKey(const ValueKey('steps-personality')));
        await _frames(tester);
        expect(find.text('5 + 7 + 7 + 5 + 4 + 5 + 5 = 38'), findsOneWidget);
        expect(find.byKey(const ValueKey('tab-analysis')), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'V04 selection suppresses old cached/in-flight results and notice expires',
    (tester) async {
      await setup('/analysis');
      await tester.pumpWidget(host());
      await _frames(tester);
      await emitCalculation(tester);
      await emitCalculation(tester, refreshing: true);
      await emitCalculation(tester);
      expect(
        find.byKey(const ValueKey('analysis-updated-notice')),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 3300));
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        find.byKey(const ValueKey('analysis-updated-notice')),
        findsNothing,
      );
      await tester.pumpWidget(host(scale: 1.1));
      await _frames(tester);
      expect(
        find.byKey(const ValueKey('analysis-updated-notice')),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('analysis-profile-switcher')));
      await _frames(tester);
      await tester.tap(find.byKey(const ValueKey('select-profile-b')));
      await _frames(tester);
      expect(profiles.selected, 'b');
      expect(calculations.tokens['a']!.isCancelled, isTrue);
      expect(find.byKey(const ValueKey('number-personality')), findsNothing);
      await emitCalculation(tester, id: 'b', personality: 9);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('number-personality')))
            .data,
        '9',
      );
      await emitCalculation(tester);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('number-personality')))
            .data,
        '9',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'V05 derives a new article value after switching and rejects the old request',
    (tester) async {
      await setup('/number-detail?type=personality');
      await tester.pumpWidget(host());
      await _frames(tester);
      await emitCalculation(tester);
      await emitArticle(tester);
      await emitArticle(tester, refreshing: true);
      await emitArticle(tester);
      expect(
        find.byKey(const ValueKey('detail-updated-notice')),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 3300));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const ValueKey('detail-updated-notice')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('detail-profile-switcher')));
      await _frames(tester);
      await tester.tap(find.byKey(const ValueKey('select-profile-b')));
      await _frames(tester);
      expect(find.byKey(const ValueKey('article-number')), findsNothing);
      await emitCalculation(tester, id: 'b', personality: 9);
      await emitArticle(tester, value: 9);
      expect(articles.tokens[11]!.isCancelled, isTrue);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('article-number'))).data,
        '9',
      );
      await emitArticle(tester);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('article-number'))).data,
        '9',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('detail-profile-context')))
            .data,
        contains('Trần Hoàng Nam'),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'single-profile selectors hide without leaving unusable controls',
    (tester) async {
      await setup('/analysis', multiple: false);
      await tester.pumpWidget(host());
      await _frames(tester);
      await emitCalculation(tester);
      expect(
        find.byKey(const ValueKey('analysis-profile-switcher')),
        findsNothing,
      );
      router.go('/number-detail?type=personality');
      await _frames(tester);
      await emitArticle(tester);
      expect(
        find.byKey(const ValueKey('detail-profile-switcher')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
