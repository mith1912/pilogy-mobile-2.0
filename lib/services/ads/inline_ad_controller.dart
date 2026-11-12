import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ad_configuration.dart';
import 'ad_diagnostics.dart';
import 'ad_gateway.dart';
import 'ad_mob_service.dart';

class InlineAdController extends ChangeNotifier {
  InlineAdController(this.service, {required this.format})
      : assert(format == AdFormat.banner || format == AdFormat.nativeAdvanced) {
    service.addListener(_gateChanged);
  }
  final AdMobService service;
  final AdFormat format;
  InlineAdHandle? ad;
  int? _width;
  int _generation = 0;
  bool _loading = false, _disposed = false, _failed = false;
  bool _visible = true;
  int _attempts = 0;
  Timer? _retry;
  bool get _allowed => _visible && (format == AdFormat.nativeAdvanced
      ? service.nativeAllowed : service.bannerAllowed);

  void setVisible(bool visible) {
    if (_disposed || _visible == visible) return;
    _visible = visible;
    AdDiagnostics.stage('${format.name}_${visible ? 'visible' : 'hidden'}');
    _gateChanged();
  }
  void _gateChanged() {
    if (!_allowed) {
      _generation++;
      _loading = false;
      final old = ad;
      ad = null;
      if (old != null) disposeAd(old.dispose);
    }
    if (!_disposed) notifyListeners();
  }

  String? _lastSkip;
  void _skip(String reason) {
    if (_lastSkip == reason) return;
    _lastSkip = reason;
    AdDiagnostics.stage('${format.name}_skipped_$reason');
  }

  Future<void> load(int width) async {
    if (_disposed) return;
    if (width < 1) {
      _skip('invalid_width');
      return;
    }
    if (!_allowed) {
      _skip(!_visible ? 'not_visible' : service.inlineBlockReason(format));
      return;
    }
    if (_width == width && (_loading || ad != null || _failed)) {
      _skip(_loading ? 'loading' : ad != null ? 'already_loaded' : 'failure_backoff');
      return;
    }
    final unit = service.config.unit(format);
    if (unit == null) {
      _skip('unit_unconfigured');
      return;
    }
    _lastSkip = null;
    if (_width != width) {
      _retry?.cancel();
      _retry = null;
      _attempts = 0;
    }
    final generation = ++_generation;
    _width = width;
    _loading = true;
    _failed = false;
    final old = ad;
    ad = null;
    if (old != null) disposeAd(old.dispose);
    service.event('ad_load_requested', format);
    try {
      final loaded = format == AdFormat.nativeAdvanced
          ? await service.gateway.loadNative(unit, width)
          : await service.gateway.loadBanner(unit, width);
      if (_disposed || generation != _generation || !_allowed) {
        disposeAd(loaded.dispose);
        return;
      }
      ad = loaded;
      _attempts = 0;
      service.event('ad_loaded', format);
    } catch (_) {
      if (!_disposed && generation == _generation) {
        _failed = true;
        service.event('ad_load_failed', format);
        _attempts++;
        if (_attempts < 3) {
          _retry = Timer(Duration(seconds: _attempts == 1 ? 30 : 120), () {
            _retry = null;
            if (_disposed) return;
            _failed = false;
            if (_allowed) unawaited(load(width));
          });
        }
      }
    } finally {
      if (!_disposed && generation == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _retry?.cancel();
    _generation++;
    service.removeListener(_gateChanged);
    final old = ad;
    if (old != null) disposeAd(old.dispose);
    super.dispose();
  }
}
