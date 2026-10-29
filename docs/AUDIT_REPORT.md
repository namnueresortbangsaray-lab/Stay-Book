# Stay Book — Audit Report

Audit date: 2026-10-23  
Scope: PHP application, REST API, SQLite/PostgreSQL persistence, Docker runtime, Tailwind/vanilla JavaScript UI, authentication, permissions, uploads, tests, responsive behavior, and accessibility.

## System map

- **Runtime:** PHP 8.3 FPM, Nginx 1.27, Docker Compose, Node 22 build stage.
- **Backend:** custom PSR-4 micro-framework (`app/Core`), PDO repositories, service layer, file-backed PHP sessions, CSRF tokens, role policy.
- **Frontend:** server-rendered shell, Tailwind CSS 3.4, ES2020 modules bundled by esbuild, no client framework.
- **Persistence:** SQLite with WAL by default; PostgreSQL 15/Supabase-compatible migrations and dialect abstraction.
- **State:** one in-memory browser state object populated by `/api/v1/snapshot`; mutations reload the snapshot.
- **Configuration:** `.env` loaded through `vlucas/phpdotenv`; no secrets committed.

## Routes and endpoints

| Method | Route | Purpose |
|---|---|---|
| GET/POST | `/login` | Login page and session creation |
| POST | `/logout` | Destroy session |
| GET | `/` | Authenticated application shell |
| GET | `/files/{id}` | Authenticated protected attachment delivery |
| GET | `/api/v1/snapshot` | Rooms, stays, guests, and analytics |
| GET | `/api/v1/stays` | Search/filter stays |
| POST/PUT/DELETE | `/api/v1/rooms[/{id}]` | Room management |
| PUT | `/api/v1/guests/{id}` | Guest profile update |
| POST/PUT/DELETE | `/api/v1/stays[/{id}]` | Booking creation/update/deletion |
| POST | `/api/v1/stays/{id}/check-in` | Check-in transition |
| POST | `/api/v1/stays/{id}/checkout` | Checkout inspection and transition |
| POST | `/api/v1/stays/{id}/feedback` | Post-checkout feedback |
| POST | `/api/v1/stays/{id}/attachments` | Protected file upload |
| GET | `/api/v1/reports/bookings.csv` | Booking CSV export |

## Data models

`users`, `rooms`, `guests`, `stays`, `checkout_inspections`, `feedbacks`, `attachments`, `audit_logs`, and `schema_migrations`. Identifiers are UUIDv4, money is integer satang, stays use half-open date ranges, and timestamps are UTC.

## Feature inventory

| Area | User-facing functions | Flow verified |
|---|---|---|
| Authentication | Login, throttling, protected routes, logout, session renewal | UI → controller → repository → session |
| Room board | Zone grouping, vacant/occupied status, room-to-booking shortcut | Snapshot → client render |
| Bookings | Create, edit booked stay, search, status filter, list/calendar views, delete | Form → validation → service → repository → reload |
| Availability | Overlap detection, adjacent same-day turnover, capacity, pet-friendly constraint | Service → repository query |
| Pricing | Room nights, extra guests, extra bed, pet fee, discount, paid deposit balance | JS preview + PHP calculator |
| Stay lifecycle | Immediate check-in, check-in, extension, checkout inspection | API transition endpoints |
| Guests | Phone de-duplication, history, lifetime metrics, regular-customer flag, preferences | Snapshot + guest update API |
| Rooms | Create, edit, price/capacity/pet configuration, delete with related history | Room API + repository transaction |
| Feedback | Four ratings, return intent, comment, post-checkout enforcement | Feedback endpoint |
| Reports | Date presets/custom period, KPIs, revenue/occupancy charts, CSV, print | Snapshot analytics + CSV endpoint |
| Files | MIME/size validation, random storage name, protected download route | Upload API → storage → X-Accel-Redirect |
| Roles | Admin, front desk, housekeeping server policy | Policy enforced on mutations |
| Operations | Migrate, seed, create user, backup, transfer, import status | CLI commands |

## Automated baseline

| Check | Result |
|---|---|
| Docker image build and boot | Pass; PHP and Nginx healthy |
| PHP syntax | Pass, 66 files |
| PHP-CS-Fixer dry run | Pass |
| PHPStan level 6 | Pass |
| Final PHPUnit suite | Pass, 13 tests / 24 assertions |
| Added fail-before regressions | 3 failures confirmed: lifecycle bypass, HEAD routing, negative money |
| JavaScript syntax | Pass; original script omitted `icons.js` |
| Tailwind/esbuild production build | Pass; Browserslist freshness warning |
| Browser interaction | Today desk, command search, dialog close, mobile navigation and hash deep link verified |
| Browser responsive baseline | Checked at 375px, 768px, and desktop; dialog remains scrollable at small heights |

## Issues

| ID | Severity | Area | Steps to reproduce | Expected | Actual | Root cause | Files involved | Status |
|---|---|---|---|---|---|---|---|---|
| AUD-001 | Critical | Test safety | Run PHPUnit inside the Compose `php` service | Tests always use an isolated database | Compose `SQLITE_PATH` can point destructive setup at the runtime DB | Test bootstrap inherited service environment | `tests/bootstrap.php`, CI | Fixed — forced isolated test path and explicit test driver |
| AUD-002 | High | Dialogs | Open any dialog and press ปิด/ยกเลิก | Dialog closes | Button does nothing; Escape is the only exit | Empty `data-close` becomes a falsy empty string | `resources/js/app.js`, dashboard view | Fixed — attribute-presence check; browser verified |
| AUD-003 | High | Stay lifecycle | POST a new stay with `status=2` | Checkout only through inspection endpoint | Completed stay is inserted without check-in/inspection | Client-controlled lifecycle status accepted | `StayRequest`, `ResortService` | Fixed — server-owned transition; regression passes |
| AUD-004 | High | Room integrity | Update an active stay to another room via API | Old room becomes vacant or move is rejected | Old room can remain occupied | Save transaction does not reconcile previous room | `ResortRepository`, `ResortService` | Fixed — active room move rejected explicitly |
| AUD-005 | High | Reports | Select custom dates then click CSV | CSV uses selected period | Static link exports default current month | Query parameters are not synchronized | dashboard view, `app.js` | Fixed — export URL synchronized with range |
| AUD-006 | High | Analytics | Request invalid/reversed/extreme date range | 422 with bounded valid range | Invalid values reach `strtotime`; extreme ranges can cause huge loops | No report-range validator | `ResortController`, `ResortService` | Fixed — strict date/order/366-day validation |
| AUD-007 | High | Attachments | Upload a file and return to booking | Attachment is listed and downloadable | Upload succeeds but UI provides no file history/link | Snapshot omits attachment metadata | Repository, service, UI | Fixed — safe attachment metadata and links included |
| AUD-008 | High | Roles/UX | Login as housekeeping | Only allowed tasks are visible | Create/edit/delete/check-in controls remain visible and return 403 | Role is present in DOM but ignored by renderer | view, `app.js`, policy | Fixed — action and room-management visibility follows policy |
| AUD-009 | High | API errors | Update missing ID or create duplicate room/phone | 404/409/422 envelope | Generic 500 “cannot save” | All non-validation exceptions collapse into 500 | API controller, repository | Fixed — expected missing/conflict cases map to 404/409 |
| AUD-010 | Medium | Validation | Submit negative deposit/discount/extra fee | Inline/server validation error | Values silently clamp to zero | Generic money parser uses `max(0, value)` | Request validators | Fixed — strict money validation and inline field feedback |
| AUD-011 | Medium | Forms | Double-click a save/action button on slow network | One request; visible busy state | Duplicate requests are possible | Submit controls are never disabled | `app.js` | Fixed — submit button disabled for in-flight mutation |
| AUD-012 | Medium | Loading/errors | Simulate snapshot/API failure | Friendly retry state and cleared spinner | Initial error becomes static text; no retry; mutation errors only toast | No shared async state component/finally | `app.js`, view | Fixed — finally cleanup, retry UI and inline errors |
| AUD-013 | Medium | Navigation | Navigate tabs then use browser Back/deep link | Restores selected workspace | Navigation has no URL/history state | Pure in-memory tab state | `app.js` | Fixed — hash history and deep links |
| AUD-014 | Medium | Performance | Grow rooms/stays/guests into thousands | Bounded/paginated responses | Snapshot and repository reads are unbounded; `stay()` scans all stays | Whole-dataset snapshot architecture | repository/service/UI | Needs decision — pagination changes API contract |
| AUD-015 | Medium | CSV security | Guest name starts with `=`, `+`, `-`, or `@` | Cell opens as text | Spreadsheet may interpret formula | No formula-injection escaping | API controller | Fixed — dangerous prefixes emitted as text; unit tested |
| AUD-016 | Medium | HTTP | Send `HEAD /` or `HEAD /login` | Same status as GET without a body | Router returns 404 | HEAD does not fall back to GET | `Router` | Fixed — HEAD matches GET; regression passes |
| AUD-017 | Medium | Booking update | Submit edit for a checked-in/checked-out stay directly | Lifecycle fields protected | Generic update can rewrite status/details | Update route has no transition-aware field policy | `ResortService` | Fixed — status preserved; completed stays immutable |
| AUD-018 | Medium | Filter validation | Request `status=abc` | 422 invalid filter | Coerced to status 0 | Direct integer cast | API controller | Fixed — explicit enum validation |
| AUD-019 | Medium | Accessibility | Inspect calendar day status | Icon/label in addition to color | Small dots communicate status by color only | Calendar cell markup lacks text/pattern | `app.js` | Fixed — status name exposed to assistive technology |
| AUD-020 | Medium | Upload consistency | File move succeeds and DB insert fails | File is rolled back | Orphaned private file remains | Filesystem and DB operations lack compensating cleanup | `UploadService` | Fixed — compensating unlink on persistence failure |
| AUD-021 | Low | Lint coverage | Run `npm run lint` | All JS modules checked | `icons.js` is omitted | Hard-coded script list | `package.json` | Fixed — all four modules checked |
| AUD-022 | Low | Auth flow | Visit `/login` while authenticated | Redirect to app | Login page remains accessible | Controller does not check existing session | `AuthController` | Fixed — authenticated sessions redirect |
| AUD-023 | Low | Configuration | Change security throttle settings | Runtime follows config | Auth service hard-codes 5 attempts/15 minutes | Security config is unused | `AuthService`, config | Fixed — attempts/window read from config |
| AUD-024 | Low | Frontend dependencies | Run production build | Clean build output | `caniuse-lite` freshness warning | Lock data is behind current browser database | `package-lock.json` | Needs decision — updating lock data installs dependency metadata |
| AUD-025 | Low | UX | Trigger destructive action | Accessible custom dialog/undo for reversible work | Native confirm blocks and has inconsistent presentation | Legacy confirm flow | `app.js` | Open |

## Systemic issues

1. The 1,200-line frontend entry file mixes formatting, data state, rendering, navigation, forms, and network orchestration; defects such as dialog closure and role leakage affect every screen.
2. Lifecycle state is represented as a normal editable field rather than a server-owned state machine.
3. API error semantics are not modeled; expected conflicts and missing records become 500 responses.
4. Test quantity is too small relative to the booking/availability/lifecycle risk, and the former bootstrap did not guarantee database isolation.
5. The whole-dataset snapshot is simple and effective for the current resort size but needs an explicit pagination threshold before larger deployments.

