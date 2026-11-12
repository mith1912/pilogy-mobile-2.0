#!/usr/bin/env python3
"""Offline scaffold checks; explicitly not a replacement for Flutter checks."""
import hashlib
import json
import plistlib
import re
import sqlite3
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PRESERVED = {
    'design_preference/design_pilogy.txt': 'b0bbc581e6e54b5955a4818e652c473eb321921ab804f9a554828a81102b91e9',
    'config/GoogleService-Info.plist': 'c1c18ee741b57a43621f5a2cdd835a16707c607fc324744ae11a61fdae1cc3a9',
    'config/google-services.json': 'e6963858146fb4535c65ce17579a8167c1443d6a4b812ad9b839c6f9188d68dc',
}

def main():
    for filename, expected in PRESERVED.items():
        assert hashlib.sha256((ROOT / filename).read_bytes()).hexdigest() == expected, filename
    print('PASS: design and Firebase files preserved byte-for-byte')
    for filename in ['pubspec.yaml', 'lib/main.dart', 'android', 'ios',
                     'android/gradlew', 'android/gradle/wrapper/gradle-wrapper.jar',
                     'ios/Runner.xcworkspace/contents.xcworkspacedata']:
        assert (ROOT / filename).exists(), filename
    assert list(ROOT.rglob('pubspec.yaml')) == [ROOT / 'pubspec.yaml']
    assert not (ROOT / 'mobile').exists()
    assert not (ROOT / 'pilogy_app').exists()
    print('PASS: required project paths exist directly at', ROOT)
    gradle = (ROOT / 'android/app/build.gradle').read_text()
    assert 'applicationId "mt.numerology"' in gradle
    assert 'namespace "mt.numerology"' in gradle
    activity = ROOT / 'android/app/src/main/kotlin/mt/numerology/MainActivity.kt'
    assert 'package mt.numerology' in activity.read_text()
    xcode = (ROOT / 'ios/Runner.xcodeproj/project.pbxproj').read_text()
    bundles = re.findall(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);', xcode)
    assert bundles.count('mt.numerology') == 3
    assert set(bundles) == {'mt.numerology', 'mt.numerology.RunnerTests'}
    print('PASS: Android ID and all iOS app configurations use mt.numerology')
    for folder in ['android', 'ios']:
        for file in (ROOT / folder).rglob('*'):
            if file.is_file() and file.suffix in {'.xml', '.plist', '.pbxproj', '.gradle', '.kt', '.swift'}:
                assert '{{' not in file.read_text(), file
            if file.is_file() and file.suffix in {'.xml', '.storyboard'}:
                ET.parse(file)
            if file.is_file() and file.suffix == '.plist':
                plistlib.loads(file.read_bytes())
            if file.is_file() and file.suffix == '.json':
                json.loads(file.read_text())
    print('PASS: native XML/plist/asset JSON parses; no unrendered template fields')
    ids = set()
    for file in (ROOT / 'lib/features').rglob('*_screen.dart'):
        ids.update(re.findall(r"screenId: '(V\d+)'", file.read_text()))
    assert ids == {'V01','V02','V03','V04','V05','V08','V09','V10'}
    router = (ROOT / 'lib/app/router.dart').read_text()
    assert router.count('GoRoute(path:') == 8
    print('PASS: exactly eight allowed screens and routes')
    for file in (ROOT / 'lib').rglob('*.dart'):
        for relative in re.findall(r"import '([^']+)';", file.read_text()):
            if not relative.startswith(('dart:', 'package:')):
                assert (file.parent / relative).resolve().is_file(), (file, relative)
    print('PASS: all relative Dart imports resolve')
    source = (ROOT / 'lib/services/storage/local_database.dart').read_text()
    schema = source.split('static const schema = [', 1)[1].split('];', 1)[0]
    statements = re.findall(r"'''(.*?)'''|'([^'\n]+)'", schema, re.S)
    db = sqlite3.connect(':memory:')
    db.execute('PRAGMA foreign_keys = ON')
    for multiline, single in statements:
        db.execute(multiline or single)
    tables = {row[0] for row in db.execute("SELECT name FROM sqlite_master WHERE type='table'")}
    assert tables == {'user_profiles','app_state','calculation_cache','interpretation_cache','profile_cache_revisions','calculation_contexts'}
    db.execute("INSERT INTO user_profiles VALUES ('p1','Test','2000-01-01','now','now')")
    db.execute("UPDATE app_state SET selected_profile_id='p1' WHERE id=1")
    db.execute("INSERT INTO calculation_cache VALUES ('cache1','p1','v1','draft','2026-11-09','vi','revision','{}','now')")
    db.execute("DELETE FROM user_profiles WHERE id='p1'")
    assert db.execute('SELECT selected_profile_id FROM app_state').fetchone() == (None,)
    assert db.execute('SELECT COUNT(*) FROM calculation_cache').fetchone() == (0,)
    try:
        db.execute("INSERT INTO calculation_cache VALUES ('orphan','missing','v1',NULL,'2026-11-09','vi','r','{}','now')")
        raise AssertionError('Orphan cache was accepted')
    except sqlite3.IntegrityError:
        pass
    db.execute("INSERT INTO interpretation_cache VALUES ('a','lifePath',7,'vi','draft','{}','now')")
    try:
        db.execute("INSERT INTO interpretation_cache VALUES ('b','lifePath',7,'vi','draft','{}','now')")
        raise AssertionError('Duplicate article key was accepted')
    except sqlite3.IntegrityError:
        pass
    db.close()
    print('PASS: SQL initializes; selection cleanup, cache cascade, orphan rejection and article uniqueness work')
    assert (ROOT / 'android/app/google-services.json').read_bytes() == (ROOT / 'config/google-services.json').read_bytes()
    assert (ROOT / 'ios/Runner/GoogleService-Info.plist').read_bytes() == (ROOT / 'config/GoogleService-Info.plist').read_bytes()
    android_firebase = json.loads((ROOT / 'config/google-services.json').read_text())
    ios_firebase = plistlib.loads((ROOT / 'config/GoogleService-Info.plist').read_bytes())
    assert ios_firebase['BUNDLE_ID'] == 'mt.numerology'
    assert android_firebase['project_info']['project_id'] == ios_firebase['PROJECT_ID']
    assert any(client['client_info']['android_client_info']['package_name'] == 'mt.numerology' for client in android_firebase['client'])
    assert 'GoogleService-Info.plist in Resources' in xcode
    assert 'com.google.gms.google-services' in gradle and 'com.google.firebase.crashlytics' in gradle
    assert 'FirebaseStartup.initialize()' in (ROOT / 'lib/main.dart').read_text()
    print('PASS: Firebase native copies, identifiers, Gradle plugins, Runner resources and startup wiring')
    print('Flutter dependency resolution, compilation, analysis, and widget tests still require a functioning SDK.')

if __name__ == '__main__':
    main()
