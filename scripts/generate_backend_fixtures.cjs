// Run from mobile/. Uses the backend's installed esbuild; never modifies backend files.
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const { spawnSync } = require('node:child_process');
const backend = path.resolve(__dirname, '../../api/numerology-api');
const esbuild = require(path.join(backend, 'node_modules/esbuild'));
const route = (suffix) => JSON.stringify(path.join(backend, 'app/api/v1', suffix, 'route.ts'));
const fixtureRoot = JSON.stringify(path.resolve(__dirname, '../test/fixtures'));
const source = `
import {GET as health} from ${route('health')};
import {GET as config} from ${route('config')};
import {GET as definitions} from ${route('numerology/definitions')};
import {POST as calculate} from ${route('numerology/calculate')};
import {GET as article} from ${route('numerology/interpretations/[index]/[value]')};
import {writeFileSync} from 'node:fs';
import {join} from 'node:path';
const req = path => new Request('https://fixture.invalid/api/v1/' + path);
async function main() {
 const responses = {
  health: health(req('health')), config: config(req('config')),
  definitions: definitions(req('numerology/definitions?locale=vi')),
  article: await article(req('numerology/interpretations/personality/11?locale=vi'),
   {params: Promise.resolve({index:'personality',value:'11'})}),
  calculation: await calculate(new Request('https://fixture.invalid/api/v1/numerology/calculate', {
   method:'POST', headers:{'content-type':'application/json'},
   body:JSON.stringify({fullName:'Nguyễn Văn An',birthDate:'1990-05-20',referenceDate:'2026-11-08',locale:'vi'})}))
 };
 const expected = {lifePath:8,expression:3,soulUrge:1,personality:11,birthday:2,attitude:7,maturity:11,personalYear:8,personalMonth:1};
 for (const [key,response] of Object.entries(responses)) {
  if (response.status !== 200) throw new Error('Local route fixture failed');
  const body = await response.json();
  if (key === 'calculation') {
   for (const [type,value] of Object.entries(expected)) {
    if (body.data.indices[type].value !== value || body.data.interpretations[type].value !== value)
     throw new Error('Local fixture mapping mismatch');
   }
   if (body.data.indices.personality.baseValue !== 2 || body.data.indices.maturity.baseValue !== 2)
    throw new Error('Local master base mismatch');
  }
  writeFileSync(join(${fixtureRoot},key+'.json'),JSON.stringify(body,null,2)+'\\n');
 }
 console.log('PASS: five existing backend route handlers; nine fixture values and Master summary/base mapping. No live HTTP or Dart/SQLite verification.');
}
main().catch(() => { console.error('Local fixture generation failed'); process.exitCode=1; });
`;
const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'pilogy-fixtures-'));
try {
 const outfile = path.join(temporary, 'fixture.cjs');
 esbuild.buildSync({stdin:{contents:source,resolveDir:backend,loader:'ts'},bundle:true,
  platform:'node',format:'cjs',tsconfig:path.join(backend,'tsconfig.json'),outfile});
 const result = spawnSync(process.execPath,[outfile],{stdio:'inherit'});
 process.exitCode = result.status ?? 1;
} finally { fs.rmSync(temporary,{recursive:true,force:true}); }
