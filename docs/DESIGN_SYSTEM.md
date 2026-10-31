# Design system — Stay Book

"A calm hospitality ledger": a quiet, warm, data-dense back-office UI for front-desk and housekeeping staff at
น้ำเหนือรีสอร์ท บางเสร่, in light and dark. Screenshots: `docs/design/after/{light,dark}/{desktop,tablet,mobile}/`
(before: `docs/design/before/`). Audit and assumptions: `docs/design/UI_AUDIT.md`.

## Principles

1. **Paper, ink, pine.** Warm paper surfaces, near-black ink, one pine-green primary, a brass accent used sparingly.
   No gradients, glass, coloured shadows or decoration that carries no information.
2. **Density over cards.** Lists of stays and guests are tables with sticky headers, sorting and right-aligned
   tabular numbers; cards are for grouping, not for every row. Figures are grouped by meaning, not tiled.
3. **State is never colour alone.** Every status pairs a tone with an icon and a text label (pills, room tiles,
   calendar lines, toasts).
4. **One primary action per context.** "สร้าง Booking" in the top bar, one filled button per row, form or dialog.
5. **Thai first.** Line height ≥ 1.6, no uppercase or letter-spacing on Thai, Buddhist-era dates, ฿ amounts.
6. **Quiet motion.** Short colour and opacity fades only; nothing moves under `prefers-reduced-motion`.

## Tokens

Defined once in `src/ResortGuestbook.Web/Styles/tokens.css` as RGB channels (`--c-name: r g b`) and mapped in
`tailwind.config.js` as `rgb(var(--c-name) / <alpha-value>)`, so `bg-surface`, `text-ink-muted`, `border-line`,
`bg-primary/10` all work. **Never use a hex value or a Tailwind palette colour in markup**; the palette is replaced,
not extended, so `text-gray-500` does not exist.

| Token | Use | Light | Dark |
|---|---|---|---|
| `canvas` | Page background | `#F6F3EE` | `#121513` |
| `surface` | Cards, sidebar, tables | `#FCFAF7` | `#1A1E1B` |
| `raised` | Inputs, menus, dialogs | `#FFFFFF` | `#212622` |
| `sunken` | Table headers, wells, segmented track | `#EFEBE4` | `#161A17` |
| `line` / `line-strong` | Hairlines / dividers that must be seen | `#E4DFD6` / `#CFC8BB` | `#2E352F` / `#3B443D` |
| `control` | Input and checkbox borders (3:1) | `#857E72` | `#707972` |
| `ink` | Body text, headings | `#1F2421` | `#EDEBE5` |
| `ink-muted` | Secondary text, labels | `#545C57` | `#A8AFA8` |
| `ink-subtle` | Hints, meta, placeholders | `#616863` | `#8E968E` |
| `primary` (+`hover`) | Primary buttons, links, focus ring, active nav | `#1F5C4F` (`#174A40`) | `#4FB39A` (`#6CC7B0`) |
| `primary-subtle` | Selected rows/chips, active nav background | `#E3EFEA` | `#1E3A33` |
| `on-primary` | Text on `primary` | `#FFFFFF` | `#0D1A16` |
| `accent` / `accent-ink` / `accent-subtle` | Brass: pets, regular guests, `<mark>` | `#A67832` / `#7A5520` / `#F4EAD6` | `#D9A85B` / `#E2BA78` / `#3A2F1C` |
| `success` (+`subtle`) | Checked in, paid | `#286E46` / `#E4F1E8` | `#70C48D` / `#1A3223` |
| `warning` (+`subtle`) | Departing, deposit due | `#8F5606` / `#FAEED6` | `#E2AB54` / `#382A12` |
| `danger` (+`subtle`) | Errors, destructive actions | `#A73A29` / `#F8E7E3` | `#F08D7A` / `#3F1E19` |
| `info` (+`subtle`) | Booked / arriving | `#2E6A8E` / `#E3EDF4` | `#80B8DC` / `#182C3A` |
| `selection` | `::selection` | `#CDE2D9` | `#285247` |

Dark surfaces get lighter with elevation (canvas → surface → raised). `--theme-color` feeds the browser chrome colour.

**Tones.** `.tone-{primary,accent,success,warning,danger,info,neutral}` set `--tone` and `--tone-bg`; `.pill`,
`.chip`, `.room-tile`, `.toast`, `.timeline-item`, `.tone-text` and chart marks read them. These classes live outside
`@layer` in `components.css` because the names are composed at runtime (`tone-${status.tone}`) and would be purged.

**Contrast gate.** `build/check-contrast.mjs` runs first in `npm run build` and fails the build if any of 62 pairs per
theme misses WCAG AA: text pairs (each ink, primary and danger on every background, status on its subtle, on-primary on
primary and hover) need 4.5:1; controls, focus ring, status icons and chart marks need 3:1. Examples: ink on canvas
14.2 / 15.4, ink-subtle on sunken 4.8 / 5.8, on-primary on primary 7.8 / 7.0, control on surface 3.9 / 3.8
(light / dark). Add a pair there whenever a component uses a new combination.

## Typography

- **IBM Plex Sans Thai** 400/500/600 for everything; **Noto Serif Thai** 600 only for page titles, the login wordmark
  and the error code. Both are self-hosted woff2 (`@fontsource` packages, copied to `wwwroot/fonts` by `build.mjs`)
  with Thai and Latin `unicode-range` subsets; the Thai and Latin 400 files are preloaded. No font CDN.
- Scale (Tailwind `fontSize`, six steps): `xs` 12/20 · `sm` 14/22.4 · `base` 15/24.8 · `lg` 18/28.8 · `xl` 22/35.2 ·
  `2xl` 28/44.8 (px size / line height).
- Weights: 400 body, 500 labels and table emphasis, 600 headings and figures. No 700.
- `td`, `time`, `.num`, `kbd` use `tabular-nums`; money and counts are right-aligned in tables.
- Dates: `thaiDate` (`31 ต.ค. 2569`), `shortDate`, `longDate`, `monthTitle` in `Scripts/core/format.js`; money via `money()`.

## Spacing, shape, elevation

8px grid (Tailwind spacing). Radius: 6px controls (`rounded`), 10px cards and dialogs (`rounded-lg`), full for pills.
Borders are 1px hairlines in `line`; the only shadow is `shadow-pop`, for menus, popovers, dialogs and drawers.
Density: `data-density="compact"` on `<html>` shrinks `--control-h` (40 → 34px) and `--row-h` (44 → 36px); coarse
pointers always keep 44px targets.

## Icons

Lucide only (`lucide-static`, ISC). `Scripts/core/icon-set.js` maps app names (`arrive`, `depart`, `paw`, …) to Lucide
names; `build.mjs` writes just those symbols into `wwwroot/icons.svg`. Razor: `<icon name="search" class="h-4 w-4" />`
(`TagHelpers/IconTagHelper.cs`, versioned URL). JS: `icon('search', 'h-4 w-4')` (`Scripts/core/icons.js`, sprite URL
from `<meta name="icon-sprite">`). Stroke 1.5, `currentColor`, `aria-hidden`; icon-only buttons carry `aria-label`
and `title`. No emoji.

## Components

CSS in `Styles/components.css` (shared), `shell.css` (layout), `screens.css` (screen-specific); JS helpers in
`Scripts/core/`. Every interactive component has hover, `:focus-visible` (2px `primary` outline, 2px offset), active
and disabled styles.

| Component | Markup / helper | Notes |
|---|---|---|
| Button | `.btn` + `.btn-primary` · `-secondary` · `-ghost` · `-danger`, sizes `.btn-sm` `.btn-lg`, `.btn-icon`; `button()` | `setButtonLoading()` adds `.btn-spinner`, `aria-busy` and a label |
| Field | `.label` (+ `.req`), `.field`, `.hint`, `.field-error` (filled from `[data-field-error]`), `.form-grid`, `.form-section` | Labels above inputs; errors with icon, linked by `aria-describedby` |
| Checkbox / switch | `.check-row` + `.form-checkbox`, `.switch` | |
| Segmented control | `.segmented` + `.segmented-item[aria-pressed]` | Booking view, report range, theme on login |
| Tabs | `.tabs` + `.tab[role=tab]`; `selectTab()` | Arrow keys, Home/End |
| Pill / chip | `.pill.tone-*` (status: icon + text); `.chip[aria-pressed]` in `.chip-row` (filters with counts) | |
| Card | `.card`, `.card-header`, `.card-title`, `.card-body` | |
| Figures | `.kpi-strip` + `.kpi` (Today); `.figure-list` (Reports) | Real numbers only |
| Table | `.table-wrap` + `.data-table`, `.sort-btn`, `.cell-title`, `.cell-sub`, `.table-toolbar`, `.pagination`; `renderTable()` | Sticky header, sort, highlight, column menu, 25 rows per page, ↑/↓ row navigation; `.stack` turns rows into cards below 768px (`mobileHide` columns drop) |
| Menu | `openDropdownMenu(trigger, items)` → `.action-menu`, `.action-menu-item` | Headings, separators, `menuitemradio`/`checkbox`; arrow keys, Escape returns focus |
| Dialog | `dialog.modal` (confirm, room, action) and `dialog.drawer` (booking, guest) with `.dialog-header/-body/-actions` | Native `<dialog>`: focus trap, Escape, focus restore; `form[data-guard]` asks before discarding edits |
| Command palette | `#command-dialog` | Ctrl/⌘K |
| Toast | `toast(message, tone)` → `.toast.tone-*` in `.toast-region` (`aria-live`) | Icon + text |
| Alert | `.alert.tone-*` | Login errors, inline notices |
| Empty state | `emptyState()` → `.empty` | Explains and offers the next action |
| Avatar | `.avatar`, `.avatar-lg` | Initials |
| Timeline | `.timeline` + `.timeline-item.tone-*` | Guest notes |
| Progress / skeleton | `.progress` (indeterminate upload), `.skeleton` (first load) | |
| Charts | `barChart()` + `chartTable()` (`Scripts/core/charts.js`), `.stack-bar` | SVG in tokens; every chart has a table ("ดูเป็นตาราง") that prints |

## Dark mode

- **Preference:** Light, Dark or System (default). `Scripts/core/theme.js` stores it in `localStorage.theme`, mirrors it
  to a `theme` cookie (1 year, `SameSite=Lax`) and sets `data-theme` (resolved) and `data-theme-pref` on `<html>`.
- **First paint:** `_Layout.cshtml` renders `data-theme` from the cookie. `Views/Shared/_ThemeBoot.cshtml`, a blocking
  script with the CSP nonce placed before the stylesheet, resolves System via `prefers-color-scheme` and also applies
  density and sidebar state, so there is no flash on hard reload (checked by observing `data-theme` before `<body>`
  exists).
- **Runtime:** the theme menu (top bar) and segmented control (login, mobile menu) call `setTheme()`. System mode
  follows OS changes live through `matchMedia`; other tabs follow via the `storage` event. A `theme-switching` class
  enables a 150 ms colour fade only during a switch, never under reduced motion.
- **CSS:** Tailwind `darkMode: ['selector', '[data-theme="dark"]']`. Components use tokens, so `dark:` variants are
  almost never needed; the few exceptions (logo variant, login brand panel, image dimming) are in `shell.css`,
  `screens.css` and `base.css`. Dark tokens are inside `@media screen`, so **print is always light**.
- `<meta name="color-scheme" content="light dark">` and a per-theme `theme-color` keep scrollbars, native controls
  and browser chrome in step.

## Accessibility

- WCAG 2.2 AA target. `tests/ui/a11y.mjs` runs axe-core on login, all six sections, the calendar, five dialogs, the
  command palette and the 404 page, in light and dark, at desktop and mobile widths; it exits non-zero on any serious or
  critical violation (current result: 0 violations of any impact).
- Skip link, landmarks (`nav`, `main`, labelled `section`s), one `h1` per view, `aria-current="page"` on the active nav item.
- Keyboard: everything is reachable by Tab; menus, tabs, the palette and table rows use arrow keys; dialogs trap focus
  and restore it on close.
- Targets ≥ 44px on touch, ≥ 34px with a mouse in compact density. Layout reflows at 200% zoom without horizontal scroll.
- `prefers-reduced-motion` removes all transitions and animations.
- Charts have table equivalents; status never relies on colour alone; images have alt text.

## Adding a page or component

1. **Text:** add keys to `Resources/SharedResource.th.resx` and `.en.resx`. Razor: `@T["ui.key"]`; JS:
   `t('ui.key', { n })` (strings reach JS through the `#ui-strings` JSON block). No literal UI text in markup or JS.
2. **Colours:** use token utilities only. If you introduce a new foreground/background combination, add it to
   `build/check-contrast.mjs`.
3. **Structure:** compose existing classes (`.card`, `.data-table`, `.btn`, `.field`…) before adding CSS. New shared
   pieces go in `components.css` inside `@layer components` with every interaction state; screen-only rules go in
   `screens.css`. Delete CSS you stop using.
4. **Icons:** add the mapping to `Scripts/core/icon-set.js`; the sprite is rebuilt by `npm run build`.
5. **Behaviour hooks:** keep `id`, `name`, `data-action` and `data-id` attributes stable; JS and the baseline contract
   tests depend on them. No inline event handlers or inline scripts without the nonce.
6. **Check:** `npm --prefix src/ResortGuestbook.Web run build`, `dotnet test`, then against a running instance
   `node tests/ui/a11y.mjs` and `node tests/ui/screenshots.mjs <dir> light,dark`; look at the screenshots in both themes.
