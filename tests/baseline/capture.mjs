// Records the HTTP behaviour of a running Stay Book instance into tests/baseline/cases/.
// Usage: BASE_URL=http://localhost:8090 node tests/baseline/capture.mjs
// Requires the seeded admin plus housekeeping@staybook.local / Housekeeping123! (role housekeeping).
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const base = process.env.BASE_URL ?? 'http://localhost:8090';
const out = resolve(here, process.env.BASELINE_OUT ?? 'cases');
const logo = readFileSync(join(here, 'fixtures', 'logo_square.webp'));
mkdirSync(out, { recursive: true });

const KEPT_HEADERS = ['content-type', 'content-disposition', 'location', 'cache-control', 'x-content-type-options', 'x-frame-options',
  'referrer-policy', 'permissions-policy', 'content-security-policy', 'set-cookie', 'x-accel-redirect', 'content-length'];

class Client {
  cookies = new Map();
  token = '';
  async send(method, path, { json, form, multipart, csrf = true, headers = {} } = {}) {
    const h = new Headers(headers);
    h.set('Accept', h.get('Accept') ?? 'application/json');
    if (this.cookies.size) h.set('Cookie', [...this.cookies].map(([k, v]) => `${k}=${v}`).join('; '));
    if (csrf && this.token && method !== 'GET') h.set('X-CSRF-Token', this.token);
    let body;
    if (json !== undefined) { h.set('Content-Type', 'application/json'); body = JSON.stringify(json); }
    if (form) { body = new URLSearchParams(form); }
    if (multipart) { body = multipart; }
    const res = await fetch(base + path, { method, headers: h, body, redirect: 'manual' });
    for (const c of res.headers.getSetCookie()) {
      const [pair] = c.split(';');
      const [k, v] = pair.split('=');
      if (v === '' || v === 'deleted') this.cookies.delete(k); else this.cookies.set(k, v);
    }
    const buf = Buffer.from(await res.arrayBuffer());
    return { res, buf };
  }
  async refreshToken(path = '/login') {
    const { buf } = await this.send('GET', path, { headers: { Accept: 'text/html' } });
    this.token = /name="csrf-token" content="([^"]+)"/.exec(buf.toString())?.[1] ?? '';
  }
}

function describeBody(res, buf) {
  const type = res.headers.get('content-type') ?? '';
  if (type.includes('application/json')) return { kind: 'json', json: JSON.parse(buf.toString()) };
  if (type.includes('text/html')) {
    const html = buf.toString();
    return {
      kind: 'html',
      title: /<title>([^<]*)<\/title>/.exec(html)?.[1] ?? null,
      ids: [...html.matchAll(/\sid="([^"]+)"/g)].map(m => m[1]),
      forms: [...html.matchAll(/<form[^>]*action="([^"]*)"/g)].map(m => m[1]),
      text: [...html.matchAll(/<(h1|h2|p|button|label)[^>]*>([^<]{2,})</g)].map(m => m[2].trim()).filter(Boolean),
      bytes: buf.length,
    };
  }
  if (type.includes('text/csv')) return { kind: 'csv', text: buf.toString() };
  return { kind: 'binary', bytes: buf.length };
}

const index = [];
async function record(name, client, method, path, opts = {}) {
  const { res, buf } = await client.send(method, path, opts);
  const headers = Object.fromEntries(KEPT_HEADERS.filter(k => res.headers.has(k)).map(k => [k, res.headers.get(k)]));
  const request = { method, path, ...(opts.json !== undefined ? { json: opts.json } : {}), ...(opts.form ? { form: Object.keys(opts.form) } : {}), csrf: opts.csrf !== false && method !== 'GET', multipart: Boolean(opts.multipart) };
  const entry = { name, request, status: res.status, headers, body: describeBody(res, buf) };
  writeFileSync(join(out, `${String(index.length + 1).padStart(2, '0')}-${name}.json`), JSON.stringify(entry, null, 2) + '\n');
  index.push({ name, method, path, status: res.status });
  return entry;
}

const admin = new Client();
const anon = new Client();
const keeper = new Client();

await record('login-page', anon, 'GET', '/login', { headers: { Accept: 'text/html' } });
await record('api-unauthenticated', anon, 'GET', '/api/v1/snapshot');
await record('dashboard-unauthenticated-redirect', anon, 'GET', '/', { headers: { Accept: 'text/html' } });
await record('unknown-route-404-html', anon, 'GET', '/does-not-exist', { headers: { Accept: 'text/html' } });
await record('unknown-api-404', anon, 'GET', '/api/v1/nope');
await admin.refreshToken();
await record('login-missing-csrf-419', admin, 'POST', '/login', { form: { email: 'admin@staybook.local', password: 'x' }, csrf: false, headers: { Accept: 'text/html' } });
await record('login-wrong-password', admin, 'POST', '/login', { form: { _token: admin.token, email: 'admin@staybook.local', password: 'wrong-password' }, headers: { Accept: 'text/html' } });
await record('login-success', admin, 'POST', '/login', { form: { _token: admin.token, email: 'ADMIN@staybook.local ', password: process.env.DEMO_ADMIN_PASSWORD ?? 'ChangeMe123!' }, headers: { Accept: 'text/html' } });
await record('login-page-when-authenticated', admin, 'GET', '/login', { headers: { Accept: 'text/html' } });
await admin.refreshToken('/');
await record('dashboard', admin, 'GET', '/', { headers: { Accept: 'text/html' } });

const snap = await record('snapshot', admin, 'GET', '/api/v1/snapshot?start=2030-01-01&end=2030-01-31');
await record('snapshot-default-range', admin, 'GET', '/api/v1/snapshot');
await record('snapshot-invalid-start', admin, 'GET', '/api/v1/snapshot?start=2030-02-30&end=2030-03-01');
await record('snapshot-end-before-start', admin, 'GET', '/api/v1/snapshot?start=2030-03-01&end=2030-02-01');
await record('snapshot-range-too-long', admin, 'GET', '/api/v1/snapshot?start=2030-01-01&end=2031-02-01');
const roomId = snap.body.json.data.rooms[0].id;
const petRoom = snap.body.json.data.rooms.find(r => r.is_pet_friendly).id;

await record('room-create-missing-csrf-419', admin, 'POST', '/api/v1/rooms', { json: {}, csrf: false });
await record('room-create-invalid', admin, 'POST', '/api/v1/rooms', { json: { name: ' ', price: 0, base_guests: 0, max_guests: 0, extra_guest_fee: -1 } });
const room = await record('room-create', admin, 'POST', '/api/v1/rooms', { json: { name: 'B-101', zone: 'โซน C', type: 'วิลล่า', price: '650.50', base_guests: 2, max_guests: 4, extra_guest_fee: 150, sort_order: 9, is_pet_friendly: true } });
const newRoom = room.body.json.data.id;
await record('room-create-duplicate-409', admin, 'POST', '/api/v1/rooms', { json: { name: 'B-101', zone: 'โซน C', type: 'วิลล่า', price: 650, base_guests: 2, max_guests: 4 } });
await record('room-update', admin, 'PUT', `/api/v1/rooms/${newRoom}`, { json: { name: 'B-101', zone: 'โซน C', type: 'วิลล่าใหญ่', price: 700, base_guests: 2, max_guests: 5, extra_guest_fee: 0, is_pet_friendly: 'false' } });
await record('room-update-not-found', admin, 'PUT', '/api/v1/rooms/00000000-0000-4000-8000-000000000000', { json: { name: 'X', zone: 'Z', type: 'T', price: 1, base_guests: 1, max_guests: 1 } });

const stayInput = { guest_name: 'ทดสอบ Baseline', phone: '081-234-5678', room_id: roomId, check_in_date: '2030-01-10', check_out_date: '2030-01-12',
  guests: 3, extra_bed: true, status: 0, deposit_amount: '300', deposit_paid: true, id_verified: false, pet_count: 0, discount_amount: 50, note: 'Baseline NOTE' };
await record('stay-create-invalid', admin, 'POST', '/api/v1/stays', { json: { guest_name: 'ก', phone: '12', check_in_date: '2030-02-29', check_out_date: '2030-01-01', guests: 0, pet_count: 1, deposit_amount: -1, discount_amount: 'abc', status: 1 } });
await record('stay-create-checked-out-rejected', admin, 'POST', '/api/v1/stays', { json: { ...stayInput, status: 2 } });
await record('stay-create-over-capacity', admin, 'POST', '/api/v1/stays', { json: { ...stayInput, guests: 9 } });
await record('stay-create-pet-not-allowed', admin, 'POST', '/api/v1/stays', { json: { ...stayInput, room_id: snap.body.json.data.rooms.find(r => !r.is_pet_friendly).id, pet_count: 1, pet_type: 'สุนัข' } });
const stay = await record('stay-create', admin, 'POST', '/api/v1/stays', { json: stayInput });
const stayId = stay.body.json.data.id;
const guestId = stay.body.json.data.guest_id;
await record('stay-create-overlap', admin, 'POST', '/api/v1/stays', { json: { ...stayInput, phone: '0899999999', check_in_date: '2030-01-11', check_out_date: '2030-01-13' } });
await record('stay-create-pet', admin, 'POST', '/api/v1/stays', { json: { ...stayInput, room_id: petRoom, guests: 2, pet_count: 2, pet_type: 'แมว', phone: '0811111111', guest_name: 'Pet Owner', id_verified: true, status: 1 } });
await record('stay-update', admin, 'PUT', `/api/v1/stays/${stayId}`, { json: { ...stayInput, check_out_date: '2030-01-13', id_verified: true, status: 2 } });
await record('stay-update-unknown-422', admin, 'PUT', '/api/v1/stays/00000000-0000-4000-8000-000000000000', { json: stayInput });
await record('stays-search-thai-mixed-case', admin, 'GET', `/api/v1/stays?search=${encodeURIComponent('baseline note')}&status=0`);
await record('stays-search-thai', admin, 'GET', `/api/v1/stays?search=${encodeURIComponent('ทดสอบ')}`);
await record('stays-invalid-status', admin, 'GET', '/api/v1/stays?status=7');
await record('guest-update-invalid', admin, 'PUT', `/api/v1/guests/${guestId}`, { json: { name: 'x', phone: '1' } });
await record('guest-update', admin, 'PUT', `/api/v1/guests/${guestId}`, { json: { name: 'คุณ Baseline', phone: '081-234-5678', customer_type: 'VIP', is_regular: true, customer_note: ' แพ้อาหารทะเล ', preferences: '' } });
await record('guest-update-not-found', admin, 'PUT', '/api/v1/guests/00000000-0000-4000-8000-000000000000', { json: { name: 'ทดสอบ', phone: '0812345678' } });
await record('checkout-before-check-in', admin, 'POST', `/api/v1/stays/${stayId}/checkout`, { json: { no_damage: true } });
await record('feedback-before-checkout', admin, 'POST', `/api/v1/stays/${stayId}/feedback`, { json: { cleanliness_rating: 5, service_rating: 5, facility_rating: 5, overall_rating: 5 } });
await record('check-in', admin, 'POST', `/api/v1/stays/${stayId}/check-in`, { json: {} });
await record('check-in-again', admin, 'POST', `/api/v1/stays/${stayId}/check-in`, { json: {} });
await record('stay-move-room-while-checked-in', admin, 'PUT', `/api/v1/stays/${stayId}`, { json: { ...stayInput, room_id: newRoom, id_verified: true } });
await record('check-in-not-found', admin, 'POST', '/api/v1/stays/00000000-0000-4000-8000-000000000000/check-in', { json: {} });

const fd = () => { const f = new FormData(); f.append('file', new Blob([logo], { type: 'image/webp' }), 'logo square.webp'); return f; };
const upload = await record('upload', admin, 'POST', `/api/v1/stays/${stayId}/attachments`, { multipart: fd() });
const badFile = new FormData(); badFile.append('file', new Blob(['plain text'], { type: 'image/png' }), 'fake.png');
await record('upload-disallowed-type', admin, 'POST', `/api/v1/stays/${stayId}/attachments`, { multipart: badFile });
await record('upload-missing-file', admin, 'POST', `/api/v1/stays/${stayId}/attachments`, { multipart: new FormData() });
await record('upload-unknown-stay', admin, 'POST', '/api/v1/stays/00000000-0000-4000-8000-000000000000/attachments', { multipart: fd() });
const attachment = upload.body.json.data;
await record('file-download', admin, 'GET', `/files/${attachment.id}`, { headers: { Accept: '*/*' } });
await record('file-download-unknown', admin, 'GET', '/files/00000000-0000-4000-8000-000000000000', { headers: { Accept: '*/*' } });
await record('file-download-unauthenticated', anon, 'GET', `/files/${attachment.id}`, { headers: { Accept: '*/*' } });
await record('protected-uploads-direct', anon, 'GET', `/_protected_uploads/${attachment.stored_name}`, { headers: { Accept: '*/*' } });

await keeper.refreshToken();
await keeper.send('POST', '/login', { form: { _token: keeper.token, email: 'housekeeping@staybook.local', password: 'Housekeeping123!' } });
await keeper.refreshToken('/');
await record('housekeeping-snapshot', keeper, 'GET', '/api/v1/snapshot?start=2030-01-01&end=2030-01-31');
await record('housekeeping-room-create-403', keeper, 'POST', '/api/v1/rooms', { json: {} });
await record('housekeeping-stay-create-403', keeper, 'POST', '/api/v1/stays', { json: stayInput });
await record('housekeeping-guest-update-403', keeper, 'PUT', `/api/v1/guests/${guestId}`, { json: {} });
await record('housekeeping-checkout-damage-note-required', keeper, 'POST', `/api/v1/stays/${stayId}/checkout`, { json: { key_returned: true, room_clean: true, equipment_complete: true, no_damage: false, minibar_checked: true } });
await record('housekeeping-checkout', keeper, 'POST', `/api/v1/stays/${stayId}/checkout`, { json: { key_returned: true, room_clean: 'on', equipment_complete: true, no_damage: false, minibar_checked: false, inspection_note: 'แก้วแตก 1 ใบ' } });
await record('housekeeping-upload', keeper, 'POST', `/api/v1/stays/${stayId}/attachments`, { multipart: fd() });
await record('housekeeping-feedback-403', keeper, 'POST', `/api/v1/stays/${stayId}/feedback`, { json: { cleanliness_rating: 5, service_rating: 5, facility_rating: 5, overall_rating: 5 } });

await record('stay-update-after-checkout', admin, 'PUT', `/api/v1/stays/${stayId}`, { json: stayInput });
await record('feedback-invalid-rating', admin, 'POST', `/api/v1/stays/${stayId}/feedback`, { json: { cleanliness_rating: 6, service_rating: 5, facility_rating: 5, overall_rating: 5 } });
await record('feedback', admin, 'POST', `/api/v1/stays/${stayId}/feedback`, { json: { cleanliness_rating: 5, service_rating: '4', facility_rating: 3, overall_rating: 5, comment: 'ดีมาก' } });
await record('feedback-update', admin, 'POST', `/api/v1/stays/${stayId}/feedback`, { json: { cleanliness_rating: 4, service_rating: 4, facility_rating: 4, overall_rating: 4, would_return: false } });
await record('snapshot-after-lifecycle', admin, 'GET', '/api/v1/snapshot?start=2030-01-01&end=2030-01-31');
await record('csv-export', admin, 'GET', '/api/v1/reports/bookings.csv?start=2030-01-01&end=2030-01-31', { headers: { Accept: 'text/csv' } });
await record('csv-export-invalid-range', admin, 'GET', '/api/v1/reports/bookings.csv?start=bad&end=2030-01-31');
await record('housekeeping-csv-export', keeper, 'GET', '/api/v1/reports/bookings.csv?start=2030-01-01&end=2030-01-31', { headers: { Accept: 'text/csv' } });

await record('stay-delete', admin, 'DELETE', `/api/v1/stays/${stayId}`);
await record('stay-delete-again-404', admin, 'DELETE', `/api/v1/stays/${stayId}`);
await record('room-delete', admin, 'DELETE', `/api/v1/rooms/${newRoom}`);
await record('room-delete-not-found', admin, 'DELETE', `/api/v1/rooms/${newRoom}`);
await record('method-override-form', admin, 'POST', `/api/v1/rooms/${newRoom}`, { form: { _method: 'DELETE', _token: admin.token } });
await record('logout', admin, 'POST', '/logout', { form: { _token: admin.token }, headers: { Accept: 'text/html' } });
await record('api-after-logout-401', admin, 'GET', '/api/v1/snapshot');

const thrower = new Client();
await thrower.refreshToken();
for (let i = 0; i < 5; i++) await thrower.send('POST', '/login', { form: { _token: thrower.token, email: 'nobody@staybook.local', password: 'bad' } });
await record('login-throttled-429', thrower, 'POST', '/login', { form: { _token: thrower.token, email: 'admin@staybook.local', password: 'bad' }, headers: { Accept: 'text/html' } });

writeFileSync(join(out, '_index.json'), JSON.stringify(index, null, 2) + '\n');
console.log(`Recorded ${index.length} cases into ${out}`);
