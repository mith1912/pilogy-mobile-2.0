# Build PILOGY for iOS

Required detected baseline: Xcode **26.3 (17C529)**, iOS SDK/simulator **26.2**, deployment target **15.0**, Ruby **3.3.0**, Bundler **2.5.4**, CocoaPods **1.15.2**. See [environment details](development-environment.md) for evidence and the distinction between detected and actually verified versions.

Install full Xcode manually, open it to complete license/component setup, and verify the selected developer directory. `DEVELOPER_DIR=/Applications/<your Xcode>.app/Contents/Developer` can select it for a process; scripts do not run sudo xcode-select, install Xcode, or upgrade it. Simulator SDK presence is checked; running tests in a simulator also requires a usable simulator runtime/device.

```bash
scripts/setup.sh --install --ios
scripts/doctor.sh --ios
API_BASE_URL=http://localhost:3000/api/v1 scripts/build-ios.sh simulator
```

Simulator builds use Debug, Google test ad units and `--no-codesign`. They require an explicit API_BASE_URL and produce **build/ios/iphonesimulator/Runner.app**, checked for a fresh Info.plist and executable. This is not an IPA and needs no distribution certificate. Local HTTP can still be constrained by the app's existing ATS configuration; these scripts do not weaken it. Prefer HTTPS staging where appropriate.

## Ruby and Pods

Use the project Gemfile and selected Ruby, never global pod update. Setup installs missing bootstrap/application gems under ignored .tooling/. `.ruby-version` and Gemfile pin Ruby 3.3.0; the selected interpreter is explicit, so PATH system Ruby 2.6.10 cannot accidentally run this workflow. Set PILOGY_RUBY_EXECUTABLE to an existing exact interpreter if necessary. A missing interpreter can be built locally with ruby-build by setup --install.

No Gemfile.lock or ios/Podfile.lock was supplied. The first successful setup will warn and create genuine lockfiles through Bundler/CocoaPods resolution. Review their native Firebase, Google Mobile Ads/UMP and other plugin versions, validate compilation, and commit the locks. The existing Flutter plugin versions alone are insufficient to infer native pod versions. Subsequent setup/builds require the locks and use `BUNDLE_FROZEN=true` and `pod install --deployment`, never pod update or implicit resolution upgrades. Existing Podfile and deployment targets are preserved.

Network access to RubyGems and CocoaPods sources, working Ruby native extension compilation and Xcode tool access are required. Missing lockfiles are an explicit doctor failure, not a successful setup result.

## Signed release IPA

The existing Runner target uses mt.numerology and an existing development team setting. Scripts do not change the team, bundle ID, signing style, certificates, provisioning profiles or keychains. Configure the appropriate Apple Developer membership/account and signing capabilities manually in Xcode, using the project's authorized team. Restore valid distribution signing identities/profiles securely. App Store export may require additional Apple account/provisioning configuration beyond a valid identity.

Supply a reviewed export-options plist generated for your signing/distribution method by Xcode or your release process. Keep personal signing/export configuration outside tracked source when appropriate:

```bash
IOS_EXPORT_OPTIONS_PLIST=/secure/path/ExportOptions.plist \
  scripts/build-ios.sh release
```

Release defaults to the existing production API; API_BASE_URL can explicitly select another deployment. Ad configuration is the same explicit policy as Android: ads off by default, ADS_MODE=test for test units, or ADS_MODE=production plus ADS_PRODUCTION_READY=true only after validated M06 release gates. Telemetry remains disabled by these scripts.

The script requires a valid signing identity, runs the locked pod install and doctor, then builds with `flutter build ipa --release --export-options-plist=...`. It reports a successful IPA only when exactly one fresh, nonempty, valid **build/ios/ipa/*.ipa** contains the application payload. The Xcode archive is normally under **build/ios/archive/Runner.xcarchive**. No --no-codesign release shortcut is described as a signed release. Export/signing errors stop the script.

## Troubleshooting and acceptance

- Wrong Xcode: set DEVELOPER_DIR to the documented version; no automatic upgrades.
- License/first launch: open Xcode and complete its prompts yourself.
- FFI/native gem errors: use setup's isolated Ruby bundle; do not repair system gems with sudo.
- Missing locks: run initial setup on a working unrestricted Mac, then review/commit genuine generated locks.
- Provisioning/keychain failures: complete Apple account and signing setup manually. Scripts do not request automatic profile creation or modify credentials.
- CocoaPods deployment drift: investigate differences instead of deleting Podfile.lock or running pod update.

This execution environment detected Xcode but could not install FVM or resolve Ruby dependencies, so no iOS simulator build or signed release was verified. A successful doctor and actual simulator build on the new Mac remain acceptance gates.
