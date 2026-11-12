#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib/environment.sh
source "$(dirname "$0")/lib/environment.sh"

bundle_mode="${1:-internal-test}"
if (( $# > 0 )); then shift; fi
case "$bundle_mode" in
  internal-test)
    ad_flags=(--dart-define=ADS_ENABLED=true --dart-define=ADS_USE_TEST_ADS=true)
    ;;
  public-live-ads)
    # Explicit production invocation only; defaults remain test/off.
    # Complete docs/admob-testing.md before distributing this artifact.
    ad_flags=(
      --dart-define=ADS_ENABLED=true
      --dart-define=ADS_USE_TEST_ADS=false
      --dart-define=ADS_PRODUCTION_READY=true
      --dart-define=ADS_BANNER_ENABLED=true
      --dart-define=ADS_INTERSTITIAL_ENABLED=true
      --dart-define=ADS_APP_OPEN_ENABLED=true
      --dart-define=ADS_NATIVE_ENABLED=true
    )
    ;;
  public-no-ads)
    ad_flags=(--dart-define=ADS_ENABLED=false)
    ;;
  *)
    echo 'Usage: bash scripts/build_play_bundle.sh [internal-test|public-live-ads|public-no-ads] [flutter build options...]' >&2
    exit 2
    ;;
esac

python3 - <<'PY'
from pathlib import Path
import re
p = Path('android/key.properties')
if not p.is_file():
    raise SystemExit('Fill android/key.properties locally before building. See docs/google-play-release.md.')
s = p.read_text()
for key in ('storeFile', 'keyAlias', 'storePassword', 'keyPassword'):
    if not re.search(r'^' + key + r'[ \t]*=[ \t]*\S[^\r\n]*$', s, re.MULTILINE):
        raise SystemExit('Signing credentials are incomplete. Fill android/key.properties locally; passwords are never printed.')
if not Path('config/keystore.jks').is_file():
    raise SystemExit('config/keystore.jks is missing.')
PY

# Keep each acceptance command visible; no secrets are passed on command lines.
flutter_sdk
select_java || fail "JDK $PILOGY_JAVA required; scripts/setup.sh --install"
android_sdk || fail 'Android SDK unavailable; scripts/setup.sh --install'
configure_android_local
build_api production
scripts/doctor.sh --android
python3 scripts/verify_admob.py
resolve_packages
dart_cmd format .
flutter_cmd analyze
flutter_cmd test
flutter_cmd build appbundle --release "$@" "${ad_flags[@]}" --dart-define="API_BASE_URL=$API_BASE_URL" --dart-define=ENABLE_TELEMETRY=false
python3 scripts/verify_play_bundle.py
printf '\nBundle mode: %s\nOutput: build/app/outputs/bundle/release/app-release.aab\n' "$bundle_mode"
