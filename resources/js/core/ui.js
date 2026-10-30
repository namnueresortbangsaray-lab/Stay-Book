import { escapeHtml as h } from './dom.js';
import { icon } from './icons.js';

const variants = new Set(['primary', 'secondary', 'ghost', 'destructive', 'link']);
const sizes = new Set(['sm', 'md', 'lg']);
let openMenu = null;
let menuTrigger = null;

function attrs(values) {
  return Object.entries(values)
    .filter(([, value]) => value !== undefined && value !== null && value !== false)
    .map(([name, value]) => value === true ? name : `${name}="${h(value)}"`)
    .join(' ');
}

export function button({
  label,
  variant = 'secondary',
  size = 'md',
  iconName = '',
  type = 'button',
  className = '',
  attributes = {},
  iconOnly = false,
}) {
  const tone = variants.has(variant) ? variant : 'secondary';
  const scale = sizes.has(size) ? size : 'md';
  const classes = iconOnly
    ? `icon-button icon-button-${scale} ${tone === 'destructive' ? 'icon-button-destructive' : ''} ${className}`
    : `btn btn-${tone} btn-${scale} ${className}`;
  const accessible = iconOnly ? { 'aria-label': label, title: label } : {};
  const content = `${iconName ? icon(iconName, scale === 'sm' ? 'h-4 w-4' : 'h-5 w-5') : ''}${iconOnly ? '<span class="sr-only">' + h(label) + '</span>' : '<span>' + h(label) + '</span>'}`;
  return `<button ${attrs({ type, class: classes.trim(), ...accessible, ...attributes })}>${content}</button>`;
}

export function iconButton(options) {
  return button({ ...options, iconOnly: true });
}

export function menuTriggerButton({ context, id, label = 'การทำงานเพิ่มเติม', size = 'md' }) {
  return iconButton({
    label,
    iconName: 'more',
    size,
    attributes: {
      'data-menu-trigger': context,
      'data-id': id,
      'aria-haspopup': 'menu',
      'aria-expanded': 'false',
    },
  });
}

export function segmentedControl({ label, options, value, dataAttribute }) {
  return `<div class="segmented-control" role="group" aria-label="${h(label)}">${options.map(option => `
    <button type="button" class="segmented-control-item" aria-pressed="${option.value === value}" data-${dataAttribute}="${h(option.value)}">
      ${option.icon ? icon(option.icon, 'h-4 w-4') : ''}<span>${h(option.label)}</span>
    </button>
  `).join('')}</div>`;
}

export function selectControl({ id = '', name = '', label = '', value = '', options = [], attributes = {} }) {
  return `<label class="select-control"${label ? '' : ' aria-label="ตัวเลือก"'}>
    ${label ? `<span class="label">${h(label)}</span>` : ''}
    <select ${attrs({ id, name, class: 'field select-field', ...attributes })}>
      ${options.map(option => `<option value="${h(option.value)}" ${String(option.value) === String(value) ? 'selected' : ''}>${h(option.label)}</option>`).join('')}
    </select>
  </label>`;
}

export function splitButton({ label, action, alternatives = [], id = '' }) {
  return `<div class="split-button">
    ${button({ label, variant: 'primary', attributes: { 'data-action': action, 'data-id': id } })}
    ${iconButton({
      label: `${label} ตัวเลือกเพิ่มเติม`,
      iconName: 'chevronDown',
      attributes: {
        'data-split-items': JSON.stringify(alternatives),
        'aria-haspopup': 'menu',
        'aria-expanded': 'false',
      },
    })}
  </div>`;
}

export function setButtonLoading(target, loading, loadingLabel = 'กำลังบันทึก') {
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

export function openDropdownMenu(trigger, items, label = 'เมนูการทำงาน') {
  closeDropdownMenu();
  menuTrigger = trigger;
  trigger.setAttribute('aria-expanded', 'true');

  const layer = document.createElement('div');
  layer.className = 'action-menu-layer';
  layer.innerHTML = `
    <div class="action-menu-backdrop" data-menu-dismiss></div>
    <div class="action-menu" role="menu" aria-label="${h(label)}">
      <div class="action-menu-mobile-header">
        <strong>${h(label)}</strong>
        ${iconButton({ label: 'ปิดเมนู', iconName: 'close', size: 'sm', attributes: { 'data-menu-dismiss': true } })}
      </div>
      ${items.map(item => item.separator ? '<div class="action-menu-separator" role="separator"></div>' : `
        <button type="button" class="action-menu-item ${item.destructive ? 'action-menu-item-danger' : ''}" role="menuitem" data-action="${h(item.action)}" data-id="${h(item.id || '')}" ${item.disabled ? 'disabled' : ''}>
          ${icon(item.icon || 'more', 'h-4 w-4 shrink-0')}<span>${h(item.label)}</span>
        </button>
      `).join('')}
    </div>`;
  document.body.append(layer);
  openMenu = layer;

  const menu = layer.querySelector('.action-menu');
  if (window.matchMedia('(min-width: 768px)').matches) {
    const rect = trigger.getBoundingClientRect();
    const width = Math.min(240, window.innerWidth - 24);
    menu.style.width = `${width}px`;
    menu.style.left = `${Math.max(12, Math.min(rect.right - width, window.innerWidth - width - 12))}px`;
    menu.style.top = `${Math.min(rect.bottom + 8, window.innerHeight - menu.offsetHeight - 12)}px`;
  }

  const focusable = [...menu.querySelectorAll('[role="menuitem"]:not([disabled])')];
  focusable[0]?.focus();
  menu.addEventListener('keydown', event => {
    const index = focusable.indexOf(document.activeElement);
    if (event.key === 'ArrowDown') {
      event.preventDefault();
      focusable[(index + 1) % focusable.length]?.focus();
    }
    if (event.key === 'ArrowUp') {
      event.preventDefault();
      focusable[(index - 1 + focusable.length) % focusable.length]?.focus();
    }
    if (event.key === 'Home') {
      event.preventDefault();
      focusable[0]?.focus();
    }
    if (event.key === 'End') {
      event.preventDefault();
      focusable.at(-1)?.focus();
    }
    if (event.key === 'Escape') {
      event.preventDefault();
      closeDropdownMenu({ restoreFocus: true });
    }
  });
}

document.addEventListener('click', event => {
  const splitTrigger = event.target.closest('[data-split-items]');
  if (splitTrigger) {
    try {
      openDropdownMenu(splitTrigger, JSON.parse(splitTrigger.dataset.splitItems), splitTrigger.getAttribute('aria-label'));
    } catch {
      closeDropdownMenu();
    }
    return;
  }
  if (event.target.closest('[data-menu-dismiss]')) closeDropdownMenu({ restoreFocus: true });
});

window.addEventListener('keydown', event => {
  if (event.key === 'Escape' && openMenu) closeDropdownMenu({ restoreFocus: true });
});

