#!/usr/bin/env python3
"""Offline project metadata and safe generated-file operations. No app data."""
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import subprocess
import sys
import zipfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
PINS = dict(line.split('=', 1) for line in (ROOT / 'scripts/toolchain.env').read_text().splitlines()
            if line and not line.startswith('#'))

def require(ok, message):
    if not ok:
        raise ValueError(message)

def source(relative):
    return (ROOT / relative).read_text()

def flutter(sdk):
    data = json.loads((Path(sdk) / 'bin/cache/flutter.version.json').read_text())
    require(json.loads(source('.fvmrc'))['flutter'] == PINS['PILOGY_FLUTTER'], 'FVM configuration differs from toolchain.env')
    for key, expected in [('frameworkVersion', PINS['PILOGY_FLUTTER']),
                          ('dartSdkVersion', PINS['PILOGY_DART']), ('channel', 'stable'),
                          ('frameworkRevision', PINS['PILOGY_FLUTTER_REVISION'])]:
        require(data.get(key) == expected, f'{key}: expected {expected}, actual {data.get(key)}')
    print(f"PASS: pinned Flutter {data['frameworkVersion']} stable / Dart {data['dartSdkVersion']} metadata")

def command_tools(path):
    s=(Path(path)/'source.properties').read_text()
    require(re.search(r'^Pkg.Revision\s*=\s*'+re.escape(PINS['PILOGY_COMMAND_TOOLS'])+r'\s*$', s, re.M), 'Expected Android command-line tools '+PINS['PILOGY_COMMAND_TOOLS'])

def packages(sdk):
    paths = ['platforms/android-'+PINS['PILOGY_COMPILE_SDK'],
             'build-tools/'+PINS['PILOGY_BUILD_TOOLS'], 'ndk/'+PINS['PILOGY_NDK'],
             'cmake/'+PINS['PILOGY_CMAKE'], 'platform-tools']
    missing=[]
    for path in paths:
        metadata=Path(sdk)/path/'source.properties'
        present=metadata.is_file()
        expected=path.split('/',1)[1] if path.startswith(('build-tools/','ndk/','cmake/')) else None
        if present and expected:
            revision=re.search(r'^Pkg.Revision\s*=\s*(\S+)',metadata.read_text(),re.M)
            present=bool(revision and revision[1]==expected)
        if present and path.startswith('platforms/'):
            api=re.search(r'^AndroidVersion.ApiLevel\s*=\s*(\d+)',metadata.read_text(),re.M)
            present=bool(api and api[1]==PINS['PILOGY_COMPILE_SDK'])
        print(('PASS' if present else 'FAIL')+': Android package '+path)
        if not present: missing.append(path)
    require(not missing, 'Run scripts/setup.sh --install to install missing SDK packages; accept licenses interactively first.')

def license_state(sdk):
    root=Path(sdk)
    accepted=(root/'licenses/android-sdk-license').read_text().split()
    require(PINS['PILOGY_ANDROID_LICENSE_HASH'] in accepted,
            'Android SDK license acceptance is missing. Review terms in Android Studio SDK Manager; this script never writes acceptance records.')
    # SHA-1 is the SDK's license-text format, not a personal-data fingerprint.
    for relative in ['platforms/android-'+PINS['PILOGY_COMPILE_SDK'], 'build-tools/'+PINS['PILOGY_BUILD_TOOLS'],
                     'ndk/'+PINS['PILOGY_NDK'], 'cmake/'+PINS['PILOGY_CMAKE'], 'platform-tools']:
        metadata=root/relative/'package.xml'
        if not metadata.exists(): continue  # Missing packages are a separate gate.
        doc=ET.parse(metadata).getroot()
        texts={e.attrib['id']:(e.text or '').strip() for e in doc.iter() if e.tag.split('}')[-1]=='license'}
        for item in doc.iter():
            if item.tag.split('}')[-1]!='uses-license': continue
            ref=item.attrib['ref']
            text=texts.get(ref)
            require(text is not None, 'Cannot validate license metadata for '+relative)
            digest=hashlib.sha1(text.encode()).hexdigest()
            record=root/'licenses'/ref
            require(record.is_file() and digest in record.read_text().split(), 'License changed/unaccepted for '+relative+'; review it manually')
    print('PASS: existing SDK license records match the inspected baseline and installed package metadata; no licenses accepted')


def project(platform):
    require(json.loads(source('.fvmrc'))['flutter']==PINS['PILOGY_FLUTTER'], 'FVM project pin drift')
    wrapper=source('android/gradle/wrapper/gradle-wrapper.properties')
    require('gradle-'+PINS['PILOGY_GRADLE']+'-all.zip' in wrapper, 'Gradle wrapper drift')
    settings=source('android/settings.gradle')
    for name, pin in [('com.android.application','PILOGY_AGP'), ('org.jetbrains.kotlin.android','PILOGY_KOTLIN')]:
        require(f'id "{name}" version "{PINS[pin]}"' in settings, name+' version drift')
    gradle=source('android/app/build.gradle')
    require('applicationId "mt.numerology"' in gradle and 'namespace "mt.numerology"' in gradle, 'Android identifier drift')
    require('compileSdkVersion '+PINS['PILOGY_COMPILE_SDK'] in gradle, 'compileSdk drift')
    require('buildToolsVersion "'+PINS['PILOGY_BUILD_TOOLS']+'"' in gradle, 'Build Tools version drift')
    require('ndkVersion flutter.ndkVersion' in gradle, 'NDK must use pinned Flutter default')
    require('minSdkVersion flutter.minSdkVersion' in gradle and 'targetSdkVersion flutter.targetSdkVersion' in gradle, 'Flutter SDK defaults drift')
    require((ROOT/'android/gradlew').is_file() and (ROOT/'android/gradle/wrapper/gradle-wrapper.jar').is_file(), 'Commit Gradle wrapper launchers and JAR (ignore exceptions supplied)')
    print('PASS: Gradle '+PINS['PILOGY_GRADLE']+' / AGP '+PINS['PILOGY_AGP']+' / Kotlin '+PINS['PILOGY_KOTLIN'])
    require((ROOT/'pubspec.lock').is_file(), 'Restore committed pubspec.lock')
    # Existing originals are the authority; never copy over them.
    if platform in ('android', 'all'):
        a=ROOT/'config/google-services.json'; b=ROOT/'android/app/google-services.json'
        require(a.read_bytes()==b.read_bytes(), 'Restore android/app/google-services.json byte-for-byte from config/google-services.json')
        firebase=json.loads(a.read_text())
        require(any(c['client_info']['android_client_info']['package_name']=='mt.numerology' for c in firebase['client']), 'Firebase Android application mismatch')
    if platform in ('ios', 'all'):
        a=ROOT/'config/GoogleService-Info.plist'; b=ROOT/'ios/Runner/GoogleService-Info.plist'
        require(a.read_bytes()==b.read_bytes(), 'Restore ios/Runner/GoogleService-Info.plist byte-for-byte from config/GoogleService-Info.plist')
        require(plistlib.loads(a.read_bytes())['BUNDLE_ID']=='mt.numerology', 'Firebase iOS Bundle ID mismatch')
        require("platform :ios, '"+PINS['PILOGY_IOS_TARGET']+"'" in source('ios/Podfile'), 'Podfile deployment target drift')
        targets=re.findall(r'IPHONEOS_DEPLOYMENT_TARGET = ([\d.]+);',source('ios/Runner.xcodeproj/project.pbxproj'))
        require(targets and set(targets)=={PINS['PILOGY_IOS_TARGET']}, 'Xcode iOS deployment target drift')
    print('PASS: package IDs and Firebase copies match preserved references')

def local_properties(sdk, flutter_sdk):
    p=ROOT/'android/local.properties'
    require(not p.is_symlink(), 'Refusing symlinked local.properties')
    lines=p.read_text().splitlines() if p.exists() else []
    def escape(value):
        return value.replace('\\','\\\\').replace(':','\\:').replace(' ','\\ ')
    lines=[s for s in lines if not re.match(r'^(sdk.dir|flutter.sdk|cmake.dir)\s*=',s)]
    lines += ['sdk.dir='+escape(str(Path(sdk).resolve())), 'flutter.sdk='+escape(str(Path(flutter_sdk).resolve())), 'cmake.dir='+escape(str(Path(sdk).resolve()/'cmake'/PINS['PILOGY_CMAKE']))]
    content='\n'.join(lines)+'\n'
    if not p.exists() or p.read_text()!=content: p.write_text(content)

def flutter_android_config(java, sdk, check_only=False):
    values={'jdk-dir':str(Path(java).resolve()), 'android-sdk':str(Path(sdk).resolve())}
    legacy=Path.home()/'.flutter_settings'
    if legacy.exists():
        old=json.loads(legacy.read_text())
        require(all(old.get(k) and Path(old[k]).resolve()==Path(v) for k,v in values.items()),
                'Legacy ~/.flutter_settings overrides project XDG configuration. Back it up and reconcile its jdk-dir/android-sdk manually; setup will not change it.')
    p=ROOT/'.tooling/flutter-config/settings'
    require(not p.is_symlink(), 'Refusing symlinked Flutter settings')
    if check_only:
        require(p.is_file() and json.loads(p.read_text())==values, 'Project-local Flutter Java/SDK configuration missing or stale; run setup. Global Android Studio Java must not override the pinned JDK.')
        return
    p.parent.mkdir(parents=True,exist_ok=True)
    text=json.dumps(values,indent=2)+'\n'
    if not p.exists() or p.read_text()!=text: p.write_text(text)


def signing():
    p=ROOT/'android/key.properties'
    require(p.is_file(), 'Missing android/key.properties; see docs/build-android.md. No debug signing fallback.')
    values=dict(re.findall(r'^\s*(\w+)\s*=\s*(.*?)\s*$',p.read_text(), re.M))
    require(all(values.get(k) for k in ('storeFile','storePassword','keyAlias','keyPassword')), 'Release signing properties incomplete (values not printed)')
    require((ROOT/'android'/values['storeFile']).is_file(), 'Release keystore not found; restore it securely, never create a replacement key')
    print('PASS: release signing files present; Gradle must still validate credentials')

def artifact(kind, start, path):
    p=Path(path)
    require(p.is_file() and p.stat().st_size>0 and p.stat().st_mtime_ns >= int(start), 'No fresh nonempty artifact: '+str(p))
    if kind in ('apk','aab','ipa'):
        with zipfile.ZipFile(p) as z:
            require(z.testzip() is None,'Corrupt artifact ZIP')
            names=z.namelist()
            if kind=='apk': require('AndroidManifest.xml' in names and 'classes.dex' in names,'APK contents missing')
            if kind=='aab': require('base/manifest/AndroidManifest.xml' in names and 'BundleConfig.pb' in names,'AAB contents missing')
            if kind=='ipa': require(any(n.startswith('Payload/') and n.endswith('.app/Info.plist') for n in names),'IPA payload missing')
    print('PASS: fresh artifact '+str(p))

def clean(dry):
    for relative in ('build', '.dart_tool'):
        p=ROOT/relative
        require(not p.is_symlink(), 'Refusing symlinked generated directory: '+relative)
        if (ROOT/'.git').exists() or subprocess.run(['git','-C',str(ROOT),'rev-parse','--show-toplevel'],capture_output=True).returncode==0:
            tracked=subprocess.run(['git','-C',str(ROOT),'ls-files','--',relative],capture_output=True,text=True,check=True).stdout
            require(not tracked.strip(), 'Refusing deletion: tracked files under '+relative)
        if p.exists():
            print(('Would remove ' if dry else 'Removing ')+relative)
            if not dry:
                import shutil
                shutil.rmtree(p)

if __name__=='__main__':
    try:
        mode=sys.argv[1]
        if mode=='flutter': flutter(sys.argv[2])
        elif mode=='command-tools': command_tools(sys.argv[2])
        elif mode=='packages': packages(sys.argv[2])
        elif mode=='licenses': license_state(sys.argv[2])
        elif mode=='project': project(sys.argv[2])
        elif mode=='local-properties': local_properties(*sys.argv[2:])
        elif mode=='flutter-android-config': flutter_android_config(*sys.argv[2:])
        elif mode=='flutter-android-check': flutter_android_config(*sys.argv[2:],check_only=True)
        elif mode=='signing': signing()
        elif mode=='artifact': artifact(*sys.argv[2:])
        elif mode=='clean': clean('--dry-run' in sys.argv[2:])
        else: raise ValueError('Unknown check '+mode)
    except (ValueError, OSError, KeyError, IndexError, json.JSONDecodeError, ET.ParseError) as e:
        print('FAIL: '+str(e),file=sys.stderr)
        sys.exit(1)
