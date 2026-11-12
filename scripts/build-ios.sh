#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib/environment.sh
source "$(dirname "$0")/lib/environment.sh"
[[ $# -eq 1 ]] || fail 'Usage: scripts/build-ios.sh simulator|release'
mac_only
case "$1" in
  simulator) api_mode=development; ad_mode=debug ;;
  release) api_mode=production; ad_mode=release ;;
  *) fail 'Usage: scripts/build-ios.sh simulator|release' ;;
esac
build_api "$api_mode"
ad_flags "$ad_mode"
flutter_sdk
select_ruby || fail 'Run scripts/setup.sh --install to prepare project-local Ruby/Bundler/Pods.'
[[ -f Gemfile.lock && -f ios/Podfile.lock ]] || fail 'iOS lockfiles missing. Run setup on a working Mac, review and commit the generated locks first.'
export BUNDLE_FROZEN=true
resolve_packages
(cd ios && pod_cmd install --deployment)
scripts/doctor.sh --ios
started="$(python3 -c 'import time; print(time.time_ns())')"
if [[ "$1" == simulator ]]; then
  flutter_cmd build ios --simulator --debug --no-codesign --no-pub --dart-define="API_BASE_URL=$API_BASE_URL" "${AD_FLAGS[@]}"
  python3 scripts/environment_checks.py artifact app "$started" build/ios/iphonesimulator/Runner.app/Info.plist
  [[ -f build/ios/iphonesimulator/Runner.app/Runner ]] || fail 'Simulator app executable missing'
  printf 'Output: %s/build/ios/iphonesimulator/Runner.app\n' "$PILOGY_ROOT"
else
  [[ -f "${IOS_EXPORT_OPTIONS_PLIST:-}" ]] || fail 'Set IOS_EXPORT_OPTIONS_PLIST to your reviewed Apple export options. See docs/build-ios.md; signing is never fabricated.'
  identities="$(security find-identity -v -p codesigning 2>/dev/null)" || fail 'Cannot access signing identities; unlock/configure your signing keychain manually.'
  [[ "$identities" != *'0 valid identities found'* ]] || fail 'No valid signing identities. Configure your Apple Developer account in Xcode.'
  flutter_cmd build ipa --release --no-pub --export-options-plist="$IOS_EXPORT_OPTIONS_PLIST" --dart-define="API_BASE_URL=$API_BASE_URL" "${AD_FLAGS[@]}"
  python3 - "$started" <<'PY'
from pathlib import Path
import subprocess, sys
files=[p for p in Path('build/ios/ipa').glob('*.ipa') if p.stat().st_mtime_ns>=int(sys.argv[1])]
if len(files)!=1: raise SystemExit('FAIL: expected exactly one fresh IPA; inspect build/ios/ipa')
subprocess.run([sys.executable,'scripts/environment_checks.py','artifact','ipa',sys.argv[1],str(files[0])],check=True)
print('Output: '+str(files[0].resolve()))
PY
fi
