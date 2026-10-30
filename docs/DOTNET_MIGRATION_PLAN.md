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
- PostgreSQL migration enables RLS on all 8 tables and `__EFMigrationsHistory`, no policies.
- Provider chosen by `Database:Provider` (`Sqlite`|`Postgres`); only `Data/` and DI registration branch on it.

## 3. API compatibility notes

- Paths, methods, status codes, messages and envelope identical to `tests/baseline/cases`. JSON field names and order follow the PHP rows.
- Loose input coercion reproduced (string numbers, `"on"`/`"yes"` booleans, `(int)` truncation) so the existing JS and any scripts keep working.
- CSRF header stays `X-CSRF-Token` (Antiforgery `HeaderName`), so `Scripts/core/api.js` is unchanged except asset paths.
- Antiforgery tokens are bound to the signed-in user: clients must read a fresh token after login (the dashboard does so).
- Contract tests replay the baseline flow in-process (`WebApplicationFactory`) and compare status, message, errors, and JSON key sets/values with volatile fields masked.

## 4. Parity checklist

Status: ☐ todo · ☑ done and verified · ⚠ deviation (see §5)

| ID | Item | Target | Status |
|---|---|---|---|
| W1 | GET /login (redirect if signed in) | `AuthController.Login` | ☐ |
| W2 | POST /login (throttle 429, error 200, success 302) | `AuthController.Login(POST)` + `LoginThrottle` | ☐ |
| W3 | POST /logout | `AuthController.Logout` | ☐ |
| W4 | GET / dashboard shell | `DashboardController.Index` | ☐ |
| W5 | GET /files/{id} | `FilesController.Download` | ☐ |
| A1 | GET /api/v1/snapshot | `Api/V1/SnapshotController` | ☐ |
| A2 | GET /api/v1/stays | `Api/V1/StaysController.Search` | ☐ |
| A3–A5 | rooms POST/PUT/DELETE | `Api/V1/RoomsController` | ☐ |
| A6 | PUT /api/v1/guests/{id} | `Api/V1/GuestsController` | ☐ |
| A7–A9 | stays POST/PUT/DELETE | `Api/V1/StaysController` | ☐ |
| A10–A12 | check-in, checkout, feedback | `Api/V1/StaysController` | ☐ |
| A13 | attachments upload | `Api/V1/StaysController.Upload` | ☐ |
| A14 | bookings.csv | `Api/V1/ReportsController` | ☐ |
| N1 | /health | HealthChecks | ☐ |
| E1 | 404 html/json, 419, 500, 401 handling | `ErrorsController`, filters | ☐ |
| F1 | Price calculator | `Services/PriceCalculator` | ☐ |
| F2 | Overlap rule, same-day turnover | `StayService` | ☐ |
| F3 | Analytics/snapshot | `SnapshotService` | ☐ |
| F4 | Guest summaries | `GuestService` | ☐ |
| F5 | Audit log entries | `AuditService` | ☐ |
| F6 | Role/ability matrix | `Authorization/` | ☐ |
| F7 | Upload sniffing/limits/random names | `UploadService` | ☐ |
| F8 | CSV format (BOM, quoting, formula guard) | `CsvWriter` | ☐ |
| F9 | Security headers / CSP | middleware + nginx | ☐ |
| F10 | Session lifetime, cookie flags | Identity cookie | ☐ |
| C1 | migrate | CLI | ☐ |
| C2 | seed | CLI | ☐ |
| C3 | user:create | CLI | ☐ |
| C4 | db:backup | CLI | ☐ |
| C5 | db:transfer | CLI | ☐ |
| C6 | import:flutter | dropped → import:php | ⚠ |
| C7 | import:php (new) | CLI | ☐ |
| V1 | Login view, dashboard view, error view, layouts | Razor | ☐ |
| V2 | JS modules app/api/dom/icons/ui | `Scripts/` | ☐ |
| V3 | Tailwind theme, fonts, images, robots | `Styles/`, `wwwroot/` | ☐ |
| V4 | Translations app_name/location/login | `.resx` | ☐ |
| T1 | Port PHP tests (Csv, Price, Router HEAD, StayRequest, migration parity, service lifecycle, sqlite repo) | xUnit | ☐ |
| T2 | Smoke test | `tests/smoke/smoke-test.sh` | ☐ |

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

## 6. Assumptions

- A1: The domain is rooms/stays/guests (the prompt's "guest notes" are stay `note`, guest `customer_note`/`preferences`).
- A2: No Thai normalizer exists in PHP; search reproduces `Dialect::search` exactly.
- A3: CLI accepts `--to=postgres` and the PHP alias `pgsql`.
- A4: The PHP database file in the reused `staybook_database` volume (`stay_book.sqlite`) is left untouched; .NET uses `staybook.db` next to it, and `import:php` copies data across. Uploads volume is mounted at `storage/uploads`, so stored files are already in place.
- A5: Existing volumes are owned by Alpine `www-data` (uid 82); a one-shot `storage-init` service chowns them for the non-root .NET user (uid 1654).
- A6: Swagger UI (Development only) reads the built-in OpenAPI document.
- A7: Environment variable names switch to ASP.NET Core style (`Database__Provider`, …); `SUPABASE_DB_*`, `DEMO_ADMIN_*`, `UPLOAD_MAX_BYTES`, `BACKUP_KEEP`, `SESSION_LIFETIME` keep their PHP names for easy upgrade.
