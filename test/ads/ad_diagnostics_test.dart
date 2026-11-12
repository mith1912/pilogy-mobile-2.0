import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pilogy_app/services/ads/ad_diagnostics.dart';

class _Error extends LoadAdError {
  _Error() : super(3, 'com.google.android.gms.ads', 'No fill.\nSDK detail', null);
}

void main() {
  test('SDK load errors are opt-in and retain escaped diagnostic fields', () {
    final lines = <String>[];
    final original = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) lines.add(message);
    };
    addTearDown(() => debugPrint = original);
    AdDiagnostics.loadError('nativeAdvanced', _Error());
    if (!AdDiagnostics.enabled) {
      expect(lines, isEmpty);
      return;
    }
    expect(lines, hasLength(1));
    expect(lines.single.split('\n'), hasLength(1));
    final fields = jsonDecode(lines.single.substring('[PILOGY_ADS] '.length));
    expect(fields['stage'], 'nativeAdvanced_load_error');
    expect(fields['code'], 3);
    expect(fields['domain'], 'com.google.android.gms.ads');
    expect(fields['message'], 'No fill.\nSDK detail');
    expect(fields.containsKey('responseInfo'), isTrue);
    expect(fields['responseInfo'], isNull);
  });
}
