# Deployment

## SQLite production

1. Copy `.env.example` to `.env`; set `APP_ENV=production`, a long random `APP_KEY`, the public HTTPS `APP_URL`, secure admin credentials, and `DB_SEED=true` only for the first boot.
2. Run `docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build`.
3. Confirm `docker compose ps` reports healthy PHP and Nginx, sign in, change/create production credentials, then set `DB_SEED=false`.
4. Terminate TLS at a trusted reverse proxy and forward only the web port. Do not expose PHP-FPM, volumes, or the PostgreSQL test profile.
5. Schedule `php bin/console db:backup` and an uploads-volume snapshot. Test restores regularly.

The PHP container runs non-root workers. Its entrypoint repairs ownership on runtime volume directories, waits for PostgreSQL when selected, applies migrations, and conditionally seeds. SQLite WAL requires write access to both the database file and its directory.

## PostgreSQL verification

For a local PostgreSQL 15 verification environment:

```bash
docker compose --profile pgtest up -d postgres
docker compose run --rm -e DB_DRIVER=pgsql -e SUPABASE_DB_HOST=postgres -e PGSQL_SSLMODE=disable php php bin/console migrate
```

Use an isolated database for tests. Return `DB_DRIVER=sqlite` after verification.

## Operations

Inspect logs with `docker compose logs -f php nginx`. Deploy immutable rebuilt images when source or dependencies change. The application never relies on a source bind mount in production. Long-lived cache headers apply only to content-hashed assets. Review the audit table for mutations and keep application logs free of guest payloads.
