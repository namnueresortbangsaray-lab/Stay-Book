import { api } from './core/api.js';
import { barChart, chartTable } from './core/charts.js';
import { $, $$, escapeHtml as h, formObject, toast } from './core/dom.js';
import { fileSize, iso, longDate, money, monthTitle, nights, number, shortDate, thaiDate } from './core/format.js';
import { t } from './core/i18n.js';
import { icon } from './core/icons.js';
import { initPreferences } from './core/preferences.js';
import { bindRowNavigation, columnMenuItems, highlight, renderTable, saveColumns, tableState, toggleSort } from './core/table.js';
import { shrinkImage } from './core/image.js';
import { initTheme, themePreference } from './core/theme.js';
import { button, closeDropdownMenu, emptyState, menuTriggerButton, openDropdownMenu, pill, selectTab, setButtonLoading } from './core/ui.js';

initTheme();
initPreferences();
bindRowNavigation();

document.addEventListener('click', event => {
  const toggle = event.target.closest('[data-password-toggle]');
  if (!toggle) return;
  const input = document.getElementById(toggle.getAttribute('aria-controls'));
  const show = input.type === 'password';
  input.type = show ? 'text' : 'password';
  toggle.setAttribute('aria-pressed', String(show));
});

if ($('#app')) {
  const role = $('#app').dataset.role;
  const canBook = role === 'admin' || role === 'front_desk';
  const canManageRooms = canBook;
  const isAdmin = role === 'admin';
  const canCheckout = canBook || role === 'housekeeping';
  const state = {
    me: $('#app').dataset.userId,
    data: null,
    page: 'today',
    bookingView: 'list',
    calendar: new Date(),
    selectedDay: null,
    roomState: '',
    roomZone: '',
    files: [],
    fileIndex: 0,
    tables: {
      bookings: tableState('bookings', { sort: 'check_in', dir: 'desc' }),
      day: tableState('day', { sort: 'room' }),
      guests: tableState('guests', { sort: 'latest', dir: 'desc' }),
      rooms: tableState('rooms'),
      zones: tableState('zones', { sort: 'order' }),
      users: tableState('users', { sort: 'name' }),
      types: tableState('types', { sort: 'order' }),
    },
  };

  const pages = {
    today: ['ui.nav.today', 'ui.nav.group.daily'],
    'room-map': ['ui.nav.room_map', 'ui.nav.group.daily'],
    bookings: ['ui.nav.bookings', 'ui.nav.group.daily'],
    guests: ['ui.nav.guests', 'ui.nav.group.records'],
    dashboard: ['ui.nav.reports', 'ui.nav.group.records'],
    rooms: ['ui.nav.rooms', 'ui.nav.group.records'],
    users: ['ui.nav.users', 'ui.nav.group.records'],
  };

  const STATUS = [
    { tone: 'info', icon: 'clock', label: t('ui.status.booked'), short: t('ui.status.booked_short') },
    { tone: 'primary', icon: 'bed', label: t('ui.status.in_house'), short: t('ui.status.in_house_short') },
    { tone: 'neutral', icon: 'check', label: t('ui.status.checked_out'), short: t('ui.status.checked_out_short') },
  ];
  const ROOM_STATES = {
    vacant: { tone: 'success', icon: 'vacant', label: t('ui.room_state.vacant') },
    arriving: { tone: 'info', icon: 'arrive', label: t('ui.room_state.arriving') },
    occupied: { tone: 'primary', icon: 'bed', label: t('ui.room_state.occupied') },
    departing: { tone: 'warning', icon: 'depart', label: t('ui.room_state.departing') },
  };

  const bool = v => v === true || v === 1 || v === '1';
  const statusPill = status => pill(STATUS[Number(status)].tone, STATUS[Number(status)].icon, STATUS[Number(status)].label);
  const activeStays = () => state.data.stays.filter(s => Number(s.status) === 1);
  const balanceOf = s => Math.max(0, Number(s.total_amount_satang || 0) - (s.deposit_paid ? Number(s.deposit_amount_satang || 0) : 0));
  const attachmentsOf = stayIds => (state.data.attachments || []).filter(file => stayIds.includes(file.stay_id));
  const isImage = file => String(file.mime_type).startsWith('image/');

  function roomStatus(room) {
    const today = state.data.today;
    const stay = state.data.stays.find(s => s.room_id === room.id && Number(s.status) === 1);
    if (stay) return { key: stay.check_out_date === today ? 'departing' : 'occupied', stay };
    const arrival = state.data.stays.find(s => s.room_id === room.id && Number(s.status) === 0 && s.check_in_date === today);
    return arrival ? { key: 'arriving', stay: arrival } : { key: 'vacant', stay: null };
  }

  function stayMenuItems(stay) {
    const status = Number(stay.status);
    const items = [];
    if (canBook && status === 0) items.push({ action: 'edit-booking', id: stay.id, label: t('ui.booking.edit'), icon: 'edit' });
    if (canBook && status === 1) items.push({ action: 'extend', id: stay.id, label: t('ui.action.extend'), icon: 'clock' });
    items.push({ action: 'upload', id: stay.id, label: t('ui.action.upload'), icon: 'upload' });
    if (state.idPhotos?.has(stay.id)) items.push({ action: 'view-id-photo', id: stay.id, label: t('ui.id_photo.view'), icon: 'idCard' });
    if (canBook) {
      items.push({ separator: true });
      items.push({ action: 'delete-booking', id: stay.id, label: t('ui.booking.delete'), icon: 'trash', destructive: true });
    }
    return items;
  }

  const roomMenuItems = room => [{ action: 'delete-room', id: room.id, label: t('ui.rooms.delete'), icon: 'trash', destructive: true }];
  // A zone or type used by rooms cannot be deleted; the menu says why instead of failing afterwards.
  const categoryMenuItems = (kind, item) => [{
    action: `delete-${kind}`,
    id: item.id,
    label: item.room_count ? t('ui.category.in_use', { n: item.room_count }) : t(`ui.${kind}s.delete`),
    icon: 'trash',
    destructive: !item.room_count,
    disabled: item.room_count > 0,
  }];

  function primaryStayAction(s, size = 'sm') {
    const status = Number(s.status);
    const attributes = { 'data-id': s.id, 'data-row-primary': true };
    const tip = label => ({ ...attributes, title: label });
    if (status === 0 && canBook) return button({ label: t('ui.action.check_in'), variant: 'primary', size, iconName: 'arrive', attributes: { ...tip(t('ui.action.check_in')), 'data-action': 'check-in' } });
    if (status === 1 && canCheckout) return button({ label: t('ui.action.checkout'), variant: 'primary', size, iconName: 'depart', attributes: { ...tip(t('ui.action.checkout')), 'data-action': 'checkout' } });
    return '';
  }

  let loadingMarkup = null;

  async function load(show = true) {
    const loading = $('#loading');
    loadingMarkup ??= loading.innerHTML;
    if (show) {
      loading.innerHTML = loadingMarkup;
      loading.setAttribute('aria-busy', 'true');
      loading.hidden = false;
      if (!state.data) $('#main').dataset.state = 'loading';
    }
    try {
      const start = $('#range-start')?.value || '';
      const end = $('#range-end')?.value || '';
      [state.data, state.categories] = await Promise.all([
        api(`/api/v1/snapshot${start && end ? `?start=${start}&end=${end}` : ''}`),
        api('/api/v1/room-categories'),
      ]);
      state.idPhotos = new Map((await api('/api/v1/id-photos')).map(p => [p.stay_id, p]));
      if (isAdmin) state.users = await api('/api/v1/users');
      render();
      syncExportLink();
      delete $('#main').dataset.state;
      $('#splash')?.remove();
    } finally {
      $('#loading').hidden = true;
    }
  }

  /** No data at all: the failure card with a retry replaces the page (the toast would only repeat it). */
  function showLoadFailure(error) {
    $('#splash')?.remove();
    if (state.data) {
      toast(error.message, 'error');
      return;
    }
    $('#main').dataset.state = 'failed';
    const loading = $('#loading');
    loading.setAttribute('aria-busy', 'false');
    loading.hidden = false;
    loading.innerHTML = `<div class="card" role="alert">${emptyState({ iconName: 'error', title: t('ui.load_failed'), text: error.message, action: button({ label: t('ui.retry'), variant: 'primary', iconName: 'refresh', attributes: { 'data-action': 'retry-load' } }) })}</div>`;
  }

  function render() {
    renderToday();
    renderRoomMap();
    renderBookings();
    renderAnalytics();
    renderRooms();
    renderCategories();
    renderGuests();
    renderUsers();
  }

  // ================= TODAY =================
  function kpi(label, value, sub, iconName) {
    return `<div class="kpi"><p class="kpi-label">${icon(iconName)}<span>${h(label)}</span></p><p class="kpi-value">${value}</p><p class="kpi-sub">${h(sub)}</p></div>`;
  }

  function todayRow(s, action) {
    const flags = [
      !s.id_verified && Number(s.status) === 0 ? pill('warning', 'idCard', t('ui.flag.id_pending')) : '',
      !s.deposit_paid && Number(s.deposit_amount_satang) > 0 ? pill('warning', 'wallet', t('ui.flag.deposit_pending', { amount: money(s.deposit_amount_satang) })) : '',
    ].join('');
    return `<li class="flex items-center gap-3 px-4 py-3 sm:px-5">
      <span class="room-no">${h(s.room_name)}</span>
      <div class="min-w-0 flex-1">
        <p class="cell-title truncate">${h(s.guest_name)}</p>
        <p class="cell-sub">${h(s.phone || t('ui.no_phone'))} · ${h(t('ui.guests_count', { n: s.guests }))} · ${h(t('ui.nights_count', { n: nights(s.check_in_date, s.check_out_date) }))}</p>
        ${flags ? `<div class="mt-1.5 flex flex-wrap gap-1.5">${flags}</div>` : ''}
      </div>
      ${action}
    </li>`;
  }

  const listOrEmpty = (items, emptyText) => items.length
    ? `<ul class="divide-y divide-line">${items.join('')}</ul>`
    : `<p class="px-5 py-8 text-center text-sm text-ink-muted">${h(emptyText)}</p>`;

  function renderToday() {
    const { today, stays, rooms } = state.data;
    const arrivals = stays.filter(s => Number(s.status) === 0 && s.check_in_date === today);
    const departures = stays.filter(s => Number(s.status) === 1 && s.check_out_date === today);
    const inHouse = activeStays();
    const unpaid = stays.filter(s => Number(s.status) < 2 && !s.deposit_paid && Number(s.deposit_amount_satang) > 0);
    const occupancy = rooms.length ? Math.round((inHouse.length / rooms.length) * 100) : 0;
    const hour = new Date().getHours();
    const greeting = t(hour < 12 ? 'ui.today.morning' : hour < 17 ? 'ui.today.afternoon' : 'ui.today.evening');
    const notes = stays.filter(s => s.note && Number(s.status) < 2).sort((a, b) => String(b.updated_at).localeCompare(String(a.updated_at))).slice(0, 5);

    $('#today-desk').innerHTML = `
      <div class="section-head">
        <div>
          <p class="eyebrow">${h(longDate(today))}</p>
          <h2 class="page-heading">${h(greeting)}</h2>
        </div>
      </div>
      <div class="kpi-strip kpi-strip-5">
        ${kpi(t('ui.today.arrivals'), number(arrivals.length), t('ui.today.arrivals_sub', { n: arrivals.filter(s => !s.id_verified).length }), 'arrive')}
        ${kpi(t('ui.today.departures'), number(departures.length), t('ui.today.departures_sub'), 'depart')}
        ${kpi(t('ui.today.in_house'), number(inHouse.length), t('ui.guests_count', { n: inHouse.reduce((sum, s) => sum + Number(s.guests), 0) }), 'bed')}
        ${kpi(t('ui.today.occupancy'), `${occupancy}%`, t('ui.today.occupancy_sub', { used: inHouse.length, total: rooms.length }), 'roomMap')}
        ${kpi(t('ui.today.deposits'), number(unpaid.length), money(unpaid.reduce((sum, s) => sum + Number(s.deposit_amount_satang), 0)), 'wallet')}
      </div>
      <div class="mt-6 grid gap-6 md:grid-cols-2">
        <section class="card" aria-labelledby="today-arrivals">
          <div class="card-header"><h3 id="today-arrivals" class="card-title">${h(t('ui.today.arrivals_title'))}</h3>${pill('info', 'arrive', t('ui.items_count', { n: arrivals.length }))}</div>
          ${listOrEmpty(arrivals.map(s => todayRow(s, canBook ? button({ label: t('ui.action.check_in'), variant: 'primary', size: 'sm', iconName: 'arrive', attributes: { 'data-action': 'check-in', 'data-id': s.id } }) : '')), t('ui.today.no_arrivals'))}
        </section>
        <section class="card" aria-labelledby="today-departures">
          <div class="card-header"><h3 id="today-departures" class="card-title">${h(t('ui.today.departures_title'))}</h3>${pill('warning', 'depart', t('ui.items_count', { n: departures.length }))}</div>
          ${listOrEmpty(departures.map(s => todayRow(s, canCheckout ? button({ label: t('ui.action.inspect'), variant: 'primary', size: 'sm', iconName: 'depart', attributes: { 'data-action': 'checkout', 'data-id': s.id } }) : '')), t('ui.today.no_departures'))}
        </section>
      </div>
      <section class="card mt-6" aria-labelledby="today-rooms">
        <div class="card-header"><h3 id="today-rooms" class="card-title">${h(t('ui.today.rooms_title'))}</h3><button type="button" class="link text-sm" data-page="room-map">${h(t('ui.today.open_room_map'))}</button></div>
        <div class="card-body">
          <ul class="flex flex-wrap gap-2">${rooms.map(room => {
            const status = ROOM_STATES[roomStatus(room).key];
            return `<li class="room-dot tone-${status.tone}" title="${h(t('ui.room_label', { name: room.name }))} · ${h(status.label)}">${icon(status.icon)}<span>${h(room.name)}</span><span class="sr-only">${h(status.label)}</span></li>`;
          }).join('')}</ul>
          <p class="mt-3 flex flex-wrap gap-x-4 gap-y-1 text-xs text-ink-muted">${Object.values(ROOM_STATES).map(x => `<span class="inline-flex items-center gap-1.5"><span class="legend-swatch tone-${x.tone}"></span>${h(x.label)}</span>`).join('')}</p>
        </div>
      </section>
      <div class="mt-6 grid gap-6 md:grid-cols-2">
        <section class="card" aria-labelledby="today-deposits">
          <div class="card-header"><h3 id="today-deposits" class="card-title">${h(t('ui.today.deposits_title'))}</h3><button type="button" class="link text-sm" data-page="bookings">${h(t('ui.today.open_bookings'))}</button></div>
          ${listOrEmpty(unpaid.slice(0, 6).map(s => todayRow(s, '')), t('ui.today.no_deposits'))}
        </section>
        <section class="card" aria-labelledby="today-notes">
          <div class="card-header"><h3 id="today-notes" class="card-title">${h(t('ui.today.notes_title'))}</h3></div>
          <div class="card-body">${notes.length ? `<ol class="timeline">${notes.map(s => `
            <li class="timeline-item tone-${STATUS[Number(s.status)].tone}">
              <p class="text-sm font-medium text-ink">${h(t('ui.room_label', { name: s.room_name }))} · ${h(s.guest_name)}</p>
              <p class="mt-0.5 text-sm text-ink-muted">${h(s.note)}</p>
              <p class="mt-0.5 text-xs text-ink-subtle">${h(shortDate(s.check_in_date))} – ${h(shortDate(s.check_out_date))}</p>
            </li>`).join('')}</ol>` : `<p class="py-4 text-center text-sm text-ink-muted">${h(t('ui.today.no_notes'))}</p>`}</div>
        </section>
      </div>`;
  }

  // ================= ROOM BOARD =================
  function renderRoomMap() {
    const rooms = state.data.rooms.map(room => ({ room, ...roomStatus(room) }));
    const zones = byZoneOrder(new Set(rooms.map(x => x.room.zone)));
    const chip = (attr, value, label, count, current, tone = '') => `<button type="button" class="chip" data-${attr}="${h(value)}" aria-pressed="${current === value}">${tone ? `<span class="legend-swatch tone-${tone}"></span>` : ''}<span>${h(label)}</span><span class="count">${count}</span></button>`;

    $('#room-summary').innerHTML = rooms.length ? `
      <div class="chip-row mb-2" role="group" aria-label="${h(t('ui.room_board.state_filter'))}">
        ${chip('room-state', '', t('ui.filter.all'), rooms.length, state.roomState)}
        ${Object.entries(ROOM_STATES).map(([key, x]) => chip('room-state', key, x.label, rooms.filter(r => r.key === key).length, state.roomState, x.tone)).join('')}
      </div>
      ${zones.length > 1 ? `<div class="chip-row mb-5" role="group" aria-label="${h(t('ui.room_board.zone_filter'))}">
        ${chip('room-zone', '', t('ui.room_board.all_zones'), rooms.length, state.roomZone)}
        ${zones.map(zone => chip('room-zone', zone, zone, rooms.filter(r => r.room.zone === zone).length, state.roomZone)).join('')}
      </div>` : '<div class="mb-5"></div>'}` : '';

    if (!rooms.length) {
      $('#room-map').innerHTML = `<div class="card">${emptyState({
        iconName: 'rooms',
        title: t('ui.rooms.empty_title'),
        text: t('ui.rooms.empty_text'),
        action: canManageRooms ? button({ label: t('ui.rooms.new'), variant: 'primary', iconName: 'plus', attributes: { 'data-action': 'new-room' } }) : '',
      })}</div>`;
      return;
    }

    const shown = rooms.filter(x => (!state.roomState || x.key === state.roomState) && (!state.roomZone || x.room.zone === state.roomZone));
    if (!shown.length) {
      $('#room-map').innerHTML = `<div class="card">${emptyState({ iconName: 'roomMap', title: t('ui.room_board.no_match'), action: button({ label: t('ui.filter.clear'), attributes: { 'data-action': 'clear-room-filters' } }) })}</div>`;
      return;
    }

    $('#room-map').innerHTML = byZoneOrder(new Set(shown.map(x => x.room.zone))).map(zone => {
      const inZone = shown.filter(x => x.room.zone === zone);
      return `<section class="mb-8" aria-label="${h(zone)}">
        <h2 class="mb-3 flex items-baseline gap-2 text-base font-semibold">${h(zone)}<span class="text-sm font-normal text-ink-subtle">${h(t('ui.rooms_count', { n: inZone.length }))}</span></h2>
        <div class="room-grid">${inZone.map(({ room, key, stay }) => {
          const status = ROOM_STATES[key];
          const foot = stay
            ? `<p class="truncate font-medium text-ink">${h(stay.guest_name)}</p><p class="text-xs text-ink-subtle">${h(key === 'arriving' ? t('ui.room_board.arrives_today') : t('ui.room_board.leaves', { date: shortDate(stay.check_out_date) }))}</p>`
            : `<p class="flex items-baseline justify-between"><span class="font-medium tabular-nums text-ink">${money(room.price_satang)}</span><span class="text-xs text-ink-subtle">${h(t('ui.per_night'))}</span></p>`;
          return `<button type="button" class="room-tile tone-${status.tone}" data-action="${stay ? 'stay-details' : 'new-booking'}" data-id="${stay?.id || room.id}">
            <span class="flex items-start justify-between gap-2">
              <span><span class="room-tile-no block">${h(room.name)}</span><span class="room-tile-type flex items-center gap-1.5"><span>${h(room.type)}</span>${room.is_pet_friendly ? `${icon('paw', 'h-3.5 w-3.5 shrink-0')}<span class="sr-only">${h(t('ui.pet_friendly'))}</span>` : ''}</span></span>
              ${pill(status.tone, status.icon, status.label)}
            </span>
            <span class="room-tile-foot block">${foot}</span>
          </button>`;
        }).join('')}</div>
      </section>`;
    }).join('');
  }

  // ================= BOOKINGS =================
  const query = id => ($(`#${id}`)?.value || '').trim();

  function filteredStays() {
    const q = query('stay-search').toLocaleLowerCase('th');
    const status = $('#stay-status')?.value ?? '';
    return state.data.stays.filter(s =>
      (status === '' || String(s.status) === status)
      && (!q || [s.guest_name, s.phone, s.room_name, s.zone, s.note].some(v => String(v || '').toLocaleLowerCase('th').includes(q))));
  }

  function stayColumns(q) {
    return [
      {
        key: 'guest', label: t('ui.col.guest'), className: 'cell-lead', value: s => s.guest_name,
        cell: s => {
          const files = attachmentsOf([s.id]);
          return `<p class="cell-title flex items-center gap-1.5"><span>${highlight(s.guest_name, q)}</span>${state.idPhotos?.has(s.id) ? `<span class="text-ink-subtle" title="${h(t('ui.id_photo.on_file'))}">${icon('idCard', 'h-3.5 w-3.5')}<span class="sr-only">${h(t('ui.id_photo.on_file'))}</span></span>` : ''}</p><p class="cell-sub">${highlight(s.phone || t('ui.no_phone'), q)}</p>
            ${s.note ? `<p class="cell-sub cell-note mt-0.5 flex items-start gap-1" title="${h(s.note)}">${icon('note', 'mt-0.5 h-3.5 w-3.5')}<span class="truncate">${highlight(s.note, q)}</span></p>` : ''}
            ${files.length ? `<p class="mt-0.5 flex flex-wrap gap-x-3">${files.map(f => `<a class="link inline-flex min-h-6 items-center gap-1 text-xs" href="/files/${f.id}" target="_blank" rel="noopener">${icon('attachment', 'h-3.5 w-3.5')}${h(f.original_name)}</a>`).join('')}</p>` : ''}`;
        },
      },
      { key: 'room', label: t('ui.col.room'), className: 'whitespace-nowrap', value: s => s.room_name, cell: s => `<span class="inline-flex items-center gap-2"><span class="room-no">${highlight(s.room_name, q)}</span><span class="cell-sub tablet-hide">${highlight(s.zone, q)}</span></span>` },
      { key: 'check_in', label: t('ui.col.check_in'), className: 'whitespace-nowrap', firstDir: 'desc', value: s => s.check_in_date, cell: s => `<time datetime="${s.check_in_date}">${h(thaiDate(s.check_in_date))}</time><span class="cell-sub tablet-only">→ <time datetime="${s.check_out_date}">${h(thaiDate(s.check_out_date))}</time></span>` },
      { key: 'check_out', label: t('ui.col.check_out'), className: 'whitespace-nowrap', tabletHide: true, firstDir: 'desc', value: s => s.check_out_date, cell: s => `<time datetime="${s.check_out_date}">${h(thaiDate(s.check_out_date))}</time>` },
      { key: 'nights', label: t('ui.col.nights'), num: true, optional: true, mobileHide: true, tabletHide: true, value: s => nights(s.check_in_date, s.check_out_date), cell: s => number(nights(s.check_in_date, s.check_out_date)) },
      { key: 'guests', label: t('ui.col.guests'), num: true, optional: true, mobileHide: true, tabletHide: true, value: s => Number(s.guests), cell: s => number(s.guests) },
      {
        key: 'status', label: t('ui.col.status'), value: s => Number(s.status),
        cell: s => `<span class="inline-flex flex-wrap justify-end gap-1 sm:justify-start">${statusPill(s.status)}${!s.deposit_paid && Number(s.deposit_amount_satang) > 0 && Number(s.status) < 2 ? pill('warning', 'wallet', t('ui.flag.deposit_short')) : ''}</span>`,
      },
      { key: 'channel', label: t('ui.col.channel'), optional: true, mobileHide: true, tabletHide: true, value: s => channelLabel(s.booking_channel), cell: s => `<span class="${s.booking_channel ? 'text-ink' : 'text-ink-subtle'}">${h(channelLabel(s.booking_channel))}</span>` },
      { key: 'total', label: t('ui.col.total'), num: true, firstDir: 'desc', value: s => Number(s.total_amount_satang), cell: s => money(s.total_amount_satang) },
      { key: 'balance', label: t('ui.col.balance'), num: true, optional: true, mobileHide: true, tabletHide: true, firstDir: 'desc', value: balanceOf, cell: s => `<span class="${balanceOf(s) ? 'text-ink' : 'text-ink-subtle'}">${money(balanceOf(s))}</span>` },
      { key: 'actions', label: t('ui.col.actions'), hideLabel: true, className: 'actions', cell: s => `<span class="inline-flex items-center gap-1">${primaryStayAction(s)}${menuTriggerButton({ context: 'stay', id: s.id, label: t('ui.booking.menu', { room: s.room_name }), size: 'sm' })}</span>` },
    ];
  }

  function renderStatusChips() {
    const current = $('#stay-status').value;
    const counts = [0, 1, 2].map(x => state.data.stays.filter(s => Number(s.status) === x).length);
    $('#stay-status-chips').innerHTML = [
      `<button type="button" class="chip" data-stay-status="" aria-pressed="${current === ''}"><span>${h(t('ui.filter.all'))}</span><span class="count">${state.data.stays.length}</span></button>`,
      ...STATUS.map((x, i) => `<button type="button" class="chip" data-stay-status="${i}" aria-pressed="${current === String(i)}"><span class="legend-swatch tone-${x.tone}"></span><span>${h(x.label)}</span><span class="count">${counts[i]}</span></button>`),
    ].join('');
  }

  function renderBookings() {
    if (!state.data) return;
    renderStatusChips();
    const q = query('stay-search');
    $('#booking-list').innerHTML = renderTable({
      state: state.tables.bookings,
      columns: stayColumns(q),
      rows: filteredStays(),
      caption: t('ui.nav.bookings'),
      empty: `<div class="card">${emptyState({
        iconName: 'bookings',
        title: t('ui.bookings.empty_title'),
        text: t('ui.bookings.empty_text'),
        action: [
          q || $('#stay-status').value ? clearSearchButton('bookings') : '',
          canBook ? button({ label: t('ui.booking.new'), variant: 'primary', iconName: 'plus', attributes: { 'data-action': 'new-booking' } }) : '',
        ].join(''),
      })}</div>`,
    });
    renderCalendar();
  }

  const clearSearchButton = list => button({ label: t('ui.search.clear'), iconName: 'close', attributes: { 'data-action': 'clear-search', 'data-list': list } });

  // Room chart: one row per room, one column per night of the month, one bar per booking (guest name + status icon).
  // Bars follow the list's search and status filters; a bar opens the booking menu, a day header lists that day below.
  function renderCalendar() {
    const month = state.calendar.getMonth();
    const year = state.calendar.getFullYear();
    const first = new Date(year, month, 1);
    const days = new Date(year, month + 1, 0).getDate();
    const start = iso(first);
    const end = iso(new Date(year, month, days + 1));
    const dayIndex = date => Math.round((new Date(`${date}T00:00:00`) - first) / 86400000);
    const weekday = new Intl.DateTimeFormat('th-TH', { weekday: 'narrow' });
    state.selectedDay ??= state.data.today;

    const dates = Array.from({ length: days }, (_, i) => new Date(year, month, i + 1));
    const header = dates.map((d, i) => {
      const date = iso(d);
      const weekend = d.getDay() === 0 || d.getDay() === 6;
      return `<button type="button" class="tl-day ${weekend ? 'is-weekend' : ''} ${date === state.data.today ? 'is-today' : ''}" style="grid-column:${i + 2}" data-calendar-day="${date}" aria-pressed="${state.selectedDay === date}">
        <span class="tl-weekday" aria-hidden="true">${h(weekday.format(d))}</span><span class="tl-date" aria-hidden="true">${i + 1}</span><span class="sr-only">${h(thaiDate(date))}</span>
      </button>`;
    }).join('');

    const stays = filteredStays().filter(s => s.check_in_date < end && s.check_out_date > start);
    const rows = state.data.rooms.map((room, r) => {
      const row = r + 2;
      const cells = dates.map((d, i) => `<div class="tl-cell ${d.getDay() === 0 || d.getDay() === 6 ? 'is-weekend' : ''} ${iso(d) === state.data.today ? 'is-today' : ''}" style="grid-row:${row};grid-column:${i + 2}" aria-hidden="true"></div>`).join('');
      // Checked-out bars first, so a current booking is drawn on top if an old one overlaps it.
      const bars = stays.filter(s => s.room_id === room.id).sort((a, b) => Number(b.status === 2) - Number(a.status === 2) || a.check_in_date.localeCompare(b.check_in_date)).map(s => {
        const from = Math.max(0, dayIndex(s.check_in_date));
        const to = Math.min(days, dayIndex(s.check_out_date));
        const status = STATUS[Number(s.status)] ?? STATUS[0];
        const n = nights(s.check_in_date, s.check_out_date);
        const label = [s.guest_name, `${t('ui.col.room')} ${s.room_name}`, `${thaiDate(s.check_in_date)} – ${thaiDate(s.check_out_date)}`, t('ui.nights_count', { n }), t('ui.guests_count', { n: s.guests }), status.label].join(' · ');
        const classes = ['tl-bar', `tone-${status.tone}`, dayIndex(s.check_in_date) < 0 ? 'is-cont-start' : '', dayIndex(s.check_out_date) > days ? 'is-cont-end' : ''].filter(Boolean).join(' ');
        return `<button type="button" class="${classes}" style="grid-row:${row};grid-column:${from + 2} / ${to + 2}" data-menu-trigger="stay" data-id="${s.id}" title="${h(label)}">
          ${icon(status.icon, 'h-3.5 w-3.5 flex-none')}<span class="truncate">${h(barName(s.guest_name))}</span>${to - from > 2 ? `<span class="tl-bar-meta">${h(t('ui.nights_count', { n }))}</span>` : ''}<span class="sr-only"> · ${h(label)}</span>
        </button>`;
      }).join('');
      return `<div class="tl-room" style="grid-row:${row}"><span class="room-no">${h(room.name)}</span><span class="tl-room-meta">${h(room.type)}</span></div>${cells}${bars}`;
    }).join('');

    const selected = state.data.stays.filter(s => s.check_in_date <= state.selectedDay && s.check_out_date >= state.selectedDay);
    const key = `${year}-${month}`;
    const keep = state.calendarShown === key ? $('#booking-calendar .tl-scroll')?.scrollLeft : undefined;
    $('#booking-calendar').innerHTML = `
      <div class="card">
        <div class="card-header flex-wrap gap-3">
          <div class="flex items-center gap-1">
            ${button({ label: t('ui.calendar.previous'), iconName: 'chevronLeft', iconOnly: true, variant: 'ghost', size: 'sm', attributes: { 'data-calendar-nav': '-1' } })}
            <h2 class="min-w-[9rem] text-center text-base font-semibold" aria-live="polite">${h(monthTitle(first))}</h2>
            ${button({ label: t('ui.calendar.next'), iconName: 'chevronRight', iconOnly: true, variant: 'ghost', size: 'sm', attributes: { 'data-calendar-nav': '1' } })}
          </div>
          <div class="flex flex-wrap items-center gap-2">
            <span class="tl-legend">${STATUS.map(x => pill(x.tone, x.icon, x.label)).join('')}</span>
            ${button({ label: t('ui.calendar.today'), size: 'sm', iconName: 'calendar', attributes: { 'data-calendar-today': true } })}
          </div>
        </div>
        <p class="px-4 pt-3 text-sm text-ink-muted sm:px-5">${h(t('ui.calendar.hint'))}</p>
        <div class="tl-scroll" tabindex="0" role="region" aria-label="${h(t('ui.calendar.scroll'))}">
          <div class="tl-grid" style="--tl-days:${days}">
            <div class="tl-corner">${h(t('ui.col.room'))}</div>
            ${header}
            ${rows}
          </div>
        </div>
      </div>
      <section class="mt-6" aria-labelledby="calendar-day-title">
        <h3 id="calendar-day-title" class="mb-3 flex items-center gap-2 text-base font-semibold">${icon('calendar', 'text-ink-subtle')}<span>${h(t('ui.calendar.day_title', { date: thaiDate(state.selectedDay) }))}</span></h3>
        ${renderTable({ state: state.tables.day, columns: stayColumns(''), rows: selected, caption: thaiDate(state.selectedDay), paginate: false, empty: `<div class="card">${emptyState({ iconName: 'calendar', title: t('ui.calendar.empty') })}</div>` })}
      </section>`;
    if (keep !== undefined) $('#booking-calendar .tl-scroll').scrollLeft = keep;
    else scrollCalendar();
    state.calendarShown = key;
  }

  // Bars are narrow, so they drop the honorific; the full name stays in the label and tooltip.
  const barName = name => name.replace(/^คุณ\s*/, '') || name;

  // Brings the selected day (or today) into view, a day after the sticky room column.
  function scrollCalendar() {
    const scroller = $('#booking-calendar .tl-scroll');
    const day = scroller?.querySelector(`[data-calendar-day="${state.selectedDay}"]`) ?? scroller?.querySelector('.tl-day.is-today');
    if (!scroller || !day || !scroller.offsetWidth) return;
    const room = scroller.querySelector('.tl-corner').offsetWidth;
    scroller.scrollLeft = Math.max(0, day.offsetLeft - room - day.offsetWidth);
  }

  const channelLabel = code => (code && [...$('#booking-channel').options].find(o => o.value === code)?.text) || t('ui.channel.none');

  // ================= REPORTS =================
  function breakdown(title, parts) {
    const total = Math.max(1, parts.reduce((sum, p) => sum + p.value, 0));
    return `<section class="card" aria-label="${h(title)}">
      <div class="card-header"><h2 class="card-title">${h(title)}</h2></div>
      <div class="card-body">
        <div class="stack-bar" aria-hidden="true">${parts.filter(p => p.value).map(p => `<span class="tone-${p.tone}" style="width:${(p.value / total) * 100}%"></span>`).join('')}</div>
        <ul class="mt-4 space-y-2 text-sm">${parts.map(p => `<li class="flex items-center justify-between gap-3"><span class="inline-flex items-center gap-2 text-ink-muted"><span class="legend-swatch tone-${p.tone}"></span>${h(p.label)}</span><span class="tabular-nums text-ink">${number(p.value)} <span class="text-ink-subtle">· ${Math.round((p.value / total) * 100)}%</span></span></li>`).join('')}</ul>
      </div>
    </section>`;
  }

  const figureGroup = (title, items) => `<section aria-label="${h(title)}"><h2 class="mb-2 text-sm font-medium text-ink-muted">${h(title)}</h2><dl class="figure-list">${items.map(([label, value]) => `<div class="figure"><dt>${h(label)}</dt><dd>${value}</dd></div>`).join('')}</dl></section>`;

  function chartCard(id, title, subtitle, total, points, table) {
    return `<section class="card" aria-labelledby="${id}-title">
      <div class="card-header items-start">
        <div><h2 id="${id}-title" class="card-title">${h(title)}</h2><p class="text-sm text-ink-muted">${h(subtitle)}</p></div>
        <p class="text-base font-semibold tabular-nums text-ink">${total}</p>
      </div>
      <div class="card-body">
        ${barChart(points)}
        <button type="button" class="link no-print mt-3 text-sm" data-toggle-table="${id}-table" aria-expanded="false" aria-controls="${id}-table">${h(t('ui.reports.show_table'))}</button>
        ${chartTable({ id: `${id}-table`, ...table })}
      </div>
    </section>`;
  }

  // Bookings that start in the report range, grouped by channel; revenue counts checked-in and checked-out stays only,
  // like the net revenue figure above.
  function channelCard(a) {
    const started = state.data.stays.filter(s => s.check_in_date >= a.start && s.check_in_date <= a.end);
    const codes = [...[...$('#booking-channel').options].map(o => o.value).filter(Boolean), ''];
    const rows = codes.map(code => {
      const stays = started.filter(s => (codes.includes(s.booking_channel) ? s.booking_channel : '') === code);
      const billable = stays.filter(s => Number(s.status) !== 0);
      return {
        code,
        label: channelLabel(code),
        count: stays.length,
        guests: stays.reduce((sum, s) => sum + Number(s.guests), 0),
        nights: stays.reduce((sum, s) => sum + nights(s.check_in_date, s.check_out_date), 0),
        revenue: billable.reduce((sum, s) => sum + Number(s.total_amount_satang), 0),
      };
    }).filter(r => r.count).sort((x, y) => (x.code === '') - (y.code === '') || y.count - x.count);
    const total = started.length;
    const share = r => (total ? Math.round((r.count / total) * 100) : 0);
    const top = rows.find(r => r.code && r.count);
    return `<section class="card mt-6" aria-labelledby="channels-title">
      <div class="card-header items-start">
        <div><h2 id="channels-title" class="card-title">${h(t('ui.reports.channels_title'))}</h2><p class="text-sm text-ink-muted">${h(t('ui.reports.channels_sub'))}</p></div>
        ${top ? `<p class="text-sm text-ink-muted">${h(t('ui.reports.channels_top'))} <span class="font-semibold text-ink">${h(top.label)}</span> <span class="tabular-nums">${share(top)}%</span></p>` : ''}
      </div>
      <div class="table-wrap">
        <table class="data-table">
          <caption class="sr-only">${h(t('ui.reports.channels_title'))}</caption>
          <thead><tr>
            <th scope="col">${h(t('ui.col.channel'))}</th>
            <th scope="col" class="num">${h(t('ui.reports.bookings'))}</th>
            <th scope="col" class="hidden w-1/4 sm:table-cell">${h(t('ui.reports.channels_share'))}</th>
            <th scope="col" class="num hidden xl:table-cell">${h(t('ui.reports.guests'))}</th>
            <th scope="col" class="num hidden xl:table-cell">${h(t('ui.reports.room_nights'))}</th>
            <th scope="col" class="num">${h(t('ui.reports.net_revenue'))}</th>
          </tr></thead>
          <tbody>${rows.map(r => `<tr>
            <td class="font-medium ${r.code ? 'text-ink' : 'text-ink-subtle'}">${h(r.label)}</td>
            <td class="num">${number(r.count)} <span class="text-ink-subtle">· ${share(r)}%</span></td>
            <td class="hidden sm:table-cell"><div class="stack-bar" aria-hidden="true">${r.count ? `<span class="tone-primary" style="width:${share(r)}%"></span>` : ''}</div></td>
            <td class="num hidden xl:table-cell">${number(r.guests)}</td>
            <td class="num hidden xl:table-cell">${number(r.nights)}</td>
            <td class="num">${money(r.revenue)}</td>
          </tr>`).join('') || `<tr><td colspan="6" class="py-6 text-center text-ink-subtle">${h(t('ui.reports.channels_empty'))}</td></tr>`}</tbody>
        </table>
      </div>
    </section>`;
  }

  function renderAnalytics() {
    const a = state.data.analytics;
    const percent = value => `${(value * 100).toFixed(1)}%`;
    $('#report-print-range').textContent = `${thaiDate(a.start)} – ${thaiDate(a.end)}`;
    $('#analytics').innerHTML = `
      <div class="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
        ${figureGroup(t('ui.reports.group.stays'), [
          [t('ui.reports.bookings'), number(a.booking_count)],
          [t('ui.reports.checked_in'), number(a.check_in_count)],
          [t('ui.reports.checked_out'), number(a.check_out_count)],
          [t('ui.reports.guests'), h(t('ui.guests_count', { n: number(a.guest_count) }))],
          [t('ui.reports.room_nights'), h(t('ui.nights_count', { n: number(a.occupied_room_nights) }))],
          [t('ui.reports.occupancy'), percent(a.occupancy_rate)],
        ])}
        ${figureGroup(t('ui.reports.group.money'), [
          [t('ui.reports.net_revenue'), money(a.net_revenue_satang)],
          [t('ui.reports.discounts'), money(a.discount_satang)],
          [t('ui.reports.deposits_received'), money(a.deposit_received_satang)],
          [t('ui.reports.deposits_pending'), money(a.deposit_pending_satang)],
        ])}
        ${figureGroup(t('ui.reports.group.other'), [
          [t('ui.reports.pet_bookings'), number(a.pet_bookings)],
        ])}
      </div>
      <div class="mt-6 grid gap-6 lg:grid-cols-2">
        ${chartCard('revenue', t('ui.reports.revenue_title'), t('ui.reports.revenue_sub'), money(a.net_revenue_satang), {
          label: t('ui.reports.revenue_title'),
          format: value => money(Math.round(value)),
          points: a.daily.map(d => ({ label: d.date.slice(8), value: Number(d.revenue_satang), title: `${thaiDate(d.date)}: ${money(d.revenue_satang)}` })),
        }, { caption: t('ui.reports.revenue_title'), headers: [t('ui.col.date'), t('ui.reports.net_revenue')], rows: a.daily.map(d => [thaiDate(d.date), money(d.revenue_satang)]) })}
        ${chartCard('occupancy', t('ui.reports.occupancy_title'), t('ui.reports.occupancy_sub', { n: a.total_rooms }), percent(a.occupancy_rate), {
          label: t('ui.reports.occupancy_title'),
          format: value => number(Math.round(value)),
          points: a.daily.map(d => ({ label: d.date.slice(8), value: d.occupied, title: `${thaiDate(d.date)}: ${d.occupied}/${a.total_rooms}` })),
        }, { caption: t('ui.reports.occupancy_title'), headers: [t('ui.col.date'), t('ui.reports.rooms_used')], rows: a.daily.map(d => [thaiDate(d.date), `${d.occupied}/${a.total_rooms}`]) })}
      </div>
      <div class="mt-6 grid gap-6 md:grid-cols-2">
        ${breakdown(t('ui.reports.status_title'), [
          { label: STATUS[0].label, value: a.statuses.booked, tone: STATUS[0].tone },
          { label: STATUS[1].label, value: a.statuses.checked_in, tone: STATUS[1].tone },
          { label: STATUS[2].label, value: a.statuses.checked_out, tone: STATUS[2].tone },
        ])}
        ${breakdown(t('ui.reports.deposit_title'), [
          { label: t('ui.reports.deposit_paid'), value: a.deposits.paid, tone: 'success' },
          { label: t('ui.reports.deposit_unpaid'), value: a.deposits.unpaid, tone: 'warning' },
          { label: t('ui.reports.deposit_none'), value: a.deposits.none, tone: 'neutral' },
        ])}
      </div>
      ${channelCard(a)}`;
  }

  // ================= ROOMS =================
  function renderRooms() {
    if (!state.data) return;
    const columns = [
      { key: 'room', label: t('ui.col.room'), className: 'cell-lead', value: r => r.name, cell: r => `<span class="inline-flex items-center gap-3"><span class="room-no">${h(r.name)}</span><span><span class="cell-title block">${h(r.type)}</span><span class="cell-sub block md:hidden">${h(r.zone)}</span></span></span>` },
      { key: 'zone', label: t('ui.col.zone'), mobileHide: true, tabletHide: true, value: r => r.zone, cell: r => h(r.zone) },
      { key: 'price', label: t('ui.col.price'), num: true, value: r => Number(r.price_satang), cell: r => money(r.price_satang) },
      { key: 'capacity', label: t('ui.col.capacity'), num: true, value: r => Number(r.max_guests), cell: r => `${number(r.base_guests)}–${number(r.max_guests)}` },
      { key: 'extra_fee', label: t('ui.col.extra_fee'), num: true, optional: true, tabletHide: true, value: r => Number(r.extra_guest_fee_satang), cell: r => money(r.extra_guest_fee_satang) },
      { key: 'pet', label: t('ui.col.pet'), value: r => (r.is_pet_friendly ? 1 : 0), cell: r => r.is_pet_friendly ? pill('accent', 'paw', t('ui.pet_friendly')) : `<span class="text-ink-subtle">${h(t('ui.no'))}</span>` },
      { key: 'actions', label: t('ui.col.actions'), hideLabel: true, className: 'actions', cell: r => `<span class="inline-flex items-center gap-1">${button({ label: t('ui.edit'), size: 'sm', iconName: 'edit', attributes: { 'data-action': 'edit-room', 'data-id': r.id, 'data-row-primary': true, title: t('ui.edit') } })}${menuTriggerButton({ context: 'room', id: r.id, label: t('ui.rooms.menu', { name: r.name }), size: 'sm' })}</span>` },
    ];
    $('#rooms-list').innerHTML = renderTable({
      state: state.tables.rooms,
      columns,
      rows: state.data.rooms,
      caption: t('ui.rooms.title'),
      empty: `<div class="card">${emptyState({ iconName: 'rooms', title: t('ui.rooms.empty_title'), text: t('ui.rooms.empty_text'), action: button({ label: t('ui.rooms.new'), variant: 'primary', iconName: 'plus', attributes: { 'data-action': 'new-room' } }) })}</div>`,
    });
  }

  // ================= ZONES AND ROOM TYPES =================
  const zoneRank = zone => {
    const index = state.categories?.zones.findIndex(z => z.name === zone) ?? -1;
    return index < 0 ? Number.MAX_SAFE_INTEGER : index;
  };
  const byZoneOrder = names => [...names].sort((a, b) => zoneRank(a) - zoneRank(b) || a.localeCompare(b, 'th'));

  function renderCategories() {
    if (!state.categories) return;
    const order = { key: 'order', label: t('ui.category.order_short'), num: true, optional: true, mobileHide: true, value: x => Number(x.sort_order), cell: x => number(x.sort_order) };
    const used = { key: 'rooms', label: t('ui.col.rooms_using'), num: true, firstDir: 'desc', value: x => Number(x.room_count), cell: x => number(x.room_count) };
    const actions = kind => ({
      key: 'actions', label: t('ui.col.actions'), hideLabel: true, className: 'actions',
      cell: x => `<span class="inline-flex items-center gap-1">${button({ label: t('ui.edit'), size: 'sm', iconName: 'edit', attributes: { 'data-action': `edit-${kind}`, 'data-id': x.id, 'data-row-primary': true, title: t('ui.edit') } })}${menuTriggerButton({ context: kind, id: x.id, label: t(`ui.${kind}s.menu`, { name: x.name }), size: 'sm' })}</span>`,
    });
    const empty = kind => `<div class="card">${emptyState({ iconName: kind === 'zone' ? 'roomMap' : 'rooms', title: t(`ui.${kind}s.empty_title`), text: t(`ui.${kind}s.empty_text`), action: button({ label: t(`ui.${kind}s.new`), variant: 'primary', iconName: 'plus', attributes: { 'data-action': `new-${kind}` } }) })}</div>`;

    $('#zone-list').innerHTML = renderTable({
      state: state.tables.zones,
      columns: [
        { key: 'name', label: t('ui.col.zone'), className: 'cell-lead', value: z => z.name, cell: z => `<span class="cell-title">${h(z.name)}</span>` },
        used, order, actions('zone'),
      ],
      rows: state.categories.zones,
      caption: t('ui.zones.title'),
      empty: empty('zone'),
    });
    $('#type-list').innerHTML = renderTable({
      state: state.tables.types,
      columns: [
        { key: 'name', label: t('ui.col.type'), className: 'cell-lead', value: x => x.name, cell: x => `<span class="cell-title">${h(x.name)}</span>${x.is_pet_friendly ? ` <span class="ml-1">${pill('accent', 'paw', t('ui.pet_friendly'))}</span>` : ''}` },
        { key: 'price', label: t('ui.col.price'), num: true, value: x => Number(x.price_satang), cell: x => money(x.price_satang) },
        { key: 'capacity', label: t('ui.col.capacity'), num: true, value: x => Number(x.max_guests), cell: x => `${number(x.base_guests)}–${number(x.max_guests)}` },
        { key: 'extra_fee', label: t('ui.col.extra_fee'), num: true, optional: true, tabletHide: true, mobileHide: true, value: x => Number(x.extra_guest_fee_satang), cell: x => money(x.extra_guest_fee_satang) },
        used, order, actions('type'),
      ],
      rows: state.categories.types,
      caption: t('ui.types.title'),
      empty: empty('type'),
    });
  }

  function openCategory(kind, id = null) {
    const f = $(`#${kind}-form`);
    f.reset();
    clearErrors(f);
    f.elements.id.value = '';
    const list = kind === 'zone' ? state.categories.zones : state.categories.types;
    if (id) {
      const x = list.find(item => item.id === id);
      fillForm(f, kind === 'zone' ? x : { ...x, price: Number(x.price_satang) / 100, extra_guest_fee: Number(x.extra_guest_fee_satang) / 100 });
    } else {
      f.elements.sort_order.value = list.length + 1;
    }
    $(`#${kind}-dialog [data-dialog-title]`).textContent = t(id ? `ui.${kind}s.edit` : `ui.${kind}s.new`);
    f.querySelector('[data-submit-label]').textContent = t(id ? 'ui.save' : `ui.${kind}s.new`);
    resetDirty(f);
    $(`#${kind}-dialog`).showModal();
  }

  /** Room form choices; a value no longer in the list (renamed elsewhere) stays selectable for that room. */
  function categoryOptions(list, selected) {
    const names = list.map(x => x.name);
    if (selected && !names.includes(selected)) names.unshift(selected);
    return names.map(name => `<option value="${h(name)}" ${name === selected ? 'selected' : ''}>${h(name)}</option>`).join('');
  }

  /** Choosing a type fills in its room defaults; staff can still change them. */
  function applyTypeDefaults(form) {
    const type = state.categories?.types.find(x => x.name === form.elements.type.value);
    if (!type) return;
    fillForm(form, {
      price: Number(type.price_satang) / 100,
      extra_guest_fee: Number(type.extra_guest_fee_satang) / 100,
      base_guests: type.base_guests,
      max_guests: type.max_guests,
      is_pet_friendly: type.is_pet_friendly,
    });
  }

  function showRoomSetupTab(name) {
    navigate('rooms');
    selectTab($(`#rooms-tab-${name}`), true);
  }

  // ================= USERS =================
  const ROLE_TONES = { admin: 'primary', front_desk: 'info', housekeeping: 'neutral' };
  const userStatus = u => !u.active
    ? pill('neutral', 'userX', t('ui.users.status.inactive'))
    : u.locked_until ? pill('warning', 'lock', t('ui.users.status.locked')) : pill('success', 'userCheck', t('ui.users.status.active'));

  function renderUsers() {
    if (!isAdmin || !state.users) return;
    $('#user-list').innerHTML = renderTable({
      state: state.tables.users,
      columns: [
        {
          key: 'name', label: t('ui.col.user'), className: 'cell-lead', value: u => u.name,
          cell: u => `<span class="flex items-center gap-3"><span class="avatar" aria-hidden="true">${h([...u.name][0] || '?')}</span><span class="min-w-0"><span class="cell-title block">${h(u.name)}${u.id === state.me ? ` <span class="text-xs font-normal text-ink-subtle">(${h(t('ui.users.you'))})</span>` : ''}</span><span class="cell-sub block truncate">${h(u.email)}</span></span></span>`,
        },
        { key: 'role', label: t('ui.users.role'), value: u => u.role, cell: u => pill(ROLE_TONES[u.role] || 'neutral', '', t(`ui.role.${u.role}`)) },
        { key: 'status', label: t('ui.col.status'), value: u => (u.active ? 0 : 1), cell: userStatus },
        {
          key: 'actions', label: t('ui.col.actions'), hideLabel: true, className: 'actions',
          cell: u => `<span class="inline-flex items-center gap-1">${button({ label: t('ui.edit'), size: 'sm', iconName: 'edit', attributes: { 'data-action': 'edit-user', 'data-id': u.id, 'data-row-primary': true, title: t('ui.edit') } })}${menuTriggerButton({ context: 'user', id: u.id, label: t('ui.users.menu', { name: u.name }), size: 'sm' })}</span>`,
        },
      ],
      rows: state.users,
      caption: t('ui.users.title'),
      empty: '',
    });
  }

  const userMenuItems = u => [
    { action: 'reset-password', id: u.id, label: t('ui.users.reset_title'), icon: 'key' },
    { separator: true },
    u.active
      ? { action: 'deactivate-user', id: u.id, label: u.id === state.me ? t('ui.users.cannot_deactivate_self') : t('ui.users.deactivate'), icon: 'userX', destructive: u.id !== state.me, disabled: u.id === state.me }
      : { action: 'activate-user', id: u.id, label: t('ui.users.activate'), icon: 'userCheck' },
  ];

  function showRoleHint(form) {
    form.querySelector('[data-role-hint]').textContent = t(`ui.users.role_hint.${form.elements.role.value}`);
  }

  function openUser(id = null) {
    const f = $('#user-form');
    f.reset();
    clearErrors(f);
    f.elements.id.value = '';
    const u = id ? state.users.find(x => x.id === id) : null;
    if (u) fillForm(f, u);
    f.querySelector('[data-new-user-only]').hidden = Boolean(u);
    f.querySelectorAll('[data-new-user-only] input').forEach(input => { input.disabled = Boolean(u); });
    // An admin cannot change their own role; the server enforces it too.
    f.elements.role.disabled = u?.id === state.me;
    showRoleHint(f);
    $('#user-dialog [data-dialog-title]').textContent = t(u ? 'ui.users.edit' : 'ui.users.new');
    f.querySelector('[data-submit-label]').textContent = t(u ? 'ui.save' : 'ui.users.new');
    resetDirty(f);
    $('#user-dialog').showModal();
  }

  function openPasswordDialog(kind, id = null) {
    const f = $(`#${kind}-form`);
    f.reset();
    clearErrors(f);
    f.elements.id.value = id || '';
    if (kind === 'reset-password') {
      const u = state.users.find(x => x.id === id);
      $('#reset-password-dialog [data-dialog-sub]').textContent = t('ui.users.reset_for', { name: u?.name || '' });
    }
    resetDirty(f);
    $(`#${kind}-dialog`).showModal();
  }

  // ================= GUESTS =================
  const guestSortKeys = { name: 'name', count: 'count', value: 'value', latest: 'latest' };

  function renderGuests() {
    const q = query('guest-search');
    const needle = q.toLocaleLowerCase('th');
    let list = [...state.data.guests];
    if (needle) list = list.filter(g => [g.name, g.phone].some(v => String(v).toLocaleLowerCase('th').includes(needle)));
    if ($('#regular-only')?.checked) list = list.filter(g => g.is_regular);
    const columns = [
      {
        key: 'name', label: t('ui.col.guest'), className: 'cell-lead', value: g => g.name,
        cell: g => `<span class="flex items-center gap-3"><span class="avatar" aria-hidden="true">${h([...g.name][0] || '?')}</span><span class="min-w-0"><button type="button" class="cell-title text-left hover:underline" data-action="guest-details" data-id="${g.id}" data-row-primary>${highlight(g.name, q)}</button><span class="cell-sub flex flex-wrap items-center gap-1.5">${h(g.customer_type || '')}${g.is_regular ? pill('accent', 'star', t('ui.guest.regular_short')) : ''}</span></span></span>`,
      },
      { key: 'phone', label: t('ui.col.phone'), value: g => g.phone, cell: g => highlight(g.phone, q) },
      { key: 'count', label: t('ui.col.stays'), num: true, firstDir: 'desc', value: g => Number(g.completed_stays), cell: g => number(g.completed_stays) },
      { key: 'nights', label: t('ui.col.nights'), num: true, optional: true, mobileHide: true, tabletHide: true, firstDir: 'desc', value: g => Number(g.total_nights), cell: g => number(g.total_nights) },
      { key: 'value', label: t('ui.col.lifetime'), num: true, firstDir: 'desc', value: g => Number(g.lifetime_value_satang), cell: g => money(g.lifetime_value_satang) },
      { key: 'latest', label: t('ui.col.last_stay'), className: 'whitespace-nowrap', tabletHide: true, firstDir: 'desc', value: g => g.last_stay_date || '', cell: g => g.last_stay_date ? `<time datetime="${g.last_stay_date}">${h(thaiDate(g.last_stay_date))}</time> <span class="cell-sub">${h(t('ui.room_label', { name: g.last_room_name || '' }))}</span>` : '<span class="text-ink-subtle">—</span>' },
    ];
    $('#guest-list').innerHTML = renderTable({
      state: state.tables.guests,
      columns,
      rows: list,
      caption: t('ui.nav.guests'),
      empty: `<div class="card">${emptyState({ iconName: 'guests', title: t('ui.guests.empty_title'), text: t('ui.guests.empty_text'), action: query('guest-search') || $('#regular-only')?.checked ? clearSearchButton('guests') : '' })}</div>`,
    });
    if (guestSortKeys[state.tables.guests.sort]) $('#guest-sort').value = state.tables.guests.sort;
  }

  // ================= NAVIGATION =================
  function navigate(page, updateHash = true) {
    if (!pages[page]) return;
    if (page === 'rooms' && !canManageRooms) page = 'today';
    if (page === 'users' && !isAdmin) page = 'today';
    state.page = page;
    $$('[data-page-panel]').forEach(x => { x.hidden = x.id !== `page-${page}`; });
    $$('.nav-item[data-page], .tab-item[data-page]').forEach(x => {
      const current = x.dataset.page === page;
      x.classList.toggle('active', current);
      if (current) x.setAttribute('aria-current', 'page');
      else x.removeAttribute('aria-current');
    });
    $('#page-title').textContent = t(pages[page][0]);
    $('#page-group').textContent = t(pages[page][1]);
    if (updateHash && window.location.hash !== `#${page}`) history.pushState(null, '', `#${page}`);
  }

  function syncExportLink() {
    const link = $('a[href^="/api/v1/reports/bookings.csv"]');
    if (!link) return;
    link.href = `/api/v1/reports/bookings.csv?${new URLSearchParams({ start: $('#range-start').value, end: $('#range-end').value })}`;
  }

  // ================= COMMAND PALETTE =================
  function renderCommands() {
    const q = ($('#command-search').value || '').trim();
    const needle = q.toLocaleLowerCase('th');
    const menu = [
      ['today', 'today', 'ui.nav.today', 'ui.command.today'],
      ['room-map', 'roomMap', 'ui.nav.room_map', 'ui.command.room_map'],
      ['bookings', 'bookings', 'ui.nav.bookings', 'ui.command.bookings'],
      ['guests', 'guests', 'ui.nav.guests', 'ui.command.guests'],
      ['dashboard', 'reports', 'ui.nav.reports', 'ui.command.reports'],
      ...(canManageRooms ? [['rooms', 'rooms', 'ui.nav.rooms', 'ui.command.rooms']] : []),
    ].map(([page, iconName, title, detail]) => [page, iconName, t(title), t(detail)])
      .filter(([, , title, detail]) => !needle || `${title} ${detail}`.toLocaleLowerCase('th').includes(needle));
    const stays = state.data.stays.filter(s => !needle || [s.guest_name, s.phone, s.room_name].some(v => String(v || '').toLocaleLowerCase('th').includes(needle))).slice(0, 6);
    const item = (attr, value, iconName, title, detail) => `<button type="button" class="action-menu-item h-auto py-2" data-${attr}="${value}">${icon(iconName, 'text-ink-subtle')}<span class="min-w-0 flex-1"><span class="block truncate font-medium">${title}</span><span class="block truncate text-xs text-ink-subtle">${detail}</span></span></button>`;
    $('#command-results').innerHTML = `
      ${menu.length ? `<p class="action-menu-label">${h(t('ui.command.pages'))}</p>${menu.map(([page, iconName, title, detail]) => item('command-page', page, iconName, highlight(title, q), h(detail))).join('')}` : ''}
      ${stays.length ? `<p class="action-menu-label">${h(t('ui.command.stays'))}</p>${stays.map(s => item('command-stay', s.id, STATUS[Number(s.status)].icon, `${highlight(s.guest_name, q)} · ${h(t('ui.room_label', { name: s.room_name }))}`, `${highlight(s.phone || '', q)} · ${h(STATUS[Number(s.status)].label)}`)).join('')}` : ''}
      ${!menu.length && !stays.length ? `<p class="p-6 text-center text-sm text-ink-muted">${h(t('ui.command.empty'))}</p>` : ''}
      <p class="mt-2 hidden border-t border-line px-2.5 pt-2 text-xs text-ink-subtle sm:block"><kbd>↑</kbd> <kbd>↓</kbd> ${h(t('ui.command.move'))} · <kbd>Enter</kbd> ${h(t('ui.command.open'))} · <kbd>Esc</kbd> ${h(t('ui.close'))}</p>`;
  }

  function openCommand() {
    $('#command-search').value = '';
    renderCommands();
    $('#command-dialog').showModal();
    requestAnimationFrame(() => $('#command-search').focus());
  }

  // ================= FORMS =================
  function fillForm(form, data) {
    for (const [k, v] of Object.entries(data)) {
      const el = form.elements.namedItem(k);
      if (!el || el instanceof RadioNodeList) continue;
      if (el.type === 'checkbox') el.checked = bool(v);
      else el.value = v ?? '';
    }
  }

  const resetDirty = form => { if (form) delete form.dataset.dirty; };

  function clearErrors(form) {
    form.querySelectorAll('[aria-invalid="true"]').forEach(field => field.removeAttribute('aria-invalid'));
    form.querySelectorAll('[data-field-error]').forEach(error => error.remove());
  }

  /** Lists every field error at the top of the form; each item moves focus to its field. Removed with the field errors. */
  function errorSummary(form, shown) {
    const labelOf = field => {
      const label = form.querySelector(`label[for="${field.id}"]`) ?? field.closest('label');
      if (!label) return field.name;
      const copy = label.cloneNode(true);
      copy.querySelectorAll('.req, .sr-only, input').forEach(x => x.remove());
      return copy.textContent.trim();
    };
    const summary = document.createElement('div');
    summary.className = 'alert tone-danger mb-5';
    summary.dataset.fieldError = '';
    summary.setAttribute('role', 'alert');
    summary.tabIndex = -1;
    summary.innerHTML = `${icon('error')}<div class="min-w-0"><p class="font-medium">${h(t('ui.form.error_summary', { n: shown.length }))}</p><ul class="mt-1 space-y-0.5">${shown.map(([field, message]) => `<li><button type="button" class="text-left underline underline-offset-2 hover:no-underline" data-focus-field="${h(field.name)}">${h(labelOf(field))}: ${h(message)}</button></li>`).join('')}</ul></div>`;
    (form.querySelector('.dialog-body') ?? form).prepend(summary);
    return summary;
  }

  function roomOptions(selected = '') {
    return state.data.rooms.map(r => `<option value="${r.id}" ${r.id === selected ? 'selected' : ''}>${h(t('ui.booking.room_option', { name: r.name, zone: r.zone, price: money(r.price_satang) }))}</option>`).join('');
  }

  function openBooking(id = null, roomId = null) {
    const f = $('#booking-form');
    f.reset();
    clearErrors(f);
    f.elements.id.value = '';
    f.elements.room_id.innerHTML = roomOptions(roomId || '');
    const tomorrow = new Date(`${state.data.today}T00:00:00`);
    tomorrow.setDate(tomorrow.getDate() + 1);
    f.elements.check_in_date.value = state.data.today;
    f.elements.check_out_date.value = iso(tomorrow);
    f.elements.guests.value = 2;
    if (id) {
      const s = state.data.stays.find(x => x.id === id);
      fillForm(f, { ...s, id: s.id, deposit_amount: Number(s.deposit_amount_satang) / 100, discount_amount: Number(s.discount_amount_satang) / 100, check_in_now: Number(s.status) === 1 });
      f.elements.room_id.innerHTML = roomOptions(s.room_id);
    }
    $('#booking-dialog [data-dialog-title]').textContent = t(id ? 'ui.booking.edit' : 'ui.booking.new');
    f.querySelector('[data-submit-label]').textContent = t(id ? 'ui.save' : 'ui.booking.new');
    resetIdPhoto(id);
    updatePrice();
    resetDirty(f);
    $('#booking-dialog').showModal();
  }

  function updatePrice() {
    const f = $('#booking-form');
    const room = state.data.rooms.find(r => r.id === f.elements.room_id.value);
    if (!room) {
      $('#price-preview').innerHTML = `<p class="text-sm text-ink-muted">${h(t('ui.price.choose_room'))}</p>`;
      return;
    }
    const count = nights(f.elements.check_in_date.value, f.elements.check_out_date.value);
    const guests = Number(f.elements.guests.value || 1);
    const base = Number(room.price_satang) * count;
    const extraGuests = Math.max(0, guests - room.base_guests) * Number(room.extra_guest_fee_satang) * count;
    const extraBed = f.elements.extra_bed.checked ? 20000 : 0;
    const pet = Number(f.elements.pet_count.value) > 0 ? 20000 * count : 0;
    const discount = Number(f.elements.discount_amount.value || 0) * 100;
    const net = Math.max(0, base + extraGuests + extraBed + pet - discount);
    const deposit = f.elements.deposit_paid.checked ? Number(f.elements.deposit_amount.value || 0) * 100 : 0;
    const row = (label, value, cls = 'text-ink') => `<div class="flex items-baseline justify-between gap-4"><dt class="text-ink-muted">${h(label)}</dt><dd class="tabular-nums ${cls}">${value}</dd></div>`;
    $('#price-preview').innerHTML = `
      <h3 class="mb-3 text-sm font-semibold text-ink">${h(t('ui.price.title'))}</h3>
      <dl class="space-y-1.5 text-sm">
        ${row(t('ui.price.room', { nights: count, rate: money(room.price_satang) }), money(base))}
        ${extraGuests ? row(t('ui.price.extra_guests', { n: guests - room.base_guests }), money(extraGuests)) : ''}
        ${extraBed ? row(t('ui.price.extra_bed'), money(extraBed)) : ''}
        ${pet ? row(t('ui.price.pet', { n: f.elements.pet_count.value }), money(pet)) : ''}
        ${discount ? row(t('ui.price.discount'), `−${money(discount)}`, 'text-success') : ''}
      </dl>
      <div class="mt-3 flex items-baseline justify-between border-t border-line pt-3"><span class="font-semibold text-ink">${h(t('ui.price.net'))}</span><span class="text-lg font-semibold tabular-nums text-ink">${money(net)}</span></div>
      <div class="mt-1 flex items-baseline justify-between text-sm"><span class="text-ink-muted">${h(t(f.elements.deposit_paid.checked ? 'ui.price.deposit_paid' : 'ui.price.deposit_unpaid', { amount: money(deposit) }))}</span><span class="font-medium tabular-nums text-ink">${h(t('ui.price.balance', { amount: money(Math.max(0, net - deposit)) }))}</span></div>`;
  }

  function openRoom(id = null) {
    const f = $('#room-form');
    f.reset();
    clearErrors(f);
    f.elements.id.value = '';
    const r = id ? state.data.rooms.find(x => x.id === id) : null;
    f.elements.zone.innerHTML = categoryOptions(state.categories?.zones ?? [], r?.zone);
    f.elements.type.innerHTML = categoryOptions(state.categories?.types ?? [], r?.type);
    if (r) fillForm(f, { ...r, price: Number(r.price_satang) / 100, extra_guest_fee: Number(r.extra_guest_fee_satang) / 100 });
    else applyTypeDefaults(f);
    $('#room-dialog [data-dialog-title]').textContent = t(id ? 'ui.room.edit' : 'ui.rooms.new');
    f.querySelector('[data-submit-label]').textContent = t(id ? 'ui.save' : 'ui.rooms.new');
    resetDirty(f);
    $('#room-dialog').showModal();
  }

  function openGuest(id) {
    const g = state.data.guests.find(x => x.id === id);
    const f = $('#guest-form');
    f.reset();
    clearErrors(f);
    fillForm(f, g);
    const history = state.data.stays.filter(s => s.guest_id === id);
    state.files = attachmentsOf(history.map(s => s.id));

    $('#guest-head').innerHTML = `
      <span class="avatar avatar-lg" aria-hidden="true">${h([...g.name][0] || '?')}</span>
      <div class="min-w-0">
        <h2 id="guest-dialog-title" class="dialog-title truncate">${h(g.name)}</h2>
        <p class="dialog-sub">${h(g.phone)}${g.customer_type ? ` · ${h(g.customer_type)}` : ''}</p>
        ${g.is_regular ? `<p class="mt-1.5">${pill('accent', 'star', t('ui.guest.regular_short'))}</p>` : ''}
      </div>`;

    $('#guest-stats').innerHTML = `
      <div class="kpi-strip grid-cols-2 sm:grid-cols-4">
        ${kpi(t('ui.guest.completed'), number(g.completed_stays), t('ui.guest.completed_sub'), 'check')}
        ${kpi(t('ui.guest.nights'), number(g.total_nights), t('ui.guest.nights_sub'), 'bed')}
        ${kpi(t('ui.guest.lifetime'), money(g.lifetime_value_satang), t('ui.guest.lifetime_sub'), 'money')}
        ${kpi(t('ui.guest.discounts'), money(g.total_discount_satang), t('ui.guest.discounts_sub'), 'discount')}
      </div>
      ${g.completed_stays >= 3 && !g.is_regular ? `<div class="alert tone-accent mt-4">${icon('star')}<span>${h(t('ui.guest.suggest_regular'))}</span></div>` : ''}`;

    $('#guest-history').innerHTML = history.length ? `<ul class="divide-y divide-line rounded-lg border border-line">${history.map(s => `
      <li class="flex flex-wrap items-center gap-3 px-4 py-3">
        <span class="room-no">${h(s.room_name)}</span>
        <span class="min-w-0 flex-1"><span class="block text-sm text-ink"><time datetime="${s.check_in_date}">${h(thaiDate(s.check_in_date))}</time> – <time datetime="${s.check_out_date}">${h(thaiDate(s.check_out_date))}</time></span><span class="cell-sub">${h(t('ui.nights_count', { n: nights(s.check_in_date, s.check_out_date) }))} · ${money(s.total_amount_satang)}</span></span>
        ${statusPill(s.status)}
      </li>`).join('')}</ul>` : emptyState({ iconName: 'bookings', title: t('ui.guest.no_stays') });

    const notes = [
      g.customer_note ? { tone: 'accent', title: t('ui.guest.note'), text: g.customer_note } : null,
      g.preferences ? { tone: 'primary', title: t('ui.guest.preferences'), text: g.preferences } : null,
      ...history.filter(s => s.note).map(s => ({ tone: STATUS[Number(s.status)].tone, title: `${t('ui.room_label', { name: s.room_name })} · ${thaiDate(s.check_in_date)}`, text: s.note })),
    ].filter(Boolean);
    $('#guest-notes').innerHTML = notes.length
      ? `<ol class="timeline">${notes.map(n => `<li class="timeline-item tone-${n.tone}"><p class="text-sm font-medium text-ink">${h(n.title)}</p><p class="mt-0.5 whitespace-pre-line text-sm text-ink-muted">${h(n.text)}</p></li>`).join('')}</ol>`
      : emptyState({ iconName: 'note', title: t('ui.guest.no_notes') });

    $('#guest-files').innerHTML = state.files.length
      ? `<div class="file-grid">${state.files.map((file, index) => `
        <button type="button" class="file-tile" data-file-index="${index}" aria-label="${h(t('ui.files.open', { name: file.original_name }))}">
          <span class="file-thumb">${isImage(file) ? `<img src="/files/${file.id}" alt="" loading="lazy" width="320" height="240">` : icon('file', 'h-8 w-8')}</span>
          <span class="file-name">${h(file.original_name)}</span>
        </button>`).join('')}</div>`
      : emptyState({ iconName: 'attachment', title: t('ui.files.empty') });

    selectTab($('#guest-tab-overview'));
    resetDirty(f);
    $('#guest-dialog').showModal();
  }

  // ================= ID CARD PHOTO (booking form) =================
  // The photo is shrunk in the browser, previewed, and uploaded after the booking itself has been saved.
  function resetIdPhoto(stayId = null) {
    const f = $('#booking-form');
    state.idPhotoDraft = null;
    state.idPhotoRemoved = false;
    const saved = stayId ? state.idPhotos.get(stayId) : null;
    showIdPhoto(saved ? `/files/id-photo/${stayId}?v=${encodeURIComponent(saved.created_at)}` : null);
    f.querySelector('[data-id-photo-status]').textContent = saved
      ? [t('ui.id_photo.stored', { size: fileSize(saved.size_bytes) }), saved.delete_after ? t('ui.id_photo.deleted_on', { date: thaiDate(saved.delete_after) }) : ''].filter(Boolean).join(' · ')
      : t('ui.id_photo.none');
  }

  function showIdPhoto(src) {
    const f = $('#booking-form');
    const thumb = f.querySelector('[data-action="view-id-photo"]');
    thumb.hidden = !src;
    f.querySelector('[data-id-photo-preview]').src = src || '';
    f.querySelector('[data-action="remove-id-photo"]').hidden = !src;
    f.querySelector('[data-id-photo-pick]').textContent = t(src ? 'ui.id_photo.replace' : 'ui.id_photo.add');
  }

  async function pickIdPhoto(input) {
    const file = input.files?.[0];
    input.value = '';
    if (!file) return;
    const f = $('#booking-form');
    const status = f.querySelector('[data-id-photo-status]');
    status.textContent = t('ui.id_photo.shrinking');
    try {
      const shrunk = await shrinkImage(file);
      state.idPhotoDraft = { ...shrunk, url: await dataUrl(shrunk.blob) };
      state.idPhotoRemoved = false;
      showIdPhoto(state.idPhotoDraft.url);
      status.textContent = t('ui.id_photo.shrunk', { from: fileSize(file.size), to: fileSize(shrunk.blob.size), width: shrunk.width, height: shrunk.height });
      f.dataset.dirty = 'true';
    } catch {
      status.textContent = t('ui.id_photo.unreadable');
    }
  }

  async function saveIdPhoto(stayId) {
    try {
      if (state.idPhotoDraft) {
        const body = new FormData();
        body.append('file', state.idPhotoDraft.blob, state.idPhotoDraft.name);
        await api(`/api/v1/stays/${stayId}/id-photo`, { method: 'POST', body });
      } else if (state.idPhotoRemoved && state.idPhotos.has(stayId)) {
        await api(`/api/v1/stays/${stayId}/id-photo`, { method: 'DELETE' });
      }
      state.idPhotoDraft = null;
      state.idPhotoRemoved = false;
    } catch (e) {
      // The booking is saved either way; say so and let staff attach the photo again.
      toast(`${t('ui.id_photo.upload_failed')} · ${e.message}`, 'error');
    }
  }

  const dataUrl = blob => new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = () => reject(reader.error);
    reader.readAsDataURL(blob);
  });

  function viewIdPhoto(stayId, src = `/files/id-photo/${stayId}`) {
    const s = state.data.stays.find(x => x.id === stayId);
    state.files = [];
    $('#file-dialog-title').textContent = `${t('ui.id_photo.label')}${s ? ` · ${s.guest_name}` : ''}`;
    $('#file-dialog-download').href = src;
    $('#file-dialog-body').innerHTML = `<img class="viewer-img" src="${src}" alt="${h(t('ui.id_photo.label'))}">`;
    $$('[data-file-step]').forEach(b => { b.hidden = true; });
    if (!$('#file-dialog').open) $('#file-dialog').showModal();
  }

  function showFile(index) {
    if (!state.files.length) return;
    state.fileIndex = (index + state.files.length) % state.files.length;
    const file = state.files[state.fileIndex];
    $('#file-dialog-title').textContent = `${file.original_name} · ${fileSize(file.size_bytes)}`;
    $('#file-dialog-download').href = `/files/${file.id}`;
    $('#file-dialog-body').innerHTML = isImage(file)
      ? `<img class="viewer-img" src="/files/${file.id}" alt="${h(file.original_name)}">`
      : emptyState({ iconName: 'file', title: file.original_name, text: t('ui.files.preview_unavailable'), action: `<a class="btn btn-primary" href="/files/${file.id}">${icon('download')}<span>${h(t('ui.files.download'))}</span></a>` });
    $$('[data-file-step]').forEach(b => { b.hidden = state.files.length < 2; });
    if (!$('#file-dialog').open) $('#file-dialog').showModal();
  }

  function openAction(action, id) {
    const s = state.data.stays.find(x => x.id === id);
    const f = $('#action-form');
    f.reset();
    clearErrors(f);
    f.elements.stay_id.value = id;
    f.elements.action.value = action;
    $('#action-title').textContent = t(`ui.action.${action}_title`);
    $('#action-subtitle').textContent = `${t('ui.room_label', { name: s.room_name })} · ${s.guest_name}`;
    f.querySelector('[data-submit-label]').textContent = t(`ui.action.${action}_submit`);
    const check = (name, label) => `<label class="check-row"><input type="checkbox" name="${name}" checked class="form-checkbox check"><span>${h(label)}</span></label>`;
    const fields = {
      checkout: `
        <p class="text-sm text-ink-muted">${h(t('ui.checkout.intro'))}</p>
        <fieldset class="space-y-2"><legend class="sr-only">${h(t('ui.checkout.legend'))}</legend>
          ${check('key_returned', t('ui.checkout.key'))}
          ${check('room_clean', t('ui.checkout.clean'))}
          ${check('equipment_complete', t('ui.checkout.equipment'))}
          ${check('no_damage', t('ui.checkout.no_damage'))}
          ${check('minibar_checked', t('ui.checkout.minibar'))}
        </fieldset>
        <div><label class="label" for="inspection-note">${h(t('ui.checkout.note'))}</label><textarea id="inspection-note" class="field" name="inspection_note" rows="3" aria-describedby="inspection-note-hint"></textarea><p id="inspection-note-hint" class="hint">${h(t('ui.checkout.note_hint'))}</p></div>`,
      extend: `
        <div><label class="label" for="extend-date">${h(t('ui.extend.date'))}<span class="req" aria-hidden="true">*</span></label><input id="extend-date" class="field" type="date" name="check_out_date" min="${s.check_out_date}" value="${s.check_out_date}" required aria-describedby="extend-hint"><p id="extend-hint" class="hint">${h(t('ui.extend.hint', { date: thaiDate(s.check_out_date) }))}</p></div>
        <div><label class="label" for="extend-discount">${h(t('ui.extend.discount'))}</label><input id="extend-discount" class="field num" type="number" name="discount_amount" min="0" value="${Number(s.discount_amount_satang) / 100}" inputmode="decimal"></div>`,
      upload: `
        <div><label class="label" for="upload-file">${h(t('ui.upload.file'))}<span class="req" aria-hidden="true">*</span></label><input id="upload-file" class="field" type="file" name="file" accept="image/jpeg,image/png,image/webp,application/pdf" required aria-describedby="upload-hint"><p id="upload-hint" class="hint">${h(t('ui.upload.hint'))}</p></div>
        <p id="upload-selected" class="text-sm text-ink-muted" aria-live="polite"></p>
        <div id="upload-progress" class="progress" hidden></div>`,
    };
    $('#action-fields').innerHTML = fields[action] || '';
    resetDirty(f);
    $('#action-dialog').showModal();
  }

  function confirmAction({ title, message, confirmLabel = t('ui.confirm'), destructive = false }) {
    const dialog = $('#confirm-dialog');
    const accept = dialog.querySelector('[data-confirm-accept]');
    const cancel = dialog.querySelector('[data-confirm-cancel]');
    $('#confirm-title').textContent = title;
    $('#confirm-message').textContent = message;
    $('#confirm-icon').className = `flex h-10 w-10 shrink-0 items-center justify-center rounded-full ${destructive ? 'bg-danger-subtle text-danger' : 'bg-primary-subtle text-primary'}`;
    $('#confirm-icon').innerHTML = icon(destructive ? 'warning' : 'info', 'h-5 w-5');
    accept.textContent = confirmLabel;
    accept.className = `btn ${destructive ? 'btn-danger' : 'btn-primary'}`;

    return new Promise(resolve => {
      const finish = result => {
        dialog.close();
        accept.removeEventListener('click', onAccept);
        cancel.removeEventListener('click', onCancel);
        dialog.removeEventListener('cancel', onCancel);
        dialog.removeEventListener('click', onBackdrop);
        resolve(result);
      };
      const onAccept = () => finish(true);
      const onCancel = event => {
        event?.preventDefault();
        finish(false);
      };
      const onBackdrop = event => {
        if (event.target === dialog) finish(false);
      };
      accept.addEventListener('click', onAccept);
      cancel.addEventListener('click', onCancel);
      dialog.addEventListener('cancel', onCancel);
      dialog.addEventListener('click', onBackdrop);
      dialog.showModal();
      requestAnimationFrame(() => (destructive ? cancel : accept).focus());
    });
  }

  /** Closes a dialog, asking first when its form has unsaved changes. */
  async function requestClose(dialog) {
    const form = dialog.querySelector('form[data-guard]');
    if (form?.dataset.dirty) {
      const discard = await confirmAction({ title: t('ui.unsaved.title'), message: t('ui.unsaved.message'), confirmLabel: t('ui.unsaved.discard'), destructive: true });
      if (!discard) return;
    }
    resetDirty(form);
    dialog.close();
  }

  async function mutate(path, method, body, form = null, { after } = {}) {
    const submit = form?.querySelector('[type="submit"]');
    if (form) clearErrors(form);
    setButtonLoading(submit, true);
    try {
      const result = await api(path, { method, body: body instanceof FormData ? body : JSON.stringify(body || {}) });
      if (after) await after(result);
      toast(t('ui.toast.saved'));
      $$('form[data-guard]').forEach(resetDirty);
      $$('dialog[open]').forEach(d => d.close());
      await load(false);
      return true;
    } catch (e) {
      let first = null;
      const shown = [];
      for (const [name, message] of Object.entries(e.errors || {})) {
        const field = form?.elements.namedItem(name);
        if (!field || field instanceof RadioNodeList) continue;
        field.setAttribute('aria-invalid', 'true');
        const error = document.createElement('p');
        error.dataset.fieldError = '';
        error.className = 'field-error';
        error.id = `${field.id || name}-error`;
        error.innerHTML = `${icon('error')}<span>${h(message)}</span>`;
        (field.closest('.check-row') || field).insertAdjacentElement('afterend', error);
        field.setAttribute('aria-describedby', [field.getAttribute('aria-describedby'), error.id].filter(Boolean).join(' '));
        first ??= field;
        shown.push([field, message]);
      }
      // Several errors: focus a summary that links to each field; one error: focus the field itself.
      shown.sort(([a], [b]) => (a.compareDocumentPosition(b) & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1));
      if (shown.length > 1) errorSummary(form, shown).focus();
      else first?.focus();
      toast(form ? e.message : [e.message, ...Object.values(e.errors || {})].join(' · '), 'error');
      return false;
    } finally {
      setButtonLoading(submit, false);
    }
  }

  // ================= EVENTS =================
  const tableOf = name => state.tables[name];

  document.addEventListener('click', async e => {
    const b = e.target.closest('button, a');
    if (!b) {
      const dialog = e.target.closest('dialog');
      if (dialog && e.target === dialog && dialog.id !== 'confirm-dialog') requestClose(dialog);
      return;
    }
    if (b.dataset.focusField) {
      b.closest('form')?.elements.namedItem(b.dataset.focusField)?.focus();
      return;
    }

    if (b.dataset.menuTrigger) {
      const context = b.dataset.menuTrigger;
      const source = { stay: state.data.stays, room: state.data.rooms, zone: state.categories?.zones, type: state.categories?.types, user: state.users }[context] ?? [];
      const item = source.find(x => x.id === b.dataset.id);
      const items = { stay: stayMenuItems, room: roomMenuItems, zone: x => categoryMenuItems('zone', x), type: x => categoryMenuItems('type', x), user: userMenuItems }[context];
      if (item && items) openDropdownMenu(b, items(item), b.getAttribute('aria-label') ?? b.title);
      return;
    }
    if (b.dataset.action === 'theme-menu') {
      const preference = themePreference();
      openDropdownMenu(b, ['light', 'dark', 'system'].map(x => ({
        label: t(`ui.theme.${x}`), icon: { light: 'sun', dark: 'moon', system: 'system' }[x], role: 'menuitemradio', checked: preference === x, attributes: { 'data-theme-option': x },
      })), t('ui.theme.label'));
      return;
    }
    if (b.dataset.columns) {
      const table = tableOf(b.dataset.columns);
      openDropdownMenu(b, columnMenuItems(table, table.columns || []), t('ui.table.columns'));
      return;
    }
    if (b.dataset.allColumns) {
      const table = tableOf(b.dataset.allColumns);
      table.allColumns = !table.allColumns;
      saveColumns(table);
      render();
      return;
    }
    if (b.dataset.columnToggle) {
      const table = tableOf(b.dataset.table);
      if (table.hidden.has(b.dataset.columnToggle)) table.hidden.delete(b.dataset.columnToggle);
      else table.hidden.add(b.dataset.columnToggle);
      saveColumns(table);
      render();
      return;
    }

    if (b.closest('.action-menu')) closeDropdownMenu();

    if (b.dataset.page) {
      b.closest('dialog')?.close();
      navigate(b.dataset.page);
      if (b.matches('.nav-item, .tab-item')) $('#main').focus({ preventScroll: true });
    }
    if (b.hasAttribute('data-close')) {
      const dialog = b.closest('dialog');
      if (dialog) requestClose(dialog);
    }
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
    if (b.dataset.sort) {
      const table = tableOf(b.dataset.table);
      toggleSort(table, table.columns || [], b.dataset.sort);
      if (b.dataset.table === 'guests' && guestSortKeys[b.dataset.sort]) $('#guest-sort').value = b.dataset.sort;
      render();
      $(`[data-sort="${b.dataset.sort}"][data-table="${b.dataset.table}"]`)?.focus();
    }
    if (b.dataset.tablePage) {
      const table = tableOf(b.dataset.table);
      table.page += Number(b.dataset.tablePage);
      render();
    }
    if (b.dataset.stayStatus !== undefined) {
      $('#stay-status').value = b.dataset.stayStatus;
      state.tables.bookings.page = 1;
      renderBookings();
    }
    if (b.dataset.roomState !== undefined) {
      state.roomState = b.dataset.roomState;
      renderRoomMap();
    }
    if (b.dataset.roomZone !== undefined) {
      state.roomZone = b.dataset.roomZone;
      renderRoomMap();
    }
    if (b.dataset.toggleTable) {
      const panel = $(`#${b.dataset.toggleTable}`);
      panel.hidden = !panel.hidden;
      b.setAttribute('aria-expanded', String(!panel.hidden));
      b.textContent = t(panel.hidden ? 'ui.reports.show_table' : 'ui.reports.hide_table');
    }
    if (b.dataset.fileIndex !== undefined) showFile(Number(b.dataset.fileIndex));
    if (b.dataset.fileStep) showFile(state.fileIndex + Number(b.dataset.fileStep));

    const a = b.dataset.action;
    const id = b.dataset.id;
    if (a === 'new-booking') openBooking(null, id);
    if (a === 'pick-id-photo') $('#booking-id-photo').click();
    if (a === 'remove-id-photo') {
      state.idPhotoDraft = null;
      state.idPhotoRemoved = true;
      showIdPhoto(null);
      b.closest('form').querySelector('[data-id-photo-status]').textContent = t('ui.id_photo.will_remove');
      b.closest('form').dataset.dirty = 'true';
    }
    if (a === 'view-id-photo') {
      if (b.closest('#booking-form')) viewIdPhoto($('#booking-form').elements.id.value, b.querySelector('img').src);
      else viewIdPhoto(id);
    }
    if (a === 'clear-search') {
      if (b.dataset.list === 'bookings') {
        $('#stay-search').value = '';
        $('#stay-status').value = '';
        renderBookings();
        $('#stay-search').focus();
      } else {
        $('#guest-search').value = '';
        if ($('#regular-only')) $('#regular-only').checked = false;
        renderGuests();
        $('#guest-search').focus();
      }
    }
    if (a === 'command') {
      b.closest('dialog')?.close();
      openCommand();
    }
    if (a === 'mobile-more') $('#mobile-more-dialog').showModal();
    if (a === 'retry-load') load().catch(showLoadFailure);
    if (a === 'edit-booking') openBooking(id);
    if (a === 'new-room') openRoom();
    if (a === 'edit-room') openRoom(id);
    if (a === 'new-user') openUser();
    if (a === 'edit-user') openUser(id);
    if (a === 'reset-password') openPasswordDialog('reset-password', id);
    if (a === 'change-password') {
      b.closest('dialog')?.close();
      openPasswordDialog('account-password');
    }
    if (a === 'deactivate-user' || a === 'activate-user') {
      const u = state.users.find(x => x.id === id);
      const active = a === 'activate-user';
      const confirmed = active || await confirmAction({
        title: t('ui.confirm.deactivate_user_title'),
        message: t('ui.confirm.deactivate_user_message', { name: u?.name || '' }),
        confirmLabel: t('ui.users.deactivate'),
        destructive: true,
      });
      if (confirmed && u) await mutate(`/api/v1/users/${id}`, 'PUT', { name: u.name, email: u.email, role: u.role, active });
    }
    if (a === 'new-zone') openCategory('zone');
    if (a === 'edit-zone') openCategory('zone', id);
    if (a === 'new-type') openCategory('type');
    if (a === 'edit-type') openCategory('type', id);
    if (a === 'manage-categories') {
      const dialog = b.closest('dialog');
      if (dialog) await requestClose(dialog);
      if (!dialog?.open) showRoomSetupTab('zones');
    }
    if (a === 'delete-zone' || a === 'delete-type') {
      const kind = a.slice('delete-'.length);
      const item = (kind === 'zone' ? state.categories.zones : state.categories.types).find(x => x.id === id);
      const confirmed = await confirmAction({
        title: t(`ui.confirm.delete_${kind}_title`),
        message: t(`ui.confirm.delete_${kind}_message`, { name: item?.name || '' }),
        confirmLabel: t(`ui.${kind}s.delete`),
        destructive: true,
      });
      if (confirmed) await mutate(`/api/v1/room-${kind}s/${id}`, 'DELETE', {});
    }
    if (a === 'guest-details') openGuest(id);
    if (a === 'clear-room-filters') {
      state.roomState = '';
      state.roomZone = '';
      renderRoomMap();
    }
    if (a === 'stay-details') {
      navigate('bookings');
      $('#stay-search').value = state.data.stays.find(s => s.id === id)?.guest_name || '';
      renderBookings();
    }
    if (['checkout', 'extend', 'upload'].includes(a)) openAction(a, id);

    if (a === 'check-in') {
      const stay = state.data.stays.find(item => item.id === id);
      const confirmed = await confirmAction({
        title: t('ui.confirm.check_in_title'),
        message: t('ui.confirm.check_in_message', { guest: stay?.guest_name || '', room: stay?.room_name || '' }),
        confirmLabel: t('ui.action.check_in'),
      });
      if (confirmed) await mutate(`/api/v1/stays/${id}/check-in`, 'POST', {});
    }
    if (a === 'delete-booking') {
      const stay = state.data.stays.find(item => item.id === id);
      const confirmed = await confirmAction({
        title: t('ui.confirm.delete_booking_title'),
        message: t('ui.confirm.delete_booking_message', { guest: stay?.guest_name || '', room: stay?.room_name || '' }),
        confirmLabel: t('ui.booking.delete'),
        destructive: true,
      });
      if (confirmed) await mutate(`/api/v1/stays/${id}`, 'DELETE', {});
    }
    if (a === 'delete-room') {
      const room = state.data.rooms.find(item => item.id === id);
      const confirmed = await confirmAction({
        title: t('ui.confirm.delete_room_title'),
        message: t('ui.confirm.delete_room_message', { room: room?.name || '' }),
        confirmLabel: t('ui.rooms.delete'),
        destructive: true,
      });
      if (confirmed) await mutate(`/api/v1/rooms/${id}`, 'DELETE', {});
    }
    if (a === 'print') window.print();

    if (b.dataset.view) {
      state.bookingView = b.dataset.view;
      $$('[data-view]').forEach(btn => btn.setAttribute('aria-pressed', String(btn.dataset.view === state.bookingView)));
      $('#booking-list').hidden = state.bookingView !== 'list';
      $('#booking-calendar').hidden = state.bookingView !== 'calendar';
      if (state.bookingView === 'calendar') scrollCalendar();
      $('[data-columns="bookings"]').hidden = state.bookingView !== 'list';
    }
    if (b.dataset.calendarNav) {
      state.calendar = new Date(state.calendar.getFullYear(), state.calendar.getMonth() + Number(b.dataset.calendarNav), 1);
      renderCalendar();
    }
    if (b.hasAttribute('data-calendar-today')) {
      state.calendar = new Date();
      state.selectedDay = state.data.today;
      state.calendarShown = null;
      renderCalendar();
    }
    if (b.dataset.calendarDay) {
      state.selectedDay = b.dataset.calendarDay;
      renderCalendar();
      $(`[data-calendar-day="${state.selectedDay}"]`)?.focus();
    }
  });

  // Unsaved-changes guard on the form dialogs (Esc goes through the same check).
  $$('form[data-guard]').forEach(form => form.addEventListener('input', () => { form.dataset.dirty = 'true'; }));
  $$('dialog').forEach(dialog => dialog.addEventListener('cancel', event => {
    if (dialog.id === 'confirm-dialog') return;
    event.preventDefault();
    requestClose(dialog);
  }));
  $('#file-dialog').addEventListener('keydown', e => {
    if (e.key === 'ArrowLeft') showFile(state.fileIndex - 1);
    if (e.key === 'ArrowRight') showFile(state.fileIndex + 1);
  });

  $('#booking-form').addEventListener('input', e => {
    updatePrice();
    if (e.target.name === 'phone') {
      const digits = e.target.value.replace(/\D/g, '');
      const guest = digits.length >= 9 ? state.data.guests.find(g => g.normalized_phone === digits) : null;
      const hint = $('#booking-phone-hint');
      if (guest) {
        e.currentTarget.elements.guest_name.value = guest.name;
        hint.textContent = t(guest.is_regular ? 'ui.booking.found_regular' : 'ui.booking.found', { name: guest.name });
      } else {
        hint.textContent = t('ui.booking.phone_hint');
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
    await mutate(id ? `/api/v1/stays/${id}` : '/api/v1/stays', id ? 'PUT' : 'POST', d, e.currentTarget, { after: saved => saveIdPhoto(saved.id) });
  });

  $('#booking-id-photo').addEventListener('change', e => pickIdPhoto(e.target));

  $('#room-type').addEventListener('change', e => applyTypeDefaults(e.target.form));
  $('#user-role').addEventListener('change', e => showRoleHint(e.target.form));

  $('#user-form').addEventListener('submit', async e => {
    e.preventDefault();
    const d = formObject(e.currentTarget);
    const id = d.id;
    delete d.id;
    if (e.currentTarget.elements.role.disabled) d.role = state.users.find(x => x.id === id)?.role;
    if (id) d.active = state.users.find(x => x.id === id)?.active;
    await mutate(id ? `/api/v1/users/${id}` : '/api/v1/users', id ? 'PUT' : 'POST', d, e.currentTarget);
  });

  $('#reset-password-form').addEventListener('submit', async e => {
    e.preventDefault();
    const d = formObject(e.currentTarget);
    await mutate(`/api/v1/users/${d.id}/password`, 'POST', { password: d.password, confirm_password: d.confirm_password }, e.currentTarget);
  });

  $('#account-password-form').addEventListener('submit', async e => {
    e.preventDefault();
    const d = formObject(e.currentTarget);
    delete d.id;
    await mutate('/api/v1/account/password', 'POST', d, e.currentTarget);
  });

  for (const kind of ['zone', 'type']) {
    $(`#${kind}-form`).addEventListener('submit', async e => {
      e.preventDefault();
      const d = formObject(e.currentTarget);
      const id = d.id;
      delete d.id;
      await mutate(id ? `/api/v1/room-${kind}s/${id}` : `/api/v1/room-${kind}s`, id ? 'PUT' : 'POST', d, e.currentTarget);
    });
  }

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

  $('#action-form').addEventListener('change', e => {
    if (e.target.name !== 'file') return;
    const file = e.target.files?.[0];
    $('#upload-selected').textContent = file ? `${file.name} · ${fileSize(file.size)}` : '';
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
      const body = { ...s, deposit_amount: Number(s.deposit_amount_satang) / 100, discount_amount: d.discount_amount, check_out_date: d.check_out_date };
      for (const k of ['id', 'total_amount_satang', 'pet_fee_satang', 'room_name', 'zone', 'room_type', 'room_rate_satang', 'base_guests', 'max_guests', 'extra_guest_fee_satang', 'is_pet_friendly', 'customer_type', 'is_regular', 'feedback_rating', 'created_at', 'updated_at', 'deleted_at', 'guest_id']) {
        delete body[k];
      }
      await mutate(`/api/v1/stays/${id}`, 'PUT', body, e.currentTarget);
      return;
    }
    if (action === 'upload') {
      const progress = $('#upload-progress');
      progress.hidden = false;
      await mutate(`/api/v1/stays/${id}/attachments`, 'POST', new FormData(e.currentTarget), e.currentTarget);
      progress.hidden = true;
      return;
    }
    await mutate(`/api/v1/stays/${id}/${action}`, 'POST', d, e.currentTarget);
  });

  $('#stay-search')?.addEventListener('input', () => {
    state.tables.bookings.page = 1;
    renderBookings();
  });
  $('#guest-search')?.addEventListener('input', () => {
    state.tables.guests.page = 1;
    renderGuests();
  });
  $('#regular-only')?.addEventListener('input', renderGuests);
  $('#guest-sort')?.addEventListener('input', e => {
    state.tables.guests.sort = e.target.value;
    state.tables.guests.dir = e.target.value === 'name' ? 'asc' : 'desc';
    renderGuests();
  });

  $('#apply-range')?.addEventListener('click', () => load().catch(e => toast(e.message, 'error')));
  $('#command-search')?.addEventListener('input', renderCommands);
  $('#command-search')?.addEventListener('keydown', e => {
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      $('#command-results button')?.focus();
    }
    if (e.key === 'Enter') {
      e.preventDefault();
      $('#command-results button')?.click();
    }
  });
  $('#command-results')?.addEventListener('keydown', e => {
    const options = $$('#command-results button');
    const index = options.indexOf(document.activeElement);
    const moves = { ArrowDown: (index + 1) % options.length, Home: 0, End: options.length - 1 };
    if (e.key in moves) {
      e.preventDefault();
      options[moves[e.key]]?.focus();
    }
    if (e.key === 'ArrowUp') {
      e.preventDefault();
      if (index <= 0) $('#command-search').focus();
      else options[index - 1]?.focus();
    }
  });
  window.addEventListener('keydown', e => {
    if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') {
      e.preventDefault();
      openCommand();
    }
  });
  window.addEventListener('hashchange', () => navigate(location.hash.slice(1) || 'today', false));

  $$('[data-range]').forEach(rangeButton => {
    rangeButton.addEventListener('click', () => {
      $$('[data-range]').forEach(option => option.setAttribute('aria-pressed', String(option === rangeButton)));
      const now = new Date();
      const start = new Date(now);
      if (rangeButton.dataset.range === '7days') start.setDate(now.getDate() - 6);
      if (rangeButton.dataset.range === 'month') start.setDate(1);
      $('#range-start').value = iso(start);
      $('#range-end').value = iso(now);
      load().catch(e => toast(e.message, 'error'));
    });
  });

  const now = new Date();
  $('#range-start').value = iso(new Date(now.getFullYear(), now.getMonth(), 1));
  $('#range-end').value = iso(new Date(now.getFullYear(), now.getMonth() + 1, 0));

  $$('[data-manager-only]').forEach(element => { element.hidden = !canManageRooms; });
  $$('[data-booking-control]').forEach(element => { element.hidden = !canBook; });
  document.documentElement.classList.add('app-ready');
  navigate(location.hash.slice(1) || 'today', false);

  load().catch(showLoadFailure);
}
