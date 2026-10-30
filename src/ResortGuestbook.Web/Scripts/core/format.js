// Display formatting. Dates use the th-TH locale (Buddhist-era year) exactly as before; values stay ISO.
export const money = satang => new Intl.NumberFormat('th-TH', {
  style: 'currency',
  currency: 'THB',
  minimumFractionDigits: Number(satang) % 100 ? 2 : 0,
}).format(Number(satang || 0) / 100);

export const number = value => new Intl.NumberFormat('th-TH').format(Number(value || 0));

const parse = iso => new Date(`${iso}T00:00:00`);

export const thaiDate = iso => iso
  ? new Intl.DateTimeFormat('th-TH', { day: 'numeric', month: 'short', year: 'numeric' }).format(parse(iso))
  : '—';

export const shortDate = iso => iso
  ? new Intl.DateTimeFormat('th-TH', { day: 'numeric', month: 'short' }).format(parse(iso))
  : '—';

export const longDate = iso => new Intl.DateTimeFormat('th-TH', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }).format(parse(iso));

export const monthTitle = date => new Intl.DateTimeFormat('th-TH', { month: 'long', year: 'numeric' }).format(date);

export const iso = date => `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;

export const nights = (from, to) => Math.max(1, Math.round((parse(to) - parse(from)) / 86400000) || 1);

export const fileSize = bytes => bytes < 1024 * 1024
  ? `${Math.max(1, Math.round(bytes / 1024))} KB`
  : `${(bytes / 1024 / 1024).toFixed(1)} MB`;
