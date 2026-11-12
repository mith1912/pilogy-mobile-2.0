#!/usr/bin/env python3
"""Project config is authoritative; synchronize only the native iOS AdMob key."""
from pathlib import Path
import plistlib
import re

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / 'config/ads_util.dart').read_text()
match = re.search(r'_iosAppId\s*=\s*"(ca-app-pub-\d{16}~\d{10})"', source)
if not match:
    raise SystemExit('Missing or invalid iOS AdMob App ID')
path = ROOT / 'ios/Runner/Info.plist'
info = plistlib.loads(path.read_bytes())
info['GADApplicationIdentifier'] = match.group(1)
info['GADDelayAppMeasurementInit'] = True
path.write_bytes(plistlib.dumps(info, sort_keys=False))
print('iOS AdMob application metadata synchronized; source IDs not logged.')
