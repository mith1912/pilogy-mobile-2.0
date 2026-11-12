# Build PILOGY for Android

Run from the Flutter root. Use the committed wrapper and pinned SDK; never install global Gradle or bypass Flutter dependency validation. Required versions and source evidence are in [development-environment.md](development-environment.md).

```bash
scripts/setup.sh --install --android
scripts/doctor.sh --android
scripts/flutter.sh analyze
scripts/flutter.sh test
API_BASE_URL=http://10.0.2.2:3000/api/v1 scripts/build-android.sh debug
scripts/build-android.sh release
scripts/build-android.sh appbundle
```

Debug requires an explicit backend URL. Android emulators normally reach a host server through 10.0.2.2; physical devices need a reachable development host. An explicit HTTPS staging URL is also supported. HTTP transport may require existing Android network-security permissions; the scripts do not weaken those settings. Release APK/AAB builds default to `https://pilogy.vercel.app/api/v1`; set API_BASE_URL to override deliberately. URLs with credentials, query parameters or fragments are rejected.

| Mode | Output |
| --- | --- |
| debug | build/app/outputs/flutter-apk/app-debug.apk |
| release | build/app/outputs/flutter-apk/app-release.apk |
| appbundle | build/app/outputs/bundle/release/app-release.aab |

The script validates SDK/JDK metadata, locked pub dependencies, native configuration and doctor before invoking Flutter. It reports an artifact only after command success plus fresh/nonempty ZIP/content checks. A missing or stale file fails the script. It does not claim store acceptance, successful installation, network behavior or production ad delivery from an archive check.

## Java and SDK selection

The scripts select exactly JDK 17.0.21 for this process. Java source/bytecode compatibility stays at the existing 1.8; that is separate from the JDK running AGP/Gradle. Global Java 25 is not the build JDK. `PILOGY_JAVA_HOME` can identify an existing matching installation.

ANDROID_HOME and ANDROID_SDK_ROOT must agree if both are set. Common Android Studio/Homebrew locations are detected. Project-generated android/local.properties points at the FVM SDK, selected Android SDK and CMake 3.22.1. It retains unrelated properties. A local XDG Flutter configuration prevents Android Studio's bundled JDK from overriding the selection; conflicting legacy ~/.flutter_settings requires manual reconciliation.

The exact compiler package set is API 36, Build Tools 35.0.0, CLI tools 23.0, NDK 28.2.13676358 and CMake 3.22.1. Platform-tools is required for device tooling but its moving SDK package is not exactly version-pinned. No Android Studio installation or emulator image is needed merely to compile; device/emulator testing requires separate device setup.

## Release signing

Keep the existing upload key. Do not generate a replacement for an already published application. Restore the keystore from the team's secure backup and create **ignored** android/key.properties locally:

```properties
storeFile=../config/keystore.jks
storePassword=<retrieve securely>
keyAlias=<existing upload alias>
keyPassword=<retrieve securely>
```

storeFile resolves relative to android/. External secure key paths are supported by the existing Gradle configuration. Do not paste actual passwords into documentation, shell command lines, CI variables committed to source, or logs. `.gitignore` excludes keystores and signing property files. Scripts check only presence/completeness; Gradle validates the real key/password. The existing release-signing guard is retained and never falls back to the debug certificate.

A release build stops if configuration is missing. Do not call a debug-signed APK production-ready. App Bundle upload, Play signing enrollment and rollout remain explicit manual actions outside these scripts.

## AdMob and telemetry

Debug always enables official Google test ads and rejects ADS_MODE=production. Existing app logic still enforces UMP and first-session eligibility; the script does not manufacture ad requests. Release builds default to **ads off**, preserving the app's safe M06 default. Select test ads with `ADS_MODE=test`. Only after the existing documented AdMob release gates pass, explicitly run:

```bash
ADS_MODE=production ADS_PRODUCTION_READY=true scripts/build-android.sh appbundle
```

Production units remain sourced from immutable config/ads_util.dart. No unit IDs or frequency thresholds are copied into scripts. Build scripts set ENABLE_TELEMETRY=false. Existing `scripts/build_play_bundle.sh` also now uses the pinned SDK/JDK; its existing explicit internal-test/public-live-ads/public-no-ads modes remain available.

## CI

.github/workflows/android.yml runs on macos-15, uses exact Temurin 17.0.21+9 and the FVM project pin, resolves locked packages, checks formatting/analysis/tests and builds a debug APK with test ads. It never uses release signing, uploads release artifacts, changes consent, or accepts licenses automatically. Hosted runners must already have valid Android SDK licenses; otherwise it fails visibly. The runner image, FVM installer package and platform-tools remain rolling infrastructure, not fully hermetic pins. CI was added but has not run in this environment.

## Troubleshooting

- Wrong Flutter: run setup and use scripts/flutter.sh, not PATH flutter. Do not run flutter upgrade.
- Missing API 36/SDK tools: run setup --install after accepting licenses interactively.
- JDK 25 selected elsewhere: use these scripts; resolve conflicting legacy Flutter settings if doctor reports them. Do not use --android-skip-build-dependency-validation.
- Gradle cache permission error: repair the cache's managed permissions with your administrator; the scripts do not chown it or delete global caches.
- Stale artifact rejection: inspect the build log; remove only the generated output via scripts/clean.sh and rebuild. Never accept an old APK as evidence of the current command.
- Firebase/AdMob mismatch: restore the trusted original/native copies; do not create replacement platform apps.
