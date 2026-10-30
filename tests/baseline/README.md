# Baseline (characterization) of the PHP version

Captured on 2026-10-30 from tag `php-original`, run in an isolated Compose project
(`docker compose -p staybook-baseline up -d --build`, `APP_PORT=8090`, empty volumes, `DB_SEED=true`),
with two extra users created through the PHP CLI:

```bash
docker compose -p staybook-baseline exec -T php su-exec www-data php bin/console user:create --name=แม่บ้าน --email=housekeeping@staybook.local --password=Housekeeping123! --role=housekeeping
docker compose -p staybook-baseline exec -T php su-exec www-data php bin/console user:create --name=Front --email=front@staybook.local --password=FrontDesk12345! --role=front_desk
BASE_URL=http://localhost:8090 node tests/baseline/capture.mjs
```

`capture.mjs` drives the full lifecycle (login, rooms, stays, guests, check-in, upload, download, checkout,
feedback, CSV, delete, logout, throttle) and writes one JSON file per case into `cases/`
(`_index.json` lists them in order). Each file holds the request, status, selected response headers,
and the body (JSON verbatim; HTML reduced to title, element ids, form actions and visible text; CSV verbatim).

The same script replays against the new app (`BASELINE_OUT=replay`) and the contract tests compare
the two. Fields that legitimately differ between runs:

| Field | Why it varies |
|---|---|
| every `id`, `*_id`, `uploaded_by`, `entity_id` | random UUID v4 |
| `created_at`, `updated_at`, `inspected_at` | wall clock (UTC, format `YYYY-MM-DDTHH:MM:SS+00:00`) |
| `stored_name` | 48 random hex chars + extension |
| `today`, `analytics.start/end` for the default range, CSV filename date | current Bangkok date |
| `set-cookie` | session cookie name/value (`PHPSESSID` → ASP.NET Core cookie) |
| HTML `bytes` | markup is rebuilt in Razor |

## Observed behaviour worth knowing

- Every mutation is answered with message `บันทึกเรียบร้อย` and HTTP 200 (no 201/204).
- Upload errors (missing file, wrong type, too large) return **500** `ระบบไม่สามารถบันทึกข้อมูลได้`
  because `UploadService` throws `RuntimeException` (see deviation D-07 in `docs/DOTNET_MIGRATION_PLAN.md`).
- `PUT /api/v1/stays/{unknown}` returns **422** `{id: ไม่พบ Booking}`, unlike rooms/guests (404).
- The CSV export validates `start`/`end` but lists **all** stays, not only the range.
- `/files/{id}` without a session redirects (302 `/login`) because only `/api/*` paths get JSON 401.
- `/_protected_uploads/...` is not reachable from outside (404).
- Five failed logins from one IP within 15 minutes make the 6th attempt return 429.
