"""Optional bounded HTTP smoke checks with synthetic data; no response payload logs."""
import json
import urllib.request
from pathlib import Path

base = 'https://pilogy.vercel.app/api/v1/'
checks = {}
for key, route in [('health', 'health'), ('config', 'config'),
                   ('definitions', 'numerology/definitions?locale=vi'),
                   ('article', 'numerology/interpretations/personality/11?locale=vi'),
                   ('calculation', 'numerology/calculate')]:
    try:
        data = json.dumps({'fullName': 'Nguyễn Văn An', 'birthDate': '1990-05-20',
                           'referenceDate': '2026-11-08', 'locale': 'vi'}).encode() if key == 'calculation' else None
        request = urllib.request.Request(base + route, data=data,
                                         headers={'Content-Type': 'application/json', 'Accept': 'application/json'})
        with urllib.request.urlopen(request, timeout=10) as response:
            body = json.load(response)
            checks[key] = {'status': response.status, 'success': body.get('success')}
            if key == 'calculation':
                result = body['data']
                expected = {'lifePath': 8, 'expression': 3, 'soulUrge': 1, 'personality': 11,
                            'birthday': 2, 'attitude': 7, 'maturity': 11, 'personalYear': 8, 'personalMonth': 1}
                checks[key].update(valuesMatch=all(result['indices'][t]['value'] == v for t, v in expected.items()),
                                   calculationVersion=result['calculationVersion'], contentVersion=result['contentVersion'],
                                   referenceDate=result['referenceDate'],
                                   masterMapping=result['interpretations']['personality']['value'] == 11)
    except Exception as error:
        checks[key] = {'errorType': type(error).__name__, 'status': getattr(error, 'code', None)}
report = Path(__file__).resolve().parent.parent / 'docs/verification/m03/live-http.json'
report.write_text(json.dumps(checks, indent=2) + '\n')
print(json.dumps(checks, indent=2))
