# Stay Book · น้ำเหนือรีสอร์ท บางเสร่

Staff web app for the resort's guest logbook: room board, bookings, check-in/out with room inspection, guest history and
lifetime stats, pricing, feedback, attachments, analytics, CSV export, roles and an audit trail. The UI is Thai.

Built with ASP.NET Core MVC (.NET 10), EF Core (SQLite by default, PostgreSQL/Supabase ready), ASP.NET Core Identity,
Razor, Tailwind CSS and vanilla JavaScript, packaged for Docker.

คู่มือผู้ใช้ภาษาไทย: [docs/USAGE_TH.md](docs/USAGE_TH.md)

## Quick start

Requirements: Docker Desktop or Docker Engine with Compose v2.24+.

```bash
cp .env.example .env
docker compose up -d --build
```

Open <http://localhost:8080> and sign in with the seeded demo account:

- Email: `admin@staybook.local`
- Password: `ChangeMe123!`

> **Change the demo password.** Set `DEMO_ADMIN_EMAIL`/`DEMO_ADMIN_PASSWORD` in `.env` before the first start, or create
> a real admin with `make user-create` and deactivate the demo account. The seeder only creates the admin when it is missing.

## Configuration (`.env`)

| Variable | Default | Purpose |
|---|---|---|
| `APP_PORT` | `8080` | Host port |
| `ASPNETCORE_ENVIRONMENT` | `Production` | `Development` enables Swagger UI at `/swagger` and detailed logs |
| `App__Timezone` | `Asia/Bangkok` | Display timezone ("today", default report month); data is stored in UTC |
| `Database__Provider` | `Sqlite` | `Sqlite` or `Postgres` |
| `Database__AutoMigrate` | `true` | Apply EF Core migrations at startup |
| `Database__Seed` | `true` | Create the demo admin and the five rooms when missing |
| `ConnectionStrings__Sqlite` | `Data Source=/app/storage/database/staybook.db` | SQLite file (in the `staybook_database` volume) |
| `SUPABASE_DB_HOST/PORT/NAME/USER/PASSWORD` | empty / 5432 / postgres / postgres / empty | PostgreSQL / Supabase connection |
| `PGSQL_SSLMODE` | `Require` | Npgsql SSL mode |
| `SUPABASE_DB_TRANSACTION_POOLER` | `false` | Disable prepared statements (automatic on port 6543) |
| `DEMO_ADMIN_EMAIL`, `DEMO_ADMIN_PASSWORD` | demo values | Seeded administrator |
| `Storage__Provider` | `Local` | File storage (`storage/uploads`, never public) |
| `UPLOAD_MAX_BYTES` | `5242880` | Attachment limit (JPEG, PNG, WebP, PDF) |
| `SESSION_LIFETIME` | `120` | Sign-in lifetime in minutes (sliding) |
| `BACKUP_KEEP` | `7` | SQLite backups kept by `db:backup` |

## Make commands

| Command | What it does |
|---|---|
| `make up` / `make down` / `make logs` | Start (build), stop, follow logs |
| `make prod-up` | Production stack with Nginx in front |
| `make dev` | `dotnet watch` + Tailwind watcher on <http://localhost:8082> |
| `make migrate` / `make seed` | Apply migrations / seed |
| `make user-create NAME_ARG="ชื่อ" EMAIL=a@b.c PASSWORD=... ROLE=front_desk` | Create a staff account (`admin`, `front_desk`, `housekeeping`) |
| `make backup` | SQLite online backup into the `staybook_backups` volume |
| `make db-transfer` | Copy all data SQLite → PostgreSQL/Supabase |
| `make import-php` | Import an existing v1 installation (see below) |
| `make test` / `make format-check` / `make smoke` | Tests, formatting, end-to-end smoke test |
| `make migrations-add NAME=AddX` | Create a migration for both providers |

Inside the container the CLI is `dotnet ResortGuestbook.Web.dll <command>`:
`migrate`, `seed`, `user:create`, `db:backup`, `db:transfer --from=sqlite --to=postgres [--truncate] [--dry-run]`,
`import:php --sqlite=<file> [--uploads=<dir>] [--truncate] [--dry-run]`.

## Development without Docker

Requirements: .NET 10 SDK, Node 22.

```bash
npm --prefix src/ResortGuestbook.Web ci
npm --prefix src/ResortGuestbook.Web run build      # or run dev for watchers
dotnet run --project src/ResortGuestbook.Web         # http://localhost:8080, Development, seeds automatically
```

The SQLite file and uploads go to `storage/` under the working directory.

### EF Core migrations

One model, one migrations project per provider (`dotnet tool restore` installs `dotnet-ef`):

```bash
dotnet ef migrations add <Name> -p src/ResortGuestbook.Migrations.Sqlite -s src/ResortGuestbook.Migrations.Sqlite
dotnet ef migrations add <Name> -p src/ResortGuestbook.Migrations.Postgres -s src/ResortGuestbook.Migrations.Postgres
```

The app applies pending migrations on startup (`Database__AutoMigrate=true`) or with `make migrate`. A test fails if the
model has changes without a migration for either provider.

## Tests

```bash
dotnet test
```

Runs unit tests, data tests on SQLite **and** PostgreSQL 15 (Testcontainers, needs Docker), `WebApplicationFactory`
integration tests, and a contract test that replays the recorded HTTP behaviour of v1 (`tests/baseline/`, needs Node).
Set `STAYBOOK_TEST_POSTGRES` to an admin connection string to use an existing PostgreSQL instead of a container.

`tests/smoke/smoke-test.sh` (curl + jq) checks a running instance end to end.

## Backup and restore

- `make backup` writes `stay-book-YYYYmmdd-HHMMSS.sqlite` into the `staybook_backups` volume and keeps `BACKUP_KEEP` files.
- Back up the `staybook_uploads` volume together with the database; files and rows belong together.
- Restore: stop the stack, copy a backup over `/app/storage/database/staybook.db` in the `staybook_database` volume
  (delete `staybook.db-wal`/`-shm`), start again.
- `staybook_keys` holds the Data Protection keys; losing it only signs everyone out.

## Upgrading an existing v1 installation

The Compose project (`stay-book`), port and volume names are unchanged, so the old database (`stay_book.sqlite`) and
uploads are already mounted. The new app uses its own file (`staybook.db`) and never writes to the old one.

1. Back up the old database, e.g.
   `docker run --rm -v stay-book_staybook_database:/db:ro -v stay-book_staybook_backups:/b busybox cp /db/stay_book.sqlite /b/`
2. Stop the old containers, regenerate `.env` from `.env.example` (carry over your admin, Supabase and limit values),
   then `docker compose up -d --build`.
3. `make import-php` — copies every row (ids, bcrypt password hashes, timestamps) and checks the uploaded files; it is
   idempotent and `--dry-run` shows the counts first. `--truncate` replaces the freshly seeded demo data.
4. Sign in: existing passwords keep working and are re-hashed to the Identity format on first sign-in.
   Old sessions cannot carry over, so everyone signs in once. The unused `staybook_sessions` volume can be removed.

## User interface

A quiet, warm, data-dense interface ("a calm hospitality ledger") with Light, Dark and System themes, chosen from the
sun/moon menu in the top bar or on the sign-in page. A comfortable/compact density toggle sits next to it, and the
sidebar collapses to icons. Ctrl/⌘K opens search from anywhere.

- Tokens, components and dark mode: [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md). Screenshots in both themes at
  three widths: `docs/design/after/` (before: `docs/design/before/`).
- Fonts (IBM Plex Sans Thai, Noto Serif Thai) and Lucide icons are self-hosted; `npm run build` copies the fonts,
  builds the icon sprite and fails if any colour pair misses WCAG AA in either theme.
- UI checks against a running instance (`npm --prefix tests/ui ci && npx --prefix tests/ui playwright install chromium`):

```bash
BASE_URL=http://localhost:8080 node tests/ui/a11y.mjs                                # axe-core, both themes
BASE_URL=http://localhost:8080 node tests/ui/screenshots.mjs docs/design/after light,dark
```

`tests/ui/seed-demo.mjs` fills an empty development instance with fictional guests for screenshots.

## Production

See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md): `make prod-up` runs Nginx (gzip, security headers, upload limit, asset
caching, forwarded headers) in front of the non-root Kestrel container. For Supabase see [docs/SUPABASE.md](docs/SUPABASE.md).

## Troubleshooting

- **Container not healthy:** `docker compose logs web`. `storage-init` fixes volume ownership before each start.
- **Port in use:** set `APP_PORT` in `.env`.
- **Cannot sign in:** five failed attempts from one address block sign-in for 15 minutes; the same limit locks an account.
- **Upload rejected (422):** only JPEG, PNG, WebP and PDF up to `UPLOAD_MAX_BYTES`, detected from the file content.
- **Styles missing when running locally:** run `npm --prefix src/ResortGuestbook.Web run build`.
- **Supabase connection errors:** see the IPv6 and pooler notes in [docs/SUPABASE.md](docs/SUPABASE.md).

## Documentation

[API](docs/API.md) · [Architecture](docs/ARCHITECTURE.md) · [Deployment](docs/DEPLOYMENT.md) · [Supabase](docs/SUPABASE.md) ·
[Project knowledge](docs/PROJECT_KNOWLEDGE.md) · [Migration plan and deviations](docs/DOTNET_MIGRATION_PLAN.md) ·
[Design system](docs/DESIGN_SYSTEM.md) · [UI audit and assumptions](docs/design/UI_AUDIT.md)
