#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib/environment.sh
source "$(dirname "$0")/lib/environment.sh"
flutter_clean=false
reinstall=false
dry=false
for arg in "$@"; do
  case "$arg" in --flutter-clean) flutter_clean=true ;; --reinstall) reinstall=true ;; --dry-run) dry=true ;; *) fail 'Usage: scripts/clean.sh [--dry-run] [--flutter-clean] [--reinstall]' ;; esac
done
need_python
if [[ "$dry" == true ]]; then
  python3 scripts/environment_checks.py clean --dry-run
  printf 'Would run Flutter clean: %s; locked dependency reinstall: %s\n' "$flutter_clean" "$reinstall"
  exit 0
fi
# Only the fixed generated-directory allowlist can be removed; symlinks/tracked files block deletion.
python3 scripts/environment_checks.py clean
if [[ "$flutter_clean" == true ]]; then
  python3 - <<'PY'
from pathlib import Path
import subprocess
root=Path.cwd()
paths=['ios/Flutter/ephemeral','ios/Flutter/Generated.xcconfig','ios/Flutter/flutter_export_environment.sh',
       'ios/.symlinks','.flutter-plugins','.flutter-plugins-dependencies',
       'android/local.properties','macos/Flutter/ephemeral','linux/flutter/ephemeral','windows/flutter/ephemeral']
for item in paths:
    p=root/item
    if p.is_symlink(): raise SystemExit('FAIL: refusing Flutter clean with symlinked generated path: '+item)
    for parent in p.parents:
        if parent==root: break
        if parent.is_symlink(): raise SystemExit('FAIL: generated parent is a symlink')
    result=subprocess.run(['git','ls-files','--',item],capture_output=True,text=True)
    if result.returncode==0 and result.stdout.strip():
        raise SystemExit('FAIL: tracked generated files would be cleaned: '+item)
PY
  flutter_sdk
  flutter_cmd clean
fi
if [[ "$reinstall" == true ]]; then
  flutter_sdk
  resolve_packages
  if [[ "$(uname -s)" == Darwin && -f ios/Podfile.lock ]]; then
    select_ruby || fail 'Ruby unavailable; scripts/setup.sh --install'
    export BUNDLE_FROZEN=true
    (cd ios && pod_cmd install --deployment)
  fi
fi
pass 'Generated artifacts cleaned; configuration, assets, signing and local app databases were not targeted.'
