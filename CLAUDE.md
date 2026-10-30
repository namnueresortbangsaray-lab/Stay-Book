# CLAUDE.md — Stay Book (ResortGuestbook)

Staff web app for น้ำเหนือรีสอร์ท บางเสร่: room board, bookings (stays), check-in/out with inspection, guests, feedback,
attachments, analytics, CSV. UI is Thai. Being migrated from PHP 8.3 to ASP.NET Core MVC (.NET 10).

Knowledge: @docs/PROJECT_KNOWLEDGE.md (PHP behaviour, schema, rules) · @docs/DOTNET_MIGRATION_PLAN.md (mapping, parity
checklist, deviations, assumptions) · `tests/baseline/` (recorded PHP HTTP behaviour).

## Target stack
ASP.NET Core MVC .NET 10, C# 13, EF Core 10 (SQLite default, Npgsql for Supabase), Identity cookie auth, Razor, Tailwind CLI +
esbuild, vanilla JS modules, Serilog, xUnit + Testcontainers, Docker (Kestrel; Nginx in prod). Display TZ Asia/Bangkok, store UTC.

## Directory map
| Old (PHP, tag `php-original`) | New |
|---|---|
| `app/Http/Controllers` | `src/ResortGuestbook.Web/Controllers` (+ `Api/V1`) |
| `app/Services`, `Models`, `Http/Requests`, `Policies` | `Services/`, `Authorization/` |
| `app/Repositories`, `app/Database` | `Data/` (DbContext, configurations, providers, seed) |
| `database/migrations/*` | `src/ResortGuestbook.Migrations.{Sqlite,Postgres}` |
| `app/Console` | `Infrastructure/Cli` |
| `resources/views` | `Views/` |
| `resources/js`, `resources/css` | `Scripts/`, `Styles/` → `wwwroot/` |
| `public/images`, `public/fonts` | `wwwroot/images`, `wwwroot/fonts` |
| `tests/` (PHPUnit) | `tests/ResortGuestbook.Tests`, `tests/smoke` |

## Commands (planned; keep in sync with Makefile)
- Run: `cp .env.example .env && docker compose up -d --build` → http://localhost:8080 (admin@staybook.local / ChangeMe123!)
- Build: `dotnet build -c Release` · Format: `dotnet format --verify-no-changes` · Test: `dotnet test`
- Front-end: `npm --prefix src/ResortGuestbook.Web ci && npm --prefix src/ResortGuestbook.Web run build`
- Migrations: `dotnet ef migrations add <Name> -p src/ResortGuestbook.Migrations.Sqlite -s src/ResortGuestbook.Web -- --provider Sqlite`
  and the same with `.Postgres` / `Postgres`.
- CLI: `dotnet ResortGuestbook.Web.dll migrate|seed|user:create|db:backup|db:transfer|import:php`

## Hard rules
- Controllers thin; only `Data/` and `Services/` touch `AppDbContext`; no repository wrapper.
- Nothing outside `Data/` and DI registration branches on the database provider.
- Parameterized queries only; never `Html.Raw` on user data; no inline scripts without nonce; uploads never under `wwwroot`.
- API contract (paths, statuses, Thai messages, snake_case JSON, envelope) must match `tests/baseline/`.
- Audit create/update/delete/check_in/check_out/feedback; no personal data in logs.
- `TreatWarningsAsErrors`, analyzers on, `dotnet format` clean. One type per file, file-scoped namespaces.
- Never commit secrets, `.env`, SQLite files, uploads. Commit at the end of each phase.

## Gotchas
- EF SQLite stores `Guid` uppercase by default → custom lowercase converter (PHP data is lowercase).
- PHP timestamps are TEXT `yyyy-MM-ddTHH:mm:ss+00:00`; keep that format in SQLite for ordering and import.
- PHP input coercion is loose (`"650.50"`, `"on"`, `(int)"3x"`); validators reproduce it — don't swap in strict model binding.
- Upload errors were 500 in PHP (deviation D-07 makes them 422).
- `.gitignore`/`README.md` on main had merge-conflict markers; Flutter leftovers (`android ios lib test assets pubspec*`) are removed in Phase 7.
- A real PHP stack with data runs as Compose project `stay-book` on :8080 — never `down -v` it. Baseline stack is project `staybook-baseline` on :8090.
- Existing volumes belong to uid 82 (Alpine www-data); the .NET image runs as uid 1654.

## Status
- Phase 0 ✅ tag `php-original`, branch `dotnet-migration`.
- Phase 1 ✅ knowledge files + 74 baseline cases.
- Phase 2 ⏳ plan awaiting approval.

## Next steps
Phase 2 approval → Phase 3 scaffold solution + data layer → Phase 4 port → Phase 5 Docker → Phase 6 quality → Phase 7 cleanup → Phase 8 verify.

## Blockers
None.
