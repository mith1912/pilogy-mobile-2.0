import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'native visible names are PILOGY and identifiers/orientation remain',
    () {
      final android =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      final ios = File('ios/Runner/Info.plist').readAsStringSync();
      expect(android, contains('android:label="PILOGY"'));
      expect(android, contains('android:screenOrientation="portrait"'));
      expect(
        ios,
        matches(
          RegExp(r'<key>CFBundleDisplayName</key>\s*<string>PILOGY</string>'),
        ),
      );
      expect(ios, isNot(contains('UIInterfaceOrientationLandscape')));
      expect(
        File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync(),
        contains('mt.numerology'),
      );
    },
  );
}
