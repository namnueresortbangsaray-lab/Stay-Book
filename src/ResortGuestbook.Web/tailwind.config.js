const token = name => `rgb(var(--c-${name}) / <alpha-value>)`;

module.exports = {
  content: ['./Views/**/*.cshtml', './Scripts/**/*.js'],
  darkMode: ['selector', '[data-theme="dark"]'],
  theme: {
    colors: {
      transparent: 'transparent',
      current: 'currentColor',
      canvas: token('canvas'),
      surface: token('surface'),
      raised: token('raised'),
      sunken: token('sunken'),
      line: { DEFAULT: token('line'), strong: token('line-strong') },
      control: token('control'),
      ink: { DEFAULT: token('ink'), muted: token('ink-muted'), subtle: token('ink-subtle') },
      primary: { DEFAULT: token('primary'), hover: token('primary-hover'), subtle: token('primary-subtle'), on: token('on-primary') },
      accent: { DEFAULT: token('accent'), ink: token('accent-ink'), subtle: token('accent-subtle') },
      success: { DEFAULT: token('success'), subtle: token('success-subtle') },
      warning: { DEFAULT: token('warning'), subtle: token('warning-subtle') },
      danger: { DEFAULT: token('danger'), subtle: token('danger-subtle') },
      info: { DEFAULT: token('info'), subtle: token('info-subtle') },
    },
    fontFamily: {
      sans: ['Prompt', 'system-ui', '-apple-system', '"Segoe UI"', 'sans-serif'],
    },
    // Six steps; Thai needs at least 1.6 line height.
    fontSize: {
      xs: ['0.75rem', { lineHeight: '1.25rem' }],
      sm: ['0.875rem', { lineHeight: '1.4rem' }],
      base: ['var(--text-base)', { lineHeight: 'var(--text-base-leading)' }],
      lg: ['1.125rem', { lineHeight: '1.8rem' }],
      xl: ['1.375rem', { lineHeight: '2.2rem' }],
      '2xl': ['1.75rem', { lineHeight: '2.8rem' }],
    },
    borderRadius: {
      none: '0',
      sm: '4px',
      DEFAULT: '6px',
      md: '6px',
      lg: '10px',
      full: '9999px',
    },
    boxShadow: {
      none: 'none',
      pop: '0 12px 32px -12px rgb(var(--c-scrim) / 0.22), 0 2px 6px -2px rgb(var(--c-scrim) / 0.08)',
    },
    extend: {
      maxWidth: { form: '45rem' },
      transitionTimingFunction: { calm: 'var(--ease-out)' },
      // One layering scale: sticky table cells < top bar < navigation < tooltips < toasts < menus < load bar < skip link.
      zIndex: { cell: '1', head: '2', corner: '3', topbar: '30', nav: '40', tooltip: '50', toast: '70', menu: '90', progress: '100', skip: '120' },
    },
  },
  plugins: [require('@tailwindcss/forms')({ strategy: 'class' })],
};
