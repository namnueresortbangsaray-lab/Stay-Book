#!/bin/sh
set -eu
for directory in storage/database storage/app/uploads storage/backups storage/sessions storage/logs storage/cache; do
  mkdir -p "/var/www/html/$directory"
  chown -R www-data:www-data "/var/www/html/$directory"
done
if [ "${DB_DRIVER:-sqlite}" = "pgsql" ]; then
  attempts=0
  until su-exec www-data php -r 'try { new PDO(sprintf("pgsql:host=%s;port=%s;dbname=%s;sslmode=%s", getenv("SUPABASE_DB_HOST"), getenv("SUPABASE_DB_PORT") ?: "5432", getenv("SUPABASE_DB_NAME") ?: "postgres", getenv("PGSQL_SSLMODE") ?: "require"), getenv("SUPABASE_DB_USER"), getenv("SUPABASE_DB_PASSWORD")); } catch (Throwable $e) { exit(1); }'; do
    attempts=$((attempts + 1)); [ "$attempts" -ge 30 ] && echo "Database unavailable" >&2 && exit 1
    sleep 2
  done
fi
su-exec www-data php bin/console migrate
if [ "${DB_SEED:-false}" = "true" ]; then su-exec www-data php bin/console seed; fi
exec su-exec www-data "$@"
