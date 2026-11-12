#!/usr/bin/env bash
# Sourced by project scripts; compatible with macOS Bash 3.2.
set -euo pipefail
PILOGY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
# shellcheck source=scripts/toolchain.env
source "$PILOGY_ROOT/scripts/toolchain.env"
cd "$PILOGY_ROOT"
for generated_dir in .tooling .tooling/gems .tooling/bootstrap-gems .tooling/bundle-config .tooling/bundle-user .tooling/flutter-config .fvm; do
  if [[ -L "$PILOGY_ROOT/$generated_dir" ]]; then
    printf 'FAIL: refusing writes through symlinked tool directory: %s\n' "$generated_dir" >&2
    exit 1
  fi
done
export COCOAPODS_DISABLE_STATS=true
export BUNDLE_GEMFILE="$PILOGY_ROOT/Gemfile"
export BUNDLE_PATH="$PILOGY_ROOT/.tooling/gems"
export BUNDLE_APP_CONFIG="$PILOGY_ROOT/.tooling/bundle-config"
export BUNDLE_USER_HOME="$PILOGY_ROOT/.tooling/bundle-user"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }
pass() { printf 'PASS: %s\n' "$*"; }
need_python() { command -v python3 >/dev/null || fail 'Install Python 3 (brew install python@3.13), then rerun.'; }
mac_only() { [[ "$(uname -s)" == Darwin ]] || fail 'setup/iOS builds require macOS.'; }
flutter_sdk() {
  need_python
  PILOGY_SDK="$PILOGY_ROOT/.fvm/flutter_sdk"
  [[ -x "$PILOGY_SDK/bin/flutter" ]] || fail 'Pinned SDK missing. Run scripts/setup.sh --install.'
  python3 "$PILOGY_ROOT/scripts/environment_checks.py" flutter "$PILOGY_SDK" || fail 'Pinned SDK mismatch. Run fvm install and fvm use --skip-pub-get; do not upgrade globally.'
  # Use only binaries from this SDK, never global Flutter/Dart.
  export PATH="$PILOGY_SDK/bin:$PATH"
}
flutter_cmd() { XDG_CONFIG_HOME="$PILOGY_ROOT/.tooling/flutter-config" "$PILOGY_SDK/bin/flutter" "$@"; }
dart_cmd() { "$PILOGY_SDK/bin/dart" "$@"; }
select_java() {
  local candidate actual
  local candidates=()
  [[ -z "${PILOGY_JAVA_HOME:-}" ]] || candidates+=("$PILOGY_JAVA_HOME")
  if [[ "$(uname -s)" == Darwin ]]; then
    candidate="$(/usr/libexec/java_home -v "$PILOGY_JAVA" 2>/dev/null || true)"
    [[ -z "$candidate" ]] || candidates+=("$candidate")
  fi
  [[ -z "${JAVA_HOME:-}" ]] || candidates+=("$JAVA_HOME")
  candidates+=(/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home /usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home)
  for candidate in "${candidates[@]}"; do
    [[ -x "$candidate/bin/java" ]] || continue
    actual="$("$candidate/bin/java" -version 2>&1 | head -n 1)"
    if [[ "$actual" == *\""$PILOGY_JAVA"\"* ]]; then
      export JAVA_HOME="$candidate"
      export PATH="$JAVA_HOME/bin:$PATH"
      return 0
    fi
  done
  return 1
}
android_sdk() {
  if [[ -n "${ANDROID_HOME:-}" && -n "${ANDROID_SDK_ROOT:-}" && "$ANDROID_HOME" != "$ANDROID_SDK_ROOT" ]]; then
    warn 'ANDROID_HOME and ANDROID_SDK_ROOT disagree; make them identical.'
    return 1
  fi
  local candidate
  for candidate in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" "$HOME/Library/Android/sdk" /opt/homebrew/share/android-commandlinetools /usr/local/share/android-commandlinetools; do
    [[ -n "$candidate" && -d "$candidate" ]] || continue
    export ANDROID_HOME="$candidate" ANDROID_SDK_ROOT="$candidate"
    return 0
  done
  return 1
}
sdkmanager_path() {
  local candidate
  for candidate in "$ANDROID_HOME/cmdline-tools/$PILOGY_COMMAND_TOOLS/bin/sdkmanager" "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"; do
    [[ -x "$candidate" ]] || continue
    if python3 "$PILOGY_ROOT/scripts/environment_checks.py" command-tools "$(dirname "$(dirname "$candidate")")" >/dev/null; then
      printf '%s\n' "$candidate"; return 0
    fi
  done
  return 1
}
sdk_install() {
  local manager="$1"; shift
  local cli
  cli="$(dirname "$manager")/android"
  if [[ -x "$cli" ]] && grep -q 'Android CLI will be used instead' "$manager"; then
    "$cli" --no-metrics --sdk="$ANDROID_HOME" sdk install "$@" </dev/null
  else
    "$manager" --sdk_root="$ANDROID_HOME" "$@" </dev/null
  fi
}

select_ruby() {
  local candidate actual
  for candidate in "${PILOGY_RUBY_EXECUTABLE:-}" "$PILOGY_ROOT/.tooling/ruby/bin/ruby" /opt/homebrew/opt/ruby@3.3/bin/ruby /usr/local/opt/ruby/bin/ruby /usr/local/opt/ruby@3.3/bin/ruby "$(command -v ruby || true)"; do
    [[ -n "$candidate" && -x "$candidate" ]] || continue
    actual="$("$candidate" -e 'print RUBY_VERSION' 2>/dev/null || true)"
    if [[ "$actual" == 3.3.0 ]]; then
      PILOGY_RUBY_BIN="$candidate"
      export PATH="$(dirname "$candidate"):$PATH"
      export GEM_HOME="$PILOGY_ROOT/.tooling/bootstrap-gems"
      # Keep Ruby's default gems available, isolate any installed bootstrap gems.
      export GEM_PATH="$GEM_HOME:$("$candidate" -rrubygems -e 'print Gem.default_path.join(":")')"
      return 0
    fi
  done
  return 1
}
bundle_cmd() {
  "$PILOGY_RUBY_BIN" -rrubygems -e 'load Gem.bin_path("bundler", "bundle", "= 2.5.4")' -- "$@"
}
pod_cmd() { bundle_cmd exec pod "$@"; }
resolve_packages() { flutter_cmd pub get --enforce-lockfile; }
configure_android_local() {
  python3 "$PILOGY_ROOT/scripts/environment_checks.py" local-properties "$ANDROID_HOME" "$PILOGY_SDK"
  python3 "$PILOGY_ROOT/scripts/environment_checks.py" flutter-android-config "$JAVA_HOME" "$ANDROID_HOME"
}
build_api() {
  if [[ -z "${API_BASE_URL:-}" ]]; then
    [[ "$1" == production ]] || fail 'Set API_BASE_URL explicitly for debug/simulator (e.g. http://10.0.2.2:3000/api/v1).'
    API_BASE_URL=https://pilogy.vercel.app/api/v1
  fi
  python3 - "$API_BASE_URL" <<'PY'
import sys
from urllib.parse import urlparse
u=urlparse(sys.argv[1])
if u.scheme not in ('http','https') or not u.hostname or u.username or u.password or u.query or u.fragment:
    raise SystemExit('FAIL: API_BASE_URL must be an HTTP(S) base URL without credentials, query or fragment.')
PY
}
ad_flags() {
  AD_FLAGS=(--dart-define=ENABLE_TELEMETRY=false)
  local mode="${ADS_MODE:-off}"
  if [[ "$1" == debug ]]; then
    [[ "$mode" != production ]] || fail 'Production ads are forbidden in debug/simulator.'
    mode=test
  fi
  case "$mode" in
    off) AD_FLAGS+=(--dart-define=ADS_ENABLED=false) ;;
    test) AD_FLAGS+=(--dart-define=ADS_ENABLED=true --dart-define=ADS_USE_TEST_ADS=true) ;;
    production)
      [[ "${ADS_PRODUCTION_READY:-false}" == true ]] || fail 'Complete docs/admob-testing.md; explicitly set ADS_PRODUCTION_READY=true for validated production ads.'
      AD_FLAGS+=(--dart-define=ADS_ENABLED=true --dart-define=ADS_USE_TEST_ADS=false --dart-define=ADS_PRODUCTION_READY=true)
      ;;
    *) fail 'ADS_MODE must be off, test, or production.' ;;
  esac
  printf 'Ad mode: %s\n' "$mode"
}
