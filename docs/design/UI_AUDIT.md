# UI audit — Stay Book (before redesign)

Screens captured at 1440, 768 and 390 px in `docs/design/before/light/{desktop,tablet,mobile}/` from a demo instance
filled by `tests/ui/seed-demo.mjs` (fictional guests; no production data).

## Inventory

| Area | Where | Notes |
|---|---|---|
| Layouts | `Views/Shared/_Layout.cshtml`, `_AuthLayout.cshtml` | one stylesheet, one module script (dashboard only), CSP nonce on scripts |
| Login | `Views/Auth/Login.cshtml` | centred card, error alert, 429 throttle message |
| App shell | `Views/Dashboard/Index.cshtml` | sidebar (6 sections), top bar, mobile bottom nav + "more" dialog + floating "สร้าง Booking" |
| Sections (rendered by `Scripts/app.js`) | `#page-today`, `#page-room-map`, `#page-bookings` (list + calendar), `#page-dashboard` (reports), `#page-rooms`, `#page-guests` | hash routing (`#today` …) |
| Dialogs | command palette, booking form, room form, stay action (checkout / extend / feedback / upload), guest profile + edit, mobile more, confirm | native `<dialog>` |
| JS modules | `app.js` (state, renderers, events), `core/api.js`, `core/dom.js` (toast, escape, formObject), `core/icons.js` (inline SVG), `core/ui.js` (buttons, dropdown menu, loading) | |
| CSS | `Styles/app.css` (Tailwind layers + components), `tailwind.config.js` (blue brand palette) | |
| Error page | `Views/Shared/Error.cshtml` | one template for 403/404/413/419/429/500 |
| States | splash, skeleton loading, empty states per list, field errors (`aria-invalid` + inline message), toasts (success/error), button loading spinner, confirm for check-in/delete, print (`window.print`, `.no-print`) | |

Not present in the product (and out of scope for a presentation-only redesign): settings, user management and audit
log screens, notifications, room housekeeping states (cleaning/maintenance), floors, a notes entity separate from
booking notes and guest notes, bulk actions.

## Problems found

### Visual language
1. Generic SaaS look: default-like blue (`#2585E6`), gradient sidebar and profile card, blurred brand panel, coloured
   shadows, a different colour on every navigation icon. Nothing says "resort".
2. Many identical cards: 12 equal KPI tiles on the report page, 4 on Today, 3 on the room map; KPI icons in coloured
   bubbles add noise without meaning.
3. Uppercase + wide letter-spacing on Thai labels (`.label`, section captions, "OPERATIONS DESK") — Thai has no case,
   so this only reduces legibility; mixed Latin captions ("Room nights", "Occupancy Rate") next to Thai ones.
4. Radii are large and inconsistent (12/16/20/24 px), cards have shadows everywhere.

### Hierarchy and density
5. Bookings list is one large card per booking (≈ 170 px each); 12 bookings need two screens at 1440 px. Money is
   repeated in boxed sub-cards; status, dates and room are scattered. No sorting, no column alignment for numbers.
6. Guests directory: two-column cards with a metrics box each; hard to scan or compare.
7. Today: arrivals/departures are fine conceptually, but the action button is a squashed small pill and the greeting
   is always "สวัสดีตอนเช้า" whatever the time.
8. Room map communicates only vacant/occupied; arrivals today and departures today (both derivable) are invisible.
9. Reports: revenue chart is mostly empty space at a fixed height; donuts use hard-coded hex colours (`conic-gradient`)
   that ignore the palette; numbers are not tabular so columns jitter.

### Components and states
10. `btn-sm` at `text-xs` renders as a cramped pill in lists; icon and label are not optically centred.
11. Dialog backdrops blur the page (heavy on low-end tablets) and dialogs are 24 px rounded with large shadows.
12. Toasts appear under the sticky header on mobile; success toast uses dark ink background unlike the rest of the UI.
13. Field errors are red text only (no icon); required fields are not marked; labels are uppercase micro-type.
14. Calendar day markers rely on colour dots only (text exists only in `title`).
15. Error page is generic; no hint what to do for 419/429.

### Responsiveness
16. Mobile: floating "สร้าง Booking" overlaps content and sits right above the bottom navigation; two primary actions
    compete. The bottom nav labels are 10 px.
17. Tablet (768 px): sidebar at 260 px leaves a narrow content column; the bookings toolbar wraps awkwardly.

### Accessibility
18. No skip-to-content link; sections are `<section>` without headings for screen readers in some places.
19. Focus ring is `brand-500/40` (≈ 1.7:1 against white) — below the 3:1 requirement. White text on the primary button (`#2585E6`) is 3.8:1 — fails AA for normal text.
20. Muted text `#668096` on canvas `#F6FAFE` is 3.9:1 — fails AA for body text.
21. No dark mode; `color-scheme` fixed to light; no reduced-motion handling beyond a global override.

### CSP
22. Scripts: one external module with the per-request nonce; no inline handlers. Inline `style=""` attributes are used
    for chart bar heights (allowed by `style-src 'unsafe-inline'`). A head theme script must carry the nonce.

## Redesign scope

Login, app shell (sidebar, top bar, mobile navigation, command palette), Today, Room board, Bookings (table + calendar),
Reports (+ print), Rooms management, Guests table, Guest profile drawer, Booking / Room / Action forms, Confirm dialog,
Error page, Toasts, Dropdown menu, Loading/empty states, Dark mode and theme switcher, density toggle.
