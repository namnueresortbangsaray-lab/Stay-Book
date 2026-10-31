#!/usr/bin/env sh
# End-to-end smoke test against a running instance. Requires curl and jq.
#   BASE_URL=http://localhost:8080 sh tests/smoke/smoke-test.sh
set -eu
base="${BASE_URL:-http://localhost:8080}"
email="${DEMO_ADMIN_EMAIL:-admin@staybook.local}"
password="${DEMO_ADMIN_PASSWORD:-ChangeMe123!}"
here="$(cd "$(dirname "$0")" && pwd)"
image="$here/../baseline/fixtures/logo_square.webp"
cookie="$(mktemp)"
trap 'rm -f "$cookie"' EXIT

step() { printf '• %s\n' "$1"; }
token_of() { sed -n 's/.*name="csrf-token" content="\([^"]*\)".*/\1/p'; }
status() { curl -sS -o /dev/null -w '%{http_code}' "$@"; }
api() { method="$1"; path="$2"; shift 2; curl -fsS -b "$cookie" -H "X-CSRF-Token: $token" -H 'Accept: application/json' -X "$method" "$base$path" "$@"; }

step "health"
curl -fsS "$base/health" | grep -q '^ok'

step "unauthorized access is rejected"
[ "$(status "$base/api/v1/snapshot")" = "401" ]
[ "$(status "$base/")" = "302" ]

step "login (and POST without CSRF token is rejected)"
token="$(curl -fsS -c "$cookie" "$base/login" | token_of)"
[ "$(status -b "$cookie" -X POST "$base/login" -d "email=$email" -d "password=$password")" = "419" ]
curl -fsS -b "$cookie" -c "$cookie" -X POST "$base/login" --data-urlencode "_token=$token" --data-urlencode "email=$email" --data-urlencode "password=$password" -o /dev/null
token="$(curl -fsS -b "$cookie" -c "$cookie" "$base/" | token_of)"
[ -n "$token" ]

step "create booking (creates the guest)"
room="$(api GET /api/v1/snapshot | jq -r '.data.rooms[0].id')"
payload="$(jq -nc --arg room "$room" '{guest_name:"ทดสอบ Smoke",phone:"081-234-5678",room_id:$room,check_in_date:"2031-01-10",check_out_date:"2031-01-12",guests:2,extra_bed:false,status:0,deposit_amount:300,deposit_paid:true,id_verified:true,pet_count:0,discount_amount:0,note:"Smoke NOTE"}')"
created="$(api POST /api/v1/stays -H 'Content-Type: application/json' -d "$payload")"
id="$(printf '%s' "$created" | jq -r '.data.id')"
guest="$(printf '%s' "$created" | jq -r '.data.guest_id')"
[ "$(printf '%s' "$created" | jq -r '.data.price_breakdown.nights')" = "2" ]

step "edit booking and guest"
api PUT "/api/v1/stays/$id" -H 'Content-Type: application/json' -d "$(printf '%s' "$payload" | jq -c '.check_out_date="2031-01-13"')" | jq -e '.data.check_out_date == "2031-01-13"' >/dev/null
api PUT "/api/v1/guests/$guest" -H 'Content-Type: application/json' -d '{"name":"คุณ Smoke","phone":"081-234-5678","customer_type":"VIP","is_regular":true,"customer_note":"แพ้ถั่ว"}' | jq -e '.data.is_regular == true' >/dev/null

step "search: Thai text and mixed case, status filter"
api GET "/api/v1/stays?search=%E0%B8%97%E0%B8%94%E0%B8%AA%E0%B8%AD%E0%B8%9A&status=0" | jq -e '[.data[] | select(.id == "'"$id"'")] | length == 1' >/dev/null
api GET "/api/v1/stays?search=smoke%20note" | jq -e '[.data[] | select(.id == "'"$id"'")] | length == 1' >/dev/null

step "upload and download through the authenticated route"
upload="$(api POST "/api/v1/stays/$id/attachments" -F "file=@$image;type=image/webp")"
attachment="$(printf '%s' "$upload" | jq -r '.data.id')"
stored="$(printf '%s' "$upload" | jq -r '.data.stored_name')"
curl -fsS -b "$cookie" "$base/files/$attachment" -o "$cookie.download"
cmp -s "$image" "$cookie.download"
rm -f "$cookie.download"

step "no public URL to uploads"
for path in "/uploads/$stored" "/storage/uploads/$stored" "/_protected_uploads/$stored"; do
  [ "$(status "$base$path")" = "404" ]
done
[ "$(status "$base/files/$attachment")" = "302" ]

step "check-in, checkout"
api POST "/api/v1/stays/$id/check-in" -H 'Content-Type: application/json' -d '{}' | jq -e '.data.status == 1' >/dev/null
api POST "/api/v1/stays/$id/checkout" -H 'Content-Type: application/json' -d '{"key_returned":true,"room_clean":true,"equipment_complete":true,"no_damage":true,"minibar_checked":true}' | jq -e '.data.status == 2' >/dev/null

step "report export"
api GET /api/v1/reports/bookings.csv | grep -q 'ทดสอบ Smoke'

step "delete booking"
api DELETE "/api/v1/stays/$id" | jq -e '.success' >/dev/null
[ "$(status -b "$cookie" -H "X-CSRF-Token: $token" -X DELETE "$base/api/v1/stays/$id")" = "404" ]

step "logout"
curl -fsS -b "$cookie" -c "$cookie" -X POST "$base/logout" --data-urlencode "_token=$token" -o /dev/null
[ "$(status -b "$cookie" "$base/api/v1/snapshot")" = "401" ]

echo "Smoke test passed"
