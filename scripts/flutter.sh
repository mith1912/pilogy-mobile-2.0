#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib/environment.sh
source "$(dirname "$0")/lib/environment.sh"
case "${1:-}" in upgrade|downgrade|channel|config) fail 'Global SDK changes are not supported. Review/update the project pins explicitly.' ;; esac
flutter_sdk
exec env XDG_CONFIG_HOME="$PILOGY_ROOT/.tooling/flutter-config" "$PILOGY_SDK/bin/flutter" "$@"
