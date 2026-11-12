import 'package:flutter/services.dart';

/// Match the Android activity and iPhone/iPad supported-orientation declarations.
Future<void> configurePortraitOrientation() =>
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
