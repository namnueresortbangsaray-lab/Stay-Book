// Fills a fresh, seeded instance with fictional bookings so every UI state is visible in screenshots.
// Usage: BASE_URL=http://localhost:8097 node seed-demo.mjs   (admin@staybook.local / ChangeMe123!)
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const base = process.env.BASE_URL ?? 'http://localhost:8097';
const image = readFileSync(fileURLToPath(new URL('../baseline/fixtures/logo_square.webp', import.meta.url)));
const cookies = new Map();
let token = '';

async function send(method, path, body, form) {
  const headers = { Accept: 'application/json', Cookie: [...cookies].map(([k, v]) => `${k}=${v}`).join('; ') };
  if (token && method !== 'GET') headers['X-CSRF-Token'] = token;
  if (body !== undefined && !form) headers['Content-Type'] = 'application/json';
  const res = await fetch(base + path, { method, headers, body: form ?? (body === undefined ? undefined : JSON.stringify(body)), redirect: 'manual' });
  for (const c of res.headers.getSetCookie()) { const [k, v] = c.split(';')[0].split('='); cookies.set(k, v); }
  return res;
}
const json = async (...args) => {
  const res = await send(...args);
  const payload = await res.json();
  if (!payload.success) throw new Error(`${args[0]} ${args[1]}: ${payload.message} ${JSON.stringify(payload.errors)}`);
  return payload.data;
};
const meta = async path => /name="csrf-token" content="([^"]+)"/.exec(await (await send('GET', path)).text())[1];
const day = offset => { const d = new Date(); d.setDate(d.getDate() + offset); return d.toISOString().slice(0, 10); };

token = await meta('/login');
await send('POST', '/login', undefined, new URLSearchParams({ _token: token, email: 'admin@staybook.local', password: process.env.DEMO_ADMIN_PASSWORD ?? 'ChangeMe123!' }));
token = await meta('/');

for (const room of [
  { name: '6', zone: 'โซน B', type: 'เตียงคู่', price: 600, base_guests: 2, max_guests: 4, extra_guest_fee: 150, sort_order: 6, is_pet_friendly: false },
  { name: 'V1', zone: 'วิลล่าริมสระ', type: 'วิลล่า 2 ห้องนอน', price: 1800, base_guests: 4, max_guests: 6, extra_guest_fee: 200, sort_order: 7, is_pet_friendly: true },
  { name: 'V2', zone: 'วิลล่าริมสระ', type: 'วิลล่า 1 ห้องนอน', price: 1200, base_guests: 2, max_guests: 3, extra_guest_fee: 200, sort_order: 8, is_pet_friendly: false },
]) await json('POST', '/api/v1/rooms', room);

const rooms = Object.fromEntries((await json('GET', '/api/v1/snapshot')).rooms.map(r => [r.name, r.id]));
const stay = (room, guest, phone, from, to, extra = {}) => json('POST', '/api/v1/stays', {
  guest_name: guest, phone, room_id: rooms[room], check_in_date: day(from), check_out_date: day(to), guests: 2,
  extra_bed: false, status: 0, deposit_amount: 300, deposit_paid: true, id_verified: true, pet_count: 0, discount_amount: 0, note: '', ...extra,
});

// Completed stays (history, lifetime value)
for (const [room, guest, phone, from, to] of [
  ['1', 'คุณสมศรี วงศ์ใหญ่', '081-555-0101', -40, -38],
  ['V1', 'คุณประเสริฐ ทองดี', '089-222-0303', -30, -27],
  ['1', 'คุณสมศรี วงศ์ใหญ่', '081-555-0101', -20, -18],
  ['2', 'Mr. Daniel Weber', '082-777-0404', -12, -10],
  ['1', 'คุณสมศรี วงศ์ใหญ่', '081-555-0101', -8, -6],
]) {
  const s = await stay(room, guest, phone, from, to, { status: 1 });
  await json('POST', `/api/v1/stays/${s.id}/checkout`, { key_returned: true, room_clean: true, equipment_complete: true, no_damage: true, minibar_checked: true });
}

// In house now (one leaving today), arrivals today, upcoming, unpaid deposit
const inHouse = await stay('3', 'คุณวิภาวรรณ แสงทอง', '086-111-2233', -2, 1, { status: 1, pet_count: 1, pet_type: 'สุนัข', note: 'มีสุนัขพันธุ์เล็ก 1 ตัว ขอชามน้ำเพิ่ม' });
await stay('V1', 'คุณธนากร ศรีสุข', '087-444-5566', -1, 0, { status: 1, guests: 5, extra_bed: true, discount_amount: 200 });
await stay('5', 'คุณกมลชนก อินทร์แก้ว', '084-999-1212', -3, 2, { status: 1, guests: 3, deposit_paid: false });
await stay('1', 'คุณสมศรี วงศ์ใหญ่', '081-555-0101', 0, 2, { note: 'ลูกค้าประจำ ขอห้องเดิมทุกครั้ง' });
await stay('4', 'Ms. Hannah Kim', '095-123-4567', 0, 1, { id_verified: false, deposit_paid: false, deposit_amount: 500 });
await stay('V2', 'คุณอรุณี พงษ์ไพร', '083-321-6540', 3, 5, { deposit_paid: false, note: 'ฉลองครบรอบแต่งงาน' });
await stay('6', 'คุณณัฐพล ใจงาม', '080-246-8100', 6, 8, {});

const form = new FormData();
form.append('file', new Blob([image], { type: 'image/webp' }), 'สลิปมัดจำ.webp');
await json('POST', `/api/v1/stays/${inHouse.id}/attachments`, undefined, form);

const regular = (await json('GET', '/api/v1/snapshot')).guests.find(g => g.phone === '081-555-0101');
await json('PUT', `/api/v1/guests/${regular.id}`, { name: regular.name, phone: regular.phone, customer_type: 'ลูกค้าประจำ', is_regular: true, customer_note: 'ชอบห้องใกล้สวน แพ้ถั่วลิสง', preferences: 'กาแฟดำตอนเช้า หมอนเพิ่ม 1 ใบ' });
console.log('Demo data ready');
