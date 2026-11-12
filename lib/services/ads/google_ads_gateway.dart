import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_configuration.dart';
import 'ad_diagnostics.dart';
import 'ad_consent_service.dart';
import 'ad_gateway.dart';
import 'ad_mob_service.dart';

class GoogleConsentGateway implements ConsentGateway {
  @override
  Future<void> update() {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        if (!done.isCompleted) done.complete();
      },
      (error) {
        AdDiagnostics.stage('consent_update_failed', code: error.errorCode);
        if (!done.isCompleted)
          done.completeError(StateError('consent_update_unavailable'));
      },
    );
    return done.future;
  }

  Future<void> _form(
    Future<void> Function(OnConsentFormDismissedListener) action,
  ) async {
    final done = Completer<void>();
    unawaited(
      action((error) {
        if (done.isCompleted) return;
        if (error == null) {
          done.complete();
        } else {
          AdDiagnostics.stage('consent_form_failed', code: error.errorCode);
          done.completeError(StateError('consent_form_unavailable'));
        }
      }).catchError((Object _) {
        if (!done.isCompleted)
          done.completeError(StateError('consent_form_unavailable'));
      }),
    );
    await done.future;
  }

  @override
  Future<void> showRequiredForm() =>
      _form(ConsentForm.loadAndShowConsentFormIfRequired);
  @override
  Future<bool> canRequestAds() => ConsentInformation.instance.canRequestAds();
  @override
  Future<bool> privacyOptionsRequired() async =>
      await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
      PrivacyOptionsRequirementStatus.required;
  @override
  Future<void> showPrivacyOptions() =>
      _form(ConsentForm.showPrivacyOptionsForm);
}

class GoogleAdsGateway implements AdGateway {
  @override
  VoidCallback? onAdClicked;
  @override
  VoidCallback? onNativeImpression;
  static const _request = AdRequest(
    nonPersonalizedAds: true,
    httpTimeoutMillis: 15000,
  );
  @override
  Future<void> initialize() async {
    final sdk = MobileAds.instance;
    await sdk.setSameAppKeyEnabled(false);
    await sdk.disableSDKCrashReporting();
    await sdk.initialize();
  }

  @override
  Future<FullscreenAdHandle> loadFullscreen(AdFormat format, String unit) {
    final done = Completer<FullscreenAdHandle>();
    final timeout = Timer(const Duration(seconds: 20), () {
      if (!done.isCompleted) {
        AdDiagnostics.stage('${format.name}_load_timeout');
        done.completeError(TimeoutException('ad_load_timeout'));
      }
    });
    void loaded(FullscreenAdHandle ad) {
      if (done.isCompleted) {
        disposeAd(ad.dispose);
        return;
      }
      timeout.cancel();
      done.complete(ad);
    }

    void failed(Object error) {
      if (error is LoadAdError) {
        AdDiagnostics.loadError(format.name, error);
      } else {
        AdDiagnostics.stage('${format.name}_load_invocation_failed');
      }
      timeout.cancel();
      if (!done.isCompleted)
        done.completeError(StateError('ad_load_unavailable'));
    }

    try {
      final Future<void> pending;
      if (format == AdFormat.interstitial) {
        pending = InterstitialAd.load(
          adUnitId: unit,
          request: _request,
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (ad) => loaded(_InterstitialHandle(ad, () => onAdClicked?.call())),
            onAdFailedToLoad: failed,
          ),
        );
      } else if (format == AdFormat.appOpen) {
        pending = AppOpenAd.load(
          adUnitId: unit,
          request: _request,
          adLoadCallback: AppOpenAdLoadCallback(
            onAdLoaded: (ad) => loaded(_AppOpenHandle(ad, () => onAdClicked?.call())),
            onAdFailedToLoad: failed,
          ),
        );
      } else {
        throw StateError('unsupported_fullscreen');
      }
      unawaited(pending.catchError(failed));
    } catch (error) {
      failed(error);
    }
    return done.future;
  }

  @override
  Future<InlineAdHandle> loadNative(String unit, int width) async {
    final done = Completer<InlineAdHandle>();
    late NativeAd ad;
    final timeout = Timer(const Duration(seconds: 20), () {
      if (!done.isCompleted) {
        AdDiagnostics.stage('nativeAdvanced_load_timeout');
        done.completeError(TimeoutException('native_load_timeout'));
        disposeAd(ad.dispose);
      }
    });
    void failed(Object error) {
      if (error is! LoadAdError) AdDiagnostics.stage('sdk_load_invocation_failed');
      timeout.cancel();
      disposeAd(ad.dispose);
      if (!done.isCompleted) {
        done.completeError(StateError('native_load_unavailable'));
      }
    }
    ad = NativeAd(
      adUnitId: unit,
      request: _request,
      nativeTemplateStyle: NativeTemplateStyle(templateType: TemplateType.small),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          timeout.cancel();
          if (done.isCompleted) {
            disposeAd(ad.dispose);
          } else {
            done.complete(_NativeHandle(ad, width));
          }
        },
        onAdFailedToLoad: (_, error) {
          AdDiagnostics.loadError('nativeAdvanced', error);
          failed(error);
        },
        onAdClicked: (_) => onAdClicked?.call(),
        onAdImpression: (_) => onNativeImpression?.call(),
      ),
    );
    try {
      unawaited(ad.load().catchError(failed));
    } catch (error) {
      failed(error);
    }
    return done.future;
  }

  @override
  Future<BannerAdHandle> loadBanner(String unit, int width) async {
    AdDiagnostics.stage('banner_adaptive_size_started');
    final AdSize? size;
    try {
      size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
        width,
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      AdDiagnostics.stage('banner_adaptive_size_failed');
      rethrow;
    }
    if (size == null) {
      AdDiagnostics.stage('banner_adaptive_size_unavailable');
      throw StateError('adaptive_size_unavailable');
    }
    AdDiagnostics.stage('banner_adaptive_size_ready');
    final done = Completer<BannerAdHandle>();
    late BannerAd banner;
    final timeout = Timer(const Duration(seconds: 20), () {
      if (!done.isCompleted) {
        AdDiagnostics.stage('banner_load_timeout');
        done.completeError(TimeoutException('banner_load_timeout'));
        disposeAd(banner.dispose);
      }
    });
    banner = BannerAd(
      adUnitId: unit,
      size: size,
      request: _request,
      listener: BannerAdListener(
        onAdClicked: (_) => onAdClicked?.call(),
        onAdImpression: (_) => AdDiagnostics.stage('banner_ad_displayed'),
        onAdLoaded: (_) {
          timeout.cancel();
          if (done.isCompleted) {
            disposeAd(banner.dispose);
          } else {
            done.complete(_BannerHandle(banner));
          }
        },
        onAdFailedToLoad: (_, error) {
          AdDiagnostics.loadError('banner', error);
          timeout.cancel();
          disposeAd(banner.dispose);
          if (!done.isCompleted)
            done.completeError(StateError('banner_load_unavailable'));
        },
      ),
    );
    void failed(Object error) {
      if (error is! LoadAdError) AdDiagnostics.stage('sdk_load_invocation_failed');
      timeout.cancel();
      disposeAd(banner.dispose);
      if (!done.isCompleted)
        done.completeError(StateError('banner_load_unavailable'));
    }

    try {
      AdDiagnostics.stage('banner_sdk_load_called');
      unawaited(banner.load().catchError(failed));
    } catch (error) {
      failed(error);
    }
    return done.future;
  }
}

class _BannerHandle implements BannerAdHandle {
  _BannerHandle(this.ad);
  final BannerAd ad;
  @override
  int get width => ad.size.width;
  @override
  int get height => ad.size.height;
  @override
  Widget view() => AdWidget(ad: ad);
  @override
  Future<void> dispose() => ad.dispose();
}

class _InterstitialHandle implements FullscreenAdHandle {
  _InterstitialHandle(this.ad, this.onClicked);
  final VoidCallback onClicked;
  final InterstitialAd ad;
  @override
  Future<void> show({
    required VoidCallback onShown,
    required VoidCallback onClosed,
    required VoidCallback onFailed,
  }) {
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdClicked: (_) => onClicked(),
      onAdShowedFullScreenContent: (_) => onShown(),
      onAdDismissedFullScreenContent: (_) => onClosed(),
      onAdFailedToShowFullScreenContent: (_, error) => onFailed(),
    );
    return ad.show();
  }

  @override
  Future<void> dispose() => ad.dispose();
}

class _AppOpenHandle implements FullscreenAdHandle {
  _AppOpenHandle(this.ad, this.onClicked);
  final VoidCallback onClicked;
  final AppOpenAd ad;
  @override
  Future<void> show({
    required VoidCallback onShown,
    required VoidCallback onClosed,
    required VoidCallback onFailed,
  }) {
    ad.fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
      onAdClicked: (_) => onClicked(),
      onAdShowedFullScreenContent: (_) => onShown(),
      onAdDismissedFullScreenContent: (_) => onClosed(),
      onAdFailedToShowFullScreenContent: (_, error) => onFailed(),
    );
    return ad.show();
  }

  @override
  Future<void> dispose() => ad.dispose();
}

class _NativeHandle implements InlineAdHandle {
  _NativeHandle(this.ad, this.width);
  final NativeAd ad;
  @override
  final int width;
  @override
  int get height => 140;
  @override
  Widget view() => AdWidget(ad: ad);
  @override
  Future<void> dispose() => ad.dispose();
}
