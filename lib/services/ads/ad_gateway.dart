import 'package:flutter/widgets.dart';
import 'ad_configuration.dart';

abstract interface class FullscreenAdHandle {
  Future<void> show({
    required VoidCallback onShown,
    required VoidCallback onClosed,
    required VoidCallback onFailed,
  });
  Future<void> dispose();
}

abstract interface class InlineAdHandle {
  int get width;
  int get height;
  Widget view();
  Future<void> dispose();
}

abstract interface class BannerAdHandle implements InlineAdHandle {}

abstract interface class AdGateway {
  set onAdClicked(VoidCallback? callback);
  set onNativeImpression(VoidCallback? callback);
  Future<void> initialize();
  Future<FullscreenAdHandle> loadFullscreen(AdFormat format, String unit);
  Future<BannerAdHandle> loadBanner(String unit, int width);
  Future<InlineAdHandle> loadNative(String unit, int width);
}

abstract interface class AdAnalyticsService {
  void event(String name, AdFormat format);
}

class SilentAdAnalytics implements AdAnalyticsService {
  @override
  void event(String name, AdFormat format) {}
}
