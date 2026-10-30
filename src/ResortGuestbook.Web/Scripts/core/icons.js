// Decorative Lucide icon from the versioned sprite (/icons.svg, built from icon-set.js).
const sprite = document.querySelector('meta[name="icon-sprite"]')?.content || '/icons.svg';

export function icon(name, className = '') {
  return `<svg class="icon ${className}" aria-hidden="true" focusable="false"><use href="${sprite}#${name}"></use></svg>`;
}
