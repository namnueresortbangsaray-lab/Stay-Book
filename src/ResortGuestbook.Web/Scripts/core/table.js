import { escapeHtml as h } from './dom.js';
import { icon } from './icons.js';
import { t } from './i18n.js';
import { iconButton } from './ui.js';

const PAGE_SIZE = 25;

/** Per-table view state: sort, page and hidden optional columns (remembered on this device). */
export function tableState(name, { sort = null, dir = 'asc' } = {}) {
  let hidden = [];
  try {
    hidden = JSON.parse(localStorage.getItem(`columns:${name}`) || '[]');
  } catch {
    hidden = [];
  }
  return { name, sort, dir, page: 1, hidden: new Set(hidden) };
}

export function saveColumns(state) {
  try {
    localStorage.setItem(`columns:${state.name}`, JSON.stringify([...state.hidden]));
  } catch {
    // Not remembered in private mode.
  }
}

/** Escapes text and wraps case-insensitive matches of the query in <mark>. */
export function highlight(text, query) {
  const safe = h(text ?? '');
  const needle = h(query ?? '').toLocaleLowerCase('th');
  if (!needle) return safe;
  const lower = safe.toLocaleLowerCase('th');
  let out = '';
  let from = 0;
  for (let at = lower.indexOf(needle); at !== -1; at = lower.indexOf(needle, from)) {
    out += `${safe.slice(from, at)}<mark>${safe.slice(at, at + needle.length)}</mark>`;
    from = at + needle.length;
  }
  return out + safe.slice(from);
}

const compare = (a, b) => typeof a === 'number' && typeof b === 'number'
  ? a - b
  : String(a ?? '').localeCompare(String(b ?? ''), 'th', { numeric: true });

export function sortRows(state, columns, rows) {
  const column = columns.find(c => c.key === state.sort);
  if (!column?.value) return rows;
  const sorted = [...rows].sort((a, b) => compare(column.value(a), column.value(b)));
  return state.dir === 'desc' ? sorted.reverse() : sorted;
}

/** Applies a header click: same column flips direction, a new column starts with its preferred direction. */
export function toggleSort(state, columns, key) {
  const column = columns.find(c => c.key === key);
  if (state.sort === key) state.dir = state.dir === 'asc' ? 'desc' : 'asc';
  else {
    state.sort = key;
    state.dir = column?.firstDir || 'asc';
  }
  state.page = 1;
}

export function columnMenuItems(state, columns) {
  return [
    { heading: t('ui.table.show_columns') },
    ...columns.filter(c => c.optional).map(c => ({
      label: c.label,
      icon: 'columns',
      role: 'menuitemcheckbox',
      checked: !state.hidden.has(c.key),
      attributes: { 'data-column-toggle': c.key, 'data-table': state.name },
    })),
  ];
}

/** A sortable, paginated table that stacks into cards on phones. */
export function renderTable({ state, columns, rows, caption, empty, paginate = true }) {
  state.columns = columns;
  if (!rows.length) return empty;
  const visible = columns.filter(c => !(c.optional && state.hidden.has(c.key)));
  const sorted = sortRows(state, columns, rows);
  const pages = paginate ? Math.max(1, Math.ceil(sorted.length / PAGE_SIZE)) : 1;
  state.page = Math.min(Math.max(1, state.page), pages);
  const start = paginate ? (state.page - 1) * PAGE_SIZE : 0;
  const pageRows = paginate ? sorted.slice(start, start + PAGE_SIZE) : sorted;

  const head = visible.map(c => {
    const sortAttr = state.sort === c.key ? ` aria-sort="${state.dir === 'asc' ? 'ascending' : 'descending'}"` : '';
    const label = c.hideLabel ? `<span class="sr-only">${h(c.label)}</span>` : h(c.label);
    const content = c.value && c.sortable !== false
      ? `<button type="button" class="sort-btn" data-sort="${c.key}" data-table="${state.name}">${label}${icon(state.sort === c.key ? (state.dir === 'asc' ? 'sortAsc' : 'sortDesc') : 'sort')}</button>`
      : label;
    return `<th scope="col" class="${c.num ? 'num' : ''} ${c.className === 'actions' ? 'actions' : ''}"${sortAttr}>${content}</th>`;
  }).join('');

  const body = pageRows.map((row, index) => `<tr data-row tabindex="${index === 0 ? 0 : -1}">${visible.map(c =>
    `<td data-label="${c.hideLabel ? '' : h(c.label)}" class="${c.num ? 'num' : ''} ${c.mobileHide ? 'mobile-hide' : ''} ${c.className || ''}">${c.cell(row)}</td>`).join('')}</tr>`).join('');

  const footer = paginate && sorted.length > PAGE_SIZE ? `
    <div class="pagination">
      <span>${h(t('ui.table.showing', { from: start + 1, to: start + pageRows.length, total: sorted.length }))}</span>
      <span class="flex items-center gap-1">
        ${iconButton({ label: t('ui.table.previous'), iconName: 'chevronLeft', size: 'sm', attributes: { 'data-table-page': '-1', 'data-table': state.name, disabled: state.page === 1 } })}
        <span class="px-2 tabular-nums">${state.page} / ${pages}</span>
        ${iconButton({ label: t('ui.table.next'), iconName: 'chevronRight', size: 'sm', attributes: { 'data-table-page': '1', 'data-table': state.name, disabled: state.page === pages } })}
      </span>
    </div>` : `<p class="pagination">${h(t('ui.table.count', { total: sorted.length }))}</p>`;

  return `<div class="table-wrap"><table class="data-table stack"><caption class="sr-only">${h(caption)}</caption><thead><tr>${head}</tr></thead><tbody>${body}</tbody></table></div>${footer}`;
}

/** Arrow keys move between rows; Enter runs the row's primary control. */
export function bindRowNavigation() {
  document.addEventListener('keydown', event => {
    const row = event.target.closest?.('tr[data-row]');
    if (!row || event.target !== row) return;
    const rows = [...row.closest('tbody').querySelectorAll('tr[data-row]')];
    const index = rows.indexOf(row);
    const next = { ArrowDown: index + 1, ArrowUp: index - 1, Home: 0, End: rows.length - 1 }[event.key];
    if (next !== undefined && rows[next]) {
      event.preventDefault();
      row.tabIndex = -1;
      rows[next].tabIndex = 0;
      rows[next].focus();
    }
    if (event.key === 'Enter') {
      event.preventDefault();
      row.querySelector('[data-row-primary]')?.click();
    }
  });
}
