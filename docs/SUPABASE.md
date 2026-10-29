# Switching from SQLite to Supabase PostgreSQL

The switch is configuration plus one transfer command; application code does not change.

1. Create a Supabase project and obtain the database connection details from its dashboard.
2. Choose a connection mode:
   - Direct connection or session pooler, normally port 5432: keep `PGSQL_EMULATE_PREPARES=false`.
   - Transaction pooler, normally port 6543: set `PGSQL_EMULATE_PREPARES=true`. PgBouncer transaction mode cannot use server-side prepared statements reliably.
3. Set `SUPABASE_DB_HOST`, `SUPABASE_DB_PORT`, `SUPABASE_DB_NAME`, `SUPABASE_DB_USER`, `SUPABASE_DB_PASSWORD`, and `PGSQL_SSLMODE=require`. Keep these values server-side only.
4. While the running application still uses SQLite, migrate PostgreSQL and perform a dry run:

```bash
docker compose run --rm -e DB_DRIVER=pgsql php php bin/console migrate
docker compose exec php php bin/console db:transfer --from=sqlite --to=pgsql --dry-run
```

5. Enter a short maintenance window, create a final SQLite/upload backup, stop writes, and transfer:

```bash
docker compose exec php php bin/console db:transfer --from=sqlite --to=pgsql
```

The transfer follows foreign-key dependency order, upserts UUID rows in a transaction, normalizes booleans/JSON/timestamps, and compares table counts. It is safe to rerun; add `--truncate` only for an intentionally empty replacement target.
6. Set `DB_DRIVER=pgsql`, rebuild/restart, run the smoke and PHPUnit suites, then verify row counts and representative Thai searches.

## RLS and credentials

PostgreSQL migrations enable Row Level Security on every table and create no public policies, so Supabase’s generated anon REST API cannot read guest data. Connect PHP with a private server-side database role that can run the schema. Never place the anon key, service-role key, or database password in browser JavaScript. This release deliberately retains PHP sessions and local protected uploads; Supabase Auth and Storage could be adopted later only with a separate threat-model and migration.

## Rollback

Stop writes, set `DB_DRIVER=sqlite`, restore the final matching SQLite and uploads snapshots if required, and restart. Preserve the PostgreSQL database for investigation; do not transfer newer PostgreSQL data backward until conflicts are reviewed.
