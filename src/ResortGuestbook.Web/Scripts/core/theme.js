// Light / Dark / System theme. The head script (_ThemeBoot) applies it before first paint; this module handles
// changes: saves to localStorage and a cookie (so the server can render the right theme), follows the OS in System
// mode, and syncs other tabs.
const root = document.documentElement;
const media = window.matchMedia('(prefers-color-scheme: dark)');

export const themePreference = () => root.dataset.themePref || 'system';

function apply(preference, animate) {
  const resolved = preference === 'system' ? (media.matches ? 'dark' : 'light') : preference;
  if (animate) {
    root.classList.add('theme-switching');
    window.setTimeout(() => root.classList.remove('theme-switching'), 200);
  }
  root.dataset.themePref = preference;
  root.dataset.theme = resolved;
  const meta = document.querySelector('meta[name="theme-color"]');
  meta?.setAttribute('content', meta.dataset[resolved]);
  document.querySelectorAll('[data-theme-option]').forEach(option => {
    const selected = option.dataset.themeOption === preference;
    option.setAttribute(option.getAttribute('role') === 'menuitemradio' ? 'aria-checked' : 'aria-pressed', String(selected));
  });
}

export function setTheme(preference) {
  if (!['light', 'dark', 'system'].includes(preference)) return;
  try {
    localStorage.setItem('theme', preference);
  } catch {
    // Private mode: the cookie still carries the choice.
  }
  document.cookie = `theme=${preference}; path=/; max-age=31536000; samesite=lax`;
  apply(preference, true);
}

export function initTheme() {
  apply(themePreference(), false);
  media.addEventListener('change', () => {
    if (themePreference() === 'system') apply('system', true);
  });
  window.addEventListener('storage', event => {
    if (event.key === 'theme' && event.newValue) apply(event.newValue, true);
  });
  document.addEventListener('click', event => {
    const option = event.target.closest('[data-theme-option]');
    if (option) setTheme(option.dataset.themeOption);
  });
}
