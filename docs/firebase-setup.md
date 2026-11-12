# Firebase setup (M02)

Existing files were parsed rather than inferred from names:

- config/google-services.json: contains Android application mt.numerology.
- config/GoogleService-Info.plist: contains BUNDLE_ID mt.numerology.
- Both reference existing project numerology-857a6. No project/application was created or changed remotely. Original config/ files remain byte-for-byte unchanged.

## Native configuration

Android has a byte-identical copy at android/app/google-services.json. Existing root/app Gradle files retain AGP 7.3.0, Gradle 7.5 and Kotlin 1.7.10. Added Google Services classpath/plugin 4.3.15 and Crashlytics classpath/plugin 2.9.9. A build-time guard rejects JSON lacking the mt.numerology client; Google Services selects by application ID. Application ID and namespace remain mt.numerology. Release signing configuration was not changed.

iOS has a byte-identical copy at ios/Runner/GoogleService-Info.plist, explicitly referenced by the Runner group and Runner Resources build phase. Runner Bundle ID remains mt.numerology in all app configurations, deployment target remains 12.0, and signing was preserved. Existing Flutter plugin registration handles Firebase plugins. The Crashlytics Symbols build phase invokes the pinned SDK's upload-symbols tool using the existing plist for Release/device builds only; it is skipped for debug/simulator. ios/firebase_app_id_file.json was generated locally from the existing plist for the pinned FlutterFire tooling; it does not register an application.

## Flutter startup and privacy

Declared direct package versions are firebase_core 2.24.2, firebase_analytics 10.8.0, firebase_crashlytics 3.4.9, selected together against their cached package manifests for the installed Flutter 3.13.9/Dart 3.1.5 baseline. Packages are not claimed installed: pub get aborts before resolution. Native dependency/build compatibility is still unverified.

main awaits FirebaseStartup.initialize before runApp. Native Firebase.initializeApp reads the supplied platform configuration; no generated API-key options or FlutterFire CLI/project creation is required. The helper runs only on Android/iOS and compares projectId/appId against the identities extracted from config before accessing Analytics/Crashlytics. A mismatch returns invalidConfiguration and stops relevant Dart integration. Initialization failures return unavailable so local profiles remain usable. Status is exposed as firebaseStartupStatusProvider. Initialization/configuration has bounded timeouts so local UI is not held indefinitely waiting for telemetry setup.

Native collection flags default false, including automatic screen reporting. Runtime collection also defaults false. Enable explicitly using --dart-define=ENABLE_TELEMETRY=true only after runtime validation. SDK instances are configured after identity validation even when collection is off. When enabled, framework/platform hooks send fixed safe failure codes with reporter-local stacks, never original exception/details/stack/request data. Reporter failures are swallowed without recursive reporting. Raw native SDK crash collection behavior still requires device validation; no personal data is deliberately attached to logs, events, custom keys or user IDs. Any previous telemetry user identifier is cleared on valid initialization. No profile IDs, names, dates or calculation payloads are passed to analytics. There is no arbitrary analytics-event or crash-context API in profile/cache code.

No Authentication, Firestore, Realtime Database, Functions, ads or profile synchronization dependencies were added.

## Verification and remaining setup

Offline checks confirm native configuration IDs, byte-identical copies, Gradle declarations, Runner resources, Xcode/plist/XML parseability and startup wiring. Unit tests use FakeFirebaseDriver, not a live Firebase service. No physical-device Analytics event, crash upload, symbolication, Firebase console permission, or backend connection was tested. These checks are not claimed successful.

After restoring a working Flutter SDK, run pub get/analyze/test and native builds. For an authorized telemetry validation run, enable the flag, confirm initialization status, and use a deliberate non-personal test event/crash on a device; verify symbols and dashboard delivery. Do not deliberately crash or send events during ordinary unit tests. If replacing configuration files later, revalidate both application IDs and update expected Firebase app identities/native copies consistently. Never run a Firebase provisioning command automatically.

Sources: [Flutter setup](https://firebase.google.com/docs/flutter/setup), [Google Services plugin/file](https://firebase.google.com/docs/android/google-services-plugin-and-file), [Crashlytics](https://firebase.google.com/docs/crashlytics/get-started?platform=flutter). Native integration details also follow the locally inspected pinned FlutterFire source/manifests; current documentation may describe newer SDK minimums than this older baseline.
