// Per-device display preferences: table density and sidebar state (applied early by _ThemeBoot).
const root = document.documentElement;

const save = (key, value) => {
  try {
    localStorage.setItem(key, value);
  } catch {
    // Preference simply isn't remembered.
  }
};

const isRail = () => root.dataset.sidebar === 'collapsed'
  || (root.dataset.sidebar !== 'expanded' && window.matchMedia('(min-width: 640px) and (max-width: 1279px)').matches);

function sync() {
  document.querySelectorAll('[data-action="toggle-density"]').forEach(button => button.setAttribute('aria-pressed', String(root.dataset.density === 'compact')));
  // The top-bar menu button collapses the sidebar to an icon rail (and back); its state is the sidebar's expansion.
  document.querySelectorAll('[data-action="toggle-sidebar"]').forEach(button => button.setAttribute('aria-expanded', String(!isRail())));
}

export function initPreferences() {
  sync();
  document.addEventListener('click', event => {
    const button = event.target.closest('[data-action="toggle-density"], [data-action="toggle-sidebar"]');
    if (!button) return;
    if (button.dataset.action === 'toggle-density') {
      const compact = root.dataset.density !== 'compact';
      if (compact) root.dataset.density = 'compact';
      else delete root.dataset.density;
      save('density', compact ? 'compact' : 'comfortable');
    } else {
      const next = isRail() ? 'expanded' : 'collapsed';
      root.dataset.sidebar = next;
      save('sidebar', next);
    }
    sync();
  });
  window.matchMedia('(min-width: 640px) and (max-width: 1279px)').addEventListener('change', sync);
}
