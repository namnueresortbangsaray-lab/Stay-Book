# Deployment

## Single host with Docker

```bash
cp .env.example .env          # set DEMO_ADMIN_PASSWORD, APP_PORT, Supabase values if used
make prod-up                  # docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
```

Services:

| Service | Image | Role |
|---|---|---|
| `storage-init` | busybox | One-shot: creates the storage folders and gives them to uid 1654 |
| `web` | `docker/Dockerfile` | Kestrel on 8080, non-root `app` user, ICU + tzdata, healthcheck on `/health` (no curl needed) |
| `nginx` | nginx 1.27 | Public port `${APP_PORT}`; gzip, security headers, 6 MB upload limit, dotfiles denied, long caching for versioned assets, `X-Forwarded-*` |
| `postgres` | postgres 15 | Profile `pgtest` only |

`web` publishes no port in production; Nginx forwards to it and `App__TrustForwardedHeaders=true` lets the app see the
client IP (used by the login throttle and the audit log) and scheme.

## TLS

Terminate TLS in front of Nginx (a reverse proxy, Cloudflare Tunnel or a load balancer) or add a `listen 443 ssl`
server block with your certificates to `docker/nginx/default.conf`. Cookies follow the request scheme, so they are
`Secure` over HTTPS. HSTS is sent by the app in Production on HTTPS requests.

## Volumes

| Volume | Mount | Contents |
|---|---|---|
| `staybook_database` | `/app/storage/database` | `staybook.db` (+ `-wal`, `-shm`) |
| `staybook_uploads` | `/app/storage/uploads` | Attachments (random names, served only through `/files/{id}`) |
| `staybook_backups` | `/app/storage/backups` | `db:backup` output |
| `staybook_logs` | `/app/storage/logs` | Serilog rolling files (14 days) |
| `staybook_keys` | `/app/storage/keys` | Data Protection keys (cookies, antiforgery) |

The keys are stored unencrypted on the volume; restrict host access to it. Back up `database` and `uploads` together.

## Updating

```bash
git pull
make prod-up
```

Migrations run at startup. Watch `docker compose logs web` until the container is healthy.

## Health and logs

- `GET /health` → `ok` (checks the database), used by both container healthchecks.
- Request logs and errors go to stdout and `storage/logs/app-*.log`; bodies, passwords and guest data are not logged.

## Security checklist

- Change `DEMO_ADMIN_PASSWORD` or replace the demo admin.
- Keep `.env` out of version control; it is in `.gitignore` and `.dockerignore`.
- Use HTTPS when the system is reachable outside the resort network.
- Give staff the least role they need: `housekeeping` can only view, check out and attach files.
