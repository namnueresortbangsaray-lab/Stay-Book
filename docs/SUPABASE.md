# Moving Stay Book to Supabase (PostgreSQL)

Switching is a configuration change plus one data copy. The app uses Supabase only as a PostgreSQL server: no Supabase
Auth, Storage, anon key or service-role key is involved, and the browser never talks to Supabase.

## 1. Create the project

1. Create a Supabase project in a region close to the resort (e.g. Singapore).
2. Database → Settings: note the host, database (`postgres`), user and password.
3. Prefer a dedicated role for the app (it must own the tables it creates):
   ```sql
   create role staybook login password '<strong password>';
   grant create on schema public to staybook;
   ```
   Otherwise use the `postgres` user.

## 2. Pick a connection type

| Connection | Host / port | Notes |
|---|---|---|
| Direct | `db.<ref>.supabase.co:5432` | IPv6-first. Hosts without IPv6 (many Docker setups) cannot reach it. |
| Session pooler | `aws-0-<region>.pooler.supabase.com:5432` | IPv4, behaves like a direct connection. **Recommended.** User is `<user>.<ref>`. |
| Transaction pooler | `aws-0-<region>.pooler.supabase.com:6543` | No prepared statements: the app sets `Max Auto Prepare=0` and `No Reset On Close=true` automatically on port 6543 or when `SUPABASE_DB_TRANSACTION_POOLER=true`. |

SSL is required (`PGSQL_SSLMODE=Require`, the default).

## 3. Configure `.env`

```dotenv
SUPABASE_DB_HOST=aws-0-ap-southeast-1.pooler.supabase.com
SUPABASE_DB_PORT=5432
SUPABASE_DB_NAME=postgres
SUPABASE_DB_USER=staybook.<project-ref>
SUPABASE_DB_PASSWORD=<password>
PGSQL_SSLMODE=Require
```

Keep `Database__Provider=Sqlite` for now.

## 4. Apply migrations and copy the data

```bash
make backup                                   # safety copy of the SQLite database
docker compose exec web dotnet ResortGuestbook.Web.dll db:transfer --from=sqlite --to=postgres --dry-run
docker compose exec web dotnet ResortGuestbook.Web.dll db:transfer --from=sqlite --to=postgres
```

`db:transfer` applies the PostgreSQL migrations (including row level security), then copies all eight tables in
foreign-key order inside one transaction, preserving ids, password hashes and timestamps, and fails if any source row is
missing afterwards. It prints `table  source -> target` per table. Re-running is safe (rows are upserted by id);
`--truncate` empties the target first.

## 5. Verify and switch

1. Compare the printed counts.
2. Set `Database__Provider=Postgres` in `.env` and run `docker compose up -d`.
3. `curl http://localhost:8080/health` returns `ok`; sign in and check the dashboard; optionally run `make smoke`
   against a test copy.

Uploads stay on the `staybook_uploads` volume; only rows move.

## Rollback

Set `Database__Provider=Sqlite` and restart. The SQLite file is untouched by the transfer. To bring changes made on
Supabase back: `db:transfer --from=postgres --to=sqlite --truncate`.

## Row level security

The PostgreSQL migrations run `ALTER TABLE … ENABLE ROW LEVEL SECURITY` on every table, including
`__EFMigrationsHistory`, and create **no policies**. The table owner (the app's role) bypasses RLS; Supabase's `anon`
and `authenticated` roles, used by the auto-generated REST API, can read nothing. Do not add public policies and never
put the service-role key into this app.

## Local test server

`docker compose --profile pgtest up -d postgres` starts PostgreSQL 15 on `127.0.0.1:5432` (user/password `postgres`).
Point `SUPABASE_DB_HOST=postgres`, `PGSQL_SSLMODE=Disable` at it from the `web` container to rehearse the switch.
The test suite runs every data test against PostgreSQL 15 via Testcontainers.

## Future: Supabase Storage

Files go through `IFileStorage` (`Infrastructure/Storage`). To store them in Supabase Storage, add a
`SupabaseFileStorage` implementing `SaveAsync`, `OpenReadAsync`, `DeleteAsync` and `ExistsAsync` against a **private**
bucket with a server-side key, register it when `Storage__Provider=Supabase`, and copy existing files with a one-off
command. `FilesController` keeps authorising every download, so no public bucket URL is ever exposed.
