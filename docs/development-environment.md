# PILOGY development environment

The application remains in this directory; do not create a nested Flutter project. Android and iOS identifiers remain `mt.numerology`. Backend APIs, app logic, UI, original Firebase/AdMob files and signing configuration are unchanged by this work.

## Baseline and verification status

Inspected on November 12, 2026: macOS **15.7.9 (24G830)**, Intel **x86_64**. The user reports successful local application builds. This execution environment could inspect the installation but could not repeat those builds. The following pins preserve detected versions; they are not evidence of a newly tested cross-machine toolchain.

| Component | Baseline | Evidence / notes |
| --- | --- | --- |
| Flutter | **3.47.9 stable** | Installed SDK `flutter.version.json`; revision `c197ca5199e9ee5661e865596c9c07294dfab51c` |
| Dart | **3.13.7** | Bundled SDK metadata; scripts never choose global Dart |
| FVM | Supported FVM CLI with `install/use --skip-pub-get` | Not installed here. Setup installs Homebrew's FVM if missing; FVM supplies its own runtime bootstrap |
| pubspec constraints | Dart >=3.7.0 <4.0.0; Flutter >=3.29.0 | Preserved |
| Resolved lock constraints | Dart >=3.13.0 <4.0.0; Flutter >=3.47.0 | Existing pubspec.lock is authoritative and retained |
| Java | **17.0.21**, detected Temurin build **+9** | Installed alongside global Java 25.0.5+8, which is not selected for this project |
| Gradle | **8.14**, `all` distribution | Existing wrapper; SHA-256 pinned from the inspected cached ZIP |
| AGP / Kotlin | **8.11.1 / 2.2.20** | Existing settings.gradle, unchanged |
| Google Services / Crashlytics Gradle plugins | **4.3.15 / 2.9.9** | Existing settings.gradle, unchanged |
| compile / target / minimum Android SDK | **36 / 36 / 24** | compileSdk in app Gradle; target/min defaults verified in pinned FlutterExtension.kt |
| Build Tools | **35.0.0** | Existing installed version and AGP 8.11 default; now explicit in app Gradle |
| Command-line Tools | **23.0** | Installed `latest/source.properties` identifies this numeric package |
| NDK | **28.2.13676358** | Pinned Flutter default, existing installation |
| CMake | **3.22.1** | Existing installation and jni native build-command/CMakeCache evidence; generated local.properties selects it |
| Platform Tools | Installed **33.0.2**, adb 1.0.41 | Required but not exactly pinned: sdkmanager exposes the moving `platform-tools` package. Does not select compiler dependencies |
| Xcode | **26.3 (17C529)** | `xcodebuild -version`; exact baseline checked for iOS |
| Xcode minimum macOS | **15.6** | Installed Xcode Info.plist LSMinimumSystemVersion; observed machine is 15.7.9 |
| iOS device / simulator SDK | **26.2 / 26.2** | `xcodebuild -showsdks` |
| iOS deployment target | **15.0** | Existing Podfile and Xcode build configurations, unchanged |
| Ruby | **3.3.0** | Existing non-system installation selected; system Ruby 2.6.10 is not used by the new workflow |
| Bundler | **2.5.4** | Installed with Ruby 3.3.0; system Bundler 1.17.2 is not selected |
| CocoaPods | **1.15.2** | Existing global `pod --version`; pinned in Gemfile |

The installed CocoaPods executable originally runs under system Ruby 2.6.10. Pairing that same CocoaPods version with detected non-system Ruby 3.3.0 is an isolated proposed workflow, not a verified existing native bundle. No Gemfile.lock or ios/Podfile.lock was supplied. Attempts to resolve the Ruby lock failed because RubyGems was unreachable; no lockfiles were invented. Native iOS dependency versions therefore remain unresolved. Review and commit genuine locks after the first successful setup on an unrestricted Mac.

Important existing Dart lock entries include google_mobile_ads 6.0.0, Firebase Core 2.24.2, Analytics 10.8.0, Crashlytics 3.4.9, Messaging 14.7.10 and native jni 1.1.2. The full lockfile, not this summary, pins transitive versions. Existing pubspec.lock was not regenerated or upgraded. Inspected iOS plugin podspecs request Firebase/CoreOnly, Analytics, Crashlytics and Messaging **10.18.0** (firebase_core's default), Google-Mobile-Ads-SDK **~>12.2.0**, Flutter and webview_flutter_wkwebview. UMP and other transitive native versions still require a real Podfile.lock; do not infer an exact resolution from these constraints.

## Version management and process isolation

`.fvmrc` selects the exact Flutter release. `scripts/toolchain.env` records the inspected native baseline; doctor detects source drift. Scripts invoke `.fvm/flutter_sdk/bin/flutter` and its bundled Dart only after checking SDK version, channel and revision. No global Flutter fallback or `fvm global` is used. A PATH Flutter warning is informational: the pinned SDK takes precedence.

Setup uses Homebrew FVM instead of bootstrapping FVM through an arbitrary global Dart. Existing FVM installations are reused. Homebrew manages its executable/runtime dependency; a full global Flutter is not needed. Homebrew installations need a user-writable prefix. If Homebrew is absent, its potentially privileged first installation remains manual. Intel bottle availability may be limited; do not force an unsupported Homebrew installation. FVM also documents standalone macOS x64/arm64 installers; install one manually if Homebrew cannot supply FVM, then rerun setup. No existing manager or SDK is removed.

Java is selected by exact **17.0.21** using `PILOGY_JAVA_HOME`, macOS java_home, existing JAVA_HOME or a non-linked Homebrew JDK directory. No global Java configuration or system symlinks are changed. Homebrew openjdk@17 is only a bootstrap candidate: if its current patch is not 17.0.21, setup stops and asks for the exact archived Temurin version. No newer patch is silently accepted.

Flutter can prefer Android Studio's bundled Java over JAVA_HOME. To avoid that, Flutter commands receive a project-local XDG configuration containing the selected JDK and Android SDK paths under ignored `.tooling/`. Existing legacy `~/.flutter_settings` has higher precedence in Flutter: setup/doctor refuse conflicting legacy settings and ask the developer to reconcile them manually. They never edit them. Local absolute paths only appear in ignored generated files, not tracked source.

Ruby 3.3.0 is selected from `PILOGY_RUBY_EXECUTABLE`, an existing installation, or `.tooling/ruby`. If needed, setup uses Homebrew ruby-build to compile exactly 3.3.0 into the project, without rbenv global changes. Bundler bootstrap gems and application gems live under `.tooling/`. CocoaPods is always `bundle exec pod`, invoked through the selected Ruby/Bundler. Do not use global `pod update`.

## Standard commands

```bash
scripts/setup.sh --install           # fresh Mac; both platforms
scripts/setup.sh                    # repeat setup without new Homebrew/Ruby/SDK installs
scripts/doctor.sh --all
scripts/doctor.sh --android
scripts/doctor.sh --ios
scripts/flutter.sh pub get --enforce-lockfile
scripts/flutter.sh analyze
.fvm/flutter_sdk/bin/dart format .
scripts/flutter.sh test
python3 scripts/test_environment_scripts.py
scripts/clean.sh --dry-run
scripts/clean.sh                     # generated build/ and .dart_tool/ only
scripts/clean.sh --flutter-clean --reinstall
```

Setup supports `--android` and `--ios`. It installs only absent SDK package directories, checks existing license records against installed package metadata without answering prompts, and never invokes sudo or edits shell startup files. It always rechecks locked Flutter packages; `bundle check` avoids reinstalling a satisfied bundle. Existing Pods use `pod install --deployment`. An initial iOS setup without locks explicitly warns before creating real locks; subsequent runs enforce them.

Clean refuses symlinked generated directories and Git-tracked contents. Optional Flutter clean preflights known generated paths; dependency reinstall retains lockfiles. It never targets original configuration, keystores, source assets, certificates or provision profiles. It does not clear application SQLite databases/preferences.

## Configuration and secrets

Restore `config/google-services.json`, `config/GoogleService-Info.plist` and immutable `config/ads_util.dart` from the project's trusted source. Native Firebase copies must match their originals byte-for-byte. Setup verifies rather than overwriting mismatches. AdMob Android App ID is derived by Gradle; iOS Info.plist must already match the existing projection (`scripts/sync_admob_config.py` is an explicit repair action, not automatically run).

App name, package/bundle IDs and portrait settings are preserved. Firebase collection stays off by default. Build scripts explicitly disable telemetry. API_BASE_URL is a non-secret dart-define, not a backend modification; do not embed credentials in a URL. Debug/simulator require an explicit URL, while release/appbundle default to the existing production API.

Android keystores/passwords, Apple signing materials, local SDK directories and generated configuration are ignored. Gradle wrapper launchers/JAR now have ignore exceptions so a clone can actually use the wrapper. Preserve pubspec.lock; commit genuine Gemfile.lock and Podfile.lock when resolved. This workspace's scripts do not perform a Git commit or stage secrets.

## Actual results and remaining gates

See [verification results](verification/environment/RESULTS.md). Shell syntax and isolated script contracts pass. FVM installation failed due to Homebrew-prefix/cache permissions; the pinned SDK was not installed. All required Android SDK package directories were present. Gradle cache locking/execution was blocked; license acceptance is verified read-only against SDK records. RubyGems was unreachable. Flutter pub get/analyze/tests and Android/iOS builds were attempted through the pinned entry points and stopped at the missing SDK gate. No new successful build, device run or iOS native resolution is claimed.

Fresh-machine installation, a successful second setup, Apple Silicon behavior and CI remain unverified. This is a version-pinned workflow with visible release gates, not a claim of complete reproducibility. Toolchain or lock changes require a separately reviewed update and actual native build validation.

Command-line Tools 23.0 includes the new Android CLI and a deprecated sdkmanager shim. Setup uses `android --no-metrics --sdk=... sdk install` when that shim is detected, otherwise legacy sdkmanager. Acceptance records are checked before and after package installation; nothing writes them. See [Android CLI SDK commands](https://developer.android.com/tools/agents/android-cli/commands/sdk).

References: [FVM installation](https://fvm.app/documentation/getting-started/installation), [FVM commands](https://fvm.app/documentation/guides/basic-commands), [AGP 8.11 requirements](https://developer.android.com/build/releases/agp-8-11-0-release-notes), [CocoaPods with Gemfile](https://guides.cocoapods.org/using/a-gemfile.html).
