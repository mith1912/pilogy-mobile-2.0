#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib/environment.sh
source "$(dirname "$0")/lib/environment.sh"
[[ $# -eq 1 ]] || fail 'Usage: scripts/build-android.sh debug|release|appbundle'
mode="$1"
case "$mode" in
  debug) api_mode=development; ad_mode=debug; kind=apk; artifact=build/app/outputs/flutter-apk/app-debug.apk; build=(apk --debug) ;;
  release) api_mode=production; ad_mode=release; kind=apk; artifact=build/app/outputs/flutter-apk/app-release.apk; build=(apk --release) ;;
  appbundle) api_mode=production; ad_mode=release; kind=aab; artifact=build/app/outputs/bundle/release/app-release.aab; build=(appbundle --release) ;;
  *) fail 'Usage: scripts/build-android.sh debug|release|appbundle' ;;
esac
build_api "$api_mode"
ad_flags "$ad_mode"
flutter_sdk
select_java || fail "JDK $PILOGY_JAVA required; scripts/setup.sh --install"
android_sdk || fail 'Android SDK missing/conflicting; scripts/setup.sh --install'
configure_android_local
resolve_packages
scripts/doctor.sh --android
if [[ "$mode" != debug ]]; then python3 scripts/environment_checks.py signing; fi
started="$(python3 -c 'import time; print(time.time_ns())')"
flutter_cmd build "${build[@]}" --no-pub --dart-define="API_BASE_URL=$API_BASE_URL" "${AD_FLAGS[@]}"
python3 scripts/environment_checks.py artifact "$kind" "$started" "$artifact"
printf 'Output: %s/%s\n' "$PILOGY_ROOT" "$artifact"
[[ "$mode" == debug ]] || printf 'Signing and archive checks succeeded; store/AdMob release gates still apply.\n'
