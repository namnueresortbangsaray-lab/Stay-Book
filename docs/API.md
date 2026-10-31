# JSON API v1

All endpoints require a signed-in session (Identity cookie). State-changing requests also need the antiforgery token in
the `X-CSRF-Token` header (or `_token` form field); the token is in the page's `csrf-token` meta tag and must be re-read
after signing in. In Development the OpenAPI document is at `/openapi/v1.json` and Swagger UI at `/swagger`.

Every JSON response uses the same envelope (keys are snake_case, Thai text is not escaped):

```json
{"success":true,"data":{},"message":"บันทึกเรียบร้อย","errors":{}}
```

`success` is `status < 400`; `errors` maps a field name to one message.

| Status | When | Message |
|---|---|---|
| 200 | success (all writes too) | `บันทึกเรียบร้อย`, `โหลดข้อมูลแล้ว`, `โหลดรายการแล้ว` |
| 401 | not signed in | `กรุณาเข้าสู่ระบบ` |
| 403 | role lacks the ability | `ไม่มีสิทธิ์ดำเนินการ` |
| 404 | unknown id or route | e.g. `ไม่พบ Booking`, `ไม่พบหน้าที่ต้องการ` |
| 409 | duplicate (room name, guest phone) | `ข้อมูลนี้มีอยู่ในระบบแล้ว` |
| 413 | request larger than 6 MB | `ไฟล์มีขนาดไม่ถูกต้องหรือใหญ่เกินกำหนด` |
| 419 | missing/invalid antiforgery token | `เซสชันหมดอายุ กรุณาลองใหม่` |
| 422 | validation | `ข้อมูลไม่ถูกต้อง` + `errors` |
| 429 | rate limit | `คำขอมากเกินไป กรุณาลองใหม่ภายหลัง` |
| 500 | unexpected | `ระบบไม่สามารถบันทึกข้อมูลได้` (writes) / `ระบบขัดข้อง กรุณาลองใหม่` |

Checks run in this order: 401 → 419 → 403 → 422/404/409.

| Method | Path | Ability | Purpose |
|---|---|---|---|
| GET | `/api/v1/snapshot?start=&end=` | any | Rooms, stays, guests (with lifetime stats), attachments, analytics for the range (default: current month, max 366 days), `today` |
| GET | `/api/v1/stays?search=&status=` | any | Case-insensitive search over guest name, phone, room, zone, note; `status` 0/1/2 |
| POST | `/api/v1/rooms` | manage_rooms | Create room |
| PUT / DELETE | `/api/v1/rooms/{id}` | manage_rooms | Update / delete room (deletes its bookings) |
| PUT | `/api/v1/guests/{id}` | edit_guest | Update guest profile |
| POST | `/api/v1/stays` | booking | Create booking; links or creates the guest by phone; returns `price_breakdown` |
| PUT / DELETE | `/api/v1/stays/{id}` | booking | Edit/extend or delete booking |
| POST | `/api/v1/stays/{id}/check-in` | booking | Check in (requires `id_verified`, no overlap) |
| POST | `/api/v1/stays/{id}/checkout` | checkout | Inspection + check out atomically |
| POST | `/api/v1/stays/{id}/attachments` | upload | Multipart `file`: JPEG, PNG, WebP or PDF ≤ 5 MB |
| GET | `/api/v1/reports/bookings.csv?start=&end=` | any | UTF-8 CSV with BOM (all bookings; the range is validated) |
| GET | `/api/v1/room-categories` | any | `{zones, types}` in sort order, each with `room_count`; types carry room defaults (`price_satang`, `base_guests`, `max_guests`, `extra_guest_fee_satang`, `is_pet_friendly`) |
| POST | `/api/v1/room-zones` | manage_rooms | Create zone: `name` (`กรุณากรอกชื่อโซน`), `sort_order` |
| PUT / DELETE | `/api/v1/room-zones/{id}` | manage_rooms | Rename (rooms in the zone follow) / delete (422 `{name: มีห้องพักใช้โซนนี้อยู่ N ห้อง}` while used) |
| POST | `/api/v1/room-types` | manage_rooms | Create type: `name` (`กรุณากรอกชื่อประเภทห้อง`) plus the room price and guest fields and rules |
| PUT / DELETE | `/api/v1/room-types/{id}` | manage_rooms | Update or rename (rooms of the type follow; their prices do not change) / delete (422 while used) |
| GET | `/files/{id}` | any (signed in) | Download an attachment |
| GET | `/api/v1/id-photos` | any | Bookings that have an ID card photo: `stay_id, size_bytes, created_at, delete_after` (`delete_after` = check-out date + retention, once checked out) |
| POST | `/api/v1/stays/{id}/id-photo` | booking | Multipart `file`: JPEG, PNG or WebP ≤ 2 MB (the dashboard shrinks it to WebP ≤ 1600 px first); replaces an existing photo |
| DELETE | `/api/v1/stays/{id}/id-photo` | booking | Remove the photo (404 `ไม่พบรูปบัตร`) |
| GET | `/files/id-photo/{stayId}` | any (signed in) | The photo, inline, `Cache-Control: no-store` |
| GET | `/api/v1/users` | manage_users | Staff accounts: `id, name, email, role, active, locked_until, created_at, updated_at` (never hashes or stamps) |
| POST | `/api/v1/users` | manage_users | Create: `name` (≥ 2), `email`, `role` (`admin`/`front_desk`/`housekeeping`), `password`, `confirm_password` |
| PUT | `/api/v1/users/{id}` | manage_users | Update `name, email, role, active` (accounts are deactivated, never deleted) |
| POST | `/api/v1/users/{id}/password` | manage_users | Set a new password (`password`, `confirm_password`); also lifts a sign-in lockout |
| POST | `/api/v1/account/password` | any (signed in) | Change own password: `current_password`, `password`, `confirm_password` |

ID card photos are deleted automatically `IdPhotos__RetentionDays` (90) days after check-out, and with their booking or room.

Abilities: `admin` all; `front_desk` all except user management; `housekeeping` view, checkout, upload.

## Input

Bodies are JSON objects (or form fields). Values are coerced like v1: numbers may be strings (`"650.50"`), booleans
accept `true`, `1`, `"on"`, `"yes"`. Money inputs are decimal baht (`price`, `extra_guest_fee`, `deposit_amount`,
`discount_amount`); responses expose integer `*_satang`. Dates are `YYYY-MM-DD`. Stay status: `0` booked, `1` checked
in, `2` checked out. Checkout takes `key_returned`, `room_clean`, `equipment_complete`, `no_damage`, `minibar_checked`
and requires `inspection_note` when `no_damage` is false.

Staff do not record guest feedback (deviation D-24): `POST /api/v1/stays/{id}/feedback` was removed and answers 404.
Feedback already stored (for example imported from v1) is still returned as `feedback_rating` on stays and
`average_feedback` in the snapshot analytics.

## Output

Timestamps are UTC `YYYY-MM-DDTHH:MM:SS+00:00`. Field names and order follow the recorded v1 responses in
`tests/baseline/cases/`, which the contract test replays.

## Zones and room types (added after v1)

Rooms still store `zone` and `type` as text, so `/api/v1/rooms`, the snapshot and the recorded v1 contract are
unchanged. The lists only define the choices: saving a room with a name that is not listed adds it; renaming an entry
renames it on its rooms in the same transaction (each room audited); an entry in use cannot be deleted; a duplicate name
is 409. Audit entity types: `room_zone`, `room_type`.

## Staff accounts (added after v1)

Passwords need at least `Auth__PasswordMinLength` characters (default 10) and no composition rules. Admins cannot
change their own role or deactivate themselves (422), and the last active admin cannot be demoted or deactivated (422
`ต้องมีผู้ดูแลระบบที่ใช้งานอยู่อย่างน้อย 1 คน`). A new password, role, email or status gets a new security stamp, so the
user's other sessions end at the next check (every `Auth__SessionCheckSeconds`, default 60); changing your own
password keeps the current session. Duplicate email: 409. Audit entity type `user` (`create`, `update`, `password`),
without hashes.
