# UI audit with ui-ux-pro-max

Audit of the blue/white responsive UI (branch `ui-blue-responsive`, commit 9f9ab71) against the skill's
`references/quick-reference.md` (rule IDs in backticks), `references/pro-rules.md`, `data/stacks/html-tailwind.csv`
and axe-core (`wcag2a/aa`, `wcag21aa`, `wcag22aa`, `best-practice`). Screens: `docs/design/before-skill/{light,dark}/{390,768,1024,1440}/`
(194 captures from the Docker build with fictional demo data, including validation, empty, loading, load-failure,
print and 403/404/419/429/500 states). Skill notes: `SKILL_NOTES.md`; design-system comparison: `SKILL_DESIGN_SYSTEM.md`.

Status legend: **fixed** (commit), **deferred** (with reason), **n/a**. Result: 16 findings (0 critical, 6 major, 10 minor); 14 fixed, 2 deferred. After screenshots: `docs/design/after-skill/` (same 194 captures).

## Inventory

| Area | Items |
|---|---|
| Pages | Login (`Views/Auth/Login`), dashboard shell (`Views/Dashboard/Index`: Today, Room board, Bookings list + calendar, Reports, Room setup, Guests), error page (`Views/Shared/Error`: 403, 404, 419, 429, 500) |
| Layouts / partials | `_Layout`, `_AuthLayout`, `_ThemeBoot`, `_ThemeSwitch`, `_Logo`, `Dashboard/_NavItems` |
| Dialogs | Command palette, booking drawer, guest drawer (4 tabs), room modal, action modal (check-in/out, extend, feedback, upload), confirm modal, phone navigation drawer, file viewer |
| Components | Buttons, fields, checkbox/switch, segmented, tabs, chips, pills, cards, KPI strip, figure list, data table (sort, paginate, columns, stack, tablet columns), dropdown menu / bottom sheet, toasts, alerts, empty state, skeleton, splash, timeline, progress, avatar, charts + table fallback, stacked bars |
| JS modules | `app.js`, `core/{api,dom,i18n,icons,icon-set,format,theme,preferences,ui,table,charts}.js` |
| States | Loading (splash + skeleton), empty (per list, search), load failure + retry, inline field errors, toasts, unsaved-changes guard, button busy, disabled, print, login error, error pages |

## Findings

| ID | Page / component | Problem | Severity | Guideline | Proposed fix | Status |
|---|---|---|---|---|---|---|
| SA-01 | Shell, tables | Shift+Tab through a long page or table can land the focused control under the sticky top bar, the sticky table header or (phones) the bottom tab bar | major | `focus-not-obscured` (WCAG 2.4.11 AA), `fixed-element-offset` | `scroll-padding` on the page and on table containers equal to the sticky bars | fixed (99e09aa) |
| SA-02 | Forms (booking, room, action, guest) | A failed submit shows inline errors but no summary; with several errors the user has no overview | major | `error-summary`, `focus-management`, `aria-live-errors` | Error summary alert at the top of the form body listing each error as a link to its field; focus the summary when there are 2+ errors, the field when there is one | fixed (caf4c61) |
| SA-03 | Toasts | The error toast repeats every field message in one long line, stays 7 s, cannot be dismissed and is still on screen after the dialog closes and the user moves to another page (`15-form-errors`, `16-empty-search`) | major | `toast-dismiss`, `toast-accessibility`, `error-placement` | Field errors stay inline only (toast shows the short message); close button; timers pause on hover/focus; success 4 s, error 6 s | fixed (caf4c61) |
| SA-04 | Load failure | The failure card renders above a live but empty toolbar (search, view switch, columns) and the same message also appears as a toast (`18-load-failed`) | major | `error-recovery`, `error-state-chart`, `timeout-feedback` | While data is unavailable hide the page panels so only the failure card and its retry show; no duplicate toast | fixed (eba38bf) |
| SA-05 | First load | A full-screen logo splash hides the whole app until data arrives; on a slow connection the user stares at a blank page (`17-loading`) | major | `progressive-loading`, `content-jumping`, `loading-states` | Keep `#splash` (contract ID) but make it a thin top progress bar; show the shell with the existing skeleton immediately | fixed (eba38bf) |
| SA-06 | Body text on phones | Body text is 15px at every width | major | `readable-font-size` (16px on mobile) | Base font-size token becomes 16px below 640px (line height stays ≥ 1.6) | fixed (99e09aa) |
| SA-07 | Reports | Section labels and card titles are `h3` directly under the page `h1` | minor | `heading-hierarchy` (axe `heading-order`) | Use `h2` for report sections and chart/breakdown cards (same styling) | fixed (84b6026) |
| SA-08 | Empty search | "No bookings found" after a search offers only "Create booking"; the obvious recovery is clearing the search or status filter | minor | `empty-states`, `error-recovery` | When a query or filter is active, add "ล้างการค้นหา" (clears search and filter) next to the create action | fixed (84b6026) |
| SA-09 | Login | No show/hide toggle on the password field | minor | `password-toggle`, `accessible-authentication` | Icon button with `aria-pressed` toggling the input type; paste and password managers stay allowed | fixed (84b6026) |
| SA-10 | Tables (touch) | Row primary action and row menu sit 4px apart | minor | `touch-spacing` (≥ 8px) | `gap-2` between row action buttons on coarse pointers | fixed (caf4c61) |
| SA-11 | All controls | No `touch-action: manipulation` | minor | `tap-delay` | Set it on buttons, links, inputs and labels in the base layer | fixed (99e09aa) |
| SA-12 | Layering | Ad-hoc z-index values (`z-[1]`, `z-[70]`, `z-[90]`, `z-[100]`, `z-[120]`, `z-10/30/40/50`) | minor | `z-index-management`, html-tailwind "Fixed elements z-index" | Named scale in `tailwind.config.js` (sticky, topbar, sidebar, overlay, menu, toast, skip) used everywhere | fixed (99e09aa) |
| SA-13 | Motion | Durations 120/150/160/200/1100 ms are typed per rule | minor | `motion-consistency`, `duration-timing` | Motion tokens (`--motion-fast`, `--motion-base`, `--ease-out`) used by transitions and dialog/toast animations | fixed (99e09aa) |
| SA-14 | Icons | Icon sizes vary by context (12–20px) through ad-hoc `h-*/w-*` classes | minor | `icon-style-consistent`, pro-rules "Consistent Icon Sizing" | — | deferred: sizes already follow the adjacent text size (xs → 12, sm → 14, base → 16, nav → 18, tab bar → 20); one set and stroke 1.5 everywhere |
| SA-15 | Phones (Android) | The system back gesture with a drawer open changes the hash page behind it instead of closing the drawer | minor | `back-behavior`, `modal-escape` | — | deferred: closing dialogs on back needs history entries, which changes routing behaviour (out of scope); Escape, ✕ and the scrim close every dialog |
| SA-16 | Login brand panel | Ruled-ledger pattern is decoration that carries no information | minor | `effects-match-style` (flat), `trend-emphasis` | Remove the pattern; plain blue panel with logo, name and one line of copy | fixed (84b6026) |

### Checked and passing (no finding)

- **Accessibility:** axe (wcag2a/aa/21aa/22aa) shows 0 violations in both themes at 390/768/1440. Present: skip link, landmarks, labels with `for`, `aria-describedby` hints, `aria-invalid`, icon buttons with names, aria-sort, colour plus icon plus text for every status, reduced motion.
- **Contrast:** 62 token pairs × 2 themes meet AA in the build gate (lowest text pair 4.8 light / 5.1 dark). Dark mode uses lighter tonal variants, not inversion (`color-dark-mode`); there is no theme flash.
- **Touch and layout:** 44px targets and 16px inputs on touch, safe areas, `dvh`, no horizontal page scroll from 390 to 1440 including split-view widths; the tab bar has 5 labelled items.
- **Style:** no gradients, glass, emoji or decorative shadows (one popover shadow); Lucide only, stroke 1.5; semantic tokens with no raw hex in components; one primary action per screen.
- **Forms:** visible labels, required markers, helper text, inline field errors with icon, semantic input types and `autocomplete`, busy and disabled buttons, unsaved-changes guard, confirmation before destructive actions.
- **Data:** tabular numerals, right-aligned money, sortable tables, every chart has a table fallback ("ดูเป็นตาราง") with low-contrast gridlines; empty states with next actions.

## Verification after the fixes

- **Build and tests:** the build's contrast check passes (62 pairs × 2 themes; lowest text pair 4.8 light / 5.1 dark). Release build has 0 warnings, `dotnet format` is clean, `dotnet test` passes 96/96 (including the v1 baseline contract), and the Docker smoke test passes.
- **axe-core** (`tests/ui/a11y.mjs`): 0 violations of any impact on every screen, dialog and the command palette, in light and dark at 390, 768 and 1440px. The responsive sweep (390, 507, 640, 678, 768, 1024, 1180, 1440px, plus 375 and 844 for this checklist) finds no horizontal page scroll, no touch target under 44px and no input text under 16px. The phone month calendar scrolls inside its card by design.
- **Keyboard and preferences:** 64/64 scripted checks pass.
  - Keyboard-only flows: sign in, Ctrl+K search, new booking (focus trap, Escape, unsaved-changes guard, focus return), sidebar navigation, table row arrows, upload through the row menu, editing and saving a guest note, theme menu, sign out.
  - Theme: the choice is mirrored to the cookie and rendered by the server, System follows the OS live, other tabs follow, and the theme is set before `<body>` exists (no flash).
  - Display: reduced motion removes transitions, 200% zoom reflows without horizontal scroll, and print preview is light with no app chrome.
- **Found during verification and fixed:** the phone loading skeleton's figure grid left an empty cell (now uses the 5-figure grid, SA-05). The login panel copy broke "เช็กอิน" mid-word (wider measure and balanced wrapping, SA-16).

## Pre-delivery checklist (`references/pro-rules.md`)

The checklist targets native apps; web equivalents are noted. ✓ passes, n/a does not apply.

| Area | Item | Result |
|---|---|---|
| Process | Searches relevant to the interface | n/a: Python missing; the same data rows were read directly (`SKILL_DESIGN_SYSTEM.md`) |
| Process | Reviewed quick-reference §1–§3 | ✓ (all ten sections in this audit) |
| Process | 375px phone and landscape | ✓ 375, 390, 844 landscape, iPad 768/1024/1180 |
| Process | Reduced motion and largest text size | ✓ reduced motion; 200% zoom as the web equivalent of Dynamic Type |
| Process | Dark mode contrast checked on its own | ✓ separate token pairs in the gate; axe in dark |
| Process | Touch targets ≥ 44, nothing behind safe areas | ✓ sweep; `env(safe-area-inset-*)` on bars, sheets and content |
| Visual | No emoji icons; one icon family | ✓ Lucide only, stroke 1.5 |
| Visual | Official brand assets with correct proportions | ✓ resort logos used unmodified with declared sizes |
| Visual | Pressed state does not shift layout | ✓ 1px translate on the button itself, no reflow |
| Visual | Semantic tokens, no per-screen colours | ✓ every colour comes from tokens; the build fails on contrast |
| Interaction | Pressed feedback on every control | ✓ hover, active and focus-visible on buttons, chips, rows, menu items |
| Interaction | Targets ≥ 44 on touch | ✓ |
| Interaction | Shared motion timing | ✓ `--motion-fast/base/slow`, `--ease-out` (SA-13) |
| Interaction | Clear disabled state | ✓ `disabled` attribute, 55% opacity, not-allowed cursor |
| Interaction | Focus order matches visual order, descriptive labels | ✓ keyboard checks; axe |
| Interaction | No conflicting gestures | n/a: no custom gestures |
| Light/Dark | Primary and secondary text ≥ 4.5:1 in both themes | ✓ |
| Light/Dark | Borders and states visible in both themes | ✓ `line`, `line-strong`, `control` tokens per theme |
| Light/Dark | Scrim keeps the foreground legible | ✓ dialogs sit on raised surfaces above a 50% navy scrim |
| Light/Dark | Both themes tested | ✓ screenshots and axe in both |
| Layout | Safe areas; content not hidden behind fixed bars | ✓ content bottom padding above the tab bar; `scroll-padding` (SA-01) |
| Layout | Small phone, large phone, tablet portrait and landscape | ✓ |
| Layout | Gutters adapt; 4/8 spacing rhythm | ✓ 16/24/32px gutters; 8px grid |
| Layout | Readable long-text measure | ✓ notes and copy are short; paragraphs capped (`max-w-md`, card widths) |
| Accessibility | Decorative icons hidden; meaningful ones named | ✓ icons `aria-hidden`; icon buttons have `aria-label` and `title` |
| Accessibility | Icon controls announce state | ✓ `aria-pressed` (theme, density, password, filters), `aria-expanded` (menus) |
| Accessibility | Labels, hints, clear errors; summary after a failed submit | ✓ (SA-02) |
| Accessibility | Colour is not the only indicator | ✓ status = tone + icon + text |
| Accessibility | Sticky UI does not obscure focus | ✓ (SA-01) |
| Accessibility | Drag alternatives | n/a: no drag interactions |
| Accessibility | Authentication allows password managers and paste | ✓ `autocomplete` username/current-password, paste allowed, show/hide toggle (SA-09) |
| Accessibility | Auto-rotating content | n/a: none |
