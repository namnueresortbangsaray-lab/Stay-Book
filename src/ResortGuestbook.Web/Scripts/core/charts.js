import { escapeHtml as h } from './dom.js';

/** Bar chart as inline SVG, coloured by tokens (.chart .bar). Values also appear in each bar's <title>. */
export function barChart({ points, label, format = String, height = 230 }) {
  // Fixed coordinate width so labels keep a readable size however many days are shown.
  const width = 640;
  const left = 64;
  const top = 12;
  const bottom = 28;
  const step = (width - left) / Math.max(1, points.length);
  const barWidth = Math.max(4, Math.min(28, step * 0.62));
  const max = Math.max(1, ...points.map(p => p.value));
  const scale = value => (height - top - bottom) * (value / max);
  const ticks = [0, max / 2, max];
  const every = Math.max(1, Math.ceil(points.length / 10));

  const grid = ticks.map(tick => {
    const y = height - bottom - scale(tick);
    return `<line class="grid-line" x1="${left}" x2="${width}" y1="${y}" y2="${y}" /><text class="axis" x="${left - 8}" y="${y + 4}" text-anchor="end">${h(format(tick))}</text>`;
  }).join('');
  const bars = points.map((p, i) => {
    const x = left + i * step + (step - barWidth) / 2;
    const barHeight = Math.max(p.value ? 2 : 0, scale(p.value));
    return `<rect class="bar" x="${x}" y="${height - bottom - barHeight}" width="${barWidth}" height="${barHeight}" rx="2"><title>${h(p.title)}</title></rect>`
      + (i % every === 0 ? `<text class="axis" x="${x + barWidth / 2}" y="${height - 8}" text-anchor="middle">${h(p.label)}</text>` : '');
  }).join('');

  return `<svg class="chart" viewBox="0 0 ${width} ${height}" role="img" aria-label="${h(label)}">${grid}${bars}</svg>`;
}

/** Accessible data table behind a chart: hidden until requested, always shown when printing. */
export function chartTable({ id, caption, headers, rows }) {
  return `<div id="${id}" class="chart-table mt-4" hidden><table class="data-table"><caption class="sr-only">${h(caption)}</caption><thead><tr>${headers.map((x, i) => `<th scope="col" class="${i ? 'num' : ''}">${h(x)}</th>`).join('')}</tr></thead><tbody>${rows.map(r => `<tr>${r.map((x, i) => `<td class="${i ? 'num' : ''}">${h(x)}</td>`).join('')}</tr>`).join('')}</tbody></table></div>`;
}
