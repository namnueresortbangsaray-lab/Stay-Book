// Builds Styles/app.css (Tailwind) and Scripts/app.js (esbuild bundle) into wwwroot. Views use asp-append-version for cache busting.
import { spawn, execFileSync } from 'node:child_process';
import { context, build } from 'esbuild';

const watch = process.argv.includes('--watch');
const tailwind = ['node_modules/tailwindcss/lib/cli.js', '-i', 'Styles/app.css', '-o', 'wwwroot/css/app.css', '--minify'];
const scripts = { entryPoints: ['Scripts/app.js'], bundle: true, minify: true, sourcemap: false, target: 'es2020', outfile: 'wwwroot/js/app.js' };

if (watch) {
  spawn(process.execPath, [...tailwind, '--watch'], { stdio: 'inherit' });
  await (await context(scripts)).watch();
} else {
  execFileSync(process.execPath, tailwind, { stdio: 'inherit' });
  await build(scripts);
}
