# Baseline (characterization) of v1

Captured on 2026-10-30 from the v1 release (see `docs/PROJECT_KNOWLEDGE.md`), run in an isolated Compose project
on port 8090 with empty volumes and the seed enabled, plus a `housekeeping@staybook.local` / `Housekeeping123!` user
(role housekeeping). Recording command:

```bash
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
| `set-cookie` | session cookie name/value |
| HTML `bytes` | markup is rebuilt in Razor |

## Observed behaviour worth knowing

- Every mutation is answered with message `บันทึกเรียบร้อย` and HTTP 200 (no 201/204).
- Upload errors (missing file, wrong type, too large) return **500** `ระบบไม่สามารถบันทึกข้อมูลได้`
  in v1 (see deviation D-07 in `docs/DOTNET_MIGRATION_PLAN.md`).
- `PUT /api/v1/stays/{unknown}` returns **422** `{id: ไม่พบ Booking}`, unlike rooms/guests (404).
- The CSV export validates `start`/`end` but lists **all** stays, not only the range.
- `/files/{id}` without a session redirects (302 `/login`) because only `/api/*` paths get JSON 401.
- `/_protected_uploads/...` is not reachable from outside (404).
- Five failed logins from one IP within 15 minutes make the 6th attempt return 429.
