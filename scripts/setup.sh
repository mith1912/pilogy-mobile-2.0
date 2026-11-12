#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib/environment.sh
source "$(dirname "$0")/lib/environment.sh"
install=false
platform=all
for arg in "$@"; do
  case "$arg" in --install) install=true ;; --android) platform=android ;; --ios) platform=ios ;; --all) platform=all ;; *) fail 'Usage: scripts/setup.sh [--install] [--android|--ios|--all]' ;; esac
done
mac_only
case "$(uname -m)" in arm64|x86_64) pass "macOS $(sw_vers -productVersion), CPU $(uname -m)" ;; *) fail 'Unsupported Mac architecture' ;; esac
xcode-select -p >/dev/null 2>&1 || fail 'Install Command Line Tools manually: xcode-select --install. Complete the dialog, then rerun.'
# No shell-profile edits, sudo, global FVM selection, Java/Ruby replacement or licenses accepted here.
if ! command -v brew >/dev/null; then
  for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$brew_bin" ]]; then export PATH="$(dirname "$brew_bin"):$PATH"; break; fi
  done
fi
command -v brew >/dev/null || fail 'Install Homebrew manually from https://brew.sh (its installer can require administrator approval), then rerun. This script never invokes sudo.'
brew_install() {
  [[ "$install" == true ]] || fail "Missing dependency: $*. Rerun scripts/setup.sh --install to authorize non-sudo Homebrew/project-local installation."
  HOMEBREW_NO_AUTO_UPDATE=1 brew install "$@"
}
command -v python3 >/dev/null || brew_install python@3.13
need_python
command -v fvm >/dev/null || brew_install fvm
# Homebrew FVM supplies its executable runtime; no PATH Dart bootstrap is used.
# install/use affect the FVM cache and this project, never fvm global.
fvm install "$PILOGY_FLUTTER" --skip-pub-get
fvm use "$PILOGY_FLUTTER" --skip-pub-get
flutter_sdk
resolve_packages
python3 scripts/environment_checks.py project "$platform"
python3 scripts/verify_admob.py
if [[ "$platform" != ios ]]; then
  if ! select_java; then
    brew_install openjdk@17
    select_java || fail "Installed formula does not supply exact Java $PILOGY_JAVA. Restore Temurin 17.0.21 from https://adoptium.net/temurin/archive/ and set PILOGY_JAVA_HOME; do not replace global Java."
  fi
  if ! android_sdk; then
    brew_install --cask android-commandlinetools
    android_sdk || fail 'Set ANDROID_HOME to the Android Studio or Homebrew SDK directory; ANDROID_SDK_ROOT must agree.'
  fi
  python3 scripts/environment_checks.py licenses "$ANDROID_HOME" || fail 'Review Android SDK terms interactively in Android Studio SDK Manager (older sdkmanager supports --licenses), then rerun. No acceptance is performed here.'
  if ! manager="$(sdkmanager_path)"; then
    # Use installed latest CLI only to bootstrap the explicitly pinned CLI package.
    bootstrap="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
    [[ -x "$bootstrap" ]] || fail 'Install Android SDK Command-line Tools with Android Studio SDK Manager, then rerun.'
    [[ "$install" == true ]] || fail 'Missing pinned SDK CLI; rerun setup --install.'
    sdk_install "$bootstrap" "cmdline-tools;$PILOGY_COMMAND_TOOLS"
    manager="$(sdkmanager_path)" || fail 'Pinned Android SDK CLI installation failed.'
  fi
  missing=()
  [[ -f "$ANDROID_HOME/platforms/android-$PILOGY_COMPILE_SDK/source.properties" ]] || missing+=("platforms;android-$PILOGY_COMPILE_SDK")
  [[ -f "$ANDROID_HOME/build-tools/$PILOGY_BUILD_TOOLS/source.properties" ]] || missing+=("build-tools;$PILOGY_BUILD_TOOLS")
  [[ -f "$ANDROID_HOME/ndk/$PILOGY_NDK/source.properties" ]] || missing+=("ndk;$PILOGY_NDK")
  [[ -f "$ANDROID_HOME/cmake/$PILOGY_CMAKE/source.properties" ]] || missing+=("cmake;$PILOGY_CMAKE")
  [[ -f "$ANDROID_HOME/platform-tools/source.properties" ]] || missing+=(platform-tools)
  if [[ ${#missing[@]} -gt 0 ]]; then
    [[ "$install" == true ]] || fail 'Android packages missing; rerun scripts/setup.sh --install.'
    # EOF never means yes; a new package license blocks rather than being accepted.
    sdk_install "$manager" "${missing[@]}"
  else pass 'All required SDK packages already installed; no SDK installation needed'; fi
  python3 scripts/environment_checks.py packages "$ANDROID_HOME"
  python3 scripts/environment_checks.py licenses "$ANDROID_HOME"
  configure_android_local
fi
if [[ "$platform" != android ]]; then
  xcodebuild -version || fail 'Install full Xcode manually from Apple Developer downloads; select it using DEVELOPER_DIR.'
  xcodebuild -checkFirstLaunchStatus || fail 'Open Xcode and complete its license/component setup manually.'
  if ! select_ruby; then
    command -v ruby-build >/dev/null || brew_install ruby-build
    [[ "$install" == true ]] || fail 'Run setup --install to compile project-local Ruby 3.3.0.'
    [[ ! -e .tooling/ruby ]] || fail 'Incomplete .tooling/ruby exists; inspect it manually rather than overwriting.'
    mkdir -p .tooling
    ruby-build "$PILOGY_RUBY" "$PILOGY_ROOT/.tooling/ruby"
    select_ruby || fail 'Project-local Ruby installation failed'
  fi
  if ! bundle_cmd --version >/dev/null 2>&1; then
    [[ "$install" == true ]] || fail 'Bundler missing; rerun setup --install.'
    "$PILOGY_RUBY_BIN" "$(dirname "$PILOGY_RUBY_BIN")/gem" install bundler --version "$PILOGY_BUNDLER" --no-document --install-dir "$GEM_HOME"
  fi
  if [[ -f Gemfile.lock ]]; then
    export BUNDLE_FROZEN=true
  else
    warn 'No Gemfile.lock was supplied. Initial resolution will create one; review and commit it. Reproducibility is not yet established.'
  fi
  if ! bundle_cmd check >/dev/null 2>&1; then bundle_cmd install; else pass 'Local Ruby bundle already satisfies Gemfile.lock'; fi
  if [[ -f ios/Podfile.lock ]]; then
    (cd ios && pod_cmd install --deployment)
  else
    warn 'No Podfile.lock was supplied. Initial pod install will resolve it; review and commit it before claiming an iOS baseline.'
    (cd ios && pod_cmd install)
  fi
fi
# Report readiness only from real diagnostics; first-time setup can return failure.
"$PILOGY_ROOT/scripts/doctor.sh" "--$platform"
pass "Setup completed for $platform. Run it again to check idempotency; release signing remains a separate gate."
