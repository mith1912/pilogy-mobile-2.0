# Google Play Android App Bundle

## Current signing setup

The supplied upload keystore is config/keystore.jks. A password-free certificate inspection found one private-key entry with alias thangmt; the password/integrity has not yet been verified. The keystore was not converted, overwritten or regenerated.

Release builds now use signingConfigs.release instead of the debug certificate. Signing values come from android/key.properties only, with storeFile resolved relative to android/. Missing credentials or a missing store cause release tasks to fail closed; debug tasks do not require release credentials. The root ignore file excludes keystores and android/key.properties, including the keystore outside android/.

Fill these two values in the existing local android/key.properties file:

```properties
storeFile=../config/keystore.jks
keyAlias=thangmt
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_PRIVATE_KEY_PASSWORD
```

Use the actual passwords, not these placeholders. If the key password was set equal to the keystore password, enter that same password in both fields. Do not paste passwords into chat, commit this file, or pass passwords on shell command lines. This is a Java Properties file: literal backslashes in values must be escaped. The local template is created with mode 0600.

The applicationId/namespace remains mt.numerology. The latest store version reported by the user is 1.0.11 (versionCode 12). The next source version is 1.0.12+13 (versionCode 13); use a higher unused code if 13 has since been uploaded. If this is an update to an existing Play app, verify the upload certificate against Play Console before proceeding and choose an unused higher versionCode. The installed SDK source defaults targetSdkVersion to 36, and compileSdkVersion is 36. Final manifest settings have not been verified in a built bundle.

## Build

The first verification bundle can use official test ads on Play's internal testing track:

```sh
bash scripts/build_play_bundle.sh internal-test
```

A public release can be prepared with ads disabled while live-ad release gates remain unverified:

```sh
bash scripts/build_play_bundle.sh public-no-ads
```

These commands run AdMob source checks, dependency resolution, Dart formatting, analysis and tests before building. Neither enables Analytics or production ad readiness. The wrapper stops at the first failed check. It does not upload or publish anything.

Successful output:

```
build/app/outputs/bundle/release/app-release.aab
```

The wrapper invokes scripts/verify_play_bundle.py to check the AAB container, cryptographic JAR signature and matching public certificate from config/keystore.jks, then prints the bundle's SHA-256. A bundle is not considered ready merely because a file exists; all checks must succeed. A previously built APK is not an AAB. The default verifier alias is thangmt; pass --alias explicitly if a different upload key is deliberately selected.

## Upload after verification

For the test bundle, create a release under Play Console → Testing → Internal testing, upload the AAB and enroll testers. Keep test-ad bundles on testing tracks. For a public release, finish the store listing, privacy policy, App content/Data safety/Ads declarations, content rating and Play's account-specific testing/release requirements. The app contains the advertising SDK even when requests are disabled; answer declarations according to the shipped behavior and current Console questions. Review native SDK data practices; local profile storage alone does not establish the entire app's Data safety answers.

Enable Play App Signing and retain a secure backup of the upload keystore and credentials. If Play generates the distribution signing key, its app signing certificate differs from the upload certificate. No Firebase project/app provisioning or authentication changes are required by this signing setup.

References: [Flutter Android release/signing](https://docs.flutter.dev/deployment/android), [Android App Signing](https://developer.android.com/studio/publish/app-signing), [Play target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en).

## Actual verification — 2026-11-10

No release AAB has been produced in the agent environment. The password fields are initially blank pending user completion. Pub get, format, analyze, tests and appbundle were attempted; Flutter stops because the agent cannot write engine.stamp.tmp/engine.realm in the installed SDK cache. No upload, publication, successful Flutter checks, verified release signing or Play acceptance is claimed. The user can run the prepared wrapper from their normal terminal, where prior APK builds succeeded. Production ad readiness remains false until its documented gates pass.

The build wrapper passed bash syntax validation. The bundle verifier passed Python syntax validation and an integration exercise using temporary generated JKS keys and synthetic AAB-shaped ZIP fixtures: it accepted a matching signed fixture and rejected unsigned, wrong-certificate and tampered fixtures. This validates verifier behavior, not a real Flutter bundle or the supplied keystore password. Temporary fixtures were deleted; no project signing credentials were used.

## Explicit public build with all ad formats

The user explicitly requested a store bundle with all four ad formats enabled. After completing signing credentials and the live-ad gates in docs/admob-testing.md, run:

```sh
bash scripts/build_play_bundle.sh public-live-ads
```

This explicit mode enables banner, interstitial, App Open and Native Advanced, disables test units, and passes production readiness to that build only. It does not change source defaults or override UMP, first-session, placement, reading-time or frequency restrictions. Ads are opportunities rather than guaranteed impressions; account approval, eligibility, network and available fill still matter. The wrapper runs formatting, analysis and tests before compilation and checks the resulting AAB signature. It does not certify manual/device gates or publish the bundle.

The agent checked again: the keystore exists, both password fields remain blank, and the Flutter build still stops at SDK cache permissions. No AAB was created. A direct diagnostic build attempt kept production readiness false; it did not reach compilation. The live-ad mode has been prepared but has not been built, run, or verified on a device.

## Next release after store build 12

From the mobile project directory, after the device/UMP/live-ad gates above pass:

```sh
bash scripts/build_play_bundle.sh public-live-ads --build-name=1.0.12 --build-number=13
```

The wrapper forwards Flutter build options, enables all four configured ad formats with live units for this release invocation, runs required checks, then verifies the AAB signature. Source defaults stay off/test. Permission, UMP eligibility, first-session and frequency policies still govern delivery; enabling flags cannot guarantee ad fill. The source pubspec version is also 1.0.12+13. Do not upload build 12 again. Output remains build/app/outputs/bundle/release/app-release.aab.
