#!/usr/bin/env python3
"""Offline metadata/source checks only; no ad serving or Dart execution."""
from pathlib import Path
import hashlib
import json
import plistlib
import re
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
source = (root / 'config/ads_util.dart').read_text()
ids = dict(re.findall(r'static const String (_\w+)\s*=\s*"([^"]+)"', source))
app = re.compile(r'^ca-app-pub-\d{16}~\d{10}$')
unit = re.compile(r'^ca-app-pub-\d{16}/\d{10}$')
assert app.fullmatch(ids['_androidAppId']) and app.fullmatch(ids['_iosAppId'])
assert unit.fullmatch(ids['_androidBannerId']) and unit.fullmatch(ids['_androidInterstitialId'])
assert unit.fullmatch(ids['_iosInterstitialId'])
assert unit.fullmatch(ids['_iosBannerId'])
for prefix in ('_android', '_ios'):
    assert unit.fullmatch(ids[prefix + 'CustomAdId']), 'Missing or invalid custom unit'
for prefix in ('_android', '_ios'):
    app_open = next((ids[key] for key in (prefix + 'AppOpenId', prefix + 'AdOpenId', prefix + 'AdOpen') if key in ids), None)
    assert app_open is not None and unit.fullmatch(app_open), 'Missing or invalid supplied App Open unit'
expected = {
    '_androidAppId': 'ca-app-pub-1578425271408021~1229517112',
    '_androidBannerId': 'ca-app-pub-1578425271408021/6573343131',
    '_androidInterstitialId': 'ca-app-pub-1578425271408021/2634098121',
    '_androidAdOpen': 'ca-app-pub-1578425271408021/4389220110',
    '_androidCustomAdId': 'ca-app-pub-1578425271408021/1894918711',
    '_iosAppId': 'ca-app-pub-1578425271408021~3755608109',
    '_iosBannerId': 'ca-app-pub-1578425271408021/5987019770',
    '_iosInterstitialId': 'ca-app-pub-1578425271408021/9163847454',
    '_iosAdOpenId': 'ca-app-pub-1578425271408021/9409859923',
    '_iosCustomAdId': 'ca-app-pub-1578425271408021/1351993236',
}
assert all(ids.get(key) == value for key, value in expected.items()), 'Inventory differs from user-supplied Google instructions'
info = plistlib.loads((root / 'ios/Runner/Info.plist').read_bytes())
assert info['GADApplicationIdentifier'] == ids['_iosAppId']
assert info['GADDelayAppMeasurementInit'] is True
assert info['CFBundleDisplayName'] == 'PILOGY'
assert not any('Landscape' in x for k,v in info.items() if k.startswith('UISupportedInterfaceOrientations') for x in v)
networks = [item['SKAdNetworkIdentifier'] for item in info['SKAdNetworkItems']]
assert 'cstr6suwn9.skadnetwork' in networks and len(networks) == len(set(networks))
manifest = ET.parse(root / 'android/app/src/main/AndroidManifest.xml').getroot()
ns = '{http://schemas.android.com/apk/res/android}'
meta = {el.get(ns+'name'):el.get(ns+'value') for el in manifest.findall('./application/meta-data')}
assert meta['com.google.android.gms.ads.APPLICATION_ID'] == '${admobAppId}'
assert meta['com.google.android.gms.ads.DELAY_APP_MEASUREMENT_INIT'] == 'true'
assert "../config/ads_util.dart" in (root / 'android/app/build.gradle').read_text()
config = (root / 'lib/services/ads/ad_configuration.dart').read_text()
assert "bool.fromEnvironment('ADS_ENABLED')" in config
assert 'bool get testing => !release || testAds;' in config
assert 'productionReady && validUnit(id)' in config
assert "AdFormat.nativeAdvanced: values['${prefix}CustomAdId']" in config
assert "'ADS_NATIVE_ENABLED'" in config
assert "ca-app-pub-3940256099942544/2247696110" in config
assert "ca-app-pub-3940256099942544/3986624511" in config
gateway = (root / 'lib/services/ads/google_ads_gateway.dart').read_text()
assert 'NativeAd(' in gateway and 'TemplateType.small' in gateway
assert 'onNativeImpression?.call()' in gateway
for p in (root / 'lib/features').rglob('*.dart'):
    assert 'ca-app-pub-' not in p.read_text(), 'Ad units must not enter screen widgets'
assert not (root / 'lib/services/ads/google_ads_gateway.dart').read_text().count('print(')
print('PASS: supplied identifiers classified; invalid/missing production formats recorded')
print('PASS: native IDs match source, delayed measurement, branding and portrait preserved')
print('PASS: SKAdNetwork snapshot unique; ad IDs absent from screen widgets; debug test guard present')
print('Source checks only: no Flutter analysis, platform build, consent UI or ad serving verified.')
