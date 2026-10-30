// UI strings come from Resources/SharedResource.<culture>.resx, rendered by _Layout as JSON (data, not script).
let strings = null;

function load() {
  if (strings) return strings;
  try {
    strings = JSON.parse(document.getElementById('ui-strings')?.textContent || '{}');
  } catch {
    strings = {};
  }
  return strings;
}

/** t('ui.table.showing', { from: 1, to: 25, total: 40 }) — named {placeholders}. */
export function t(key, values) {
  const text = load()[key] ?? key;
  return values ? text.replace(/\{(\w+)\}/g, (_, name) => String(values[name] ?? '')) : text;
}
