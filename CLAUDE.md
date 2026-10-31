# CLAUDE.md — Stay Book (ResortGuestbook)

Staff web app for น้ำเหนือรีสอร์ท บางเสร่: room board, bookings (stays), check-in/out with inspection, guests,
attachments, analytics, CSV. UI is Thai. ASP.NET Core MVC on .NET 10.

Knowledge: @docs/ARCHITECTURE.md · @docs/API.md · @docs/DOTNET_MIGRATION_PLAN.md (deviations, assumptions) ·
@docs/PROJECT_KNOWLEDGE.md (behaviour of v1, the source of truth for business rules) · `tests/baseline/` (recorded v1 HTTP behaviour).
"v1" = the previous implementation (git tag `php-original`).

## Stack
ASP.NET Core MVC .NET 10, C# 13, EF Core 10 (SQLite default, Npgsql for Supabase), Identity cookie auth with a custom
user store, Razor, Tailwind CLI + esbuild, vanilla JS modules, Serilog, xUnit + Testcontainers, Docker (Kestrel; Nginx in prod).
Display TZ Asia/Bangkok, store UTC.

## Layout
| Path | Contents |
|---|---|
| `src/ResortGuestbook.Web` | `Controllers/` (+ `Api/V1`), `Services/` (+ `Validation`, `Errors`), `Authorization/`, `Infrastructure/{Cli,Extensions,Http,Identity,Middleware,Options,Storage}`, `Models/{Dtos,ViewModels}`, `Views/`, `Resources/` (.resx), `Scripts/`, `Styles/`, `wwwroot/` |
| `src/ResortGuestbook.Data` | `AppDbContext`, `Entities/`, `Configurations/`, `Conversions/`, `Interceptors/`, `Providers/`, `Identity/`, `Seed/`, `Transfer/`, `Legacy/`, `Maintenance/` |
| `src/ResortGuestbook.Migrations.{Sqlite,Postgres}` | EF migrations + design-time factory per provider |
| `tests/ResortGuestbook.Tests` | `Unit/`, `Data/` (both providers), `Integration/` (WAF + baseline contract) |
| `tests/baseline`, `tests/smoke` | v1 recording, replay/compare scripts; curl/jq smoke test |
| `docker/`, `docker-compose*.yml` | Dockerfile, Nginx; dev/prod/pgtest |

## Commands
- Run: `cp .env.example .env && docker compose up -d --build` → http://localhost:8080 (admin@staybook.local / ChangeMe123!)
- Local: `npm --prefix src/ResortGuestbook.Web ci && npm --prefix src/ResortGuestbook.Web run build && dotnet run --project src/ResortGuestbook.Web`
- Build/format/test: `dotnet build -c Release` · `dotnet format --verify-no-changes` · `dotnet test` (needs Docker for PostgreSQL, Node for the contract test)
- Migrations: `make migrations-add NAME=X` (= `dotnet ef migrations add X -p src/ResortGuestbook.Migrations.<P> -s src/ResortGuestbook.Migrations.<P>` for Sqlite and Postgres)
- CLI (in container): `dotnet ResortGuestbook.Web.dll migrate|seed|user:create|db:backup|db:transfer|import:php`; Makefile wraps them
- Baseline replay: `BASE_URL=http://localhost:8080 BASELINE_OUT=replay node tests/baseline/capture.mjs && node tests/baseline/compare.mjs`

## Hard rules
- Controllers thin; only `ResortGuestbook.Data` and `Services/` touch `AppDbContext`; no repository wrapper.
- Nothing outside `ResortGuestbook.Data` and DI registration branches on the database provider.
- Parameterized queries only; never `Html.Raw` on user data; scripts only with the CSP nonce; uploads never under `wwwroot`.
- API contract (paths, statuses, Thai messages, snake_case JSON and field order, envelope) must keep matching `tests/baseline/`;
  intended differences go into `tests/baseline/deviations.json` and the deviation table.
- Audit every create/update/delete/check_in/check_out; no personal data in logs.
- Staff accounts (D-25): `UserService` only; never delete users (deactivate), keep the self-lockout and last-admin guards,
  give a new security stamp on password/role/email/status changes, never put hashes or stamps in DTOs or audit rows.
  Keep `OnValidatePrincipal = SecurityStampValidator.ValidatePrincipalAsync` in the cookie events.
- ID card photos (D-26) are personal data: only through `IdPhotoService`, never in `attachments`, the snapshot, logs
  or audit JSON (audit holds size and type only); keep `no-store`, the retention purge and deletion with booking/room.
- Guest satisfaction feedback is not recorded by staff (D-24): no feedback endpoint or UI. The `feedbacks` table and
  existing rows stay (read as `feedback_rating` / `average_feedback`) for a future guest-facing form.
- `TreatWarningsAsErrors`, code style enforced in build, `dotnet format` clean. One type per file, file-scoped namespaces.
- Every model change needs migrations for **both** providers (a test fails otherwise); new PostgreSQL tables also get
  `ENABLE ROW LEVEL SECURITY` in their migration.
- Rooms store zone/type names; `room_zones` / `room_types` only define the choices. Keep them in step through
  `RoomCategoryService` (rename cascades, delete guard) and `RoomCategorySync`, never by editing rooms or lists alone.
- Never commit secrets, `.env`, SQLite files, uploads.

## Gotchas
- EF SQLite stores `Guid` uppercase by default → `LowercaseGuidConverter`; timestamps are TEXT `yyyy-MM-ddTHH:mm:ss+00:00` (`UtcTimestampConverter`).
- Input coercion is deliberately loose (`Coerce`, `RequestInput`): `"650.50"`, `"on"`, `(int)"3x"`; don't swap in strict model binding.
- Antiforgery tokens are user-bound: re-read the `csrf-token` meta after sign-in. Forms with a literal `action` need `asp-antiforgery="true"`.
- Config is read while building services, so integration tests pass settings via environment variables (one test collection).
- Git on Windows ignores case: `*.sqlite` would match `ResortGuestbook.Migrations.Sqlite/` (re-included in `.gitignore`).
- Git Bash rewrites `/app/...` paths in `docker compose exec` args: prefix with `MSYS_NO_PATHCONV=1`.
- Volumes from v1 belong to uid 82; `storage-init` chowns them for uid 1654 on every start.

## UI / Design system
Read @docs/DESIGN_SYSTEM.md before touching views, `Styles/` or `Scripts/`. In short:
- Colours only through token utilities (`bg-surface`, `text-ink-muted`, `tone-*`); the Tailwind palette is replaced, so
  `gray-500` etc. do not exist. New colour pairs go into `build/check-contrast.mjs` (the build fails below AA).
- Dark mode = `data-theme` on `<html>` (cookie + `_ThemeBoot` head script, nonce'd, before the stylesheet). Dark
  tokens are `@media screen` only, so print stays light. Avoid `dark:` variants unless a token cannot express it.
- All UI text via resx (`@T["ui.x"]` / `t('ui.x')`), Lucide icons via `<icon name>` / `icon()` + `icon-set.js`.
- Keep `id`, `name`, `data-action`, `data-id` stable (JS and the baseline contract depend on them).
- `.tone-*` sit outside `@layer` on purpose (runtime class names would be purged).
- Build helpers live in `build/`, not `scripts/`: on Windows `scripts` collides with `Scripts` in Docker contexts.
- Breakpoints: phone < 640 (`sm`), iPad 640–1279 (icon rail, `tabletHide` columns), desktop ≥ 1280. Touch targets
  44px on coarse pointers, inputs 16px below 1280px. The `theme-color` hex lives only on the meta tag in `_Layout`.
- Layering only through the named `z-*` scale and motion only through `--motion-*` / `--ease-out` tokens. Field errors
  stay inline (plus the error summary), never in toasts. `#splash` and `#loading` are contract ids.
- Verify with `node tests/ui/a11y.mjs` (axe + responsive sweep must exit 0) and `node tests/ui/screenshots.mjs`, and
  look at both themes at 390/768/1024/1440.

## Status
All phases done (migration from v1 completed 2026-10-30): 96 tests green on SQLite + PostgreSQL, baseline contract
matches, Docker stack healthy, local installation upgraded and v1 data imported.
UI redesign + dark mode done 2026-10-31 on branch `ui-redesign`; blue/white theme and phone/iPad layouts on branch
`ui-blue-responsive` (2026-10-31): contrast gate passes in both themes, axe-core 0 violations and responsive sweep 0
issues. ui-ux-pro-max review (2026-10-31): 16 findings, 14 fixed, 2 deferred (`docs/design/SKILL_AUDIT.md`);
screenshots in `docs/design/after-skill/`.
Zones and room types (branch `room-categories`, 2026-10-31): managed lists with room defaults, room form selects;
D-23 in the migration plan.
ID card photos (branch `id-photos`, 2026-11-01): optional photo in the booking form, shrunk in the browser to
WebP ≤ 1600 px (a 6 MB phone photo ≈ 30–300 KB), private storage, purged 90 days after check-out; D-26.

## Next steps
- Optional: `SupabaseFileStorage` (see docs/SUPABASE.md), concurrency tokens if staff report conflicting edits.

## Blockers
- No Python on this machine: the Thai worksheet .docx was not regenerated (assumption A8), and the ui-ux-pro-max
  skill's `search.py` / `--design-system` generator cannot run. Its CSV data was read directly instead
  (`docs/design/SKILL_DESIGN_SYSTEM.md`). Installing Python 3 enables both; nothing was installed.
