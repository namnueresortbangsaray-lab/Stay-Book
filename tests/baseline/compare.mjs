// Compares a replay (BASELINE_OUT=replay node capture.mjs) with the recorded PHP baseline.
// Usage: node tests/baseline/compare.mjs [replayDir]   — exits 1 when an unexpected difference is found.
import { readFileSync, readdirSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const baselineDir = join(here, 'cases');
const replayDir = resolve(here, process.argv[2] ?? 'replay');
const deviations = JSON.parse(readFileSync(join(here, 'deviations.json'), 'utf8'));

const UUID = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi;
const TIMESTAMP = /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\+00:00/g;
const STORED = /[0-9a-f]{48}\.(webp|png|jpg|pdf)/g;
const VOLATILE_KEYS = new Set(['today']);
const COMPARED_HEADERS = ['content-type', 'content-disposition', 'location', 'x-content-type-options', 'x-frame-options', 'referrer-policy', 'permissions-policy'];

const mask = value => {
  if (typeof value === 'string') return value.replace(UUID, '<uuid>').replace(TIMESTAMP, '<ts>').replace(STORED, '<stored>');
  if (Array.isArray(value)) return value.map(mask);
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, VOLATILE_KEYS.has(k) ? '<volatile>' : mask(v)]));
  }
  return value;
};
const normalizeType = v => v?.toLowerCase().replace(/\s+/g, '');
const today = /\d{4}-\d{2}-\d{2}/g;

const differences = [];
for (const file of readdirSync(baselineDir).filter(f => f !== '_index.json').sort()) {
  const name = file.replace(/^\d+-/, '').replace(/\.json$/, '');
  let replay;
  try { replay = JSON.parse(readFileSync(join(replayDir, file), 'utf8')); } catch { differences.push([name, 'missing in replay']); continue; }
  const base = JSON.parse(readFileSync(join(baselineDir, file), 'utf8'));
  const allowed = deviations[name] ?? [];
  const report = (what, expected, actual) => {
    if (!allowed.includes(what)) differences.push([name, what, expected, actual]);
  };

  if (base.status !== replay.status) report('status', base.status, replay.status);
  for (const header of COMPARED_HEADERS) {
    if (header === 'content-type' && base.status >= 300 && base.status < 400) continue;
    let expected = base.headers[header];
    let actual = replay.headers[header];
    if (header === 'content-type') { expected = normalizeType(expected); actual = normalizeType(actual); }
    if (header === 'content-disposition') { expected = expected?.replace(today, '<date>'); actual = actual?.replace(today, '<date>'); }
    if (expected !== actual) report(`header:${header}`, expected, actual);
  }
  if (base.status >= 300 && base.status < 400 && base.status === replay.status) continue; // redirects: only status and location matter
  const b = base.body;
  const r = replay.body;
  if (b.kind !== r.kind) { report('body:kind', b.kind, r.kind); continue; }
  if (b.kind === 'json') {
    const expected = JSON.stringify(mask(b.json));
    const actual = JSON.stringify(mask(r.json));
    if (expected !== actual) report('body:json', expected, actual);
  } else if (b.kind === 'html') {
    if (b.title !== r.title) report('body:title', b.title, r.title);
    const missingIds = b.ids.filter(id => !r.ids.includes(id));
    if (missingIds.length) report('body:ids', missingIds.join(','), '(missing)');
    const missingText = b.text.filter(t => !r.text.includes(t));
    if (missingText.length) report('body:text', missingText.join(' | '), '(missing)');
  } else if (b.kind === 'csv') {
    const expected = mask(b.text);
    const actual = mask(r.text);
    if (expected !== actual) report('body:csv', expected, actual);
  }
}

for (const [name, what, expected, actual] of differences) {
  console.log(`✗ ${name} — ${what}`);
  if (expected !== undefined) console.log(`    PHP : ${String(expected).slice(0, 600)}`);
  if (actual !== undefined) console.log(`    .NET: ${String(actual).slice(0, 600)}`);
}
console.log(differences.length ? `${differences.length} unexpected difference(s)` : 'No unexpected differences');
process.exit(differences.length ? 1 : 0);
