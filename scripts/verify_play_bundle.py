#!/usr/bin/env python3
"""Verify the built AAB signature against the supplied upload certificate.

Reads public certificates only. No keystore password is required or logged.
"""
import argparse
import hashlib
from pathlib import Path
import re
import ssl
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def run(*args, input_text=None):
    result = subprocess.run(args, input=input_text, text=True, capture_output=True)
    if result.returncode:
        raise SystemExit('Bundle verification tool failed; check the local JDK and signing setup. No tool output containing credentials is forwarded.')
    return result.stdout


def certificate_digest(pem):
    matches = re.findall(r'-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----', pem, re.S)
    if not matches:
        raise SystemExit('No signing certificate found.')
    return hashlib.sha256(ssl.PEM_cert_to_DER_cert(matches[0])).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--bundle', type=Path, default=ROOT / 'build/app/outputs/bundle/release/app-release.aab')
    parser.add_argument('--keystore', type=Path, default=ROOT / 'config/keystore.jks')
    parser.add_argument('--alias', default='thangmt')
    args = parser.parse_args()
    if not args.bundle.is_file() or not args.keystore.is_file():
        raise SystemExit('Bundle or upload keystore missing; build a signed AAB first.')
    with zipfile.ZipFile(args.bundle) as archive:
        if 'base/manifest/AndroidManifest.xml' not in archive.namelist():
            raise SystemExit('Expected an Android App Bundle with a base manifest.')
    verification = run('jarsigner', '-J-Duser.language=en', '-J-Duser.country=US', '-verify', str(args.bundle))
    if 'jar verified.' not in verification:
        raise SystemExit('The bundle signature was not verified. Do not upload this artifact.')
    bundle_certificate = run('keytool', '-printcert', '-jarfile', str(args.bundle), '-rfc')
    upload_certificate = run('keytool', '-exportcert', '-keystore', str(args.keystore), '-alias', args.alias, '-rfc', input_text='\n')
    if certificate_digest(bundle_certificate) != certificate_digest(upload_certificate):
        raise SystemExit('Bundle signer does not match the supplied upload certificate. Do not upload this artifact.')
    bundle_hash = hashlib.sha256(args.bundle.read_bytes()).hexdigest()
    print('PASS: AAB container, cryptographic signature and upload certificate match.')
    print('AAB SHA-256: ' + bundle_hash)
    print('This does not verify Play policy acceptance, device behavior or ad serving.')


if __name__ == '__main__':
    main()
