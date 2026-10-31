// Front-end build: contrast gate, self-hosted fonts, Lucide sprite, Tailwind CSS and the esbuild bundle → wwwroot.
// Views reference the outputs with asp-append-version / IFileVersionProvider for cache busting.
import { spawn, execFileSync } from 'node:child_process';
import { copyFileSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { build, context } from 'esbuild';
import { ICONS } from './Scripts/core/icon-set.js';

const watch = process.argv.includes('--watch');

execFileSync(process.execPath, ['build/check-contrast.mjs'], { stdio: 'inherit' });

mkdirSync('wwwroot/fonts', { recursive: true });
const fonts = [
  ...['thai', 'latin'].flatMap(subset => [400, 500, 600].map(weight => `@fontsource/ibm-plex-sans-thai/files/ibm-plex-sans-thai-${subset}-${weight}-normal.woff2`)),
  ...['thai', 'latin'].map(subset => `@fontsource/noto-serif-thai/files/noto-serif-thai-${subset}-600-normal.woff2`),
];
for (const font of fonts) copyFileSync(`node_modules/${font}`, `wwwroot/fonts/${font.split('/').pop()}`);

const symbols = Object.entries(ICONS).map(([name, lucide]) => {
  const svg = readFileSync(`node_modules/lucide-static/icons/${lucide}.svg`, 'utf8');
  const inner = svg.slice(svg.indexOf('>', svg.indexOf('<svg')) + 1, svg.lastIndexOf('</svg>')).replace(/\s*\n\s*/g, '');
  return `<symbol id="${name}" viewBox="0 0 24 24">${inner}</symbol>`;
});
writeFileSync('wwwroot/icons.svg', `<svg xmlns="http://www.w3.org/2000/svg"><!-- Lucide icons, ISC licence -->${symbols.join('')}</svg>\n`);

const tailwind = ['node_modules/tailwindcss/lib/cli.js', '-i', 'Styles/app.css', '-o', 'wwwroot/css/app.css', '--minify'];
const scripts = { entryPoints: ['Scripts/app.js'], bundle: true, minify: true, sourcemap: false, target: 'es2020', outfile: 'wwwroot/js/app.js' };

if (watch) {
  spawn(process.execPath, [...tailwind, '--watch'], { stdio: 'inherit' });
  await (await context(scripts)).watch();
} else {
  execFileSync(process.execPath, tailwind, { stdio: 'inherit' });
  await build(scripts);
}
