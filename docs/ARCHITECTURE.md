# Architecture

## Solution

```
src/ResortGuestbook.Web                 ASP.NET Core MVC app, API, Razor views, CLI, front-end sources
src/ResortGuestbook.Data                EF Core model, provider setup, Identity store, seed, transfer/import/backup
src/ResortGuestbook.Migrations.Sqlite   EF Core migrations for SQLite
src/ResortGuestbook.Migrations.Postgres EF Core migrations for PostgreSQL (+ row level security)
tests/ResortGuestbook.Tests             unit, data (both providers), integration, baseline contract
tests/baseline                          recorded HTTP behaviour of v1, replay + compare scripts
tests/smoke                             curl/jq end-to-end test
```

The data layer is a separate library because each migrations project must reference the `DbContext` and the web app
must load both migrations assemblies; with the context inside the web project those references would form a cycle.

## Request pipeline

```
Kestrel (behind Nginx in production)
 → ForwardedHeaders → Serilog request log → ExceptionHandler → HSTS (prod) → SecurityHeaders (CSP nonce)
 → StatusCodePages (re-execute /errors/{code}) → ResponseCompression → HttpMethodOverride (_method)
 → StaticFiles → Routing → RequestLocalization (th-TH) → Authentication → Authorization (fallback: signed in)
 → RateLimiter → MVC: AutoValidateAntiforgeryToken (419) → RequireAbility (403) → controller → service → DbContext
```

Controllers are thin: they read the request (`RequestInput` keeps v1's loose JSON/form coercion), call one service and
return the JSON envelope (`ApiResults`) or a view. `ApiExceptionFilter` maps `ValidationException` (422),
`NotFoundException` (404) and duplicate-key `DbUpdateException` (409) to envelopes. Unknown routes fall back to a 404
endpoint, so they never trigger a login redirect.

## Domain services

| Service | Responsibility |
|---|---|
| `ResortQueries` | Read models with v1 shape and ordering (rooms, joined stays, guest summaries, attachments) |
| `StayService` | Create/edit with validation, capacity, pet and overlap rules, guest lookup by phone, pricing; check-in; checkout with inspection; delete |
| `RoomService`, `GuestService` | Room CRUD with cascade delete; guest profile update |
| `UserService` | Staff accounts: create/edit/deactivate (never delete), admin password reset (lifts lockout), own password change; self-lockout and last-admin guards; new security stamp on sign-in-relevant changes |
| `RoomCategoryService` | Zone and room-type lists (`room_zones`, `room_types`): rename cascades to rooms, delete only when unused, room defaults per type; `RoomCategorySync` (Data) fills the lists from rooms after migrate, seed and `import:php` |
| `SnapshotService` | Date-range validation and analytics |
| `PriceCalculator`, `CsvWriter` | Pricing rules; CSV with BOM, formula guard and v1 quoting |
| `UploadService` + `IFileStorage` | Signature sniffing, size limit, random names, private storage |
| `IdPhotoService` + `IdPhotoRetentionService` | One ID card photo per booking (`stay_id_photos`, private storage); removed with the booking or room; a hosted job purges photos 90 days after check-out at start-up and daily |
| `AuditService` | `audit_logs` rows with before/after JSON for create, update, delete, check_in, check_out; `RecordSystemAsync` for jobs (no user, IP `system`) |

## Data

One EF Core model, two providers, chosen by `Database:Provider`; only `ResortGuestbook.Data` and DI registration know
which. Tables, columns, CHECK constraints and indexes keep the v1 schema. On SQLite, GUIDs are lowercase TEXT and
timestamps UTC TEXT (`…+00:00`) via value converters; PostgreSQL uses `uuid`, `timestamptz`, `date`, `jsonb`.
Interceptors set `created_at`/`updated_at` and SQLite pragmas (foreign keys, WAL, 5 s busy timeout). `deleted_at` is a
global query filter; deletes are physical, as before. Search uses `lower(col) LIKE lower(@p)` on SQLite and `ILIKE` on
PostgreSQL (`StaySearchExtensions`).

## Security

- Identity cookie auth (HttpOnly, SameSite=Lax, Secure over HTTPS, sliding 120 min) with a custom store over `users`;
  roles come from `users.role`. bcrypt hashes from v1 verify and are re-hashed on sign-in. `SecurityStampValidator`
  re-checks sessions every `Auth__SessionCheckSeconds`, so password, role, email or status changes end other sessions.
- Staff accounts are managed in the app (`UserService`, `manage_users` = admin): create, edit, deactivate, reset password;
  everyone changes their own password. Password rule: minimum length only (`Auth__PasswordMinLength`, default 10).
- Per-IP failed-login throttle (5 in 15 min) plus Identity lockout; rate limits on login and writes.
- Antiforgery on every non-GET request (`X-CSRF-Token` header / `_token` field).
- Ability policies: `admin` everything, `front_desk` everything but user management, `housekeeping` view/checkout/upload.
- CSP with a per-request script nonce, `X-Frame-Options: DENY`, `nosniff`, `Referrer-Policy`, `Permissions-Policy`.
- Uploads outside `wwwroot`, delivered only by `FilesController` after authorization, with `nosniff`. ID card photos
  are shrunk in the browser (`Scripts/core/image.js`), served with `no-store`, and purged after the retention period.
- PostgreSQL: RLS enabled on all tables without policies.

## Front end

Razor renders the login page and the dashboard shell; `Scripts/app.js` (bundled by esbuild) loads `/api/v1/snapshot`
and renders the six sections. Tailwind compiles `Styles/app.css` against `Views/**/*.cshtml` and `Scripts/**/*.js`.
Assets are cache-busted with `asp-append-version`.
