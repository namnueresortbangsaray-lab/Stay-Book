# UI audit with ui-ux-pro-max

Audit of the blue/white responsive UI (branch `ui-blue-responsive`, commit 9f9ab71) against the skill's
`references/quick-reference.md` (rule IDs in backticks), `references/pro-rules.md`, `data/stacks/html-tailwind.csv`
and axe-core (`wcag2a/aa`, `wcag21aa`, `wcag22aa`, `best-practice`). Screens: `docs/design/before-skill/{light,dark}/{390,768,1024,1440}/`
(194 captures from the Docker build with fictional demo data, including validation, empty, loading, load-failure,
print and 403/404/419/429/500 states). Skill notes: `SKILL_NOTES.md`; design-system comparison: `SKILL_DESIGN_SYSTEM.md`.

Status legend: **open** (to fix), **fixed**, **deferred** (with reason), **n/a**.

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
| SA-01 | Shell, tables | Shift+Tab through a long page or table can land the focused control under the sticky top bar, the sticky table header or (phones) the bottom tab bar | major | `focus-not-obscured` (WCAG 2.4.11 AA), `fixed-element-offset` | `scroll-padding` on the page and on table containers equal to the sticky bars | open |
| SA-02 | Forms (booking, room, action, guest) | A failed submit shows inline errors but no summary; with several errors the user has no overview | major | `error-summary`, `focus-management`, `aria-live-errors` | Error summary alert at the top of the form body listing each error as a link to its field; focus the summary when there are 2+ errors, the field when there is one | open |
| SA-03 | Toasts | The error toast repeats every field message in one long line, stays 7 s, cannot be dismissed and is still on screen after the dialog closes and the user moves to another page (`15-form-errors`, `16-empty-search`) | major | `toast-dismiss`, `toast-accessibility`, `error-placement` | Field errors stay inline only (toast shows the short message); close button; timers pause on hover/focus; success 4 s, error 6 s | open |
| SA-04 | Load failure | The failure card renders above a live but empty toolbar (search, view switch, columns) and the same message also appears as a toast (`18-load-failed`) | major | `error-recovery`, `error-state-chart`, `timeout-feedback` | While data is unavailable hide the page panels so only the failure card and its retry show; no duplicate toast | open |
| SA-05 | First load | A full-screen logo splash hides the whole app until data arrives; on a slow connection the user stares at a blank page (`17-loading`) | major | `progressive-loading`, `content-jumping`, `loading-states` | Keep `#splash` (contract ID) but make it a thin top progress bar; show the shell with the existing skeleton immediately | open |
| SA-06 | Body text on phones | Body text is 15px at every width | major | `readable-font-size` (16px on mobile) | Base font-size token becomes 16px below 640px (line height stays ≥ 1.6) | open |
| SA-07 | Reports | Section labels and card titles are `h3` directly under the page `h1` | minor | `heading-hierarchy` (axe `heading-order`) | Use `h2` for report sections and chart/breakdown cards (same styling) | open |
| SA-08 | Empty search | "No bookings found" after a search offers only "Create booking"; the obvious recovery is clearing the search or status filter | minor | `empty-states`, `error-recovery` | When a query or filter is active, add "ล้างการค้นหา" (clears search and filter) next to the create action | open |
| SA-09 | Login | No show/hide toggle on the password field | minor | `password-toggle`, `accessible-authentication` | Icon button with `aria-pressed` toggling the input type; paste and password managers stay allowed | open |
| SA-10 | Tables (touch) | Row primary action and row menu sit 4px apart | minor | `touch-spacing` (≥ 8px) | `gap-2` between row action buttons on coarse pointers | open |
| SA-11 | All controls | No `touch-action: manipulation` | minor | `tap-delay` | Set it on buttons, links, inputs and labels in the base layer | open |
| SA-12 | Layering | Ad-hoc z-index values (`z-[1]`, `z-[70]`, `z-[90]`, `z-[100]`, `z-[120]`, `z-10/30/40/50`) | minor | `z-index-management`, html-tailwind "Fixed elements z-index" | Named scale in `tailwind.config.js` (sticky, topbar, sidebar, overlay, menu, toast, skip) used everywhere | open |
| SA-13 | Motion | Durations 120/150/160/200/1100 ms are typed per rule | minor | `motion-consistency`, `duration-timing` | Motion tokens (`--motion-fast`, `--motion-base`, `--ease-out`) used by transitions and dialog/toast animations | open |
| SA-14 | Icons | Icon sizes vary by context (12–20px) through ad-hoc `h-*/w-*` classes | minor | `icon-style-consistent`, pro-rules "Consistent Icon Sizing" | — | deferred: sizes already follow the adjacent text size (xs → 12, sm → 14, base → 16, nav → 18, tab bar → 20); one set and stroke 1.5 everywhere |
| SA-15 | Phones (Android) | The system back gesture with a drawer open changes the hash page behind it instead of closing the drawer | minor | `back-behavior`, `modal-escape` | — | deferred: closing dialogs on back needs history entries, which changes routing behaviour (out of scope); Escape, ✕ and the scrim close every dialog |
| SA-16 | Login brand panel | Ruled-ledger pattern is decoration that carries no information | minor | `effects-match-style` (flat), `trend-emphasis` | Remove the pattern; plain blue panel with logo, name and one line of copy | open |

### Checked and passing (no finding)

- **Accessibility:** axe (wcag2a/aa/21aa/22aa) shows 0 violations in both themes at 390/768/1440. Present: skip link, landmarks, labels with `for`, `aria-describedby` hints, `aria-invalid`, icon buttons with names, aria-sort, colour plus icon plus text for every status, reduced motion.
- **Contrast:** 62 token pairs × 2 themes meet AA in the build gate (lowest text pair 4.8 light / 5.1 dark). Dark mode uses lighter tonal variants, not inversion (`color-dark-mode`); there is no theme flash.
- **Touch and layout:** 44px targets and 16px inputs on touch, safe areas, `dvh`, no horizontal page scroll from 390 to 1440 including split-view widths; the tab bar has 5 labelled items.
- **Style:** no gradients, glass, emoji or decorative shadows (one popover shadow); Lucide only, stroke 1.5; semantic tokens with no raw hex in components; one primary action per screen.
- **Forms:** visible labels, required markers, helper text, inline field errors with icon, semantic input types and `autocomplete`, busy and disabled buttons, unsaved-changes guard, confirmation before destructive actions.
- **Data:** tabular numerals, right-aligned money, sortable tables, every chart has a table fallback ("ดูเป็นตาราง") with low-contrast gridlines; empty states with next actions.
