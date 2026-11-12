#!/usr/bin/env python3
"""Isolated contract tests; these do not run Flutter, Gradle, Pods or builds."""
import importlib.util
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import unittest
import zipfile

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('checks', ROOT/'scripts/environment_checks.py')
checks=importlib.util.module_from_spec(spec)
spec.loader.exec_module(checks)

class EnvironmentContracts(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.root=Path(self.tmp.name)
        self.oldroot=checks.ROOT
        checks.ROOT=self.root
        (self.root/'android').mkdir()
    def tearDown(self):
        checks.ROOT=self.oldroot
        self.tmp.cleanup()
    def test_local_properties_preserves_other_values_and_is_idempotent(self):
        p=self.root/'android/local.properties'
        p.write_text('flutter.versionCode=13\nsdk.dir=old\nflutter.sdk=old\n')
        checks.local_properties('/tmp/SDK with space','/tmp/pinned')
        content=p.read_bytes()
        self.assertIn(b'flutter.versionCode=13',content)
        self.assertIn(b'SDK\\ with\\ space',content)
        stamp=p.stat().st_mtime_ns
        checks.local_properties('/tmp/SDK with space','/tmp/pinned')
        self.assertEqual(p.read_bytes(),content)
        self.assertEqual(p.stat().st_mtime_ns,stamp)
    def test_clean_never_follows_symlink(self):
        outside=self.root/'outside'; outside.mkdir()
        keep=outside/'keep'; keep.write_text('preserve')
        (self.root/'build').symlink_to(outside,target_is_directory=True)
        with self.assertRaises(ValueError): checks.clean(False)
        self.assertTrue(keep.exists())
    def test_clean_refuses_git_tracked_generated_file(self):
        subprocess.run(['git','init','-q',str(self.root)],check=True)
        (self.root/'build').mkdir()
        (self.root/'build/tracked').write_text('preserve')
        subprocess.run(['git','-C',str(self.root),'add','build/tracked'],check=True)
        with self.assertRaises(ValueError): checks.clean(False)
        self.assertTrue((self.root/'build/tracked').exists())
    def test_clean_dry_run_and_repeat_preserve_config(self):
        (self.root/'build').mkdir()
        (self.root/'config').mkdir()
        p=self.root/'config/ads_util.dart';p.write_text('unchanged')
        checks.clean(True)
        self.assertTrue((self.root/'build').exists())
        checks.clean(False); checks.clean(False)
        self.assertEqual(p.read_text(),'unchanged')
    def test_artifact_rejects_stale_and_malformed_archives(self):
        p=self.root/'output.apk'
        with zipfile.ZipFile(p,'w') as z: z.writestr('AndroidManifest.xml','manifest')
        with self.assertRaises(ValueError): checks.artifact('apk',str(time.time_ns()+1000000),str(p))
        with self.assertRaises(ValueError): checks.artifact('apk','0',str(p))
        with zipfile.ZipFile(p,'a') as z: z.writestr('classes.dex','dex')
        checks.artifact('apk','0',str(p))
    def shell(self, code, **env):
        import os
        return subprocess.run(['bash','-c','source scripts/lib/environment.sh; '+code],
            cwd=ROOT,env={**os.environ,**env},text=True,capture_output=True)
    def test_debug_requires_explicit_backend(self):
        r=self.shell('unset API_BASE_URL; build_api development')
        self.assertNotEqual(r.returncode,0)
    def test_release_defaults_to_production_backend(self):
        r=self.shell('unset API_BASE_URL; build_api production; printf "%s" "$API_BASE_URL"')
        self.assertEqual(r.returncode,0,r.stderr)
        self.assertEqual(r.stdout,'https://pilogy.vercel.app/api/v1')
    def test_debug_never_selects_production_ads(self):
        r=self.shell('ad_flags debug',ADS_MODE='production')
        self.assertNotEqual(r.returncode,0)
        r=self.shell('ad_flags debug; printf "%s\\n" "${AD_FLAGS[@]}"',ADS_MODE='test')
        self.assertEqual(r.returncode,0,r.stderr)
        self.assertIn('ADS_USE_TEST_ADS=true',r.stdout)
        self.assertNotIn('ADS_PRODUCTION_READY=true',r.stdout)
    def test_production_ads_need_explicit_readiness(self):
        r=self.shell('ad_flags release',ADS_MODE='production',ADS_PRODUCTION_READY='false')
        self.assertNotEqual(r.returncode,0)
    def test_backend_rejects_embedded_secrets(self):
        r=self.shell('build_api development',API_BASE_URL='https://user:secret@example.com/api/v1')
        self.assertNotEqual(r.returncode,0)
        self.assertNotIn('secret',r.stdout+r.stderr)

    def test_license_records_are_only_read_and_missing_acceptance_blocks(self):
        sdk=self.root/'sdk'; (sdk/'licenses').mkdir(parents=True)
        record=sdk/'licenses/android-sdk-license'
        record.write_text('not-accepted')
        with self.assertRaises(ValueError): checks.license_state(str(sdk))
        record.write_text(checks.PINS['PILOGY_ANDROID_LICENSE_HASH']+'\n')
        before=record.read_bytes()
        checks.license_state(str(sdk))
        self.assertEqual(record.read_bytes(),before)
    def test_no_global_flutter_fallback(self):
        # Verify explicit refusal in an isolated root, regardless of the developer's SDK.
        root=self.root/'project';(root/'scripts/lib').mkdir(parents=True)
        shutil.copy(ROOT/'scripts/lib/environment.sh',root/'scripts/lib/environment.sh')
        shutil.copy(ROOT/'scripts/toolchain.env',root/'scripts/toolchain.env')
        r=subprocess.run(['bash','-c','source scripts/lib/environment.sh; flutter_sdk'],cwd=root,capture_output=True,text=True)
        self.assertNotEqual(r.returncode,0)
        self.assertIn('Pinned SDK missing',r.stderr)
    def test_setup_reuses_existing_dependencies_twice_with_stubbed_tools(self):
        # This verifies shell orchestration only, not real SDK installation or builds.
        import os
        root=self.root/'project'; root.mkdir()
        shutil.copytree(ROOT/'scripts',root/'scripts')
        (root/'scripts/environment_checks.py').write_text('import sys\n')
        (root/'scripts/verify_admob.py').write_text('')
        (root/'scripts/doctor.sh').write_text('#!/bin/bash\nexit 0\n')
        (root/'scripts/doctor.sh').chmod(0o755)
        bins=root/'fake-bin';bins.mkdir()
        calls=root/'calls'
        def tool(path,text):
            path.parent.mkdir(parents=True,exist_ok=True)
            path.write_text('#!/bin/bash\n'+text+'\n');path.chmod(0o755)
        tool(bins/'uname', 'if [[ "${1:-}" == -m ]]; then echo arm64; else echo Darwin; fi')
        tool(bins/'sw_vers', 'echo test-macOS')
        tool(bins/'xcode-select','echo /fake/Xcode')
        tool(bins/'brew','echo brew-install >> "$TEST_CALLS"; exit 99')
        tool(bins/'fvm','echo fvm >> "$TEST_CALLS"')
        sdk=root/'android-sdk'
        for relative in ['platforms/android-36','build-tools/35.0.0','ndk/28.2.13676358','cmake/3.22.1','platform-tools']:
            p=sdk/relative/'source.properties';p.parent.mkdir(parents=True,exist_ok=True);p.write_text('fixture')
        tool(sdk/'cmdline-tools/23.0/bin/sdkmanager','echo sdk-install >> "$TEST_CALLS"; exit 99')
        java=root/'java'
        tool(java/'bin/java', "echo 'openjdk version \"17.0.21\"'")
        tool(root/'.fvm/flutter_sdk/bin/flutter','echo flutter >> "$TEST_CALLS"')
        env={**os.environ,'PATH':str(bins)+':'+os.environ['PATH'],'PILOGY_JAVA_HOME':str(java),
             'ANDROID_HOME':str(sdk),'ANDROID_SDK_ROOT':str(sdk),'TEST_CALLS':str(calls)}
        for _ in range(2):
            r=subprocess.run(['bash','scripts/setup.sh','--android'],cwd=root,env=env,capture_output=True,text=True)
            self.assertEqual(r.returncode,0,r.stdout+r.stderr)
        log=calls.read_text()
        self.assertNotIn('brew-install',log)
        self.assertNotIn('sdk-install',log)
        self.assertEqual(log.count('flutter'),2)

if __name__=='__main__': unittest.main()
