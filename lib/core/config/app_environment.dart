import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppEnvironment {
  AppEnvironment({String apiBaseUrl = defaultApiBaseUrl})
    : apiBaseUri = _validate(apiBaseUrl);

  static const defaultApiBaseUrl = 'https://pilogy.vercel.app/api/v1';
  final Uri apiBaseUri;

  factory AppEnvironment.fromDartDefines() => AppEnvironment(
    apiBaseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: defaultApiBaseUrl,
    ),
  );

  static Uri _validate(String value) {
    final uri = Uri.tryParse(value);
    const localHosts = {'localhost', '127.0.0.1', '::1', '10.0.2.2'};
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !(uri.scheme == 'https' ||
            (uri.scheme == 'http' && localHosts.contains(uri.host)))) {
      throw const FormatException('API_BASE_URL must be an HTTPS base URL.');
    }
    final path = uri.path.replaceFirst(RegExp(r'/+$'), '');
    return uri.replace(path: '$path/');
  }
}

final environmentProvider = Provider<AppEnvironment>(
  (ref) => AppEnvironment.fromDartDefines(),
);
