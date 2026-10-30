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
| POST | `/api/v1/stays/{id}/feedback` | booking | Create or update the feedback (after checkout) |
| POST | `/api/v1/stays/{id}/attachments` | upload | Multipart `file`: JPEG, PNG, WebP or PDF ≤ 5 MB |
| GET | `/api/v1/reports/bookings.csv?start=&end=` | any | UTF-8 CSV with BOM (all bookings; the range is validated) |
| GET | `/files/{id}` | any (signed in) | Download an attachment |

Abilities: `admin` all; `front_desk` all except user management; `housekeeping` view, checkout, upload.

## Input

Bodies are JSON objects (or form fields). Values are coerced like v1: numbers may be strings (`"650.50"`), booleans
accept `true`, `1`, `"on"`, `"yes"`. Money inputs are decimal baht (`price`, `extra_guest_fee`, `deposit_amount`,
`discount_amount`); responses expose integer `*_satang`. Dates are `YYYY-MM-DD`. Stay status: `0` booked, `1` checked
in, `2` checked out. Checkout takes `key_returned`, `room_clean`, `equipment_complete`, `no_damage`, `minibar_checked`
and requires `inspection_note` when `no_damage` is false. Feedback takes four ratings 1–5, `would_return`, `comment`.

## Output

Timestamps are UTC `YYYY-MM-DDTHH:MM:SS+00:00`. Field names and order follow the recorded v1 responses in
`tests/baseline/cases/`, which the contract test replays.
