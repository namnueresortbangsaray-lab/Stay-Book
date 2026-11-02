# PHP → ASP.NET Core migration plan

Source: tag `php-original` (see `docs/PROJECT_KNOWLEDGE.md`, `tests/baseline/`). Target: ASP.NET Core MVC on .NET 10 (SDK 10.0.403
installed locally), EF Core 10 with SQLite (default) and PostgreSQL/Supabase, Identity cookie auth, Razor, Tailwind CLI, Docker.
The solution keeps the requested name `ResortGuestbook`; the product shown to users stays "Stay Book".

## 1. Mapping

| PHP | ASP.NET Core |
|---|---|
| `public/index.php`, `bootstrap/app.php`, `Container` | `Program.cs` + `Infrastructure/Extensions/ServiceCollectionExtensions` (built-in DI, Options) |
| `Router` + `routes/*.php` | attribute routing; `HEAD` handled by `[HttpGet]`; `_method` via `UseHttpMethodOverride(FormFieldName="_method")` |
| `Request::input()` loose JSON/form | `Infrastructure/Http/RequestInput` (JSON object or form → PHP-compatible coercion helpers `Php.ToInt/ToBool/IsNumeric`) |
| `Http/Requests/RoomRequest`, `StayRequest` | `Services/Validation/RoomRequest`, `StayRequest` returning typed commands; same messages and order |
| `ValidationException`, `NotFoundException`, `PDOException` mapping | `Services/Errors/*Exception` + `ApiExceptionFilter` (422/404/409/500 envelopes) |
| `Response::json` envelope | `Models/Dtos/ApiEnvelope` + `ApiResults` helper; snake_case via explicit `JsonPropertyName`/`SnakeCaseLower` policy, `UnsafeRelaxedJsonEscaping` (unescaped Thai) |
| `Session`, `AuthService` | ASP.NET Core Identity (`AddIdentityCore<AppUser>` + `SignInManager`, cookie), `LoginThrottle` (per-IP failure window) |
| `password_hash`/`password_verify` | `LegacyBcryptPasswordHasher` (BCrypt.Net-Next for `$2y$`/`$2a$`/`$2b$`, `SuccessRehashNeeded`) wrapping `PasswordHasher<AppUser>` |
| CSRF in session | Antiforgery, global `AutoValidateAntiforgeryToken`; header `X-CSRF-Token`, form field `_token`; failure → 419 |
| `ResortPolicy::allows` | authorization policies `manage_rooms, edit_guest, booking, checkout, upload, view, manage_users` + `AbilityHandler` (role → ability table) |
| `ResortRepository` + `Dialects` | `Data/AppDbContext` + `Data/Providers/SearchExtensions` (LIKE lower / ILIKE) — no repository wrapper; services query EF directly |
| `Migrator` + SQL files + `schema_migrations` | EF migrations in `ResortGuestbook.Migrations.Sqlite` / `.Postgres`, `__EFMigrationsHistory` |
| `Seeder`, `database/seeders/rooms.php` | `Data/Seed/DatabaseSeeder` + `RoomSeedData` |
| `Transfer` | `Infrastructure/Cli/DbTransferCommand` (EF, both providers) |
| `Backup` | `Infrastructure/Cli/DbBackupCommand` (`VACUUM INTO`) |
| `ImportFlutterCommand` | dropped (it only printed an error); replaced by `import:php` |
| `bin/console` | `dotnet ResortGuestbook.Web.dll <command>` (`Infrastructure/Cli/CliRunner`, before host start) |
| `views/*.php` | Razor: `Views/Shared/_Layout`, `_AuthLayout`, `Views/Auth/Login`, `Views/Dashboard/Index`, `Views/Shared/Error` (+ `StatusCodes`) |
| `resources/lang/*/messages.php` | `Resources/SharedResource.th.resx` / `.en.resx`, `IViewLocalizer`, default culture `th-TH` with Gregorian calendar |
| `resources/js`, `resources/css`, `scripts/build.mjs` | `Scripts/`, `Styles/app.css` → `wwwroot/js/app.js`, `wwwroot/css/app.css` (esbuild + Tailwind CLI), `asp-append-version` |
| `X-Accel-Redirect` + nginx internal | `FilesController` → authorize → `PhysicalFile` from `IFileStorage` (`LocalFileStorage`, `storage/uploads`) |
| `UploadService` + finfo | `Services/UploadService` + `FileSignatureSniffer` (JPEG/PNG/WebP/PDF magic bytes) |
| `Logger` | Serilog (console + rolling file `storage/logs`) |
| nginx `/health` | `MapHealthChecks("/health")` with `DbContext` check, body `ok` |
| nginx security headers | `SecurityHeadersMiddleware` (same headers, nonce-based `script-src`) + nginx in prod |
| PHP-FPM/nginx compose | `docker/Dockerfile` (node → sdk → aspnet), `docker-compose*.yml`, `docker/nginx/default.conf` (prod) |
| PHPUnit | xUnit (`tests/ResortGuestbook.Tests`), Testcontainers PostgreSQL |

## 2. Data model decisions

- Same table and column names (snake_case via `ToTable`/`HasColumnName`), same CHECK constraints and index names.
- `Guid` keys stored as **lowercase TEXT** in SQLite (custom converter; EF's default is uppercase) and `uuid` in PostgreSQL.
- Timestamps `DateTimeOffset` UTC; SQLite stores the PHP format `yyyy-MM-ddTHH:mm:ss+00:00` (sortable text, PHP-compatible), PostgreSQL `timestamptz`.
- Dates `DateOnly` (`yyyy-MM-dd` TEXT / `date`). Booleans INTEGER 0/1 / boolean. Money `long` satang.
- `audit_logs.before_json/after_json`: `string` mapped to TEXT / `jsonb`.
- `users` keeps the PHP columns and gains the columns Identity needs (`user_name, normalized_user_name, normalized_email,
  security_stamp, concurrency_stamp, lockout_end, lockout_enabled, access_failed_count`); unused IdentityUser members
  (phone, 2FA, email-confirmed) are ignored in the model. Role stays in `users.role` (CHECK) and becomes a role claim;
  no AspNetRoles tables.
- `deleted_at` filters become global query filters; deletes stay physical exactly like PHP.
- `created_at`/`updated_at` set by `TimestampInterceptor`. SQLite connection interceptor: `foreign_keys=ON`, `journal_mode=WAL`, `busy_timeout=5000`.
- PostgreSQL migration enables RLS on all 8 tables and `__EFMigrationsHistory`, no policies (and on `room_zones` / `room_types`, added later).
- Provider chosen by `Database:Provider` (`Sqlite`|`Postgres`); only `Data/` and DI registration branch on it.

## 3. API compatibility notes

- Paths, methods, status codes, messages and envelope identical to `tests/baseline/cases`. JSON field names and order follow the PHP rows.
- Loose input coercion reproduced (string numbers, `"on"`/`"yes"` booleans, `(int)` truncation) so the existing JS and any scripts keep working.
- CSRF header stays `X-CSRF-Token` (Antiforgery `HeaderName`), so `Scripts/core/api.js` is unchanged except asset paths.
- Antiforgery tokens are bound to the signed-in user: clients must read a fresh token after login (the dashboard does so).
- The contract test starts the app on Kestrel (`WebApplicationFactory.UseKestrel`), replays `tests/baseline/capture.mjs` and compares status, headers, messages, errors and full JSON bodies (volatile ids and timestamps masked) with `compare.mjs`; allowed differences are listed in `tests/baseline/deviations.json`.

## 4. Parity checklist

Status: ☑ done and verified (unit, integration and contract tests; Docker smoke test on SQLite and PostgreSQL) · ⚠ deviation (see §5)

| ID | Item | Target | Status |
|---|---|---|---|
| W1 | GET /login (redirect if signed in) | `AuthController.Login` | ☑ |
| W2 | POST /login (throttle 429, error 200, success 302) | `AuthController.Login(POST)` + `LoginThrottle` | ☑ |
| W3 | POST /logout | `AuthController.Logout` | ☑ |
| W4 | GET / dashboard shell | `DashboardController.Index` | ☑ |
| W5 | GET /files/{id} | `FilesController.Download` | ☑ |
| A1 | GET /api/v1/snapshot | `Api/V1/SnapshotController` | ☑ |
| A2 | GET /api/v1/stays | `Api/V1/StaysController.Search` | ☑ |
| A3–A5 | rooms POST/PUT/DELETE | `Api/V1/RoomsController` | ☑ |
| A6 | PUT /api/v1/guests/{id} | `Api/V1/GuestsController` | ☑ |
| A7–A9 | stays POST/PUT/DELETE | `Api/V1/StaysController` | ☑ |
| A10–A12 | check-in, checkout, feedback | `Api/V1/StaysController` (feedback removed later, D-24) | ☑ / ⚠ |
| A13 | attachments upload | `Api/V1/StaysController.Upload` | ☑ |
| A14 | bookings.csv | `Api/V1/ReportsController` | ☑ |
| N1 | /health | HealthChecks | ☑ |
| E1 | 404 html/json, 419, 500, 401 handling | `ErrorsController`, filters | ☑ |
| F1 | Price calculator | `Services/PriceCalculator` | ☑ |
| F2 | Overlap rule, same-day turnover | `StayService` | ☑ |
| F3 | Analytics/snapshot | `SnapshotService` | ☑ |
| F4 | Guest summaries | `GuestService` | ☑ |
| F5 | Audit log entries | `AuditService` | ☑ |
| F6 | Role/ability matrix | `Authorization/` | ☑ |
| F7 | Upload sniffing/limits/random names | `UploadService` | ☑ |
| F8 | CSV format (BOM, quoting, formula guard) | `CsvWriter` | ☑ |
| F9 | Security headers / CSP | middleware + nginx | ☑ |
| F10 | Session lifetime, cookie flags | Identity cookie | ☑ |
| C1 | migrate | CLI | ☑ |
| C2 | seed | CLI | ☑ |
| C3 | user:create | CLI | ☑ |
| C4 | db:backup | CLI | ☑ |
| C5 | db:transfer | CLI | ☑ |
| C6 | import:flutter | dropped → import:php | ⚠ |
| C7 | import:php (new) | CLI | ☑ |
| V1 | Login view, dashboard view, error view, layouts | Razor | ☑ |
| V2 | JS modules app/api/dom/icons/ui | `Scripts/` | ☑ |
| V3 | Tailwind theme, fonts, images, robots | `Styles/`, `wwwroot/` | ☑ |
| V4 | Translations app_name/location/login | `.resx` | ☑ |
| T1 | Port PHP tests (Csv, Price, Router HEAD, StayRequest, migration parity, service lifecycle, sqlite repo) | xUnit | ☑ |
| T2 | Smoke test | `tests/smoke/smoke-test.sh` | ☑ |

## 5. Intentional deviations

| ID | PHP | .NET | Reason |
|---|---|---|---|
| D-01 | `PHPSESSID` file session | Identity auth cookie `.StayBook.Auth` (sliding, same lifetime) | framework auth; existing sessions are dropped once at upgrade |
| D-02 | CSRF token per session | Antiforgery token per user/session; header/field names unchanged | built-in Antiforgery; token must be re-read after login |
| D-03 | `users` table | + Identity columns | Identity needs stamps/lockout |
| D-04 | `schema_migrations` | `__EFMigrationsHistory` | EF migrations |
| D-05 | no account lockout | Identity lockout 5 failures / 15 min per account, in addition to per-IP throttle | requested hardening, same thresholds as the IP throttle |
| D-06 | write endpoints unlimited | rate limiter 120 writes/min per user → 429 envelope | requested; generous enough not to affect staff use |
| D-07 | upload errors → 500 generic | 422 `ข้อมูลไม่ถูกต้อง` with `errors.file` = original Thai reason | the PHP message hid the real reason; status was a bug |
| D-08 | `import:flutter` | removed | it could never succeed; `import:php` covers the real upgrade path |
| D-09 | X-Accel-Redirect | app streams the file after authorization | no PHP-FPM; Nginx is optional in dev |
| D-10 | CSP `script-src 'self'` | `script-src 'self' 'nonce-…'` | per-request nonce requirement; no inline script exists today |
| D-11 | guest list rows leak first joined stay columns | kept (`stay_id`, `stay_status`, …) | parity — documented as quirk |
| D-12 | no concurrency control | none added | API carries no version field; adding tokens would change the contract |
| D-13 | audit in repository calls | `AuditService` called by services (not a SaveChanges interceptor) | actions like `check_in`/`feedback` and API-shaped JSON cannot be inferred by an interceptor |
| D-14 | – | data layer in `src/ResortGuestbook.Data` instead of `Web/Data` | the migrations projects must reference the DbContext and the host must load them; inside Web that is a project-reference cycle |
| D-15 | cookie `Secure` when APP_ENV=production | `Secure` follows the request scheme | the resort LAN may use plain HTTP; behind TLS (forwarded proto) cookies are Secure |
| D-16 | error page also loaded `app.js` (which then threw) | scripts only on the dashboard | the bundle expects the dashboard markup |
| D-17 | always Thai | Thai unless `?culture=en` or the culture cookie | the English `.resx` is available on request; the browser language is ignored, as before |
| D-18 | unnamed inline UNIQUE/CHECK constraints | named constraints (`ck_*`, `ux_*`) plus EF FK indexes (`IX_*`) | EF requires names; the extra indexes only speed up deletes |
| D-19 | `user:create` crashed on a duplicate email | prints an error and exits 1 | clearer CLI; other CLI failures also print one line instead of a stack trace |
| D-20 | prompt suggested header `RequestVerificationToken` | header stays `X-CSRF-Token` | API compatibility; the JavaScript is unchanged |
| D-21 | no Thai normalizer existed | search reproduces `LOWER() LIKE` / `ILIKE` without a normalized column | nothing to port; Thai has no letter case |
| D-22 | dashboard shell copy (section labels, dialog subtitles) | redesigned interface copy from the resx files; titles, element ids and login/error text unchanged | UI redesign (docs/DESIGN_SYSTEM.md); recorded in tests/baseline/deviations.json |
| D-23 | free-text room zone and type | managed `room_zones` / `room_types` lists (migration `AddRoomCategories`, both providers); rooms keep the names, new endpoints `/api/v1/room-categories`, `/room-zones`, `/room-types` | feature added after the migration; v1 endpoints and contract unchanged |
| D-24 | staff record guest feedback (`POST /api/v1/stays/{id}/feedback`, rating form, average in reports) | endpoint and UI removed (404); `feedbacks` table and existing rows kept and still read | feedback is for guests to give, not staff; the table stays for a future guest-facing form. Recorded in `tests/baseline/deviations.json` |
| D-27 | no record of how a booking came in | optional `stays.booking_channel` (migration `AddBookingChannel`, both providers), validated against a fixed list; booking form select, bookings table column, reports breakdown | requested feature; the field is appended to stay rows, `compare.mjs` ignores it (`ADDED_KEYS`), every other field is still compared; `import:php` reads v1 stays without it |
| D-26 | no record of the ID card check | optional ID card photo per booking (`stay_id_photos`, `/api/v1/id-photos`, `/api/v1/stays/{id}/id-photo`, `/files/id-photo/{stayId}`), shrunk in the browser, deleted 90 days after check-out | requested feature; separate table and endpoints, so snapshot and attachment contracts are unchanged |
| D-25 | staff accounts only via `user:create`; `manage_users` unused; no password change | users page and API for admins, own password change for everyone, minimum password length 10, sessions re-validated by security stamp (the cookie events had dropped Identity's validator) | requested feature after the migration; v1 endpoints and contract unchanged |

## 6. Assumptions

- A1: The domain is rooms/stays/guests (the prompt's "guest notes" are stay `note`, guest `customer_note`/`preferences`).
- A2: No Thai normalizer exists in PHP; search reproduces `Dialect::search` exactly.
- A3: CLI accepts `--to=postgres` and the PHP alias `pgsql`.
- A4: The PHP database file in the reused `staybook_database` volume (`stay_book.sqlite`) is left untouched; .NET uses `staybook.db` next to it, and `import:php` copies data across. Uploads volume is mounted at `storage/uploads`, so stored files are already in place.
- A5: Existing volumes are owned by Alpine `www-data` (uid 82); a one-shot `storage-init` service chowns them for the non-root .NET user (uid 1654).
- A6: Swagger UI (Development only) reads the built-in OpenAPI document.
- A7: Environment variable names switch to ASP.NET Core style (`Database__Provider`, …); `SUPABASE_DB_*`, `DEMO_ADMIN_*`, `UPLOAD_MAX_BYTES`, `BACKUP_KEEP`, `SESSION_LIFETIME` keep their PHP names for easy upgrade.
- A8: The Thai worksheet `docs/ใบงานปฏิบัติงาน_Stay_Book.docx` and its generator `tools/build_staybook_worksheet.py` are kept unchanged as a historical record of the PHP phase; regenerating them needs Python + python-docx, which are not installed here.
- A9: The local installation was upgraded in place: the old `.env` is saved as `.env.php.bak` (git-ignored) and `.env` was regenerated from `.env.example` with the admin, Supabase and limit values carried over; the PHP containers were stopped (not removed); the PHP database was copied to the backups volume as `php-stay_book-before-dotnet-20261030.sqlite` and imported with `import:php --truncate`. The unused `stay-book_staybook_sessions` volume was left in place.
- A10: `MapStaticAssets` is not used because the front end is built by npm outside MSBuild; `UseStaticFiles` + `asp-append-version` provide fingerprinting.
- A11: In comments and test names the previous implementation is called "v1"; only these two history documents, the `import:php` command and the `php-original` tag name it.
