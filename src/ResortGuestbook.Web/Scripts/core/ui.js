import { escapeHtml as h } from './dom.js';
import { icon } from './icons.js';
import { t } from './i18n.js';

const variants = { primary: 'btn-primary', secondary: 'btn-secondary', ghost: 'btn-ghost', danger: 'btn-danger', destructive: 'btn-danger' };
let openMenu = null;
let menuTrigger = null;

function attrs(values) {
  return Object.entries(values)
    .filter(([, value]) => value !== undefined && value !== null && value !== false)
    .map(([name, value]) => value === true ? name : `${name}="${h(value)}"`)
    .join(' ');
}

export function button({ label, variant = 'secondary', size = 'md', iconName = '', type = 'button', className = '', attributes = {}, iconOnly = false }) {
  const classes = ['btn', variants[variant] || variants.secondary, size === 'sm' ? 'btn-sm' : size === 'lg' ? 'btn-lg' : '', iconOnly ? 'btn-icon' : '', className]
    .filter(Boolean).join(' ');
  const accessible = iconOnly ? { 'aria-label': label, title: label } : {};
  const content = `${iconName ? icon(iconName) : ''}${iconOnly ? '' : `<span>${h(label)}</span>`}`;
  return `<button ${attrs({ type, class: classes, ...accessible, ...attributes })}>${content}</button>`;
}

export const iconButton = options => button({ variant: 'ghost', ...options, iconOnly: true });

export function menuTriggerButton({ context, id, label = t('ui.menu.more'), size = 'md' }) {
  return iconButton({ label, iconName: 'more', size, attributes: { 'data-menu-trigger': context, 'data-id': id, 'aria-haspopup': 'menu', 'aria-expanded': 'false' } });
}

/** Status pill: colour + icon + text, never colour alone. */
export const pill = (tone, iconName, label) => `<span class="pill tone-${tone}">${iconName ? icon(iconName) : ''}<span>${h(label)}</span></span>`;

export function emptyState({ iconName, title, text = '', action = '' }) {
  return `<div class="empty"><span class="empty-icon">${icon(iconName)}</span><p class="empty-title">${h(title)}</p>${text ? `<p class="empty-text">${h(text)}</p>` : ''}${action ? `<div class="mt-4">${action}</div>` : ''}</div>`;
}

export function setButtonLoading(target, loading, loadingLabel = t('ui.saving')) {
  if (!target) return;
  if (loading) {
    if (!target.dataset.originalContent) target.dataset.originalContent = target.innerHTML;
    target.disabled = true;
    target.setAttribute('aria-busy', 'true');
    target.innerHTML = `<span class="btn-spinner" aria-hidden="true"></span><span>${h(loadingLabel)}</span>`;
    return;
  }
  target.disabled = false;
  target.removeAttribute('aria-busy');
  if (target.dataset.originalContent) {
    target.innerHTML = target.dataset.originalContent;
    delete target.dataset.originalContent;
  }
}

export function closeDropdownMenu({ restoreFocus = false } = {}) {
  if (!openMenu) return;
  openMenu.remove();
  openMenu = null;
  if (menuTrigger) {
    menuTrigger.setAttribute('aria-expanded', 'false');
    if (restoreFocus) menuTrigger.focus();
  }
  menuTrigger = null;
}

function menuItem(item) {
  if (item.separator) return '<div class="action-menu-separator" role="separator"></div>';
  if (item.heading) return `<p class="action-menu-label" role="presentation">${h(item.heading)}</p>`;
  const role = item.role || 'menuitem';
  const checkable = role !== 'menuitem';
  return `<button ${attrs({
    type: 'button',
    class: `action-menu-item ${item.destructive ? 'action-menu-item-danger' : ''}`,
    role,
    'aria-checked': checkable ? String(Boolean(item.checked)) : undefined,
    'data-action': item.action,
    'data-id': item.id,
    disabled: item.disabled,
    ...(item.attributes || {}),
  })}>${icon(item.icon || 'more')}<span>${h(item.label)}</span>${checkable ? icon('check', 'check-mark') : ''}</button>`;
}

/** Opens a keyboard-navigable menu next to the trigger (bottom sheet on phones). */
export function openDropdownMenu(trigger, items, label = t('ui.menu.more')) {
  closeDropdownMenu();
  menuTrigger = trigger;
  trigger.setAttribute('aria-expanded', 'true');

  const layer = document.createElement('div');
  layer.className = 'action-menu-layer';
  layer.innerHTML = `
    <div class="action-menu-backdrop" data-menu-dismiss></div>
    <div class="action-menu" role="menu" aria-label="${h(label)}">
      <div class="action-menu-header"><span>${h(label)}</span>${iconButton({ label: t('ui.close'), iconName: 'close', size: 'sm', attributes: { 'data-menu-dismiss': true } })}</div>
      ${items.map(menuItem).join('')}
    </div>`;
  document.body.append(layer);
  openMenu = layer;

  const menu = layer.querySelector('.action-menu');
  if (window.matchMedia('(min-width: 768px)').matches) {
    const rect = trigger.getBoundingClientRect();
    const width = Math.max(menu.offsetWidth, 208);
    menu.style.left = `${Math.max(12, Math.min(rect.right - width, window.innerWidth - width - 12))}px`;
    const below = rect.bottom + 6;
    menu.style.top = `${below + menu.offsetHeight > window.innerHeight - 12 ? Math.max(12, rect.top - menu.offsetHeight - 6) : below}px`;
  }

  const focusable = [...menu.querySelectorAll('[role^="menuitem"]:not([disabled])')];
  (focusable.find(item => item.getAttribute('aria-checked') === 'true') || focusable[0])?.focus();
  menu.addEventListener('keydown', event => {
    const index = focusable.indexOf(document.activeElement);
    const moves = { ArrowDown: index + 1, ArrowUp: index - 1 + focusable.length, Home: 0, End: focusable.length - 1 };
    if (event.key in moves) {
      event.preventDefault();
      focusable[moves[event.key] % focusable.length]?.focus();
    }
    if (event.key === 'Escape' || event.key === 'Tab') {
      event.preventDefault();
      closeDropdownMenu({ restoreFocus: true });
    }
  });
}

/** Tabs: [role=tablist] > [role=tab][aria-controls]; arrow keys move, panels toggle with `hidden`. */
export function selectTab(tab, focus = false) {
  const list = tab.closest('[role="tablist"]');
  list.querySelectorAll('[role="tab"]').forEach(other => {
    const selected = other === tab;
    other.setAttribute('aria-selected', String(selected));
    other.tabIndex = selected ? 0 : -1;
    const panel = document.getElementById(other.getAttribute('aria-controls'));
    if (panel) panel.hidden = !selected;
  });
  if (focus) tab.focus();
}

document.addEventListener('click', event => {
  const tab = event.target.closest('[role="tab"]');
  if (tab) selectTab(tab);
  if (event.target.closest('[data-menu-dismiss]')) closeDropdownMenu({ restoreFocus: true });
});

document.addEventListener('keydown', event => {
  const tab = event.target.closest?.('[role="tab"]');
  if (tab && ['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) {
    const tabs = [...tab.closest('[role="tablist"]').querySelectorAll('[role="tab"]')];
    const index = tabs.indexOf(tab);
    const next = { ArrowLeft: index - 1 + tabs.length, ArrowRight: index + 1, Home: 0, End: tabs.length - 1 }[event.key] % tabs.length;
    event.preventDefault();
    selectTab(tabs[next], true);
  }
  if (event.key === 'Escape' && openMenu) closeDropdownMenu({ restoreFocus: true });
});
