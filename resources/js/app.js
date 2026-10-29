import { api } from './core/api.js';
import { $, $$, escapeHtml as h, formObject, toast } from './core/dom.js';
import { icon } from './core/icons.js';

if ($('#app')) {
  const role = $('#app').dataset.role;
  const canBook = role === 'admin' || role === 'front_desk';
  const canManageRooms = canBook;
  const canCheckout = canBook || role === 'housekeeping';
  const state = {
    data: null,
    page: 'today',
    bookingView: 'list',
    calendar: new Date(),
    selectedDay: null,
  };

  const titles = {
    today: 'งานวันนี้',
    'room-map': 'ผังห้อง',
    bookings: 'ตารางเข้าพัก',
    dashboard: 'ภาพรวม',
    rooms: 'ห้องพัก',
    guests: 'ลูกค้า',
  };

  const statusText = ['รอเช็กอิน', 'กำลังเข้าพัก', 'เช็กเอาต์แล้ว'];
  const statusIcons = ['clock', 'bed', 'check'];
  const statusBadgeClass = ['badge-booked', 'badge-occupied', 'badge-completed'];

  const money = satang => new Intl.NumberFormat('th-TH', {
    style: 'currency',
    currency: 'THB',
    minimumFractionDigits: Number(satang) % 100 ? 2 : 0,
  }).format(Number(satang || 0) / 100);

  const thaiDate = iso => iso
    ? new Intl.DateTimeFormat('th-TH', { day: 'numeric', month: 'short', year: 'numeric' }).format(new Date(`${iso}T00:00:00`))
    : '—';

  const iso = d => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  const bool = v => v === true || v === 1 || v === '1';

  async function load(show = true) {
    if (show) $('#loading').hidden = false;
    try {
      const start = $('#range-start')?.value || '';
      const end = $('#range-end')?.value || '';
      state.data = await api(`/api/v1/snapshot${start && end ? `?start=${start}&end=${end}` : ''}`);
      render();
      syncExportLink();
      $('#splash')?.remove();
    } finally {
      $('#loading').hidden = true;
    }
  }

  function render() {
    renderToday();
    renderRoomMap();
    renderBookings();
    renderAnalytics();
    renderRooms();
    renderGuests();
  }

  function activeStays() {
    return state.data.stays.filter(s => Number(s.status) === 1);
  }

  function renderToday() {
    const today = state.data.today;
    const arrivals = state.data.stays.filter(s => Number(s.status) === 0 && s.check_in_date === today);
    const departures = state.data.stays.filter(s => Number(s.status) === 1 && s.check_out_date === today);
    const inHouse = activeStays();
    const unpaid = state.data.stays.filter(s => Number(s.status) < 2 && !s.deposit_paid && Number(s.deposit_amount_satang) > 0);
    const task = (s, action, label, tone = 'primary') => `
      <div class="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-line bg-white p-3.5">
        <div class="min-w-0">
          <p class="truncate text-sm font-bold text-ink">ห้อง ${h(s.room_name)} · ${h(s.guest_name)}</p>
          <p class="mt-0.5 text-xs text-muted">${h(s.phone || 'ไม่มีเบอร์โทร')} · ${s.guests} ท่าน</p>
        </div>
        ${action ? `<button class="${tone === 'primary' ? 'btn-primary' : 'btn-secondary'} btn-sm" data-action="${action}" data-id="${s.id}">${label}</button>` : ''}
      </div>`;

    $('#today-desk').innerHTML = `
      <div class="mb-6 flex flex-wrap items-end justify-between gap-3">
        <div>
          <p class="text-xs font-bold uppercase tracking-[0.18em] text-brand-700">Operations desk</p>
          <h2 class="mt-1 text-2xl font-bold tracking-tight text-ink">สวัสดีตอนเช้า · ${thaiDate(today)}</h2>
          <p class="mt-1 text-sm text-muted">งานที่ต้องดูแลวันนี้ถูกรวมไว้ในที่เดียว</p>
        </div>
        <button class="btn-secondary" data-action="command">${icon('search', 'w-4 h-4')}<span>ค้นหาทุกอย่าง</span></button>
      </div>
      <div class="mb-6 grid grid-cols-2 gap-3 xl:grid-cols-4">
        ${[
          ['เช็กอินวันนี้', arrivals.length, 'clock', 'text-amber-700 bg-amber-50'],
          ['เช็กเอาต์วันนี้', departures.length, 'signout', 'text-brand-700 bg-brand-50'],
          ['กำลังเข้าพัก', inHouse.length, 'bed', 'text-occupied-ink bg-occupied-bg'],
          ['มัดจำรอติดตาม', unpaid.length, 'money', 'text-red-700 bg-red-50'],
        ].map(([label, value, name, tone]) => `<div class="card flex items-center justify-between p-4"><div><p class="text-xs font-semibold text-muted">${label}</p><p class="mt-1 text-3xl font-bold text-ink">${value}</p></div><div class="flex h-10 w-10 items-center justify-center rounded-xl ${tone}">${icon(name, 'w-5 h-5')}</div></div>`).join('')}
      </div>
      <div class="grid gap-5 xl:grid-cols-2">
        <section class="card p-4 md:p-5">
          <div class="mb-3 flex items-center justify-between"><h3 class="font-bold text-ink">ผู้เข้าพักที่จะมาถึง</h3><span class="badge-booked">${arrivals.length} รายการ</span></div>
          <div class="space-y-2">${arrivals.map(s => task(s, canBook ? 'check-in' : '', 'เช็กอิน')).join('') || '<p class="rounded-xl bg-canvas p-5 text-center text-sm text-muted">ไม่มีรายการเช็กอินวันนี้</p>'}</div>
        </section>
        <section class="card p-4 md:p-5">
          <div class="mb-3 flex items-center justify-between"><h3 class="font-bold text-ink">ห้องที่ต้องเช็กเอาต์</h3><span class="badge-occupied">${departures.length} รายการ</span></div>
          <div class="space-y-2">${departures.map(s => task(s, canCheckout ? 'checkout' : '', 'ตรวจห้อง')).join('') || '<p class="rounded-xl bg-canvas p-5 text-center text-sm text-muted">ไม่มีรายการเช็กเอาต์วันนี้</p>'}</div>
        </section>
      </div>
      ${unpaid.length ? `<section class="card mt-5 p-4 md:p-5"><div class="mb-3 flex items-center justify-between"><h3 class="font-bold text-ink">รายการมัดจำที่ต้องติดตาม</h3><button class="text-xs font-semibold text-brand-700" data-page="bookings">ดูรายการทั้งหมด</button></div><div class="grid gap-2 md:grid-cols-2">${unpaid.slice(0, 4).map(s => task(s, '', '')).join('')}</div></section>` : ''}
    `;
  }

  // ================= 1. ROOM MAP =================
  function renderRoomMap() {
    const occupied = activeStays();
    const vacant = state.data.rooms.length - occupied.length;

    // KPI Summary Header
    $('#room-summary').innerHTML = `
      <div class="mb-7 grid grid-cols-2 gap-3 sm:grid-cols-3 sm:gap-4">
        <div class="card flex items-center justify-between p-5">
          <div>
            <p class="text-xs font-semibold uppercase tracking-wider text-muted">ห้องทั้งหมด</p>
            <p class="mt-1 text-3xl font-bold tracking-tight text-ink">${state.data.rooms.length}</p>
          </div>
          <div class="flex h-11 w-11 items-center justify-center rounded-2xl bg-canvas text-muted">
            ${icon('rooms', 'w-5 h-5')}
          </div>
        </div>

        <div class="card flex items-center justify-between border-brand-200/80 bg-brand-50/60 p-5">
          <div>
            <p class="text-xs font-semibold uppercase tracking-wider text-brand-700">ห้องว่าง พร้อมเข้าพัก</p>
            <p class="mt-1 text-3xl font-bold tracking-tight text-brand-700">${vacant}</p>
          </div>
          <div class="flex h-11 w-11 items-center justify-center rounded-2xl bg-white text-brand-500 shadow-subtle">
            ${icon('check', 'w-5 h-5')}
          </div>
        </div>

        <div class="card col-span-2 flex items-center justify-between border-occupied-border/80 bg-occupied-bg/70 p-5 sm:col-span-1">
          <div>
            <p class="text-xs font-semibold uppercase tracking-wider text-occupied-ink">ห้องไม่ว่าง (มีแขกพัก)</p>
            <p class="mt-1 text-3xl font-bold tracking-tight text-occupied-ink">${occupied.length}</p>
          </div>
          <div class="flex h-11 w-11 items-center justify-center rounded-2xl bg-white text-occupied shadow-subtle">
            ${icon('bed', 'w-5 h-5')}
          </div>
        </div>
      </div>
    `;

    // Grouping by Zone
    const zones = Object.groupBy
      ? Object.groupBy(state.data.rooms, r => r.zone)
      : state.data.rooms.reduce((a, r) => ((a[r.zone] ??= []).push(r), a), {});

    const zoneEntries = Object.entries(zones);

    if (zoneEntries.length === 0) {
      $('#room-map').innerHTML = `
        <div class="card text-center py-12">
          <div class="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-2xl bg-canvas text-muted">
            ${icon('rooms', 'w-6 h-6')}
          </div>
          <p class="text-base font-semibold text-ink">ยังไม่มีข้อมูลห้องพัก</p>
          <p class="text-xs text-muted mt-1">เริ่มต้นโดยการเพิ่มห้องพักในแท็บ 'ห้องพัก'</p>
          <button class="btn-primary mt-4" data-action="new-room">
            ${icon('plus', 'w-4 h-4')}
            <span>เพิ่มห้องพักแรก</span>
          </button>
        </div>
      `;
      return;
    }

    $('#room-map').innerHTML = zoneEntries.map(([zone, rooms]) => `
      <section class="mb-8">
        <div class="mb-3.5 flex items-center justify-between">
          <div class="flex items-center gap-2">
            <h2 class="text-base font-bold text-ink">${h(zone)}</h2>
            <span class="rounded-full bg-line/60 px-2.5 py-0.5 text-[11px] font-semibold text-muted">${rooms.length} ห้อง</span>
          </div>
        </div>

        <div class="grid grid-cols-1 gap-3.5 sm:grid-cols-2 md:grid-cols-3 xl:grid-cols-5">
          ${rooms.map(room => {
            const stay = occupied.find(s => s.room_id === room.id);
            const isVacant = !stay;

            return `
              <button
                class="card-interactive min-h-[170px] flex flex-col justify-between text-left p-4 ${
                  isVacant
                    ? 'border-line hover:border-brand-300 bg-white'
                    : 'border-occupied-border/70 bg-occupied-bg/40 hover:border-occupied'
                }"
                data-action="${isVacant ? 'new-booking' : 'stay-details'}"
                data-id="${stay?.id || room.id}"
              >
                <!-- Top Header: Room number & status badge -->
                <div>
                  <div class="flex items-start justify-between gap-2">
                    <strong class="text-lg font-bold text-ink">ห้อง ${h(room.name)}</strong>
                    <span class="${isVacant ? 'badge-vacant' : 'badge-occupied'} !py-0.5 !px-2 text-[11px]">
                      ${isVacant ? icon('check', 'w-3 h-3') : icon('bed', 'w-3 h-3')}
                      <span>${isVacant ? 'ว่าง' : 'มีแขก'}</span>
                    </span>
                  </div>
                  <p class="mt-0.5 text-xs text-muted">${h(room.type)}</p>

                  ${room.is_pet_friendly ? `
                    <div class="mt-2 inline-flex items-center gap-1 rounded-md bg-brand-50 px-1.5 py-0.5 text-[10px] font-medium text-brand-700">
                      ${icon('paw', 'w-3 h-3')}
                      <span>Pet Friendly</span>
                    </div>
                  ` : ''}
                </div>

                <!-- Bottom Details: Price or Guest Information -->
                <div class="mt-4 pt-3 border-t border-line/60">
                  ${isVacant ? `
                    <div class="flex items-baseline justify-between">
                      <span class="text-xs text-muted">ราคาปกติ</span>
                      <strong class="text-sm font-bold text-brand-700">${money(room.price_satang)}</strong>
                    </div>
                    <p class="mt-0.5 text-[11px] text-muted text-right">ต่อคืน</p>
                  ` : `
                    <div class="min-w-0">
                      <p class="truncate text-sm font-bold text-occupied-ink">${h(stay.guest_name)}</p>
                      <p class="mt-0.5 flex items-center gap-1 text-[11px] text-occupied-muted">
                        ${icon('clock', 'w-3 h-3 shrink-0')}
                        <span>ออก ${thaiDate(stay.check_out_date)}</span>
                      </p>
                    </div>
                  `}
                </div>
              </button>
            `;
          }).join('')}
        </div>
      </section>
    `).join('');
  }

  // ================= 2. BOOKINGS LIST =================
  function filteredStays() {
    const q = ($('#stay-search')?.value || '').trim().toLocaleLowerCase('th');
    const status = $('#stay-status')?.value ?? '';
    return state.data.stays.filter(s =>
      (status === '' || String(s.status) === status) &&
      (!q || [s.guest_name, s.phone, s.room_name, s.zone, s.note].some(v =>
        String(v || '').toLocaleLowerCase('th').includes(q)
      ))
    );
  }

  function stayCard(s) {
    const statusIdx = Number(s.status);
    const totalSatang = Number(s.total_amount_satang || 0);
    const depositSatang = s.deposit_paid ? Number(s.deposit_amount_satang || 0) : 0;
    const balanceSatang = Math.max(0, totalSatang - depositSatang);
    const attachments = (state.data.attachments || []).filter(file => file.stay_id === s.id);

    return `
      <article class="card p-5 border-line hover:border-brand-200">
        <!-- Top Row: Guest & Room + Status Badge -->
        <div class="flex flex-wrap items-start justify-between gap-3">
          <div>
            <div class="flex flex-wrap items-center gap-2">
              <h3 class="text-base font-bold text-ink">${h(s.guest_name)}</h3>
              <span class="rounded-md border border-line bg-canvas px-2 py-0.5 text-xs font-semibold text-brand-700">
                ห้อง ${h(s.room_name)} (${h(s.zone)})
              </span>
              ${s.phone ? `
                <span class="flex items-center gap-1 text-xs text-muted">
                  ${icon('phone', 'w-3 h-3')}
                  <span>${h(s.phone)}</span>
                </span>
              ` : ''}
            </div>
            <p class="mt-1 flex items-center gap-2 text-xs text-muted">
              <span class="flex items-center gap-1">
                ${icon('calendar', 'w-3.5 h-3.5')}
                <span>${thaiDate(s.check_in_date)} – ${thaiDate(s.check_out_date)}</span>
              </span>
              <span>·</span>
              <span class="flex items-center gap-1">
                ${icon('user', 'w-3.5 h-3.5')}
                <span>${s.guests} ท่าน</span>
              </span>
            </p>
          </div>

          <span class="${statusBadgeClass[statusIdx]}">
            ${icon(statusIcons[statusIdx], 'w-3 h-3')}
            <span>${statusText[statusIdx]}</span>
          </span>
        </div>

        <!-- Financial Summary Bar -->
        <div class="mt-4 grid grid-cols-2 gap-3 rounded-xl border border-line bg-canvas/60 p-3 text-xs sm:grid-cols-3">
          <div class="col-span-2 sm:col-span-1">
            <span class="text-muted block text-[11px]">ยอดสุทธิ</span>
            <strong class="text-sm font-bold text-ink">${money(totalSatang)}</strong>
          </div>
          <div>
            <span class="text-muted block text-[11px]">มัดจำ</span>
            <div class="flex items-center gap-1">
              <strong class="text-sm font-semibold text-ink">${money(s.deposit_amount_satang)}</strong>
              <span class="text-[10px] font-medium ${s.deposit_paid ? 'text-emerald-600' : 'text-amber-600'}">
                (${s.deposit_paid ? 'ชำระแล้ว' : 'รอชำระ'})
              </span>
            </div>
          </div>
          <div>
            <span class="text-muted block text-[11px]">ยอดคงเหลือ</span>
            <strong class="text-sm font-bold ${balanceSatang > 0 ? 'text-brand-700' : 'text-muted'}">
              ${money(balanceSatang)}
            </strong>
          </div>
        </div>

        ${s.note ? `
          <div class="mt-3 flex items-start gap-2 rounded-xl bg-brand-50/50 p-2.5 text-xs text-muted border border-brand-100">
            <span class="shrink-0 text-brand-500 mt-0.5">${icon('info', 'w-3.5 h-3.5')}</span>
            <span>หมายเหตุ: ${h(s.note)}</span>
          </div>
        ` : ''}

        ${attachments.length ? `
          <div class="mt-3 flex flex-wrap items-center gap-2 text-xs">
            <span class="font-semibold text-muted">เอกสาร:</span>
            ${attachments.map(file => `<a class="rounded-lg border border-line bg-white px-2.5 py-1 font-medium text-brand-700 hover:border-brand-300" href="/files/${file.id}" target="_blank" rel="noopener">${h(file.original_name)}</a>`).join('')}
          </div>
        ` : ''}

        <!-- Card Action Buttons -->
        <div class="no-print mt-4 flex flex-wrap items-center gap-2 pt-3 border-t border-line/60">
          ${statusIdx === 0 && canBook ? `
            <button class="btn-primary btn-sm" data-action="check-in" data-id="${s.id}">
              ${icon('check', 'w-3.5 h-3.5')}
              <span>เช็กอิน</span>
            </button>
            <button class="btn-secondary btn-sm" data-action="edit-booking" data-id="${s.id}">
              ${icon('edit', 'w-3.5 h-3.5')}
              <span>แก้ไข</span>
            </button>
          ` : ''}

          ${statusIdx === 1 && canCheckout ? `
            <button class="btn-primary btn-sm" data-action="checkout" data-id="${s.id}">
              ${icon('signout', 'w-3.5 h-3.5')}
              <span>เช็กเอาต์</span>
            </button>
            ${canBook ? `<button class="btn-secondary btn-sm" data-action="extend" data-id="${s.id}">
              ${icon('clock', 'w-3.5 h-3.5')}
              <span>ต่อเวลา</span>
            </button>` : ''}
          ` : ''}

          ${statusIdx === 2 && canBook ? `
            <button class="btn-secondary btn-sm" data-action="feedback" data-id="${s.id}">
              ${icon('star', 'w-3.5 h-3.5')}
              <span>แบบประเมิน</span>
            </button>
          ` : ''}

          <button class="btn-secondary btn-sm" data-action="upload" data-id="${s.id}">
            ${icon('upload', 'w-3.5 h-3.5')}
            <span>แนบไฟล์</span>
          </button>
          ${canBook ? `<button class="btn-danger btn-sm ml-auto" data-action="delete-booking" data-id="${s.id}">
            ${icon('trash', 'w-3.5 h-3.5')}
            <span>ลบ</span>
          </button>` : ''}
        </div>
      </article>
    `;
  }

  function renderBookings() {
    if (!state.data) return;
    const stays = filteredStays();

    $('#booking-list').innerHTML = `
      <div class="space-y-3.5">
        ${stays.map(stayCard).join('') || `
          <div class="card text-center py-12">
            <div class="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-2xl bg-canvas text-muted">
              ${icon('bookings', 'w-6 h-6')}
            </div>
            <p class="text-base font-semibold text-ink">ไม่พบรายการ Booking</p>
            <p class="text-xs text-muted mt-1">ลองเปลี่ยนคำค้นหา หรือเปิดรายการเข้าพักใหม่</p>
          </div>
        `}
      </div>
    `;

    renderCalendar();
  }

  // ================= 3. CALENDAR VIEW =================
  function renderCalendar() {
    const month = state.calendar.getMonth(), year = state.calendar.getFullYear();
    const first = new Date(year, month, 1);
    const days = new Date(year, month + 1, 0).getDate();
    const pad = (first.getDay() + 6) % 7;

    let cells = '';
    for (let i = 0; i < pad; i++) {
      cells += '<div class="min-h-[85px] rounded-xl bg-canvas/30 border border-transparent"></div>';
    }

    for (let day = 1; day <= days; day++) {
      const date = iso(new Date(year, month, day));
      const items = state.data.stays.filter(s => s.check_in_date <= date && s.check_out_date >= date);
      const statuses = [...new Set(items.map(s => s.status))];
      const isSelected = state.selectedDay === date;

      cells += `
        <button
          data-calendar-day="${date}"
          class="min-h-[85px] flex flex-col justify-between rounded-xl border p-2.5 text-left transition-all ${
            isSelected
              ? 'border-brand-500 bg-brand-50/70 shadow-subtle ring-1 ring-brand-500'
              : 'border-line bg-white hover:border-brand-300'
          }"
        >
          <div class="flex items-center justify-between">
            <span class="text-xs font-bold ${isSelected ? 'text-brand-700' : 'text-ink'}">${day}</span>
            ${items.length ? `
              <span class="rounded-full bg-line/80 px-1.5 py-0.2 text-[10px] font-semibold text-muted">
                ${items.length}
              </span>
            ` : ''}
          </div>

          <div class="mt-2 space-y-1">
            <div class="flex flex-wrap gap-1">
              ${statuses.map(x => `
                <span title="${statusText[Number(x)]}" aria-label="${statusText[Number(x)]}" class="inline-block h-2 w-2 rounded-full ${
                  Number(x) === 0 ? 'bg-amber-400' : Number(x) === 1 ? 'bg-brand-500' : 'bg-emerald-500'
                }"></span>
              `).join('')}
            </div>
            ${items.length ? `
              <p class="text-[10px] text-muted truncate">${items.length} รายการ</p>
            ` : ''}
          </div>
        </button>
      `;
    }

    const selected = state.selectedDay
      ? state.data.stays.filter(s => s.check_in_date <= state.selectedDay && s.check_out_date >= state.selectedDay)
      : [];

    $('#booking-calendar').innerHTML = `
      <div class="card p-5">
        <!-- Month Navigation Header -->
        <div class="mb-5 flex flex-wrap items-center justify-between gap-3">
          <div class="flex items-center gap-2">
            <button class="btn-secondary !min-h-[36px] !p-2" data-calendar-nav="-1" aria-label="เดือนก่อนหน้า">
              ${icon('chevronLeft', 'w-4 h-4')}
            </button>
            <h2 class="text-base font-bold text-ink min-w-[140px] text-center">
              ${new Intl.DateTimeFormat('th-TH', { month: 'long', year: 'numeric' }).format(first)}
            </h2>
            <button class="btn-secondary !min-h-[36px] !p-2" data-calendar-nav="1" aria-label="เดือนถัดไป">
              ${icon('chevronRight', 'w-4 h-4')}
            </button>
          </div>

          <button class="btn-secondary !min-h-[36px] px-3 text-xs" data-calendar-today>
            ${icon('calendar', 'w-3.5 h-3.5')}
            <span>วันนี้</span>
          </button>
        </div>

        <div class="calendar-scroll" tabindex="0" aria-label="ปฏิทินรายเดือน เลื่อนแนวนอนได้บนหน้าจอขนาดเล็ก">
          <div class="calendar-grid-shell">
            <!-- Weekday Headers -->
            <div class="calendar-weekdays mb-2 grid grid-cols-7 text-center text-xs font-semibold text-muted">
              ${['จันทร์', 'อังคาร', 'พุธ', 'พฤหัส', 'ศุกร์', 'เสาร์', 'อาทิตย์'].map(x => `<div>${x}</div>`).join('')}
            </div>

            <!-- Month Grid -->
            <div class="grid grid-cols-7 gap-1.5">${cells}</div>
          </div>
        </div>
      </div>

      <!-- Selected Day Inspector Panel -->
      ${state.selectedDay ? `
        <div class="mt-6">
          <div class="mb-3 flex items-center justify-between">
            <h3 class="text-base font-bold text-ink flex items-center gap-2">
              ${icon('calendar', 'w-4 h-4 text-brand-500')}
              <span>รายการเข้าพักประจำวันที่ ${thaiDate(state.selectedDay)}</span>
            </h3>
            <span class="text-xs text-muted">${selected.length} รายการ</span>
          </div>
          <div class="space-y-3">
            ${selected.map(stayCard).join('') || `
              <div class="card text-center py-8 text-muted text-sm">
                ไม่มีรายการเข้าพักในวันนี้
              </div>
            `}
          </div>
        </div>
      ` : ''}
    `;
  }

  // ================= 4. DASHBOARD & ANALYTICS =================
  function renderAnalytics() {
    const a = state.data.analytics;
    const cards = [
      ['Booking ทั้งหมด', a.booking_count, 'bookings'],
      ['เช็กอินแล้ว', a.check_in_count, 'check'],
      ['เช็กเอาต์แล้ว', a.check_out_count, 'signout'],
      ['จำนวนผู้เข้าพัก', `${a.guest_count} ท่าน`, 'guests'],
      ['Room nights', `${a.occupied_room_nights} คืน`, 'bed'],
      ['Occupancy Rate', (a.occupancy_rate * 100).toFixed(1) + '%', 'dashboard'],
      ['รายได้สุทธิ', money(a.net_revenue_satang), 'money'],
      ['ส่วนลดมอบให้', money(a.discount_satang), 'sparkles'],
      ['มัดจำรับแล้ว', money(a.deposit_received_satang), 'check'],
      ['มัดจำรอชำระ', money(a.deposit_pending_satang), 'clock'],
      ['Booking มีสัตว์เลี้ยง', `${a.pet_bookings} รายการ`, 'paw'],
      ['Feedback เฉลี่ย', `${Number(a.average_feedback).toFixed(1)} / 5`, 'star'],
    ];

    const max = Math.max(1, ...a.daily.map(d => Number(d.revenue_satang)));
    const statusTotal = Math.max(1, a.statuses.booked + a.statuses.checked_in + a.statuses.checked_out);
    const depositTotal = Math.max(1, a.deposits.none + a.deposits.paid + a.deposits.unpaid);

    const statusA = (a.statuses.booked / statusTotal) * 360;
    const statusB = statusA + (a.statuses.checked_in / statusTotal) * 360;

    const depositA = (a.deposits.none / depositTotal) * 360;
    const depositB = depositA + (a.deposits.paid / depositTotal) * 360;

    $('#analytics').innerHTML = `
      <!-- 12 KPI Metric Cards Grid -->
      <div class="grid grid-cols-2 gap-3.5 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6">
        ${cards.map(([l, v, ic]) => `
          <div class="card p-4 flex flex-col justify-between">
            <div class="flex items-center justify-between text-muted">
              <span class="text-xs font-semibold uppercase tracking-wider truncate">${l}</span>
              <span class="opacity-70">${icon(ic, 'w-4 h-4')}</span>
            </div>
            <p class="mt-3 text-xl font-bold tracking-tight text-ink">${v}</p>
          </div>
        `).join('')}
      </div>

      <!-- Charts Section -->
      <div class="mt-6 grid gap-6 lg:grid-cols-2">
        <!-- Daily Revenue Chart -->
        <div class="card p-5">
          <div class="flex items-center justify-between">
            <div>
              <h2 class="text-base font-bold text-ink">รายได้สุทธิรายวัน</h2>
              <p class="text-xs text-muted">ยอดสุทธิที่เกิดขึ้นในแต่ละวันของรอบที่เลือก</p>
            </div>
            <span class="text-xs font-semibold text-brand-700">${money(a.net_revenue_satang)} รวม</span>
          </div>
          <div class="mt-6 flex h-48 items-end gap-1.5 overflow-x-auto pb-2 border-b border-line/60">
            ${a.daily.map(d => `
              <div class="group flex min-w-[20px] flex-1 flex-col items-center justify-end" title="${d.date}: ${money(d.revenue_satang)}">
                <div class="w-full rounded-t-md bg-brand-500/85 transition hover:bg-brand-600" style="height:${Math.max(3, Number(d.revenue_satang) / max * 150)}px"></div>
                <small class="mt-2 text-[10px] text-muted">${d.date.slice(8)}</small>
              </div>
            `).join('')}
          </div>
        </div>

        <!-- Daily Occupancy Chart -->
        <div class="card p-5">
          <div class="flex items-center justify-between">
            <div>
              <h2 class="text-base font-bold text-ink">อัตราห้องพักรายวัน</h2>
              <p class="text-xs text-muted">จำนวนห้องที่ถูกใช้งานจริงจากทั้งหมด ${a.total_rooms} ห้อง</p>
            </div>
            <span class="text-xs font-semibold text-occupied-ink">${(a.occupancy_rate * 100).toFixed(1)}% เฉลี่ย</span>
          </div>
          <div class="mt-6 flex h-48 items-end gap-1.5 overflow-x-auto pb-2 border-b border-line/60">
            ${a.daily.map(d => `
              <div class="group flex min-w-[20px] flex-1 flex-col items-center justify-end" title="${d.date}: ${d.occupied}/${a.total_rooms} ห้อง">
                <div class="w-full rounded-t-md bg-occupied/80 transition hover:bg-occupied" style="height:${Math.max(3, d.occupied / Math.max(1, a.total_rooms) * 150)}px"></div>
                <small class="mt-2 text-[10px] text-muted">${d.date.slice(8)}</small>
              </div>
            `).join('')}
          </div>
        </div>

        <!-- Donut 1: Booking Status -->
        <div class="card p-5 flex flex-col sm:flex-row items-center gap-6">
          <div class="relative flex h-32 w-32 shrink-0 items-center justify-center rounded-full shadow-subtle" style="background:conic-gradient(#f2a43a 0deg ${statusA}deg, #2585e6 ${statusA}deg ${statusB}deg, #2e9b64 ${statusB}deg 360deg)">
            <!-- Modern Donut Center Cutout -->
            <div class="flex h-20 w-20 flex-col items-center justify-center rounded-full bg-white shadow-inner">
              <span class="text-xs text-muted">รวม</span>
              <strong class="text-sm font-bold text-ink">${a.booking_count}</strong>
            </div>
          </div>
          <div class="flex-1 space-y-2">
            <h2 class="text-base font-bold text-ink">สัดส่วนสถานะการจอง</h2>
            <div class="grid gap-1.5 text-xs">
              <div class="flex items-center justify-between">
                <span class="flex items-center gap-1.5 text-muted">
                  <i class="h-2.5 w-2.5 rounded-full bg-amber-400"></i>
                  <span>รอเช็กอิน</span>
                </span>
                <strong class="text-ink">${a.statuses.booked}</strong>
              </div>
              <div class="flex items-center justify-between">
                <span class="flex items-center gap-1.5 text-muted">
                  <i class="h-2.5 w-2.5 rounded-full bg-brand-500"></i>
                  <span>กำลังเข้าพัก</span>
                </span>
                <strong class="text-ink">${a.statuses.checked_in}</strong>
              </div>
              <div class="flex items-center justify-between">
                <span class="flex items-center gap-1.5 text-muted">
                  <i class="h-2.5 w-2.5 rounded-full bg-emerald-500"></i>
                  <span>เช็กเอาต์แล้ว</span>
                </span>
                <strong class="text-ink">${a.statuses.checked_out}</strong>
              </div>
            </div>
          </div>
        </div>

        <!-- Donut 2: Deposit Status -->
        <div class="card p-5 flex flex-col sm:flex-row items-center gap-6">
          <div class="relative flex h-32 w-32 shrink-0 items-center justify-center rounded-full shadow-subtle" style="background:conic-gradient(#94a3b8 0deg ${depositA}deg, #2e9b64 ${depositA}deg ${depositB}deg, #f2a43a ${depositB}deg 360deg)">
            <!-- Modern Donut Center Cutout -->
            <div class="flex h-20 w-20 flex-col items-center justify-center rounded-full bg-white shadow-inner">
              <span class="text-xs text-muted">มัดจำ</span>
              <strong class="text-sm font-bold text-ink">${a.statuses.booked + a.statuses.checked_in}</strong>
            </div>
          </div>
          <div class="flex-1 space-y-2">
            <h2 class="text-base font-bold text-ink">สถานะเงินมัดจำ</h2>
            <div class="grid gap-1.5 text-xs">
              <div class="flex items-center justify-between">
                <span class="flex items-center gap-1.5 text-muted">
                  <i class="h-2.5 w-2.5 rounded-full bg-emerald-500"></i>
                  <span>ชำระมัดจำแล้ว</span>
                </span>
                <strong class="text-ink">${a.deposits.paid}</strong>
              </div>
              <div class="flex items-center justify-between">
                <span class="flex items-center gap-1.5 text-muted">
                  <i class="h-2.5 w-2.5 rounded-full bg-amber-400"></i>
                  <span>ยังไม่ชำระ / รอ</span>
                </span>
                <strong class="text-ink">${a.deposits.unpaid}</strong>
              </div>
              <div class="flex items-center justify-between">
                <span class="flex items-center gap-1.5 text-muted">
                  <i class="h-2.5 w-2.5 rounded-full bg-slate-400"></i>
                  <span>ไม่มีมัดจำ</span>
                </span>
                <strong class="text-ink">${a.deposits.none}</strong>
              </div>
            </div>
          </div>
        </div>
      </div>
    `;
  }

  // ================= 5. ROOMS LIST =================
  function renderRooms() {
    if (!state.data) return;

    $('#rooms-list').innerHTML = state.data.rooms.map(r => `
      <article class="card flex flex-wrap items-center justify-between gap-4 border-line p-4 hover:border-brand-200 sm:p-5">
        <div class="flex min-w-0 flex-1 items-start gap-3 sm:gap-4">
          <div class="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-brand-50 text-brand-700 font-bold text-lg">
            ${h(r.name)}
          </div>
          <div class="min-w-0 flex-1">
            <div class="flex flex-wrap items-center gap-2">
              <h3 class="text-base font-bold text-ink">ห้อง ${h(r.name)} · ${h(r.type)}</h3>
              <span class="rounded-md border border-line bg-canvas px-2 py-0.5 text-xs font-medium text-muted">
                ${h(r.zone)}
              </span>
              ${r.is_pet_friendly ? `
                <span class="inline-flex items-center gap-1 rounded-md bg-brand-50 px-2 py-0.5 text-xs font-semibold text-brand-700">
                  ${icon('paw', 'w-3 h-3')}
                  <span>Pet Friendly</span>
                </span>
              ` : ''}
            </div>
            <p class="mt-1 flex flex-wrap items-center gap-x-2 gap-y-1 text-xs text-muted">
              <span>ราคาปกติ <strong>${money(r.price_satang)}</strong> / คืน</span>
              <span>·</span>
              <span>รองรับ ${r.base_guests}–${r.max_guests} ท่าน</span>
              ${Number(r.extra_guest_fee_satang) > 0 ? `<span>(คนเพิ่ม +${money(r.extra_guest_fee_satang)}/คืน)</span>` : ''}
            </p>
          </div>
        </div>

        <div class="grid w-full grid-cols-2 gap-2 sm:flex sm:w-auto sm:items-center">
          <button class="btn-secondary btn-sm" data-action="edit-room" data-id="${r.id}">
            ${icon('edit', 'w-3.5 h-3.5')}
            <span>แก้ไข</span>
          </button>
          <button class="btn-danger btn-sm" data-action="delete-room" data-id="${r.id}">
            ${icon('trash', 'w-3.5 h-3.5')}
            <span>ลบ</span>
          </button>
        </div>
      </article>
    `).join('') || `
      <div class="card text-center py-12">
        <div class="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-2xl bg-canvas text-muted">
          ${icon('rooms', 'w-6 h-6')}
        </div>
        <p class="text-base font-semibold text-ink">ยังไม่มีห้องพัก</p>
        <p class="text-xs text-muted mt-1">กดปุ่ม '+ เพิ่มห้องพัก' ด้านบนเพื่อสร้างห้องแรก</p>
      </div>
    `;
  }

  // ================= 6. GUESTS DIRECTORY =================
  function filteredGuests() {
    let list = [...state.data.guests];
    const q = ($('#guest-search')?.value || '').toLocaleLowerCase('th');
    if (q) {
      list = list.filter(g => [g.name, g.phone].some(v => String(v).toLocaleLowerCase('th').includes(q)));
    }
    if ($('#regular-only')?.checked) {
      list = list.filter(g => g.is_regular);
    }
    const sort = $('#guest-sort')?.value;
    list.sort((a, b) =>
      sort === 'count' ? b.completed_stays - a.completed_stays :
      sort === 'value' ? b.lifetime_value_satang - a.lifetime_value_satang :
      sort === 'name' ? a.name.localeCompare(b.name, 'th') :
      String(b.last_stay_date || '').localeCompare(String(a.last_stay_date || ''))
    );
    return list;
  }

  function renderGuests() {
    const list = filteredGuests();

    $('#guest-list').innerHTML = list.map(g => `
      <button class="card-interactive p-5 text-left border-line hover:border-brand-300" data-action="guest-details" data-id="${g.id}">
        <!-- Guest Header -->
        <div class="flex flex-wrap items-start justify-between gap-2">
          <div class="flex min-w-0 items-center gap-3">
            <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl bg-brand-50 text-sm font-bold text-brand-700">
              ${h(g.name).slice(0, 1)}
            </div>
            <div class="min-w-0">
              <h3 class="truncate text-base font-bold text-ink">${h(g.name)}</h3>
              <p class="mt-0.5 flex flex-wrap items-center gap-1.5 text-xs text-muted">
                ${icon('phone', 'w-3 h-3')}
                <span>${h(g.phone)}</span>
                ${g.customer_type ? `<span>· ${h(g.customer_type)}</span>` : ''}
              </p>
            </div>
          </div>

          ${g.is_regular ? `
            <span class="inline-flex items-center gap-1 rounded-full border border-brand-200 bg-brand-50 px-2.5 py-0.5 text-xs font-semibold text-brand-700">
              ${icon('star', 'w-3 h-3')}
              <span>ลูกค้าประจำ</span>
            </span>
          ` : ''}
        </div>

        <!-- Lifetime Metrics Grid -->
        <div class="mt-4 grid grid-cols-3 gap-2 rounded-xl border border-line bg-canvas/60 p-3 text-center text-xs">
          <div>
            <span class="block text-base font-bold text-ink">${g.completed_stays}</span>
            <span class="text-[11px] text-muted">ครั้งที่พัก</span>
          </div>
          <div>
            <span class="block text-base font-bold text-ink">${g.total_nights}</span>
            <span class="text-[11px] text-muted">คืนสะสม</span>
          </div>
          <div>
            <span class="block text-base font-bold text-brand-700">${money(g.lifetime_value_satang)}</span>
            <span class="text-[11px] text-muted">ยอดรวม</span>
          </div>
        </div>
      </button>
    `).join('') || `
      <div class="card text-center py-12 md:col-span-2">
        <div class="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-2xl bg-canvas text-muted">
          ${icon('guests', 'w-6 h-6')}
        </div>
        <p class="text-base font-semibold text-ink">ไม่พบข้อมูลลูกค้า</p>
        <p class="text-xs text-muted mt-1">ลองเปลี่ยนคำค้นหา หรือรอให้มีรายการเข้าพักใหม่</p>
      </div>
    `;
  }

  // ================= 7. NAVIGATION & MODAL CONTROLLERS =================
  function navigate(page, updateHash = true) {
    if (!titles[page]) return;
    if (page === 'rooms' && !canManageRooms) page = 'today';
    state.page = page;
    $$('[data-page-panel]').forEach(x => (x.hidden = x.id !== `page-${page}`));
    $$('[data-page]').forEach(x => x.classList.toggle('active', x.dataset.page === page));
    $('#page-title').textContent = titles[page];
    if (updateHash && window.location.hash !== `#${page}`) history.pushState(null, '', `#${page}`);
  }

  function syncExportLink() {
    const link = $('a[href^="/api/v1/reports/bookings.csv"]');
    if (!link) return;
    const params = new URLSearchParams({ start: $('#range-start').value, end: $('#range-end').value });
    link.href = `/api/v1/reports/bookings.csv?${params}`;
  }

  function renderCommands() {
    const query = ($('#command-search').value || '').trim().toLocaleLowerCase('th');
    const menu = [
      ['today', 'งานวันนี้', 'สรุปเช็กอิน เช็กเอาต์ และงานค้าง'],
      ['room-map', 'ผังห้อง', 'ดูห้องว่างและผู้เข้าพัก'],
      ['bookings', 'ตารางเข้าพัก', 'ค้นหาและจัดการ Booking'],
      ['dashboard', 'ภาพรวมและรายงาน', 'สถิติและส่งออก CSV'],
      ['guests', 'ลูกค้า', 'ประวัติและความต้องการของลูกค้า'],
      ...(canManageRooms ? [['rooms', 'ตั้งค่าห้องพัก', 'ราคา ความจุ และสิ่งอำนวยความสะดวก']] : []),
    ].filter(([, title, detail]) => !query || `${title} ${detail}`.toLocaleLowerCase('th').includes(query));
    const stays = state.data.stays.filter(s => !query || [s.guest_name, s.phone, s.room_name].some(v => String(v || '').toLocaleLowerCase('th').includes(query))).slice(0, 6);
    $('#command-results').innerHTML = `
      ${menu.map(([page, title, detail]) => `<button class="flex w-full items-center justify-between rounded-xl px-3 py-2.5 text-left hover:bg-brand-50" data-command-page="${page}"><span><strong class="block text-sm text-ink">${title}</strong><span class="text-xs text-muted">${detail}</span></span><span class="text-muted">↵</span></button>`).join('')}
      ${stays.length ? '<p class="px-3 pt-3 text-[10px] font-bold uppercase tracking-wider text-muted">ผู้เข้าพักและ Booking</p>' : ''}
      ${stays.map(s => `<button class="flex w-full items-center justify-between rounded-xl px-3 py-2.5 text-left hover:bg-brand-50" data-command-stay="${s.id}"><span><strong class="block text-sm text-ink">${h(s.guest_name)} · ห้อง ${h(s.room_name)}</strong><span class="text-xs text-muted">${h(s.phone || '')} · ${statusText[Number(s.status)]}</span></span><span class="text-brand-500">→</span></button>`).join('')}
      ${!menu.length && !stays.length ? '<p class="p-6 text-center text-sm text-muted">ไม่พบข้อมูลที่ค้นหา</p>' : ''}
    `;
  }

  function openCommand() {
    $('#command-search').value = '';
    renderCommands();
    $('#command-dialog').showModal();
    requestAnimationFrame(() => $('#command-search').focus());
  }

  function fillForm(form, data) {
    for (const [k, v] of Object.entries(data)) {
      const el = form.elements.namedItem(k);
      if (!el) continue;
      if (el.type === 'checkbox') el.checked = bool(v);
      else el.value = v ?? '';
    }
  }

  function roomOptions(selected = '') {
    return state.data.rooms.map(r =>
      `<option value="${r.id}" ${r.id === selected ? 'selected' : ''}>ห้อง ${h(r.name)} · ${h(r.zone)} · ${money(r.price_satang)}/คืน</option>`
    ).join('');
  }

  function openBooking(id = null, roomId = null) {
    const f = $('#booking-form');
    f.reset();
    f.elements.id.value = '';
    f.elements.room_id.innerHTML = roomOptions(roomId || '');

    const today = state.data.today;
    const tomorrow = new Date(`${today}T00:00:00`);
    tomorrow.setDate(tomorrow.getDate() + 1);

    f.elements.check_in_date.value = today;
    f.elements.check_out_date.value = iso(tomorrow);
    f.elements.guests.value = 2;

    if (id) {
      const s = state.data.stays.find(x => x.id === id);
      fillForm(f, {
        ...s,
        id: s.id,
        deposit_amount: Number(s.deposit_amount_satang) / 100,
        discount_amount: Number(s.discount_amount_satang) / 100,
        check_in_now: Number(s.status) === 1,
      });
      f.elements.room_id.innerHTML = roomOptions(s.room_id);
    }

    updatePrice();
    $('#booking-dialog').showModal();
  }

  function updatePrice() {
    const f = $('#booking-form');
    const room = state.data.rooms.find(r => r.id === f.elements.room_id.value);

    if (!room) {
      $('#price-preview').innerHTML = `<p class="text-xs text-muted">กรุณาเลือกห้องพักเพื่อคำนวณราคา</p>`;
      return;
    }

    const from = new Date(`${f.elements.check_in_date.value}T00:00:00`);
    const to = new Date(`${f.elements.check_out_date.value}T00:00:00`);
    const nights = Math.max(1, Math.round((to - from) / 86400000) || 1);
    const guests = Number(f.elements.guests.value || 1);

    const baseGross = Number(room.price_satang) * nights;
    const extraGuestFee = Math.max(0, guests - room.base_guests) * Number(room.extra_guest_fee_satang) * nights;
    const extraBedFee = f.elements.extra_bed.checked ? 20000 : 0;
    const petFee = Number(f.elements.pet_count.value) > 0 ? 20000 * nights : 0;

    const gross = baseGross + extraGuestFee + extraBedFee + petFee;
    const discount = Number(f.elements.discount_amount.value || 0) * 100;
    const net = Math.max(0, gross - discount);

    const depositVal = f.elements.deposit_paid.checked ? Number(f.elements.deposit_amount.value || 0) * 100 : 0;
    const balance = Math.max(0, net - depositVal);

    $('#price-preview').innerHTML = `
      <div class="space-y-1.5">
        <div class="flex items-center justify-between text-xs text-muted">
          <span>ค่าห้องพัก (${nights} คืน × ${money(room.price_satang)})</span>
          <span class="font-medium text-ink">${money(baseGross)}</span>
        </div>

        ${extraGuestFee > 0 ? `
          <div class="flex items-center justify-between text-xs text-muted">
            <span>ผู้เข้าพักเสริม (+${guests - room.base_guests} ท่าน)</span>
            <span class="font-medium text-ink">${money(extraGuestFee)}</span>
          </div>
        ` : ''}

        ${extraBedFee > 0 ? `
          <div class="flex items-center justify-between text-xs text-muted">
            <span>เตียงเสริม</span>
            <span class="font-medium text-ink">${money(extraBedFee)}</span>
          </div>
        ` : ''}

        ${petFee > 0 ? `
          <div class="flex items-center justify-between text-xs text-muted">
            <span>สัตว์เลี้ยง (${f.elements.pet_count.value} ตัว)</span>
            <span class="font-medium text-ink">${money(petFee)}</span>
          </div>
        ` : ''}

        ${discount > 0 ? `
          <div class="flex items-center justify-between text-xs text-emerald-600">
            <span>ส่วนลดพิเศษ</span>
            <span class="font-medium">-${money(discount)}</span>
          </div>
        ` : ''}

        <div class="pt-2 border-t border-brand-200/80 flex items-center justify-between text-sm">
          <span class="font-bold text-ink">ยอดรวมสุทธิ</span>
          <strong class="text-base font-bold text-ink">${money(net)}</strong>
        </div>

        <div class="flex items-center justify-between text-xs">
          <span class="text-muted">มัดจำ (${f.elements.deposit_paid.checked ? 'ชำระแล้ว' : 'รอชำระ'}): ${money(depositVal)}</span>
          <span class="font-bold text-brand-700">คงเหลือต้องชำระ: ${money(balance)}</span>
        </div>
      </div>
    `;
  }

  function openRoom(id = null) {
    const f = $('#room-form');
    f.reset();
    f.elements.id.value = '';

    if (id) {
      const r = state.data.rooms.find(x => x.id === id);
      fillForm(f, {
        ...r,
        price: Number(r.price_satang) / 100,
        extra_guest_fee: Number(r.extra_guest_fee_satang) / 100,
      });
    }

    $('#room-dialog').showModal();
  }

  function openGuest(id) {
    const g = state.data.guests.find(x => x.id === id);
    const f = $('#guest-form');
    fillForm(f, g);

    $('#guest-stats').innerHTML = `
      <div class="grid grid-cols-2 gap-3 sm:grid-cols-4">
        ${[
          ['เข้าพักสำเร็จ', g.completed_stays + ' ครั้ง', 'check'],
          ['คืนสะสม', g.total_nights + ' คืน', 'bed'],
          ['ยอดใช้จ่ายสะสม', money(g.lifetime_value_satang), 'money'],
          ['ส่วนลดที่เคยได้รับ', money(g.total_discount_satang), 'sparkles'],
        ].map(([l, v, ic]) => `
          <div class="rounded-2xl border border-line bg-canvas/70 p-3.5">
            <div class="flex items-center justify-between text-muted text-xs">
              <span>${l}</span>
              ${icon(ic, 'w-3.5 h-3.5')}
            </div>
            <strong class="mt-1.5 block text-base font-bold text-ink">${v}</strong>
          </div>
        `).join('')}
      </div>

      ${g.completed_stays >= 3 && !g.is_regular ? `
        <div class="mt-4 flex items-center gap-2.5 rounded-2xl border border-amber-200 bg-amber-50/80 p-3.5 text-xs font-semibold text-amber-800">
          ${icon('star', 'w-4 h-4 text-amber-600 shrink-0')}
          <span>ลูกค้าเข้าพักสำเร็จอย่างน้อย 3 ครั้ง แนะนำให้ตั้งเป็นลูกค้าประจำ</span>
        </div>
      ` : ''}
    `;

    const history = state.data.stays.filter(s => s.guest_id === id);
    $('#guest-history').innerHTML = history.length ? history.map(s => `
      <div class="flex items-center justify-between rounded-xl border border-line bg-canvas/40 p-3 text-xs">
        <div>
          <span class="font-bold text-ink">ห้อง ${h(s.room_name)}</span>
          <span class="text-muted ml-2">${thaiDate(s.check_in_date)} – ${thaiDate(s.check_out_date)}</span>
        </div>
        <span class="${statusBadgeClass[s.status]} text-[10px]">
          ${statusText[s.status]}
        </span>
      </div>
    `).join('') : '<div class="text-xs text-muted py-2">ไม่มีประวัติก่อนหน้านี้</div>';

    $('#guest-dialog').showModal();
  }

  function openAction(action, id) {
    const s = state.data.stays.find(x => x.id === id);
    const f = $('#action-form');
    f.elements.stay_id.value = id;
    f.elements.action.value = action;

    const titles = {
      checkout: 'Checklist ตรวจสอบก่อนเช็กเอาต์',
      extend: 'ต่อระยะเวลาการเข้าพัก',
      feedback: 'แบบประเมินความพึงพอใจ',
      upload: 'แนบไฟล์เอกสาร / รูปภาพ',
    };
    $('#action-title').textContent = titles[action] || 'ดำเนินการ';

    let fields = '';

    if (action === 'checkout') {
      fields = `
        <p class="text-xs text-muted mb-2">กรุณาตรวจสอบตามรายการด้านล่าง หากพบความเสียหายให้ระบุในช่องหมายเหตุ</p>
        <div class="space-y-2">
          ${[
            ['key_returned', 'ลูกค้าคืนกุญแจห้องเรียบร้อย'],
            ['room_clean', 'ตรวจสอบสภาพความสะอาดห้องพักเบื้องต้น'],
            ['equipment_complete', 'อุปกรณ์ในห้องครบถ้วน (รีโมท ผ้าเช็ดตัว ไดร์ ฯลฯ)'],
            ['no_damage', 'ไม่พบความเสียหายต่อทรัพย์สินของรีสอร์ท'],
            ['minibar_checked', 'ตรวจสอบสินค้ามินิบาร์เรียบร้อย'],
          ].map(([n, l]) => `
            <label class="flex items-center gap-3 rounded-xl border border-line bg-canvas/40 p-3 text-xs font-medium text-ink cursor-pointer hover:border-brand-300">
              <input type="checkbox" name="${n}" checked class="rounded border-line text-brand-500 focus:ring-brand-500/20">
              <span>${l}</span>
            </label>
          `).join('')}
        </div>
        <div class="mt-4">
          <label class="label">หมายเหตุการตรวจสอบ / รายละเอียดความเสียหาย</label>
          <textarea class="field !min-h-[72px]" name="inspection_note" rows="2" placeholder="ระบุรายละเอียดเพิ่มเติม (ถ้ามี)"></textarea>
        </div>
      `;
    }

    if (action === 'extend') {
      fields = `
        <div>
          <label class="label">วันเช็กเอาต์ใหม่</label>
          <input class="field" type="date" name="check_out_date" min="${s.check_out_date}" value="${s.check_out_date}" required>
        </div>
        <div>
          <label class="label">ส่วนลดใหม่เพิ่มเติม (บาท)</label>
          <input class="field" type="number" name="discount_amount" min="0" value="${Number(s.discount_amount_satang) / 100}">
        </div>
      `;
    }

    if (action === 'feedback') {
      fields = `
        <div class="grid gap-3 sm:grid-cols-2">
          ${[
            ['cleanliness_rating', 'ความสะอาดของห้องพัก'],
            ['service_rating', 'การบริการของพนักงาน'],
            ['facility_rating', 'สิ่งอำนวยความสะดวก'],
            ['overall_rating', 'ความพึงพอใจโดยรวม'],
          ].map(([n, l]) => `
            <div>
              <label class="label">${l}</label>
              <select class="field" name="${n}">
                ${[5, 4, 3, 2, 1].map(x => `<option value="${x}">${'★'.repeat(x)} (${x} คะแนน)</option>`).join('')}
              </select>
            </div>
          `).join('')}
        </div>
        <div class="pt-2">
          <label class="flex items-center gap-3 rounded-xl border border-line bg-canvas/40 p-3 text-xs font-semibold text-ink cursor-pointer">
            <input type="checkbox" name="would_return" checked class="rounded border-line text-brand-500 focus:ring-brand-500/20">
            <span>มีความประสงค์จะกลับมาใช้บริการอีกในอนาคต</span>
          </label>
        </div>
        <div>
          <label class="label">ข้อเสนอแนะและความคิดเห็นเพิ่มเติม</label>
          <textarea class="field !min-h-[72px]" name="comment" rows="2" placeholder="ความคิดเห็นจากผู้เข้าพัก"></textarea>
        </div>
      `;
    }

    if (action === 'upload') {
      fields = `
        <div>
          <label class="label">เลือกไฟล์รูปภาพหรือ PDF (ขนาดไม่เกิน 5 MB)</label>
          <input class="field pt-2" type="file" name="file" accept="image/jpeg,image/png,image/webp,application/pdf" required>
          <p class="hint">รองรับรูปถ่ายสลิปโอนเงิน หรือเอกสารการจอง</p>
        </div>
      `;
    }

    $('#action-fields').innerHTML = fields;
    $('#action-dialog').showModal();
  }

  async function mutate(path, method, body, form = null) {
    const submit = form?.querySelector('[type="submit"]');
    form?.querySelectorAll('[aria-invalid="true"]').forEach(field => field.removeAttribute('aria-invalid'));
    form?.querySelectorAll('[data-field-error]').forEach(error => error.remove());
    if (submit) submit.disabled = true;
    try {
      await api(path, {
        method,
        body: body instanceof FormData ? body : JSON.stringify(body || {}),
      });
      toast('ดำเนินการสำเร็จเรียบร้อย');
      $$('dialog[open]').forEach(d => d.close());
      await load(false);
      return true;
    } catch (e) {
      for (const [name, message] of Object.entries(e.errors || {})) {
        const field = form?.elements.namedItem(name);
        if (!field || field instanceof RadioNodeList) continue;
        field.setAttribute('aria-invalid', 'true');
        field.insertAdjacentHTML('afterend', `<p data-field-error class="mt-1 text-xs text-red-600">${h(message)}</p>`);
      }
      toast(`${e.message}${Object.keys(e.errors || {}).length ? ' · ' + Object.values(e.errors).join(' · ') : ''}`, 'error');
      return false;
    } finally {
      if (submit) submit.disabled = false;
    }
  }

  // ================= 8. EVENT LISTENERS =================
  document.addEventListener('click', async e => {
    const b = e.target.closest('button, a');
    if (!b) return;

    if (b.dataset.page) navigate(b.dataset.page);
    if (b.hasAttribute('data-close')) b.closest('dialog')?.close();
    if (b.dataset.commandPage) {
      $('#command-dialog').close();
      navigate(b.dataset.commandPage);
    }
    if (b.dataset.commandStay) {
      $('#command-dialog').close();
      navigate('bookings');
      $('#stay-search').value = state.data.stays.find(s => s.id === b.dataset.commandStay)?.guest_name || '';
      renderBookings();
    }

    const a = b.dataset.action;
    const id = b.dataset.id;

    if (a === 'new-booking') openBooking(null, id);
    if (a === 'command') openCommand();
    if (a === 'retry-load') load().catch(error => toast(error.message, 'error'));
    if (a === 'edit-booking') openBooking(id);
    if (a === 'new-room') openRoom();
    if (a === 'edit-room') openRoom(id);
    if (a === 'guest-details') openGuest(id);

    if (a === 'stay-details') {
      navigate('bookings');
      $('#stay-search').value = state.data.stays.find(s => s.id === id)?.guest_name || '';
      renderBookings();
    }

    if (['checkout', 'extend', 'feedback', 'upload'].includes(a)) {
      openAction(a, id);
    }

    if (a === 'check-in' && confirm('ยืนยันเช็กอินรายการนี้?')) {
      await mutate(`/api/v1/stays/${id}/check-in`, 'POST', {});
    }

    if (a === 'delete-booking' && confirm('ลบรายการ Booking นี้อย่างถาวร?')) {
      await mutate(`/api/v1/stays/${id}`, 'DELETE', {});
    }

    if (a === 'delete-room' && confirm('ยืนยันลบห้องพักนี้?')) {
      await mutate(`/api/v1/rooms/${id}`, 'DELETE', {});
    }

    if (a === 'print') window.print();

    if (b.dataset.view) {
      state.bookingView = b.dataset.view;
      $$('[data-view]').forEach(btn => {
        const isCurrent = btn.dataset.view === state.bookingView;
        btn.classList.toggle('text-brand-700', isCurrent);
        btn.classList.toggle('bg-brand-50', isCurrent);
        btn.classList.toggle('text-muted', !isCurrent);
      });
      $('#booking-list').hidden = state.bookingView !== 'list';
      $('#booking-calendar').hidden = state.bookingView !== 'calendar';
    }

    if (b.dataset.calendarNav) {
      state.calendar.setMonth(state.calendar.getMonth() + Number(b.dataset.calendarNav));
      renderCalendar();
    }

    if (b.hasAttribute('data-calendar-today')) {
      state.calendar = new Date();
      state.selectedDay = state.data.today;
      renderCalendar();
    }

    if (b.dataset.calendarDay) {
      state.selectedDay = b.dataset.calendarDay;
      renderCalendar();
    }
  });

  // Dynamic guest lookup by phone
  $('#booking-form').addEventListener('input', e => {
    updatePrice();
    if (e.target.name === 'phone') {
      const digits = e.target.value.replace(/\D/g, '');
      const guest = digits.length >= 9 ? state.data.guests.find(g => g.normalized_phone === digits) : null;
      if (guest) {
        e.currentTarget.elements.guest_name.value = guest.name;
        e.target.setCustomValidity('');
        e.target.title = `พบข้อมูลลูกค้าเดิม: ${guest.name}${guest.is_regular ? ' (ลูกค้าประจำ)' : ''}`;
      } else {
        e.target.title = '';
      }
    }
  });

  $('#booking-form').addEventListener('submit', async e => {
    e.preventDefault();
    const d = formObject(e.currentTarget);
    const id = d.id;
    d.status = d.check_in_now ? 1 : (id ? state.data.stays.find(s => s.id === id).status : 0);
    delete d.id;
    delete d.check_in_now;
    await mutate(id ? `/api/v1/stays/${id}` : '/api/v1/stays', id ? 'PUT' : 'POST', d, e.currentTarget);
  });

  $('#room-form').addEventListener('submit', async e => {
    e.preventDefault();
    const d = formObject(e.currentTarget);
    const id = d.id;
    delete d.id;
    await mutate(id ? `/api/v1/rooms/${id}` : '/api/v1/rooms', id ? 'PUT' : 'POST', d, e.currentTarget);
  });

  $('#guest-form').addEventListener('submit', async e => {
    e.preventDefault();
    const d = formObject(e.currentTarget);
    const id = d.id;
    delete d.id;
    await mutate(`/api/v1/guests/${id}`, 'PUT', d, e.currentTarget);
  });

  $('#action-form').addEventListener('submit', async e => {
    e.preventDefault();
    const d = formObject(e.currentTarget);
    const id = d.stay_id;
    const action = d.action;
    delete d.stay_id;
    delete d.action;

    if (action === 'extend') {
      const s = state.data.stays.find(x => x.id === id);
      const body = {
        ...s,
        deposit_amount: Number(s.deposit_amount_satang) / 100,
        discount_amount: d.discount_amount,
        check_out_date: d.check_out_date,
      };
      for (const k of [
        'id', 'total_amount_satang', 'pet_fee_satang', 'room_name', 'zone', 'room_type',
        'room_rate_satang', 'base_guests', 'max_guests', 'extra_guest_fee_satang',
        'is_pet_friendly', 'customer_type', 'is_regular', 'feedback_rating', 'created_at',
        'updated_at', 'deleted_at', 'guest_id',
      ]) {
        delete body[k];
      }
      await mutate(`/api/v1/stays/${id}`, 'PUT', body, e.currentTarget);
      return;
    }

    if (action === 'upload') {
      const fd = new FormData(e.currentTarget);
      await mutate(`/api/v1/stays/${id}/attachments`, 'POST', fd, e.currentTarget);
      return;
    }

    await mutate(`/api/v1/stays/${id}/${action}`, 'POST', d, e.currentTarget);
  });

  for (const id of ['stay-search', 'stay-status']) {
    $('#' + id)?.addEventListener('input', renderBookings);
  }

  for (const id of ['guest-search', 'guest-sort', 'regular-only']) {
    $('#' + id)?.addEventListener('input', renderGuests);
  }

  $('#apply-range')?.addEventListener('click', () => load().catch(e => toast(e.message, 'error')));
  $('#command-search')?.addEventListener('input', renderCommands);
  window.addEventListener('keydown', e => {
    if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') {
      e.preventDefault();
      openCommand();
    }
  });
  window.addEventListener('hashchange', () => navigate(location.hash.slice(1) || 'today', false));

  $$('[data-range]').forEach(button => {
    button.addEventListener('click', () => {
      const now = new Date();
      const start = new Date(now);
      if (button.dataset.range === '7days') start.setDate(now.getDate() - 6);
      if (button.dataset.range === 'month') start.setDate(1);
      $('#range-start').value = iso(start);
      $('#range-end').value = iso(now);
      load().catch(e => toast(e.message, 'error'));
    });
  });

  const now = new Date();
  if ($('#range-start')) $('#range-start').value = iso(new Date(now.getFullYear(), now.getMonth(), 1));
  if ($('#range-end')) $('#range-end').value = iso(new Date(now.getFullYear(), now.getMonth() + 1, 0));

  $$('[data-manager-only]').forEach(element => { element.hidden = !canManageRooms; });
  $$('[data-booking-control]').forEach(element => { element.hidden = !canBook; });
  navigate(location.hash.slice(1) || 'today', false);

  load().catch(e => {
    toast(e.message, 'error');
    $('#loading').hidden = false;
    $('#loading').innerHTML = `<p class="font-semibold text-ink">โหลดข้อมูลไม่สำเร็จ</p><p class="mt-1 text-sm text-muted">${h(e.message)}</p><button class="btn-primary mt-4" data-action="retry-load">ลองอีกครั้ง</button>`;
  });
}
