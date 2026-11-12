#!/usr/bin/env python3
"""Package the approved opaque AppIcon artwork with macOS sips; no creative edits.

Originals in config/ are read-only. No Flutter/package installation is needed.
"""
import hashlib
import json
import shutil
import struct
import subprocess
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'config/Assets.xcassets/AppIcon.appiconset/ItunesArtwork@2x.png'


def png_info(path):
    data = path.read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n'
    width, height, depth, color = struct.unpack('>IIBB', data[16:26])
    chunks = []
    offset = 8
    while offset < len(data):
        length = struct.unpack('>I', data[offset:offset + 4])[0]
        kind = data[offset + 4:offset + 8]
        chunks.append((kind, data[offset + 8:offset + 8 + length]))
        offset += length + 12
    return width, height, depth, color, chunks


def main():
    width, height, depth, color, chunks = png_info(SOURCE)
    assert (width, height, depth, color) == (1024, 1024, 8, 2)
    assert not any(kind == b'tRNS' for kind, _ in chunks)
    # At row/column zero every PNG predictor uses zero neighbours.
    first_row = zlib.decompress(b''.join(body for kind, body in chunks if kind == b'IDAT'))
    background = '#' + first_row[1:4].hex().upper()

    def resize(destination, pixels):
        destination.parent.mkdir(parents=True, exist_ok=True)
        if pixels == width:
            shutil.copyfile(SOURCE, destination)
        else:
            subprocess.run(['sips', '--resampleHeightWidth', str(pixels), str(pixels),
                            str(SOURCE), '--out', str(destination)], check=True, capture_output=True)
        w, h, _, kind, parts = png_info(destination)
        assert (w, h) == (pixels, pixels)
        assert kind == 2 and not any(k == b'tRNS' for k, _ in parts), 'Icons must be opaque RGB'

    android = ROOT / 'android/app/src/main/res'
    android_sizes = {'mdpi': (48, 108), 'hdpi': (72, 162), 'xhdpi': (96, 216),
                     'xxhdpi': (144, 324), 'xxxhdpi': (192, 432)}
    for density, (legacy, foreground) in android_sizes.items():
        resize(android / f'mipmap-{density}/ic_launcher.png', legacy)
        resize(android / f'mipmap-{density}/ic_launcher_foreground.png', foreground)
    (android / 'values/pilogy_launcher_colors.xml').write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
        f'    <color name="pilogy_launcher_background">{background}</color>\n</resources>\n')
    (android / 'drawable/pilogy_launcher_foreground.xml').write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<inset xmlns:android="http://schemas.android.com/apk/res/android"\n'
        '    android:drawable="@mipmap/ic_launcher_foreground"\n'
        '    android:inset="16.666667%" />\n')
    adaptive = android / 'mipmap-anydpi-v26/ic_launcher.xml'
    adaptive.parent.mkdir(parents=True, exist_ok=True)
    adaptive.write_text('<?xml version="1.0" encoding="utf-8"?>\n'
                        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
                        '    <background android:drawable="@color/pilogy_launcher_background" />\n'
                        '    <foreground android:drawable="@drawable/pilogy_launcher_foreground" />\n'
                        '</adaptive-icon>\n')
    ios = ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    entries = json.loads((ios / 'Contents.json').read_text())['images']
    generated = set()
    for entry in entries:
        name = entry['filename']
        pixels = int(float(entry['size'].split('x')[0]) * float(entry['scale'].rstrip('x')))
        if name not in generated:
            resize(ios / name, pixels)
            generated.add(name)
    # Only obsolete launcher files in this native AppIcon set, never config originals.
    for old in ios.glob('*.png'):
        if old.name not in generated:
            old.unlink()
    evidence = {'source': str(SOURCE.relative_to(ROOT)),
                'sourceSha256': hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
                'background': background, 'adaptiveInsetPercent': 16.666667,
                'androidDensities': android_sizes, 'iosFiles': sorted(generated),
                'allIosIconsOpaque': True, 'identifiersChanged': False}
    report = ROOT / 'docs/verification/m04-3/launcher-icons.json'
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(json.dumps(evidence, indent=2) + '\n')
    print(f'Generated 5 legacy + 5 adaptive foreground Android icons and {len(generated)} opaque iOS icons.')
    print('Approved artwork preserved; adaptive XML keeps the complete image inside a 72dp inset region.')


if __name__ == '__main__':
    main()
