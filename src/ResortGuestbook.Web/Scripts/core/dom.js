import { t } from './i18n.js';
import { icon } from './icons.js';

export const $ = (selector, root = document) => root.querySelector(selector);
export const $$ = (selector, root = document) => [...root.querySelectorAll(selector)];
export const escapeHtml = (value = '') => String(value).replace(/[&<>'"]/g, char => ({
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  "'": '&#39;',
  '"': '&quot;',
}[char]));

/** Short status message: closes itself (4 s, errors 6 s), pauses while hovered or focused, and has a close button. */
export function toast(message, type = 'success') {
  const container = $('#toast-region');
  if (!container) return;
  const isError = type === 'error';
  const el = document.createElement('div');
  el.className = `toast ${isError ? 'tone-danger' : 'tone-success'}`;
  el.innerHTML = `${icon(isError ? 'error' : 'success')}<span class="min-w-0 flex-1">${escapeHtml(message)}</span><button type="button" class="toast-close" aria-label="${escapeHtml(t('ui.close'))}" title="${escapeHtml(t('ui.close'))}">${icon('close')}</button>`;
  container.append(el);

  let remaining = isError ? 6000 : 4000;
  let started = Date.now();
  let timer = window.setTimeout(() => el.remove(), remaining);
  let paused = false;
  const pause = () => {
    if (paused) return;
    paused = true;
    window.clearTimeout(timer);
    remaining -= Date.now() - started;
  };
  const resume = () => {
    if (!paused || el.matches(':hover, :focus-within')) return;
    paused = false;
    started = Date.now();
    timer = window.setTimeout(() => el.remove(), Math.max(remaining, 1500));
  };
  el.addEventListener('pointerenter', pause);
  el.addEventListener('focusin', pause);
  el.addEventListener('pointerleave', resume);
  el.addEventListener('focusout', () => window.setTimeout(resume));
  el.querySelector('.toast-close').addEventListener('click', () => {
    window.clearTimeout(timer);
    el.remove();
  });
}

export function formObject(form) {
  const data = Object.fromEntries(new FormData(form));
  for (const input of form.querySelectorAll('input[type="checkbox"]')) {
    data[input.name] = input.checked;
  }
  return data;
}
