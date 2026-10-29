import { icon } from './icons.js';

export const $ = (selector, root = document) => root.querySelector(selector);
export const $$ = (selector, root = document) => [...root.querySelectorAll(selector)];
export const escapeHtml = (value = '') => String(value).replace(/[&<>'"]/g, char => ({
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  "'": '&#39;',
  '"': '&quot;'
}[char]));

export function toast(message, type = 'success') {
  const container = $('#toast-region');
  if (!container) return;

  const el = document.createElement('div');
  const isError = type === 'error';

  el.className = `flex items-center gap-3 rounded-2xl px-4 py-3 text-sm font-medium shadow-dialog border transition-all duration-300 ease-luxury transform translate-y-2 opacity-0 ${
    isError
      ? 'border-red-200 bg-white text-red-700'
      : 'border-line bg-ink text-white'
  }`;

  const iconSvg = isError ? icon('close', 'w-4 h-4 text-red-500 shrink-0') : icon('check', 'w-4 h-4 text-emerald-400 shrink-0');
  el.innerHTML = `${iconSvg}<span>${escapeHtml(message)}</span>`;

  container.append(el);

  // Trigger enter animation
  requestAnimationFrame(() => {
    el.classList.remove('translate-y-2', 'opacity-0');
    el.classList.add('translate-y-0', 'opacity-100');
  });

  setTimeout(() => {
    el.classList.remove('translate-y-0', 'opacity-100');
    el.classList.add('-translate-y-2', 'opacity-0');
    setTimeout(() => el.remove(), 300);
  }, 4200);
}

export function formObject(form) {
  const data = Object.fromEntries(new FormData(form));
  for (const input of form.querySelectorAll('input[type="checkbox"]')) {
    data[input.name] = input.checked;
  }
  return data;
}
