# CLAUDE.md — Stay Book (ResortGuestbook)

Staff web app for น้ำเหนือรีสอร์ท บางเสร่: room board, bookings (stays), check-in/out with inspection, guests, feedback,
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
- Audit every create/update/delete/check_in/check_out/feedback; no personal data in logs.
- `TreatWarningsAsErrors`, code style enforced in build, `dotnet format` clean. One type per file, file-scoped namespaces.
- Every model change needs migrations for **both** providers (a test fails otherwise).
- Never commit secrets, `.env`, SQLite files, uploads.

## Gotchas
- EF SQLite stores `Guid` uppercase by default → `LowercaseGuidConverter`; timestamps are TEXT `yyyy-MM-ddTHH:mm:ss+00:00` (`UtcTimestampConverter`).
- Input coercion is deliberately loose (`Coerce`, `RequestInput`): `"650.50"`, `"on"`, `(int)"3x"`; don't swap in strict model binding.
- Antiforgery tokens are user-bound: re-read the `csrf-token` meta after sign-in. Forms with a literal `action` need `asp-antiforgery="true"`.
- Config is read while building services, so integration tests pass settings via environment variables (one test collection).
- Git on Windows ignores case: `*.sqlite` would match `ResortGuestbook.Migrations.Sqlite/` (re-included in `.gitignore`).
- Git Bash rewrites `/app/...` paths in `docker compose exec` args: prefix with `MSYS_NO_PATHCONV=1`.
- Volumes from v1 belong to uid 82; `storage-init` chowns them for uid 1654 on every start.

## Status
All phases done (migration from v1 completed 2026-10-30): 96 tests green on SQLite + PostgreSQL, baseline contract
matches, Docker stack healthy, local installation upgraded and v1 data imported.

## Next steps
- Optional: `SupabaseFileStorage` (see docs/SUPABASE.md), concurrency tokens if staff report conflicting edits.

## Blockers
None. (The Thai worksheet .docx was not regenerated: no Python on this machine; see assumption A8.)
