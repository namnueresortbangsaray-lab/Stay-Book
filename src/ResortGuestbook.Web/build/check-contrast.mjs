// Fails the build when a token pair used for text (4.5:1) or UI parts and focus rings (3:1) misses WCAG AA,
// in the light or the dark theme. Pairs mirror how components use the tokens (see docs/DESIGN_SYSTEM.md).
import { readFileSync } from 'node:fs';

const css = readFileSync(new URL('../Styles/tokens.css', import.meta.url), 'utf8');
const block = selector => {
  const start = css.indexOf(selector);
  const body = css.slice(css.indexOf('{', start) + 1, css.indexOf('}', start));
  return Object.fromEntries([...body.matchAll(/--c-([a-z-]+):\s*(\d+)\s+(\d+)\s+(\d+);/g)].map(m => [m[1], [+m[2], +m[3], +m[4]]]));
};
const themes = { light: block(":root,"), dark: block("[data-theme='dark']") };

const luminance = rgb => {
  const [r, g, b] = rgb.map(v => v / 255).map(v => (v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4));
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
};
const ratio = (a, b) => {
  const [x, y] = [luminance(a), luminance(b)].sort((p, q) => q - p);
  return (x + 0.05) / (y + 0.05);
};

const backgrounds = ['canvas', 'surface', 'raised', 'sunken'];
const pairs = [
  ...['ink', 'ink-muted', 'ink-subtle', 'primary', 'danger'].flatMap(fg => backgrounds.map(bg => [fg, bg, 4.5])),
  ['ink', 'primary-subtle', 4.5],
  ['primary', 'primary-subtle', 4.5],
  ['on-primary', 'primary', 4.5],
  ['on-primary', 'primary-hover', 4.5],
  ['accent-ink', 'accent-subtle', 4.5],
  ['accent-ink', 'surface', 4.5],
  ['success', 'success-subtle', 4.5],
  ['warning', 'warning-subtle', 4.5],
  ['danger', 'danger-subtle', 4.5],
  ['info', 'info-subtle', 4.5],
  ['success', 'surface', 4.5],
  ['warning', 'surface', 4.5],
  ['info', 'surface', 4.5],
  ['ink', 'selection', 4.5],
  // Non-text: control borders, focus ring, status icons and chart marks against their surfaces.
  ...['control', 'primary', 'accent', 'success', 'warning', 'danger', 'info'].flatMap(fg => backgrounds.map(bg => [fg, bg, 3])),
];

let failures = 0;
for (const [name, tokens] of Object.entries(themes)) {
  for (const [fg, bg, min] of pairs) {
    if (!tokens[fg] || !tokens[bg]) {
      console.error(`✗ ${name}: missing token ${tokens[fg] ? bg : fg}`);
      failures++;
      continue;
    }
    const value = ratio(tokens[fg], tokens[bg]);
    if (value < min) {
      console.error(`✗ ${name}: ${fg} on ${bg} = ${value.toFixed(2)} (needs ${min})`);
      failures++;
    }
  }
}
if (failures) {
  console.error(`Contrast check failed: ${failures} pair(s) below WCAG AA.`);
  process.exit(1);
}
console.log(`Contrast check passed: ${pairs.length} pairs × ${Object.keys(themes).length} themes meet WCAG AA.`);
