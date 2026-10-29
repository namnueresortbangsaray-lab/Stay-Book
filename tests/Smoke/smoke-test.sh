#!/usr/bin/env sh
set -eu
base="${BASE_URL:-http://localhost:8080}"
cookie="$(mktemp)"
trap 'rm -f "$cookie"' EXIT
login="$(curl -fsS -c "$cookie" "$base/login")"
token="$(printf '%s' "$login" | sed -n 's/.*name="csrf-token" content="\([^"]*\)".*/\1/p')"
curl -fsS -b "$cookie" -c "$cookie" -X POST "$base/login" -d "_token=$token" -d "email=${DEMO_ADMIN_EMAIL:-admin@staybook.local}" -d "password=${DEMO_ADMIN_PASSWORD:-ChangeMe123!}" >/dev/null
snapshot="$(curl -fsS -b "$cookie" "$base/api/v1/snapshot")"
room="$(printf '%s' "$snapshot" | jq -r '.data.rooms[0].id')"
payload="$(jq -nc --arg room "$room" '{guest_name:"ทดสอบ ระบบ",phone:"081-234-5678",room_id:$room,check_in_date:"2030-01-10",check_out_date:"2030-01-12",guests:2,extra_bed:false,status:0,deposit_amount:300,deposit_paid:true,id_verified:true,pet_count:0,discount_amount:0,note:"smoke"}')"
created="$(curl -fsS -b "$cookie" -H "X-CSRF-Token: $token" -H 'Content-Type: application/json' -X POST "$base/api/v1/stays" -d "$payload")"
id="$(printf '%s' "$created" | jq -r '.data.id')"
curl -fsS -b "$cookie" "$base/api/v1/stays?search=%E0%B8%97%E0%B8%94%E0%B8%AA%E0%B8%AD%E0%B8%9A&status=0" | jq -e '.data | length == 1' >/dev/null
upload="$(curl -fsS -b "$cookie" -H "X-CSRF-Token: $token" -X POST "$base/api/v1/stays/$id/attachments" -F 'file=@public/images/logo_square.webp;type=image/webp')"
attachment="$(printf '%s' "$upload" | jq -r '.data.id')"
stored="$(printf '%s' "$upload" | jq -r '.data.stored_name')"
curl -fsS -b "$cookie" "$base/files/$attachment" -o /dev/null
direct="$(curl -sS -o /dev/null -w '%{http_code}' "$base/_protected_uploads/$stored")"
[ "$direct" = "404" ]
curl -fsS -b "$cookie" -H "X-CSRF-Token: $token" -H 'Content-Type: application/json' -X POST "$base/api/v1/stays/$id/check-in" -d '{}' | jq -e '.success' >/dev/null
inspection='{"key_returned":true,"room_clean":true,"equipment_complete":true,"no_damage":true,"minibar_checked":true}'
curl -fsS -b "$cookie" -H "X-CSRF-Token: $token" -H 'Content-Type: application/json' -X POST "$base/api/v1/stays/$id/checkout" -d "$inspection" | jq -e '.success' >/dev/null
feedback='{"cleanliness_rating":5,"service_rating":5,"facility_rating":4,"overall_rating":5,"would_return":true,"comment":"ดีมาก"}'
curl -fsS -b "$cookie" -H "X-CSRF-Token: $token" -H 'Content-Type: application/json' -X POST "$base/api/v1/stays/$id/feedback" -d "$feedback" | jq -e '.success' >/dev/null
curl -fsS -b "$cookie" "$base/api/v1/reports/bookings.csv" | grep -q 'ทดสอบ ระบบ'
curl -fsS -b "$cookie" -H "X-CSRF-Token: $token" -X DELETE "$base/api/v1/stays/$id" | jq -e '.success' >/dev/null
curl -fsS -b "$cookie" -H "X-CSRF-Token: $token" -X POST "$base/logout" >/dev/null
code="$(curl -sS -o /dev/null -w '%{http_code}' -b "$cookie" "$base/api/v1/snapshot")"
[ "$code" = "401" ]
echo "Smoke test passed"
