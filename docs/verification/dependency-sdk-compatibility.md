# Dependency compatibility repair — 2026-11-09

The reported release build reached Dart compilation and failed in win32 5.1.1
(`UnmodifiableUint8ListView`) and google_fonts 6.1.0 (constant FontWeight map).

Changes in pubspec.yaml:

- Pin google_fonts to 6.3.2, whose changelog documents the non-const FontWeight map fix.
- Constrain the transitive win32 dependency to >=5.5.1 <6.0.0 through a normal
  dependency constraint, without overriding upstream constraints. Version 5.5.1
  migrated away from UnmodifiableUint8ListView.
- Align minimum SDK constraints with google_fonts: Flutter >=3.29 / Dart >=3.7.

Sources: https://pub.dev/packages/google_fonts/versions/6.3.2/changelog
and https://win32.pub/changelog/5.5.1 .

Installed SDK metadata now reports Flutter 3.47.9 / Dart 3.13.7. This is metadata
read from bin/cache/flutter.version.json and dart-sdk/version, not a successful
execution of the SDK. The current lockfile still contains google_fonts 6.1.0 and
win32 5.1.1; it was not manually edited or presented as newly resolved.

Actual attempts: flutter pub get, dart format ., flutter analyze, flutter test,
and flutter build apk --release all exited 1 before initialization. The sandbox
denies writes to the external Flutter SDK cache (engine.stamp.tmp and engine.realm).
No dependency resolution, formatting, analysis, tests or APK success is claimed.

Run in an unrestricted local terminal from the project root:

```sh
flutter pub get
dart format .
flutter analyze
flutter test
flutter build apk --release
```

Successful pub get must update pubspec.lock to the compatible versions. Keep that
generated lockfile. No Gradle, native identifiers, designs or config assets were
changed by this repair.

## Android embedding and compile SDK follow-up

The subsequent user build resolved google_fonts 6.3.2 and win32 5.15.0, but
failed compiling path_provider_android 2.2.3 against the removed Flutter
PluginRegistry.Registrar API. Inspection also found that API in the installed
sqflite 2.3.0 and shared_preferences_android 2.2.1 sources.

The follow-up constrains path_provider to 2.1.5 (which requires
path_provider_android >=2.2.5), sqflite to 2.3.3+2 (the release removing v1
embedding), and shared_preferences to 2.5.3. Existing SharedPreferences API
usage, preference keys, SQLite schema and database filenames remain unchanged.
No storage migration or data deletion is performed.

Android compileSdkVersion is now 36 to meet the reported integration_test and
webview_flutter_android requirements. The SDK platform must be installed on the
build machine. Application ID, target/min SDK settings and native config assets
were not edited. Current Gradle 8.14, AGP 8.11.1 and Kotlin 2.2.20 were retained;
their future-support warnings are distinct from the reported compiler failure.

Sources: https://pub.dev/packages/path_provider/changelog ,
https://pub.dev/packages/sqflite/changelog , and
https://pub.dev/packages/shared_preferences/changelog .

Follow-up attempts of flutter pub get, dart format ., flutter analyze, flutter
test and flutter build apk --debug each exited 1 before initialization due to
the same SDK-cache sandbox write denial. These dependency changes are not yet
resolved into pubspec.lock; no passing runtime checks or build is claimed.
Run the commands above locally, substituting --debug for --release as needed.

## Missing multidex and Cupertino font — 2026-11-10

The user's subsequent release build reached app Java compilation, then failed
because the existing generated FlutterMultiDexApplication imports
androidx.multidex.MultiDex without a matching Gradle dependency. Added the
explicit androidx.multidex:multidex:2.0.1 dependency to the app module, retaining
the existing generated application and manifest placeholder. No min SDK or
application identity change is required. Android reference:
https://developer.android.com/build/multidex .

Added cupertino_icons 1.0.8 to supply the missing
packages/cupertino_icons/CupertinoIcons font reported by the icon tree shaker.
Material icon tree shaking and the ads SDK deprecated-API note are informational.
Gradle/AGP/Kotlin future-support warnings remain unchanged.

flutter pub get, dart format ., flutter analyze, flutter test and flutter build
apk --release were attempted again. All exited 1 before initialization because
SDK cache writes remain denied by the sandbox. The Cupertino package is not
claimed resolved and the APK is not claimed built. Run those commands locally
to resolve the lockfile and verify native compilation.

## Gradle heap exhaustion — 2026-11-10

The user's debug build subsequently reported Java heap exhaustion. Raised the
project Gradle maximum heap from 1536M to 4G, allowed 1G metaspace, selected G1GC,
and capped Gradle workers at two with project parallelism disabled to limit
concurrent memory pressure. These are upper limits, not reserved allocations.
Reading machine RAM via sysctl was denied by the sandbox; the memory settings
have not been tuned against measured host RAM.

flutter build apk --debug was attempted and exited 1 before initialization due
to the external SDK cache write denial. No successful build is claimed. Stop
the old Gradle daemons locally, then retry from the project root:

```sh
(cd android && ./gradlew --stop)
flutter run
```
