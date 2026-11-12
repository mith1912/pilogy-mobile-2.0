#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib/environment.sh
source "$(dirname "$0")/lib/environment.sh"
mode="${1:---all}"
case "$mode" in --android) platform=android ;; --ios) platform=ios ;; --all) platform=all ;; *) fail 'Usage: scripts/doctor.sh [--android|--ios|--all]' ;; esac
[[ $# -le 1 ]] || fail 'Too many arguments'
need_python
failures=0
check() {
  local label="$1"; shift
  if "$@"; then pass "$label"; else
    printf 'FAIL: %s\n' "$label" >&2
    failures=$((failures + 1))
  fi
}
printf 'PILOGY environment doctor (%s)\nOS: %s; CPU: %s\n' "$platform" "$(uname -s)" "$(uname -m)"
if [[ "$(uname -s)" == Darwin ]]; then sw_vers; else
  if [[ "$platform" != android ]]; then check 'iOS requires macOS' false; fi
fi
case "$(uname -m)" in arm64|x86_64|aarch64) pass 'CPU supported (native SDK required)' ;; *) check 'Unsupported CPU; use Intel or Apple Silicon Mac' false ;; esac
if command -v fvm >/dev/null; then
  check 'FVM executable (fix: scripts/setup.sh --install)' python3 scripts/run_bounded.py 20 fvm --version
else check 'FVM missing; run scripts/setup.sh --install' false; fi
global_flutter="$(command -v flutter || true)"
sdk_ok=false
if (flutter_sdk); then
  flutter_sdk
  sdk_ok=true
  check "Flutter runtime, expected $PILOGY_FLUTTER stable" python3 scripts/run_bounded.py 40 "$PILOGY_SDK/bin/flutter" --version --machine
  check "Bundled Dart runtime, expected $PILOGY_DART" python3 scripts/run_bounded.py 20 "$PILOGY_SDK/bin/dart" --version
else check 'Pinned SDK absent/wrong; run scripts/setup.sh --install' false; fi
# Warn about the original PATH SDK without executing or selecting it.
if [[ -n "$global_flutter" && "$global_flutter" != "$PILOGY_ROOT/.fvm/flutter_sdk/bin/flutter" ]]; then
  global_version="$(python3 - "$global_flutter" <<'PY2'
from pathlib import Path
import json, sys
try:
    binary=Path(sys.argv[1]).resolve()
    print(json.loads((binary.parent/'cache/flutter.version.json').read_text()).get('frameworkVersion','unknown'))
except (OSError,ValueError): print('unknown')
PY2
)"
  warn "PATH Flutter version $global_version ($global_flutter) is ignored; expected $PILOGY_FLUTTER stable. Use scripts/flutter.sh or fvm flutter."
fi
check 'Project pins, IDs and Firebase references (restore config/ from secure project source)' python3 scripts/environment_checks.py project "$platform"
check 'AdMob configuration and native App IDs (see scripts/verify_admob.py)' python3 scripts/verify_admob.py
if [[ -f .dart_tool/package_config.json ]]; then
  pass 'Flutter package configuration exists; build scripts enforce pubspec.lock again'
else check 'Dependencies unresolved; run scripts/setup.sh' false; fi
if [[ "$platform" != ios ]]; then
  java_ok=false
  if select_java; then
    java_ok=true
    check "Java expected $PILOGY_JAVA (process-local selection)" "$JAVA_HOME/bin/java" -version
  else check "JDK $PILOGY_JAVA missing; restore Temurin 17.0.21 or set PILOGY_JAVA_HOME" false; fi
  if android_sdk; then
    printf 'Android SDK: %s\n' "$ANDROID_HOME"
    if [[ "$java_ok" == true ]]; then
      check 'Flutter uses project-local Java/SDK settings, without changing global config' python3 scripts/environment_checks.py flutter-android-check "$JAVA_HOME" "$ANDROID_HOME"
    fi
    check 'Required Android SDK packages' python3 scripts/environment_checks.py packages "$ANDROID_HOME"
    if manager="$(sdkmanager_path)"; then
      pass "Command-line Tools $PILOGY_COMMAND_TOOLS"
      check 'Android SDK license acceptance (read-only; review missing terms in Android Studio)' python3 scripts/environment_checks.py licenses "$ANDROID_HOME"
    else check "Command-line Tools $PILOGY_COMMAND_TOOLS missing; scripts/setup.sh --install" false; fi
  else check 'Android SDK missing/conflicting; set ANDROID_HOME and ANDROID_SDK_ROOT to the same directory' false; fi
  if [[ "$java_ok" == true ]]; then
    check "Gradle wrapper expected $PILOGY_GRADLE (no global Gradle)" python3 scripts/run_bounded.py 45 bash android/gradlew --version
  fi
  if [[ "$sdk_ok" == true ]]; then
    check 'Pinned Flutter Android defaults' python3 - "$PILOGY_SDK" <<'PY'
import pathlib, re, sys
s=(pathlib.Path(sys.argv[1])/'packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt').read_text()
for name, expected in [('minSdkVersion','24'),('targetSdkVersion','36'),('ndkVersion','28.2.13676358')]:
    match=re.search(r'val '+name+r': \w+ = "?([\d.]+)',s)
    if not match or match[1]!=expected: raise SystemExit('FAIL: Flutter '+name+' differs from inspected baseline')
print('minSdk=24 targetSdk=36 NDK=28.2.13676358')
PY
  fi
fi
if [[ "$platform" != android ]]; then
  if [[ "$(uname -s)" == Darwin ]]; then
    check 'Xcode selected (use DEVELOPER_DIR for this process or select in Xcode Settings)' xcode-select -p
    if xcode_actual="$(xcodebuild -version 2>/dev/null)"; then
      printf '%s\n' "$xcode_actual"
      if [[ "$xcode_actual" == "Xcode $PILOGY_XCODE"$'\n'"Build version $PILOGY_XCODE_BUILD" ]]; then pass 'Exact detected Xcode baseline'; else
        check "Expected Xcode $PILOGY_XCODE ($PILOGY_XCODE_BUILD); set DEVELOPER_DIR to that installation. No automatic upgrade." false
      fi
    else check 'Install full Xcode manually from Apple Developer downloads' false; fi
    check 'Xcode license/first-launch components (open Xcode and complete setup manually)' xcodebuild -checkFirstLaunchStatus
    if sdks="$(xcodebuild -showsdks 2>/dev/null)" && [[ "$sdks" == *iphonesimulator* && "$sdks" == *iphoneos* ]]; then
      pass 'iOS device and simulator SDKs available'
    else check 'iOS SDKs missing; install components in Xcode Settings' false; fi
  fi
  if select_ruby; then
    check "Ruby expected $PILOGY_RUBY" "$PILOGY_RUBY_BIN" --version
    check "Bundler expected $PILOGY_BUNDLER (project gems)" bundle_cmd --version
    if [[ -f Gemfile.lock ]]; then
      check 'Frozen local Ruby dependency bundle (run scripts/setup.sh)' bundle_cmd check
      check "CocoaPods expected $PILOGY_COCOAPODS" pod_cmd --version
    else check 'Gemfile.lock missing: run setup to resolve, review and commit the genuine lockfile' false; fi
  else check "Ruby $PILOGY_RUBY missing; scripts/setup.sh --install uses project-local ruby-build" false; fi
  if [[ -f ios/Podfile.lock ]]; then pass 'Podfile.lock present (pod install --deployment enforces it)'; else
    check 'ios/Podfile.lock absent: resolve Pods on a working Mac, review and commit before reproducibility can be claimed' false
  fi
fi
printf '\nDoctor: %s mandatory check(s) failed. Android/iOS signing is validated separately by release builds.\n' "$failures"
[[ "$failures" -eq 0 ]]
