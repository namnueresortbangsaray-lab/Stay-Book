# Design system — Stay Book

A flat, clean blue-and-white back-office UI for front-desk and housekeeping staff at น้ำเหนือรีสอร์ท บางเสร่, in light
and dark, on phones, iPads and desktops. Screenshots: `docs/design/after-skill/{light,dark}/{390,768,1024,1440}/`
(including loading, failure, validation, print and error-page states; earlier states in `before-skill/` and `before/`).
Audits: `docs/design/UI_AUDIT.md` and `docs/design/SKILL_AUDIT.md` (ui-ux-pro-max review, findings SA-01…SA-16).

## Principles

1. **Blue and white.** White surfaces on a very light blue-grey canvas, navy ink, one blue primary, an amber accent
   used sparingly, hairline borders. No gradients, glass, coloured shadows or decoration that carries no information.
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
| `canvas` | Page background | `#F4F7FB` | `#0E1522` |
| `surface` | Cards, sidebar, tables | `#FFFFFF` | `#151F31` |
| `raised` | Inputs, menus, dialogs | `#FFFFFF` | `#1B2840` |
| `sunken` | Table headers, wells, segmented track | `#ECF1F8` | `#111A2A` |
| `line` / `line-strong` | Hairlines / dividers that must be seen | `#DCE4EF` / `#C3CFDF` | `#243049` / `#33425F` |
| `control` | Input and checkbox borders (3:1) | `#7C8AA3` | `#70819E` |
| `ink` | Body text, headings | `#14213D` | `#E8EEF8` |
| `ink-muted` | Secondary text, labels | `#4A5A73` | `#9FB0C8` |
| `ink-subtle` | Hints, meta, placeholders | `#5A6880` | `#8799B5` |
| `primary` (+`hover`) | Primary buttons, links, focus ring, active nav | `#1D5FD1` (`#174DB0`) | `#5B9BFF` (`#7DB0FF`) |
| `primary-subtle` | Selected rows/chips, active nav background | `#E6EFFC` | `#1B2D4F` |
| `on-primary` | Text on `primary` | `#FFFFFF` | `#0E1522` |
| `accent` / `accent-ink` / `accent-subtle` | Amber: pets, regular guests, `<mark>` | `#A86A12` / `#7A4D0C` / `#FBF1DF` | `#E0A84E` / `#EBC07C` / `#3A2E18` |
| `success` (+`subtle`) | Vacant, paid | `#17774B` / `#E3F4EA` | `#5FCB8E` / `#12301F` |
| `warning` (+`subtle`) | Departing, deposit due | `#8A5A10` / `#FCF1DC` | `#E8B04F` / `#3A2C12` |
| `danger` (+`subtle`) | Errors, destructive actions | `#C0392B` / `#FBE9E7` | `#FF8A7A` / `#3F1D1D` |
| `info` (+`subtle`) | Booked / arriving | `#0B6A8C` / `#E1F1F8` | `#5FC3E8` / `#0F2E3D` |
| `selection` | `::selection` | `#C9DCFA` | `#24467E` |
| `scrim` | Dialog and sheet backdrops, popover shadow | `#14213D` | `#03070E` |

Dark surfaces get lighter with elevation (canvas → surface → raised). The browser chrome colour comes from the
`data-light` / `data-dark` attributes of the `theme-color` meta in `_Layout.cshtml` (its only copy).

**Tones.** `.tone-{primary,accent,success,warning,danger,info,neutral}` set `--tone` and `--tone-bg`; `.pill`,
`.chip`, `.room-tile`, `.toast`, `.timeline-item`, `.tone-text` and chart marks read them. These classes live outside
`@layer` in `components.css` because the names are composed at runtime (`tone-${status.tone}`) and would be purged.

**Contrast gate.** `build/check-contrast.mjs` runs first in `npm run build` and fails the build if any of 62 pairs per
theme misses WCAG AA: text pairs (each ink, primary and danger on every background, status on its subtle, on-primary on
primary and hover) need 4.5:1; controls, focus ring, status icons and chart marks need 3:1. Examples (light / dark): ink on canvas 14.9 / 15.7, ink-subtle on sunken 5.0 / 6.0, primary on canvas 5.4 / 6.6,
on-primary on primary 5.8 / 6.6, control on surface 3.5 / 4.2; the lowest text pair is 4.8 / 5.1. Brief values that
missed AA were darkened within their hue (light ink-subtle, success, warning, info); text on the dark-theme primary is
navy because white on `#5B9BFF` is only 2.8:1. Add a pair there whenever a component uses a new combination.

## Typography

- **Prompt** 400/500/600 for everything, page titles and the login wordmark included (since 2026-11-01; it replaced
  IBM Plex Sans Thai and Noto Serif Thai). Self-hosted woff2 (`@fontsource/prompt`, OFL, copied to `wwwroot/fonts` by
  `build.mjs`) with Thai and Latin `unicode-range` subsets; the Thai and Latin 400 files are preloaded. No font CDN:
  Google Fonts would break the CSP (`font-src` / `style-src 'self'`) and fails on a resort LAN without internet.
- Scale (Tailwind `fontSize`, six steps): `xs` 12/20 · `sm` 14/22.4 · `base` 15/24.8 (16/26.4 below 640px) · `lg`
  18/28.8 · `xl` 22/35.2 · `2xl` 28/44.8 (px size / line height). `base` reads `--text-base` / `--text-base-leading`
  from `tokens.css`, so phones get 16px body text without per-page classes.
- Weights: 400 body, 500 labels and table emphasis, 600 headings and figures. No 700.
- `td`, `time`, `.num`, `kbd` use `tabular-nums`; money and counts are right-aligned in tables.
- Dates: `thaiDate` (`31 ต.ค. 2569`), `shortDate`, `longDate`, `monthTitle` in `Scripts/core/format.js`; money via `money()`.

## Spacing, shape, elevation

8px grid (Tailwind spacing). Radius: 6px controls (`rounded`), 10px cards and dialogs (`rounded-lg`), full for pills.
Borders are 1px hairlines in `line`; the only shadow is `shadow-pop`, for menus, popovers, dialogs and drawers.
Density: `data-density="compact"` on `<html>` shrinks `--control-h` (40 → 34px) and `--row-h` (44 → 36px); coarse
pointers always keep 44px targets.

**Layering** (Tailwind `z-*`, defined once in `tailwind.config.js`; never use arbitrary `z-[…]`): `cell` 1 (sticky lead
cells) · `head` 2 (sticky table header) · `corner` 3 · `topbar` 30 · `nav` 40 (sidebar, tab bar) · `tooltip` 50 ·
`toast` 70 · `menu` 90 · `progress` 100 (first-load bar) · `skip` 120. Dialogs use the browser top layer.

**Motion** (`tokens.css`): `--motion-fast` 120ms (hover, colour, borders), `--motion-base` 160ms (dialogs, toasts,
theme fade), `--motion-slow` 200ms (drawers), `--ease-out` for entering. Only opacity, colour and transform animate;
`prefers-reduced-motion` turns everything off.

## Breakpoints and touch

Mobile first; one set of breakpoints in CSS (`@media`), JS (`matchMedia` in `preferences.js`, `ui.js`) and
Tailwind classes (`sm` = 640, `md` = 768, `lg` = 1024, `xl` = 1280):

| Range | Layout |
|---|---|
| Phone, < 640px | Top bar with a menu button (opens the navigation drawer `#mobile-more-dialog`), bottom tab bar with five destinations, tables stacked into cards, single-column forms, drawers full screen, modals and menus as bottom sheets, action bars at the bottom within thumb reach |
| iPad, 640–1279px | Icon rail by default, expanded with the top-bar menu button (remembered), two-column dashboards and forms, tables with key columns only, the room chart scrolls sideways; works in portrait, landscape and split view |
| Desktop, ≥ 1280px | Full sidebar (the top-bar menu button collapses it to the icon rail, remembered) and full tables |

- **Tables:** `renderTable` columns take `mobileHide` (dropped from phone cards) and `tabletHide` (hidden on
  tablets). A "แสดงทุกคอลัมน์" toggle under each table brings tablet columns back (remembered per table); a
  `.tablet-only` line shows check-out under check-in when that column is hidden. Row actions turn icon-only on
  tablets (label kept as accessible name and `title`). When a table is still wider than its card (split-view widths),
  the lead column stays sticky while the rest scrolls inside the card; the page itself never scrolls sideways.
- **Touch:** every control is at least 44×44px on coarse pointers (`--control-h`, chips, tabs, segmented items, sort
  headers, link buttons, rail items); inline text links are exempt. Inputs use 16px text below 1280px and on touch
  devices so iOS does not zoom. Nothing depends on hover: rail labels are tooltips on hover/focus and the items still
  navigate on tap.
- **Viewport:** `viewport-fit=cover` with `env(safe-area-inset-*)` padding on the top bar, content, tab bar, sheets
  and drawers; heights use `100dvh`.
- **Thai text** wraps at word boundaries; truncation (`truncate`, `.cell-note`) always carries the full text in a
  `title`.

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
| Table | `.table-wrap` + `.data-table`, `.sort-btn`, `.cell-title`, `.cell-sub`, `.table-toolbar`, `.pagination`; `renderTable()` | Sticky header, sort, highlight, column menu, 25 rows per page, ↑/↓ row navigation; `.stack` turns rows into cards below 640px (`mobileHide` columns drop); `tabletHide` columns hide at 640–1279px |
| Menu | `openDropdownMenu(trigger, items)` → `.action-menu`, `.action-menu-item` | Headings, separators, `menuitemradio`/`checkbox`; arrow keys, Escape returns focus |
| Dialog | `dialog.modal`, centred, for every form and confirmation (booking, room, zone, room type, stay action, confirm, command palette, file viewer); `dialog.drawer` only for the guest profile and the phone menu; `.dialog-header/-body/-actions` | Native `<dialog>`: focus trap, Escape, focus restore; header and action bar stay in view while the body scrolls; `form[data-guard]` asks before discarding edits |
| Command palette | `#command-dialog` | Ctrl/⌘K |
| Toast | `toast(message, tone)` → `.toast.tone-*` in `.toast-region` (`aria-live`) | Icon + short text + close button; 4 s (errors 6 s), paused while hovered or focused. Field errors never go into a toast |
| Error summary | `errorSummary(form, errors)` in `app.js` → `.alert.tone-danger[role=alert]` at the top of the form | Shown and focused when a submit returns two or more field errors; each item focuses its field. Inline `.field-error` messages stay |
| Alert | `.alert.tone-*` | Login errors, inline notices |
| Empty state | `emptyState()` → `.empty` | Explains and offers the next action; when a search or filter caused it, "ล้างการค้นหา" comes first |
| Avatar | `.avatar`, `.avatar-lg` | Initials |
| Timeline | `.timeline` + `.timeline-item.tone-*` | Guest notes |
| Loading / failure | `#splash` (3px top bar), `#loading` skeleton, `<main data-state="loading\|failed">` | The shell shows at once; while there is no data the page panels are hidden and the skeleton or the failure card (with retry) fills the content |
| Progress / skeleton | `.progress` (indeterminate upload), `.skeleton` (first load) | |
| Room chart | `renderCalendar()` → `.tl-scroll` > `.tl-grid` (`.tl-corner`, `.tl-day`, `.tl-room`, `.tl-cell`, `.tl-bar.tone-*`) | Bookings → ปฏิทิน: rooms down, nights across (5rem columns, 4.5rem on phones), one bar per booking with status icon and name ("คุณ" dropped; full details in `title` and screen-reader text). Follows the list search and status chips; a bar opens the booking menu, a day lists that day below; scrolls to the selected day and keeps its position on re-render. Sticky room column, weekend and today shading |
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
  command palette and the 404 page, in light and dark, at 390, 768 and 1440px; then sweeps 390, 507, 640, 678, 768,
  1024, 1180 and 1440px for horizontal page scroll, touch targets under 44px and input text under 16px. It exits
  non-zero on any serious or critical violation or layout issue (current result: 0 violations of any impact, 0 layout
  issues).
- Skip link, landmarks (`nav`, `main`, labelled `section`s), one `h1` per view with `h2` sections below it,
  `aria-current="page"` on the active nav item. `scroll-padding` keeps keyboard focus clear of the sticky top bar,
  table headers and the phone tab bar (WCAG 2.4.11).
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
   `node tests/ui/a11y.mjs` and `node tests/ui/screenshots.mjs <dir> light,dark 390,768,1024,1440`; look at the
   screenshots in both themes at every width.
