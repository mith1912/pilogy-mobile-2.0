import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'ad_configuration.dart';
import 'ad_diagnostics.dart';
import 'ad_consent_service.dart';
import 'ad_frequency_policy.dart';
import 'ad_gateway.dart';

void disposeAd(Future<void> Function() dispose) {
  unawaited(Future<void>.sync(dispose).catchError((Object _) {}));
}

class _ReadyAd {
  _ReadyAd(this.handle, this.loadedAt);
  final FullscreenAdHandle handle;
  final DateTime loadedAt;
}

/// Coordinates formats and lifecycle. No profiles, dates or results enter here.
class AdMobService extends ChangeNotifier {
  AdMobService({
    required this.config,
    required this.consent,
    required this.gateway,
    AdAnalyticsService? analytics,
    DateTime Function()? now,
  }) : analytics = analytics ?? SilentAdAnalytics(),
       policy = AdFrequencyPolicy(config, now: now) {
    consent.addListener(_consentChanged);
    gateway.onAdClicked = _adClicked;
    gateway.onNativeImpression = () {
      if (!_disposed) event('ad_displayed', AdFormat.nativeAdvanced);
    };
  }
  final AdConfiguration config;
  final AdConsentService consent;
  final AdGateway gateway;
  final AdAnalyticsService analytics;
  final AdFrequencyPolicy policy;
  bool returningUser = false, initialized = false, calculationBusy = true;
  bool dialogOpen = false, _disposed = false;
  String screen = 'startup';
  bool _skipAppOpenOnce = false;

  void _adClicked() {
    // A return from the advertiser must not trigger another full-screen ad.
    _skipAppOpenOnce = true;
    AdDiagnostics.stage('advertiser_return_suppression_armed');
  }
  DateTime? _backgroundAt, _detailReadyAt;
  int _visit = 0, _generation = 0;
  Future<void>? _startup, _sdkInitialization;
  VoidCallback? _activeDispose;
  final Map<AdFormat, _ReadyAd> _ready = {};
  final Set<AdFormat> _loading = {};
  final Map<AdFormat, int> _attempts = {};
  final Map<AdFormat, Timer> _retry = {};
  final Map<AdFormat, String> _lastPreloadSkip = {};
  void _preloadSkipped(AdFormat format, String reason) {
    if (_lastPreloadSkip[format] == reason) return;
    _lastPreloadSkip[format] = reason;
    AdDiagnostics.stage('${format.name}_preload_skipped_$reason');
  }
  bool get canRequest =>
      !_disposed &&
      initialized &&
      returningUser &&
      config.enabled &&
      consent.allowed &&
      !consent.busy &&
      policy.foreground;
  bool get safeOverview =>
      (screen == 'discover' || screen == 'analysis') &&
      !calculationBusy &&
      !dialogOpen;
  static const bannerScreens = {
    'welcome',
    'profileForm',
    'discover',
    'analysis',
    'numberDetail',
    'profiles',
    'settings',
    'privacyData',
  };
  bool get bannerAllowed =>
      canRequest &&
      bannerScreens.contains(screen) &&
      !dialogOpen &&
      !policy.presenting;
  bool get nativeAllowed =>
      canRequest && safeOverview && !policy.presenting;
  // Fixed labels only; never include profile identifiers or backend state.
  String inlineBlockReason(AdFormat format) {
    if (_disposed) return 'disposed';
    if (!config.enabled) return 'disabled';
    if (!returningUser) return 'first_session';
    if (consent.busy) return 'consent_busy';
    if (!consent.allowed) return 'consent_ineligible';
    if (!initialized) return 'sdk_not_initialized';
    if (!policy.foreground) return 'background';
    if (dialogOpen) return 'dialog';
    if (policy.presenting) return 'fullscreen_presenting';
    if (format == AdFormat.banner && !bannerScreens.contains(screen)) {
      return 'screen';
    }
    if (format == AdFormat.nativeAdvanced && !safeOverview) {
      return 'overview_unavailable';
    }
    return 'gate';
  }

  bool _notificationScheduled = false;
  void _notify() {
    if (_disposed) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_notificationScheduled) return;
      _notificationScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _notificationScheduled = false;
        if (!_disposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  void event(String name, AdFormat format) {
    AdDiagnostics.stage('${format.name}_$name');
    try {
      analytics.event(name, format);
    } catch (_) {
      /* Telemetry never affects UI. */
    }
  }

  Future<void> start({required bool returning}) =>
      _startup ??= _start(returning);
  Future<void> _start(bool returning) async {
    returningUser = returning;
    AdDiagnostics.stage(config.enabled ? 'ads_enabled' : 'ads_disabled');
    AdDiagnostics.stage(config.testing ? 'test_units' : 'production_units');
    AdDiagnostics.stage(returning ? 'returning_session' : 'first_session_ad_free');
    AdDiagnostics.stage(
      AdConfiguration.validApp(config.appId) ? 'app_id_valid' : 'app_id_invalid',
    );
    for (final format in AdFormat.values) {
      AdDiagnostics.stage(
        '${format.name}_${config.unit(format) == null ? 'unconfigured' : 'configured'}',
      );
    }
    if (!config.enabled ||
        !config.supported ||
        !AdConfiguration.validApp(config.appId))
      return;
    await consent.initialize();
    if (_disposed || !consent.allowed) return;
    await _ensureSdk();
  }

  Future<void> _ensureSdk() => _sdkInitialization ??= _initializeSdk();
  Future<void> _initializeSdk() async {
    try {
      await gateway.initialize().timeout(const Duration(seconds: 15));
      if (_disposed) return;
      initialized = true;
      AdDiagnostics.stage('sdk_initialized');
      _notify();
      _preload();
    } catch (_) {
      initialized = false;
      AdDiagnostics.stage('sdk_initialization_failed');
      _notify();
    }
  }

  void _consentChanged() {
    if (!consent.allowed || consent.busy) _clearLoaded();
    _notify();
    if (consent.allowed &&
        !consent.busy &&
        config.enabled &&
        config.supported) {
      unawaited(_ensureSdk());
      _preload();
    }
  }

  void context({
    required String screen,
    required bool calculationBusy,
    required bool dialogOpen,
  }) {
    if (this.screen != screen || this.calculationBusy != calculationBusy ||
        this.dialogOpen != dialogOpen) {
      AdDiagnostics.stage(
        screen == 'discover' ? 'discover_visible' : 'discover_not_visible',
      );
      AdDiagnostics.stage(calculationBusy ? 'calculation_blocked' : 'calculation_ready');
      AdDiagnostics.stage(dialogOpen ? 'dialog_blocked' : 'dialog_clear');
    }
    this.screen = screen;
    this.calculationBusy = calculationBusy;
    this.dialogOpen = dialogOpen;
    _notify();
    _preload();
  }

  void beginInterpretation() {
    _visit++;
    _detailReadyAt = null;
  }

  void interpretationReady() {
    if (screen == 'numberDetail') _detailReadyAt ??= policy.now();
  }

  int? endInterpretation() {
    final ready = _detailReadyAt;
    _detailReadyAt = null;
    if (_disposed ||
        ready == null ||
        policy.now().difference(ready) < const Duration(seconds: 10) ||
        !returningUser)
      return null;
    return _visit;
  }

  void finishInterpretation(int? visit) {
    if (_disposed || visit == null) return;
    if (policy.completeInterpretation(visit) && safeOverview)
      _show(AdFormat.interstitial);
  }

  void inactive() {
    policy.foreground = false;
    _notify();
  }

  void paused() {
    // Ignore lifecycle noise produced by consent and full-screen ads/dialogs.
    if (!policy.presenting && !consent.busy && !dialogOpen)
      _backgroundAt ??= policy.now();
    policy.foreground = false;
    _notify();
  }

  void resumed() {
    final background = _backgroundAt;
    final skipAppOpen = _skipAppOpenOnce;
    _skipAppOpenOnce = false;
    _backgroundAt = null;
    policy.foreground = true;
    _notify();
    // One opportunity only. A later load never displays over an active session.
    AdDiagnostics.stage(skipAppOpen ? 'appOpen_skipped_advertiser_return' :
      background == null ? 'appOpen_skipped_no_background' :
      !safeOverview ? 'appOpen_skipped_unsafe_overview' :
      !policy.appOpenDue(policy.now().difference(background)) ? 'appOpen_skipped_policy' :
      'appOpen_resume_eligible');
    if (!skipAppOpen &&
        background != null &&
        safeOverview &&
        policy.appOpenDue(policy.now().difference(background))) {
      _show(AdFormat.appOpen);
    }
    _preload();
  }

  void _preload() {
    if (!canRequest) return;
    for (final format in [AdFormat.interstitial, AdFormat.appOpen]) {
      unawaited(preload(format));
    }
  }

  bool _expired(AdFormat format, _ReadyAd ready) {
    final age = policy.now().difference(ready.loadedAt);
    final maxAge = format == AdFormat.appOpen
        ? const Duration(hours: 4) : const Duration(hours: 1);
    return age.isNegative || age >= maxAge;
  }

  Future<void> preload(AdFormat format) async {
    final unit = config.unit(format);
    if ((format != AdFormat.interstitial && format != AdFormat.appOpen) ||
        unit == null || !canRequest ||
        policy.fullscreenLimitReached) {
      _preloadSkipped(format, unit == null ? 'unconfigured' :
          !canRequest ? 'request_gate' : 'session_cap');
      return;
    }
    final cached = _ready[format];
    if (cached != null && _expired(format, cached)) {
      _ready.remove(format);
      disposeAd(cached.handle.dispose);
    }
    if (_ready.containsKey(format) ||
        _loading.contains(format) ||
        _retry.containsKey(format) ||
        (_attempts[format] ?? 0) >= 3) {
      _preloadSkipped(format, _ready.containsKey(format) ? 'cached' :
          _loading.contains(format) ? 'loading' :
          _retry.containsKey(format) ? 'backoff' : 'attempt_limit');
      return;
    }
    _lastPreloadSkip.remove(format);
    final generation = _generation;
    _loading.add(format);
    event('ad_load_requested', format);
    try {
      final handle = await gateway.loadFullscreen(format, unit);
      if (_disposed || generation != _generation || !canRequest) {
        disposeAd(handle.dispose);
        return;
      }
      _ready[format] = _ReadyAd(handle, policy.now());
      _attempts[format] = 0;
      event('ad_loaded', format);
    } catch (_) {
      if (_disposed || generation != _generation) return;
      event('ad_load_failed', format);
      _scheduleReload(format);
    } finally {
      _loading.remove(format);
    }
  }

  void _scheduleReload(AdFormat format) {
    final attempts = (_attempts[format] ?? 0) + 1;
    _attempts[format] = attempts;
    if (_disposed || attempts >= 3 || _retry.containsKey(format)) return;
    _retry[format] = Timer(Duration(seconds: attempts == 1 ? 30 : 120), () {
      _retry.remove(format);
      unawaited(preload(format));
    });
  }

  void _show(AdFormat format) {
    if (!canRequest ||
        !safeOverview ||
        (format == AdFormat.interstitial && !policy.interstitialDue)) {
      AdDiagnostics.stage('${format.name}_show_skipped_gate_or_policy');
      return;
    }
    final ready = _ready[format];
    if (ready == null) {
      AdDiagnostics.stage('${format.name}_show_skipped_not_loaded');
      return;
    } // Never wait for an ad or block navigation.
    if (_expired(format, ready)) {
      _ready.remove(format);
      disposeAd(ready.handle.dispose);
      unawaited(preload(format));
      return;
    }
    if (!policy.acquire()) {
      AdDiagnostics.stage('${format.name}_show_skipped_policy_lock');
      return;
    }
    _ready.remove(format);
    _notify();
    var ended = false, shown = false, released = false;
    void release() {
      if (released) return;
      released = true;
      disposeAd(ready.handle.dispose);
    }

    _activeDispose = release;
    void finish(bool failed) {
      if (ended) return;
      ended = true;
      policy.ended();
      release();
      if (identical(_activeDispose, release)) _activeDispose = null;
      event(failed ? 'ad_display_failed' : 'ad_closed', format);
      _notify();
      _scheduleReload(format);
    }

    unawaited(
      Future<void>.sync(
        () => ready.handle.show(
          onShown: () {
            if (ended || shown) return;
            shown = true;
            policy.shown(format);
            event('ad_displayed', format);
          },
          onClosed: () => finish(false),
          onFailed: () => finish(true),
        ),
      ).catchError((Object _) {
        finish(true);
      }),
    );
  }

  void _clearLoaded() {
    _generation++;
    for (final ready in _ready.values) {
      disposeAd(ready.handle.dispose);
    }
    _ready.clear();
    for (final timer in _retry.values) {
      timer.cancel();
    }
    _retry.clear();
  }

  @override
  void dispose() {
    _disposed = true;
    gateway.onAdClicked = null;
    gateway.onNativeImpression = null;
    _activeDispose?.call();
    _activeDispose = null;
    consent.removeListener(_consentChanged);
    _clearLoaded();
    super.dispose();
  }
}
