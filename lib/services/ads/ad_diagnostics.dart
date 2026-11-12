import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Opt-in device console only. Never forward to Analytics/Crashlytics or pass
/// application exceptions, requests, profiles or calculation content here.
class AdDiagnostics {
  static const enabled = bool.fromEnvironment('ADS_DIAGNOSTICS');

  static void stage(String stage, {int? code}) {
    if (!enabled) return;
    debugPrint('[PILOGY_ADS] $stage${code == null ? '' : ' code=$code'}');
  }

  /// SDK-owned diagnostic fields only; JSON escaping prevents multiline output.
  static void loadError(String format, LoadAdError error) {
    if (!enabled) return;
    debugPrint('[PILOGY_ADS] ${jsonEncode({
      'stage': '${format}_load_error',
      'code': error.code,
      'domain': error.domain,
      'message': error.message,
      'responseInfo': error.responseInfo?.toString(),
    })}');
  }
}
