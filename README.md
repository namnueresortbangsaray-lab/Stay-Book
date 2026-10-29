# Stay Book · น้ำเหนือรีสอร์ทบางเสร่

Production-ready web edition of the resort’s Thai guest logbook. It covers the room board, bookings, check-in/out, guest history, pricing, inspections, feedback, analytics, CSV export, attachments, staff sessions, roles, and audit history. SQLite is the default; the same application and repository layer supports PostgreSQL/Supabase.

คู่มือสำหรับผู้ใช้งานและผู้ดูแลระบบภาษาไทย: [docs/USAGE_TH.md](docs/USAGE_TH.md)

## Quick start

Requirements: Docker Desktop or Docker Engine with Compose.

```bash
cp .env.example .env
docker compose up -d --build
```

Open <http://localhost:8080>. The seeded development account is:

- Email: `admin@staybook.local`
- Password: `ChangeMe123!`

Change both values in `.env` before first production startup. If a user was already seeded, create a replacement with `php bin/console user:create`, verify it, then disable the demo user in the database.

## Useful commands

```bash
make up                 # build and start
make down               # stop
make logs               # follow logs
make migrate            # apply active-driver migrations
make seed               # idempotent demo seed
make test               # PHPUnit
make lint               # PSR-12 + PHPStan
make backup             # SQLite online backup
make db-transfer        # SQLite -> configured PostgreSQL
```

Direct equivalents are available through `docker compose exec php php bin/console ...`.

## Configuration

All configuration comes from `.env`. Important values are `APP_ENV`, `APP_KEY`, `APP_URL`, `APP_PORT`, `DB_DRIVER`, `SQLITE_PATH`, `DB_SEED`, `SESSION_LIFETIME`, and `UPLOAD_MAX_BYTES`. PostgreSQL/Supabase uses the `SUPABASE_DB_*`, `PGSQL_SSLMODE`, and `PGSQL_EMULATE_PREPARES` values. Timestamps are stored in UTC and presented in `Asia/Bangkok`.

## Data and backups

SQLite, uploads, sessions, backups, and logs use separate named Docker volumes. Create an online SQLite backup with `make backup`; the command uses `VACUUM INTO`, writes a timestamped file to the backups volume, and retains `BACKUP_KEEP` copies. Back up the uploads volume alongside the database. To restore, stop the stack, replace the SQLite file in the database volume and restore the matching uploads snapshot, then start the stack.

## Tests and quality

`vendor/bin/phpunit`, `vendor/bin/phpstan analyse`, `vendor/bin/php-cs-fixer fix --dry-run --diff`, `npm run lint`, and `npm run build` are the local checks. CI runs quality checks against SQLite and PostgreSQL 15, then builds the Docker images. `tests/Smoke/smoke-test.sh` exercises the HTTP workflow against a running stack.

## Production

Use `docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build`. Set a long random `APP_KEY`, secure credentials, `APP_ENV=production`, `DB_SEED=false`, HTTPS at the load balancer/reverse proxy, and reliable volume backups. See [deployment](docs/DEPLOYMENT.md), [architecture](docs/ARCHITECTURE.md), [API](docs/API.md), and [Supabase migration](docs/SUPABASE.md).

## Troubleshooting

- `database is locked`: confirm the database directory—not just the file—is writable by the PHP container. The app enables WAL and a 5-second busy timeout.
- Login fails after changing `.env`: seed values only create a missing account; use `user:create` for a new credential.
- PostgreSQL cannot connect: verify host/port, TLS mode, pooler type, and whether transaction-pooler emulated prepares are enabled.
- Assets are missing: rebuild the images; hashed CSS/JS and `manifest.json` are produced during the Docker build.
