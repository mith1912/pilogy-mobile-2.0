"""Embed synthetic backend fixtures in the integration-test bundle, never lib/assets."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
source="// Generated from test/fixtures via scripts/generate_flutter_test_fixtures.py.\n// Test-only synthetic data; not included in production application assets.\nconst fixtureBodies = <String,String>{\n"
for path in sorted((root/'test/fixtures').glob('*.json')):
    body=path.read_text()
    assert "'''" not in body
    source += "  '"+path.stem+"': r'''"+body+"''',\n"
source += '};\n'
(root/'integration_test/fixture_data.dart').write_text(source)
