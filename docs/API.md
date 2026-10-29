# JSON API v1

All endpoints require an authenticated PHP session. State-changing methods also require `X-CSRF-Token`, available in the page’s `csrf-token` meta element. JSON responses use:

```json
{"success":true,"data":{},"message":"บันทึกเรียบร้อย","errors":{}}
```

Errors use appropriate HTTP status codes: 401 unauthenticated, 403 forbidden, 419 invalid CSRF, 422 validation, 429 throttled login, and 500 unexpected server failure.

| Method | Path | Purpose |
|---|---|---|
| GET | `/api/v1/snapshot?start=&end=` | Rooms, stays, guests, and analytics |
| GET | `/api/v1/stays?search=&status=` | Thai/case-insensitive stay search and status filter |
| POST | `/api/v1/rooms` | Create room |
| PUT/DELETE | `/api/v1/rooms/{id}` | Update/delete room |
| PUT | `/api/v1/guests/{id}` | Update permanent guest profile |
| POST | `/api/v1/stays` | Create booking and link/create guest |
| PUT/DELETE | `/api/v1/stays/{id}` | Edit/extend or delete booking |
| POST | `/api/v1/stays/{id}/check-in` | Check in after ID verification |
| POST | `/api/v1/stays/{id}/checkout` | Store inspection and check out atomically |
| POST | `/api/v1/stays/{id}/feedback` | Create or update one feedback record |
| POST | `/api/v1/stays/{id}/attachments` | Upload JPEG, PNG, WebP, or PDF |
| GET | `/api/v1/reports/bookings.csv` | UTF-8 CSV export |

Booking money inputs are decimal baht; responses expose stored `*_satang` integers. Dates use `YYYY-MM-DD`. Status is `0` booked, `1` checked in, or `2` checked out. Checkout accepts the five booleans `key_returned`, `room_clean`, `equipment_complete`, `no_damage`, and `minibar_checked`; `inspection_note` is mandatory when damage exists.
