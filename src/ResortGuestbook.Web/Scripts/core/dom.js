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

export function toast(message, type = 'success') {
  const container = $('#toast-region');
  if (!container) return;
  const isError = type === 'error';
  const el = document.createElement('div');
  el.className = `toast ${isError ? 'tone-danger' : 'tone-success'}`;
  el.innerHTML = `${icon(isError ? 'error' : 'success')}<span>${escapeHtml(message)}</span>`;
  container.append(el);
  window.setTimeout(() => el.remove(), isError ? 7000 : 4200);
}

export function formObject(form) {
  const data = Object.fromEntries(new FormData(form));
  for (const input of form.querySelectorAll('input[type="checkbox"]')) {
    data[input.name] = input.checked;
  }
  return data;
}
