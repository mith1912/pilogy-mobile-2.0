# Set up PILOGY on another Mac

Use an Intel or Apple Silicon Mac with a native shell/SDK architecture. The inspected Mac was Intel, macOS 15.7.9. Apple Silicon is supported by the setup branches but has not been tested here. Avoid running an arm64 installation under a Rosetta x86_64 shell. Xcode 26.3 requires macOS 15.6 according to its installed metadata; use the documented detected baseline until another configuration is validated.

1. Clone the repository and enter the Flutter root (the directory containing pubspec.yaml). Do not nest another app.
2. Install full **Xcode 26.3 (17C529)** from Apple Developer downloads. Open it, review its license and finish component installation. Setup never installs Xcode or accepts its license. If several versions exist, set `DEVELOPER_DIR` for this terminal/script process rather than changing system selection.
3. Install Command Line Tools if `xcode-select -p` fails: run `xcode-select --install` and finish the dialog. Install Homebrew from its official instructions at [brew.sh](https://brew.sh). Review any administrator prompts yourself; PILOGY scripts never invoke sudo.
4. Restore required project configuration if your repository does not distribute it: originals under config/ and matching native Firebase copies. Restore Android upload signing only when you need release builds. Obtain these from the trusted project owner, not a newly provisioned Firebase/AdMob app.
5. Run:

   ```bash
   scripts/setup.sh --install
   ```

   For Android-only work, add `--android`; for iOS-only work, add `--ios`. `--install` authorizes missing non-sudo Homebrew dependencies and project-local Ruby/gems/SDK packages. Without it, missing bootstrap dependencies produce instructions. FVM downloads the pinned SDK when missing even on ordinary repeated setup; it never changes the global Flutter selection.

6. If Android SDK licenses are not already accepted, setup stops. Review/accept the SDK terms in Android Studio SDK Manager, then rerun. Legacy sdkmanager installations also support an interactive --licenses command; the installed CLI 23.0 shim says that option is no longer needed. Setup validates the actual accepted-license records instead. Do not pipe `yes` into a tool or fabricate acceptance files.
7. If a JDK bootstrap formula has moved beyond 17.0.21, obtain **Temurin 17.0.21+9** for your architecture from the [official archive](https://adoptium.net/temurin/archive/), extract/install it without replacing your existing JDK, and set `PILOGY_JAVA_HOME` to its Contents/Home directory for this invocation. The script detects an existing exact JDK first.
8. Setup detects an Android Studio SDK at `$HOME/Library/Android/sdk`, or uses matching ANDROID_HOME/ANDROID_SDK_ROOT overrides. If SDK CLI tools are missing, use Android Studio's SDK Manager or the supported Homebrew command-line-tools package. Conflicting environment roots are rejected. It requests only API 36, Build Tools 35.0.0, CLI tools 23.0, NDK 28.2.13676358, CMake 3.22.1 and platform-tools.
9. Initial iOS setup must resolve the missing Gemfile.lock and ios/Podfile.lock. Review and commit the genuine files, then rerun setup. No iOS transitive native lock can be inferred from pubspec.lock. If Ruby 3.3.0 is missing, ruby-build compiles it to ignored `.tooling/ruby`; this may take time and requires working Apple compilation tools/network access.
10. Run setup again and require a successful doctor:

    ```bash
    scripts/setup.sh
    scripts/doctor.sh --all
    ```

    The second run must reuse the installed SDK packages and satisfied Ruby bundle. Flutter lockfile verification and pod deployment checks intentionally still run.

No `.zshrc`, `.bash_profile`, global JAVA_HOME, global Ruby, global Flutter or signing identities are changed. Native SDK installs/cache downloads require appropriate write permissions. If Homebrew reports an unwritable prefix, stop and ask your machine administrator to repair the managed installation; do not blindly execute recursive ownership-change suggestions. Intel Homebrew bottle support is a known limitation. If needed, install FVM through its [official standalone method](https://fvm.app/documentation/getting-started/installation) manually, then rerun setup; don't force unsupported Homebrew options.

Use [Android build instructions](build-android.md) and [iOS build instructions](build-ios.md) for smoke builds. A new Mac is ready only after its own doctor, package resolution, analysis, tests and native builds pass. The current execution environment could not complete that validation; see [actual results](verification/environment/RESULTS.md).
