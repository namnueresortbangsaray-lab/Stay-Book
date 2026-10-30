# Stay Book — project knowledge

Stay Book (สมุดบันทึกผู้เข้าพัก, น้ำเหนือรีสอร์ท บางเสร่) is a staff-only web app for a small resort: room board,
bookings ("stays"), check-in/out with room inspection, guest registry with lifetime stats, feedback, attachments,
analytics, and CSV export. All UI text is Thai.

History: Flutter/Dart offline app (tag `flutter-original`) → PHP 8.3 web app (tag `php-original`) → ASP.NET Core MVC
(branch `dotnet-migration`). This file describes the **PHP version** as the source of truth for the rewrite.
Observed HTTP behaviour is recorded in `tests/baseline/`.

## 1. Architecture and request lifecycle (PHP)

```
Browser → Nginx (security headers, /health, hashed assets, X-Accel internal uploads)
        → PHP-FPM public/index.php → bootstrap/app.php (Config::load, TZ, Container, routes)
        → Application::run: Session::start → Router::match → auth? → CSRF (non GET/HEAD) → handler → Response
        → Controller → Service (validation, policy, business rules, audit) → ResortRepository (PDO) → SQLite/PostgreSQL
```

- `app/Core`: tiny framework — `Router` (regex `{param}`, HEAD→GET, trailing slash trimmed), `Request`
  (JSON body if `Content-Type: application/json` else `$_POST`; `_method` override on POST), `Response`
  (JSON envelope, redirect, raw), `Session` (file sessions, CSRF token in session), `View` (PHP templates +
  layout, `manifest.json` hashed assets), `Config` (env with true/false/null coercion), `Logger` (one line per error).
- Errors in `Application`: no route → 404; unauthenticated → API 401 JSON `กรุณาเข้าสู่ระบบ` / web 302 `/login`;
  bad CSRF → 419 `เซสชันหมดอายุ กรุณาลองใหม่`; uncaught → 500 `ระบบขัดข้อง กรุณาลองใหม่`. API (`/api/*`) errors are
  JSON envelopes; web errors render `errors/error` inside `layouts/base` with the status code.
- JSON envelope: `{"success": status<400, "data": …, "message": "…", "errors": {}}`, `JSON_UNESCAPED_UNICODE|SLASHES`,
  `Content-Type: application/json; charset=utf-8`. `errors` is always an object (field → single message string).
- Timezone: `date_default_timezone_set(APP_TIMEZONE=Asia/Bangkok)`; "today" and default ranges use Bangkok;
  stored timestamps are UTC `gmdate('c')` → `2026-10-30T14:37:41+00:00`.

## 2. Routes

| # | Method | Path | Handler | Auth | Ability | Notes |
|---|---|---|---|---|---|---|
| W1 | GET | `/login` | AuthController::show | no | – | 302 `/` if logged in; renders login in `layouts/auth` |
| W2 | POST | `/login` | AuthController::login | no | – | form `email`,`password`,`_token`; throttled → 429 page; wrong → 200 page with error; ok → 302 `/` |
| W3 | POST | `/logout` | AuthController::logout | yes | – | destroys session, 302 `/login` |
| W4 | GET | `/` | DashboardController::index | yes | – | SPA shell `pages/dashboard/index` with `$user` |
| W5 | GET | `/files/{id}` | UploadController::download | yes | – (any role) | 404 JSON `ไม่พบไฟล์`; `X-Accel-Redirect: /_protected_uploads/<stored>`, `Content-Disposition: attachment; filename="<sanitised>"`, `Content-Length` |
| A1 | GET | `/api/v1/snapshot?start&end` | snapshot | yes | – | message `โหลดข้อมูลแล้ว`; 422 on bad range |
| A2 | GET | `/api/v1/stays?search&status` | stays | yes | – | status must be '', 0,1,2 else 422 `{status: กรุณาเลือกสถานะที่ถูกต้อง}` msg `สถานะไม่ถูกต้อง`; message `โหลดรายการแล้ว` |
| A3 | POST | `/api/v1/rooms` | room | yes | manage_rooms | RoomRequest |
| A4 | PUT | `/api/v1/rooms/{id}` | room | yes | manage_rooms | 404 `ไม่พบห้องพัก` |
| A5 | DELETE | `/api/v1/rooms/{id}` | deleteRoom | yes | manage_rooms | hard delete + cascade of its stays |
| A6 | PUT | `/api/v1/guests/{id}` | guest | yes | edit_guest | 404 `ไม่พบลูกค้า` |
| A7 | POST | `/api/v1/stays` | stay | yes | booking | StayRequest + rules |
| A8 | PUT | `/api/v1/stays/{id}` | stay | yes | booking | unknown id → 422 `{id: ไม่พบ Booking}` |
| A9 | DELETE | `/api/v1/stays/{id}` | deleteStay | yes | booking | 404 `ไม่พบ Booking` |
| A10 | POST | `/api/v1/stays/{id}/check-in` | checkIn | yes | booking | |
| A11 | POST | `/api/v1/stays/{id}/checkout` | checkout | yes | checkout | inspection |
| A12 | POST | `/api/v1/stays/{id}/feedback` | feedback | yes | booking | upsert |
| A13 | POST | `/api/v1/stays/{id}/attachments` | upload | yes | upload | multipart `file` |
| A14 | GET | `/api/v1/reports/bookings.csv?start&end` | export | yes | – | CSV, BOM |
| N1 | GET | `/health` | nginx | no | – | `200 ok\n` text/plain (nginx only) |

Mutations (`mutate()`): policy check first (403 `ไม่มีสิทธิ์ดำเนินการ`), then action. Success → 200 `บันทึกเรียบร้อย`
with the result (or `null` for deletes). `ValidationException` → 422 message `ข้อมูลไม่ถูกต้อง` + errors;
`NotFoundException` → 404 with its message; `PDOException` with SQLSTATE 23000 or "unique" → 409
`ข้อมูลนี้มีอยู่ในระบบแล้ว`; anything else → 500 `ระบบไม่สามารถบันทึกข้อมูลได้` (logged).
Order of checks for an API mutation: route → 401 → 419 (CSRF) → 403 (policy) → 422/404/409/500.

## 3. Roles and permissions (`app/Policies/ResortPolicy.php`, `app/Enums/Role.php`)

| Ability | admin | front_desk | housekeeping |
|---|---|---|---|
| manage_rooms, edit_guest, booking | ✓ | ✓ | ✗ |
| checkout, upload, view | ✓ | ✓ | ✓ |
| manage_users (unused) | ✓ | ✗ | ✗ |

Read endpoints (snapshot, stays, CSV, file download) only require a session. The dashboard receives `data-role`
and JS hides actions, but the server is the authority.

## 4. Business rules

### RoomRequest (`app/Http/Requests/RoomRequest.php`)
- `name`, `zone`, `type` required after trim → `กรุณากรอกชื่อห้อง` / `กรุณากรอกโซน` / `กรุณากรอกประเภทห้อง`.
- `price`: money = `round(max(0,(float)v)*100)`; `<1` → `ราคาต้องมากกว่า 0`; not numeric or ≤0 → `ราคาต้องเป็นตัวเลขที่มากกว่า 0` (overrides).
- `extra_guest_fee` (default 0): must be numeric ≥0 → `ค่าแขกเสริมต้องเป็นตัวเลขที่ไม่ติดลบ`.
- `base_guests` `(int)` ≥1 → `จำนวนคนพื้นฐานต้องอย่างน้อย 1`; `max_guests` ≥ base → `จำนวนคนสูงสุดต้องไม่น้อยกว่าจำนวนคนพื้นฐาน`.
- Output: trimmed strings, `price_satang`, `extra_guest_fee_satang`, ints, `sort_order = max(0,(int))`, `is_pet_friendly = filter_var bool`.
- New rooms get `status=0`.

### StayRequest
- `guest_name` trimmed `mb_strlen ≥ 2` → `ชื่อลูกค้าต้องมีอย่างน้อย 2 ตัวอักษร`.
- `phone` digits-only length ≥ 9 → `เบอร์โทรต้องมีอย่างน้อย 9 หลัก` (phone stored as typed, trimmed).
- `check_in_date` strict `Y-m-d` (round-trip) → `วันที่เช็กอินไม่ถูกต้อง`.
- `check_out_date` strict and string-greater than check-in (when check-in non-empty) → `วันที่เช็กเอาต์ต้องอยู่หลังวันเช็กอิน`.
- `room_id` non-empty → `กรุณาเลือกห้อง`; `guests (int) ≥1` → `จำนวนผู้เข้าพักต้องอย่างน้อย 1`.
- `pet_count = max(0,(int))`; >0 needs `pet_type` → `กรุณาระบุประเภทสัตว์เลี้ยง`; pet_type stored only if pet_count>0.
- `deposit_amount`, `discount_amount` numeric ≥0 → `เงินมัดจำต้องเป็นตัวเลขที่ไม่ติดลบ` / `ส่วนลดต้องเป็นตัวเลขที่ไม่ติดลบ`.
- `status (int)` ∈ {0,1,2} → `สถานะไม่ถูกต้อง`; status 1 requires `id_verified` → `ต้องตรวจสอบบัตรประชาชนก่อนเช็กอิน`.
- `note` trimmed or null. Bools via `filter_var(FILTER_VALIDATE_BOOLEAN)` (`1,true,on,yes` case-insensitive → true).

### ResortService::saveStay
1. Validate. 2. Editing unknown id → 422 `{id: ไม่พบ Booking}`. 3. Creating with status 2 → `{status: ต้องเช็กอินและตรวจห้องก่อนเช็กเอาต์}`.
4. Editing: checked-out → `{status: Booking ที่เช็กเอาต์แล้วไม่สามารถแก้ไขได้}`; checked-in + room change →
`{room_id: ไม่สามารถย้ายห้องระหว่างเข้าพักได้ กรุณาเช็กเอาต์ก่อน}`; status always kept from the stored row.
5. Room must exist (`{room_id: ไม่พบห้องพัก}`), guests ≤ max (`{guests: จำนวนผู้เข้าพักเกินความจุห้อง}`),
pets need pet-friendly room (`{room_id: ห้องนี้ไม่รองรับสัตว์เลี้ยง}`), no overlap (`{room_id: ห้องนี้มี Booking ทับซ้อนในช่วงวันที่เลือก}`).
6. Guest found by normalized phone or created (`customer_type` `ลูกค้าทั่วไป`, not regular). Guest name is **not** updated for existing guests.
7. Price via `PriceCalculator`; stores `total_amount_satang`, `pet_fee_satang = pet_total`.
8. Save in a transaction; if status==1 set room status 1. Response = stay row (joined) + `price_breakdown`. Audit create/update.

Overlap (`hasOverlap`): same room, status IN (0,1), not deleted, `check_in < :to AND check_out > :from`, excluding self. Same-day turnover allowed.

### PriceCalculator
nights = max(1, day diff); extra guests = max(0, guests − base); room = price×nights; extra guest = fee×extra×nights;
extra bed = 20 000 satang flat; pets = 20 000×nights if pet_count>0 (not per pet); gross = sum; net = max(0, gross − discount);
balance = max(0, net − (deposit if paid else 0)). Breakdown keys: `nights, room_total_satang, extra_guest_total_satang,
extra_bed_total_satang, pet_total_satang, gross_total_satang, total_amount_satang, balance_due_satang`.

### Check-in / checkout / feedback / delete
- checkIn: 404 `ไม่พบ Booking`; status≠0 → `{status: Booking นี้ไม่อยู่ในสถานะรอเช็กอิน}`; not id_verified → `{id_verified: ต้องตรวจสอบบัตรประชาชนก่อนเช็กอิน}`;
overlap → `{room_id: ห้องมีรายการเข้าพักอื่นทับซ้อน}`; sets stay 1 and room 1; audit `check_in`.
- checkout: status≠1 → `{status: Booking นี้ยังไม่ได้เช็กอิน}`; five bools `key_returned, room_clean, equipment_complete, no_damage, minibar_checked`;
`inspection_note` required when `no_damage` false → `{inspection_note: กรุณาระบุรายละเอียดความเสียหาย}`; replaces any inspection row;
stay → 2, room → 0; audit `check_out` (before/after stay rows).
- feedback: status≠2 → `{status: บันทึก Feedback ได้หลังเช็กเอาต์เท่านั้น}`; four ratings `(int)` 1–5 checked in order
`cleanliness, service, facility, overall`, first failure only → `{<key>: คะแนนต้องอยู่ระหว่าง 1–5}`; `would_return` default true;
`comment` cleaned; upsert by stay_id; returns the feedback row; audit `feedback` (before null).
- deleteStay: hard-deletes feedbacks, inspections, attachment rows (files stay on disk), then stay; if it was checked in, room → 0. Audit `delete`.
- deleteRoom: hard delete; if stays reference it, deletes their children, the stays, then the room in a transaction. Audit `delete`.
- saveGuest (PUT only): name `mb_strlen≥2` → `กรุณากรอกชื่ออย่างน้อย 2 ตัวอักษร`; phone digits ≥9 → `เบอร์โทรต้องมีอย่างน้อย 9 หลัก`;
`customer_type` default `ลูกค้าทั่วไป` (trimmed, may become empty), `is_regular`, `customer_note`/`preferences` cleaned. Duplicate normalized phone → 409.
Response is the plain guest row (no summary). Audit `update` with before = guest summary incl. `stays`.

### Snapshot and analytics (`ResortService::snapshot`)
Defaults: first and last day of the current Bangkok month. Range validation: strict dates (`{start: วันที่เริ่มต้นไม่ถูกต้อง}`,
`{end: วันที่สิ้นสุดไม่ถูกต้อง}`), `end ≥ start` (`{end: วันที่สิ้นสุดต้องไม่น้อยกว่าวันที่เริ่มต้น}`), span ≤ 366 days
(`{end: ช่วงรายงานต้องไม่เกิน 366 วัน}`). Returns `rooms, stays, guests, attachments, analytics, today`; rooms/stays/guests are
**all** records (not range-filtered). Analytics over stays whose check-in is in range ("started"); `daily` per day: `occupied`
(stays with in ≤ d < out, any status), `revenue_satang` (status≠0 stays checking in that day). Keys: `start, end, day_count,
total_rooms, booking_count, check_in_count (status≥1), check_out_count, guest_count, occupied_room_nights, occupancy_rate
(nights/(rooms×days), float), gross_revenue_satang (billable net+discount), discount_satang, net_revenue_satang,
deposit_received_satang, deposit_pending_satang, pet_bookings, average_feedback (float), statuses{booked,checked_in,checked_out},
deposits{none,paid,unpaid}, daily[]`.

### Read models (JSON field order matters for parity)
- room: all `rooms` columns (`is_pet_friendly` bool), order `zone, sort_order, name`.
- stay: `stays.*` + `room_name, zone, room_type, room_rate_satang, base_guests, max_guests, extra_guest_fee_satang,
is_pet_friendly, customer_type, is_regular, feedback_rating` ordered `check_in_date DESC, created_at DESC`.
- guest list: `guests.*` + columns of the first joined stay (`stay_id, check_in_date, check_out_date, stay_status,
total_amount_satang, discount_amount_satang, room_name`, null when none) + `completed_stays, total_nights,
lifetime_value_satang, total_discount_satang, last_stay_date, last_room_name`, order `updated_at DESC`.
Completed = status 2. Last stay = max check-in.
- attachment list: `id, stay_id, original_name, mime_type, size_bytes, created_at` order `created_at DESC`; upload
response includes `uploaded_by, stored_name`.

### Search (`/api/v1/stays`)
`%trim(search)%` against `s.guest_name, s.phone, r.name, r.zone, s.note` OR-ed; SQLite `LOWER(col) LIKE LOWER(:p)`,
PostgreSQL `ILIKE`. `%`/`_` are not escaped. There is no Thai normalizer; Thai has no case, so plain substring match.

### Uploads
Max `UPLOAD_MAX_BYTES` (5 242 880); finfo MIME must be `image/jpeg→jpg, image/png→png, image/webp→webp, application/pdf→pdf`;
stored as `bin2hex(random_bytes(24)).ext` in `storage/app/uploads`; original name = basename. Row inserted; file removed if insert fails.
No image re-encoding. Download name sanitised with `/[^\pL\pN._ -]+/u → _`.

### CSV export
Header `Booking ID, ชื่อลูกค้า, โทรศัพท์, ห้อง, เช็กอิน, เช็กเอาต์, สถานะ, ยอดสุทธิ (บาท)`; one row per stay (all stays);
values passed through `Csv::safe` (prefix `'` when first char is `= + - @`); amount `number_format(x/100, 2, '.', '')`; UTF-8 BOM;
PHP `fputcsv` quoting (quote when the field contains `,` `"` `\` space tab CR LF; double inner quotes); LF line endings;
filename `stay-book-report-<Bangkok Y-m-d>.csv`.

### Auth
- Login: email lower+trim; user must be `active` and not deleted; `password_verify` (bcrypt `$2y$`, cost 10 via PASSWORD_DEFAULT).
- Session: `user = {id,name,email,role}`, id regenerated, lifetime `SESSION_LIFETIME` (120) minutes, HttpOnly, SameSite=Lax, Secure when APP_ENV=production.
- Throttle: per IP, failures stored with timestamps, 5 within 900 s → 429 page `ลองเข้าสู่ระบบมากเกินไป กรุณารอ 15 นาทีแล้วลองใหม่`. Success clears.
- Wrong credentials → 200 page with `อีเมลหรือรหัสผ่านไม่ถูกต้อง`.
- CSRF: one random token per session; header `X-CSRF-Token` or field `_token`; required for all non-GET/HEAD.
- `config/security.php password_min_length=12` is declared but never enforced.

### Audit (`audit_logs`)
Explicit calls: `create|update|delete` on `room`, `guest` (update only), `stay`; `check_in`, `check_out`, `feedback` on `stay`.
`before_json`/`after_json` = JSON of the API representation (unescaped Unicode), `ip_address` = REMOTE_ADDR, `user_id` actor.

## 5. Database (`database/migrations/{sqlite,pgsql}/0001_initial_schema.sql`)

Tracking table `schema_migrations(version, applied_at)`. All ids are UUID v4 strings (lowercase). SQLite stores
bool as INTEGER 0/1, dates/timestamps as TEXT; PostgreSQL uses uuid/boolean/date/timestamptz/jsonb/bigint.

| Table | Columns (constraints) |
|---|---|
| users | id PK, name, email UNIQUE, password_hash, role CHECK IN (admin, front_desk, housekeeping), active bool default true, created_at, updated_at, deleted_at |
| rooms | id PK, name UNIQUE, zone, type, price_satang ≥0, base_guests ≥1, max_guests ≥ base_guests, extra_guest_fee_satang default 0, sort_order default 0, status default 0 IN (0,1), is_pet_friendly default false, created_at, updated_at, deleted_at |
| guests | id PK, name, phone, normalized_phone UNIQUE, customer_type default 'ลูกค้าทั่วไป', is_regular default false, customer_note, preferences, created_at, updated_at, deleted_at |
| stays | id PK, guest_id FK guests NULL, room_id FK rooms, guest_name, phone NULL, check_in_date, check_out_date, guests ≥1, extra_bed, total_amount_satang ≥0, status IN (0,1,2), note, deposit_amount_satang, deposit_paid, id_verified, pet_type, pet_count, pet_fee_satang, discount_amount_satang, created_at, updated_at, deleted_at, CHECK(check_out_date > check_in_date) |
| checkout_inspections | id PK, stay_id UNIQUE FK stays ON DELETE CASCADE, key_returned, room_clean, equipment_complete, no_damage, minibar_checked, inspection_note, inspected_by FK users NULL, inspected_at |
| feedbacks | id PK, stay_id UNIQUE FK CASCADE, cleanliness/service/facility/overall_rating 1–5, would_return default true, comment, created_at, updated_at |
| attachments | id PK, stay_id FK CASCADE, uploaded_by FK users, original_name, stored_name UNIQUE, mime_type, size_bytes, created_at |
| audit_logs | id PK, user_id FK users NULL, action, entity_type, entity_id, before_json, after_json (jsonb in pg), ip_address, created_at |

Indexes: `idx_rooms_zone_status(zone,status)`, `idx_guests_name(name)`, `idx_guests_phone(normalized_phone)`,
`idx_stays_dates(check_in_date,check_out_date)`, `idx_stays_room_status(room_id,status)`, `idx_stays_guest(guest_id)`,
`idx_audit_entity(entity_type,entity_id,created_at)`. PostgreSQL enables RLS on all tables (incl. schema_migrations), no policies.
`deleted_at` exists everywhere but nothing sets it: deletes are hard deletes; reads filter `deleted_at IS NULL`.

Seed (`app/Database/Seeder.php`): admin `DEMO_ADMIN_EMAIL` (default `admin@staybook.local`) / `DEMO_ADMIN_PASSWORD`
(`ChangeMe123!`), name `ผู้ดูแลระบบ`, role admin, only if missing; five rooms when the table is empty:
`1,2,3` อาคารหลัก เตียงคู่ 500฿ base2 max3 extra100฿ (3 pet-friendly), `4` โซน B เตียงเดี่ยว 450฿ 2/2 pet, `5` โซน B เตียงคู่ 550฿ 2/4 pet.

## 6. CLI (`bin/console`, `app/Console`)

| Command | Behaviour |
|---|---|
| `migrate` | apply pending SQL files of the active driver; prints `Applied: …` or `Database is current.` |
| `seed` | Seeder; prints `Seed complete.` |
| `user:create --name= --email= --password= [--role=front_desk]` | missing → `Missing --x` exit 1; bad role exit 1; email lowercased; prints `User created.` |
| `db:backup` | SQLite `VACUUM INTO storage/backups/stay-book-YYYYmmdd-HHMMSS.sqlite` (UTC), keep newest `BACKUP_KEEP`=7; prints path |
| `db:transfer --from=sqlite --to=pgsql [--truncate] [--dry-run]` | migrates target, copies 8 tables in FK order inside one transaction with upsert on id, converts bools, verifies counts, prints `table src -> dst` |
| `import:flutter` | always fails (exit 2): no Flutter data source exists |
| (none/`help`) | usage text |

## 7. Views, front-end, i18n

- Layouts: `layouts/base.php` (title `Stay Book · น้ำเหนือรีสอร์ท บางเสร่`, theme-color #ffffff, csrf meta, `app.css`, module `app.js`),
`layouts/auth.php` (title `เข้าสู่ระบบ · Stay Book · น้ำเหนือรีสอร์ท`, theme-color #f6fafe, css only). Favicon `/images/logo_square.webp`.
- Pages: `pages/auth/login.php` (form → POST /login with `_token`), `pages/dashboard/index.php` (SPA shell: sidebar nav, logout form,
sections `page-today, page-room-map, page-bookings, page-dashboard, page-rooms, page-guests`, dialogs `command, booking, room, action,
guest, mobile-more, confirm`, `toast-region`; uses `$user.name`, `$user.role`), `errors/error.php` (status + message, link `/`).
- JS (`resources/js`, bundled by esbuild into `public/build/app-<hash>.js`, `scripts/build.mjs` writes `manifest.json`):
  `app.js` (state, `load()` → `/api/v1/snapshot`, renderers per section, dialogs, mutations, hash routing, print, CSV link),
  `core/api.js` (fetch wrapper: `Accept: application/json`, `X-CSRF-Token` from meta, 401 → `/login`, throws with `errors`),
  `core/dom.js` (`$`, `$$`, `escapeHtml`, `toast`, `formObject`), `core/icons.js` (inline SVG icons), `core/ui.js` (buttons, menus, segmented controls).
  No inline scripts or handlers in views.
- CSS: `resources/css/app.css` (Tailwind layers + components `.card .btn-* .field .label` …), `tailwind.config.js`
  (brand/ink/muted/canvas/line/status palette, Noto Sans Thai, shadows), font `public/fonts/NotoSansThai-Variable.ttf`.
- Images: `public/images/{logo,logo_banner,logo_square,logo_white}.webp`, `public/robots.txt`.
- Translations `resources/lang/{th,en}/messages.php`: `app_name`, `location`, `login` — defined but not referenced by any view.

## 8. Infrastructure

- Compose services: `php` (php:8.3-fpm-alpine, entrypoint migrates and optionally seeds, runs as www-data), `nginx`
(port `${APP_PORT:-8080}:80`, builds assets, serves `/build`, `/images`, internal `/_protected_uploads/`), `postgres`
(profile `pgtest`), dev override adds bind mounts, `node` watcher (profile dev), `sqlite-browser` (profile tools, port 8081).
- Volumes: `staybook_database` (`stay_book.sqlite`), `staybook_uploads`, `staybook_backups`, `staybook_sessions`, `staybook_logs`, `staybook_postgres`.
- Nginx security headers: `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`,
`Permissions-Policy: camera=(self), geolocation=(), microphone=()`, CSP `default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline';
script-src 'self'; font-src 'self'; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'`. `client_max_body_size 6m`, gzip.
- Env (`.env.example`): APP_*, DB_DRIVER, SQLITE_PATH, SUPABASE_DB_HOST/PORT/NAME/USER/PASSWORD, PGSQL_SSLMODE, PGSQL_EMULATE_PREPARES
(auto on port 6543), DB_SEED, DEMO_ADMIN_EMAIL/PASSWORD, SESSION_LIFETIME, UPLOAD_MAX_BYTES, BACKUP_KEEP.
- CI: matrix sqlite/pgsql with php-cs-fixer, phpstan, phpunit; docker build.

## 9. Tests (PHP)

Unit: `CsvTest` (formula escaping), `PriceCalculatorTest` (3 pricing cases), `RouterTest` (HEAD uses GET route), `StayRequestTest`
(invalid/zero-night dates, negative money). Feature: `MigrationParityTest` (same tables/columns per driver), `ResortServiceTest`
(no direct checked-out create, overlap vs same-day turnover, full lifecycle, cancel), `SqliteRepositoryTest` (migrate+seed+overlap).
Smoke: `tests/Smoke/smoke-test.sh` (login → create stay → Thai search → upload/download → no direct upload URL → check-in → checkout → feedback → CSV → delete → logout → 401).

## 10. Known quirks / gotchas

- `.gitignore` and `README.md` on `main` contain unresolved merge-conflict markers (PHP vs Flutter).
- Flutter leftovers still in the tree: `android/ ios/ lib/ test/ assets/ pubspec.* analysis_options.yaml .metadata`.
- Upload validation errors surface as HTTP 500 (generic message).
- CSV export ignores the date range for rows.
- Dashboard view prints the avatar initial unescaped (`mb_substr($user['name'])`).
- Guest-list rows leak the first joined stay's columns (`stay_id`, `stay_status`, …); the JS ignores them.
- `deleted_at` is never set; filters exist but deletes are physical.
- A running PHP stack (`stay-book-php-1`, `stay-book-nginx-1`) with real data uses Compose project `stay-book`.
