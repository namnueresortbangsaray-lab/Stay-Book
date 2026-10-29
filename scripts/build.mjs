import { build, context } from 'esbuild';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const out = 'public/build';
mkdirSync(out, { recursive: true });
for (const file of readdirSync(out)) rmSync(join(out, file), { force: true });
execFileSync(process.execPath, ['node_modules/tailwindcss/lib/cli.js', '-i', 'resources/css/app.css', '-o', `${out}/app.css`, '--minify'], { stdio: 'inherit' });
await build({ entryPoints: ['resources/js/app.js'], bundle: true, minify: true, sourcemap: false, target: 'es2020', outfile: `${out}/app.js` });
const manifest = {};
for (const type of ['css', 'js']) {
  const source = `${out}/app.${type}`;
  const hash = createHash('sha256').update(readFileSync(source)).digest('hex').slice(0, 12);
  const target = `${out}/app-${hash}.${type}`;
  await import('node:fs').then(({ renameSync }) => renameSync(source, target));
  manifest[`app.${type}`] = `/build/app-${hash}.${type}`;
}
writeFileSync(`${out}/manifest.json`, JSON.stringify(manifest, null, 2));
