import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/launch.dart';
import 'core/config/app_orientation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configurePortraitOrientation();
  runApp(const ProviderScope(child: PilogyLaunch()));
}
