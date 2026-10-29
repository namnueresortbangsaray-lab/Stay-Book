<?php use App\Core\Session; use App\Core\View; ?>
<div id="app" data-role="<?= View::e($user['role'] ?? '') ?>" class="min-h-screen md:grid md:grid-cols-[260px_1fr] bg-canvas">

  <!-- Tranquil Splash Screen -->
  <div id="splash" class="fixed inset-0 z-[100] flex flex-col items-center justify-center bg-white text-ink transition-opacity duration-300">
    <div class="flex flex-col items-center max-w-xs text-center px-4">
      <img src="/images/logo_banner.webp" class="h-20 w-auto object-contain" alt="น้ำเหนือรีสอร์ท บางเสร่">
      <p class="mt-4 text-xs font-medium uppercase tracking-widest text-muted">บางเสร่ · Resort Guest Logbook</p>
      <div class="mt-6 h-1 w-36 overflow-hidden rounded-full bg-line">
        <div class="h-full w-2/3 animate-pulse rounded-full bg-brand-500"></div>
      </div>
    </div>
  </div>

  <!-- Slim, Clean Quiet Luxury Sidebar -->
  <aside class="no-print hidden border-r border-line bg-white p-5 md:flex md:flex-col md:justify-between z-20">
    <div>
      <!-- Resort Brand Banner -->
      <div class="px-2 pt-2 pb-6 border-b border-line/60">
        <a href="/" class="block">
          <img src="/images/logo_banner.webp" class="h-12 w-auto object-contain" alt="น้ำเหนือรีสอร์ท">
        </a>
        <div class="mt-2.5 flex items-center gap-1.5 text-xs text-muted">
          <span class="inline-block h-1.5 w-1.5 rounded-full bg-emerald-500"></span>
          <span>บางเสร่ · ระบบจัดการห้องพัก</span>
        </div>
      </div>

      <!-- Main Navigation Menu -->
      <nav class="mt-6 space-y-1.5" aria-label="เมนูหลัก">
        <button class="nav-link active w-full" data-page="today">
          <svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24"><path d="M3 12h4l2-6 4 12 2-6h6"/><path d="M5 4h14a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2Z"/></svg>
          <span>วันนี้</span>
        </button>
        <button class="nav-link w-full" data-page="room-map">
          <svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24"><rect width="7" height="7" x="3" y="3" rx="1.5"/><rect width="7" height="7" x="14" y="3" rx="1.5"/><rect width="7" height="7" x="14" y="14" rx="1.5"/><rect width="7" height="7" x="3" y="14" rx="1.5"/></svg>
          <span>ผังห้อง</span>
        </button>
        <button class="nav-link w-full" data-page="bookings">
          <svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24"><path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/><path d="m9 16 2 2 4-4"/></svg>
          <span>ตารางเข้าพัก</span>
        </button>
        <button class="nav-link w-full" data-page="dashboard">
          <svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24"><path d="M3 3v18h18"/><path d="m19 9-5 5-4-4-3 3"/></svg>
          <span>ภาพรวม</span>
        </button>
        <button class="nav-link w-full" data-page="rooms" data-manager-only>
          <svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24"><path d="M3 9.5 12 3l9 6.5V20a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1z"/><path d="M9 21V12h6v9"/></svg>
          <span>ห้องพัก</span>
        </button>
        <button class="nav-link w-full" data-page="guests">
          <svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
          <span>ลูกค้า</span>
        </button>
      </nav>
    </div>

    <!-- User Profile & Sign-out Pill -->
    <div class="mt-auto pt-6">
      <div class="rounded-2xl border border-line bg-canvas/80 p-3.5">
        <div class="flex items-center gap-3">
          <div class="flex h-9 w-9 items-center justify-center rounded-xl bg-brand-100 text-xs font-bold text-brand-700">
            <?= mb_substr((string)($user['name'] ?? 'U'), 0, 1) ?>
          </div>
          <div class="min-w-0 flex-1">
            <p class="truncate text-sm font-semibold text-ink"><?= View::e($user['name'] ?? 'ผู้ใช้งาน') ?></p>
            <p class="text-[11px] uppercase tracking-wider text-muted font-medium"><?= View::e($user['role'] ?? 'staff') ?></p>
          </div>
        </div>
        <form method="post" action="/logout" class="mt-3 pt-2.5 border-t border-line/60">
          <input type="hidden" name="_token" value="<?= View::e(Session::csrf()) ?>">
          <button class="flex w-full items-center justify-between text-xs font-medium text-muted transition hover:text-red-600" type="submit">
            <span>ออกจากระบบ</span>
            <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" x2="9" y1="12" y2="12"/></svg>
          </button>
        </form>
      </div>
    </div>
  </aside>

  <!-- Main Content Layout -->
  <div class="app-content min-w-0 pb-24 md:pb-12 flex flex-col min-h-screen">
    <!-- Airy Top Header -->
    <header class="app-header no-print sticky top-0 z-30 flex items-center justify-between gap-3 border-b border-line bg-white/95 px-4 py-3 backdrop-blur-md sm:px-5 md:px-8 md:py-3.5">
      <div class="min-w-0">
        <h1 id="page-title" class="truncate text-lg font-bold tracking-tight text-ink sm:text-xl">งานวันนี้</h1>
        <p class="text-xs text-muted">น้ำเหนือรีสอร์ท · บางเสร่ ชลบุรี</p>
      </div>
      <div class="flex items-center gap-2">
        <button class="btn-secondary hidden sm:inline-flex" data-action="command" aria-label="ค้นหาด่วน">
          <svg class="h-4 w-4" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
          <span>ค้นหา</span><kbd class="rounded bg-canvas px-1.5 py-0.5 text-[10px] text-muted">⌘ K</kbd>
        </button>
        <button class="btn-primary" data-action="new-booking" data-booking-control>
          <svg class="h-4 w-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M5 12h14"/><path d="M12 5v14"/></svg>
          <span class="hidden sm:inline">เปิดรายการเข้าพัก</span><span class="sm:hidden">เพิ่ม</span>
        </button>
      </div>
    </header>

    <!-- Main Container -->
    <main class="mx-auto w-full min-w-0 max-w-7xl flex-1 p-4 sm:p-5 md:p-8">
      <!-- Loading Skeleton Indicator -->
      <div id="loading" class="space-y-4" aria-busy="true" aria-label="กำลังเตรียมข้อมูลรีสอร์ท">
        <div class="card p-4 sm:p-5">
          <div class="skeleton h-4 w-28"></div>
          <div class="skeleton mt-3 h-7 w-56 max-w-full"></div>
          <div class="skeleton mt-2 h-3 w-40 max-w-full"></div>
        </div>
        <div class="grid grid-cols-2 gap-3 lg:grid-cols-4">
          <?php for ($i = 0; $i < 4; $i++): ?>
            <div class="card p-4"><div class="skeleton h-3 w-20"></div><div class="skeleton mt-3 h-8 w-12"></div></div>
          <?php endfor; ?>
        </div>
        <p class="sr-only">กำลังเตรียมข้อมูลรีสอร์ท…</p>
      </div>

      <!-- Live Notification Toast Region -->
      <div id="toast-region" aria-live="polite" class="fixed right-4 top-20 z-[70] space-y-2 pointer-events-none *:pointer-events-auto"></div>

      <!-- Page 1: Today operations desk -->
      <section id="page-today" data-page-panel>
        <div id="today-desk"></div>
      </section>

      <!-- Page 2: Room Map -->
      <section id="page-room-map" data-page-panel>
        <div id="room-summary"></div>
        <div id="room-map"></div>
      </section>

      <!-- Page 2: Bookings -->
      <section id="page-bookings" data-page-panel hidden>
        <div class="mb-5 grid grid-cols-1 gap-3 sm:flex sm:flex-wrap sm:items-center sm:gap-2.5">
          <!-- View Switcher Segmented Control -->
          <div class="inline-flex rounded-xl border border-line bg-white p-1 shadow-subtle">
            <button class="btn-sm rounded-lg px-3.5 font-medium transition active text-brand-700 bg-brand-50" data-view="list">รายการ</button>
            <button class="btn-sm rounded-lg px-3.5 font-medium transition text-muted hover:text-ink" data-view="calendar">ปฏิทิน</button>
          </div>
          <!-- Filter Inputs -->
          <div class="relative min-w-0 flex-1">
            <input id="stay-search" class="field pl-9" placeholder="ค้นหาชื่อ เบอร์โทร ห้อง โซน หรือหมายเหตุ">
            <div class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3 text-muted">
              <svg class="h-4 w-4" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
            </div>
          </div>
          <select id="stay-status" class="field w-full sm:w-auto sm:min-w-[140px]">
            <option value="">ทุกสถานะ</option>
            <option value="0">รอเช็กอิน</option>
            <option value="1">กำลังเข้าพัก</option>
            <option value="2">เช็กเอาต์แล้ว</option>
          </select>
        </div>
        <div id="booking-list"></div>
        <div id="booking-calendar" hidden></div>
      </section>

      <!-- Page 3: Dashboard / Analytics -->
      <section id="page-dashboard" data-page-panel hidden>
        <!-- Range Filter Bar -->
        <div class="mb-6 card flex flex-wrap items-center justify-between gap-4 p-4">
          <div class="w-full space-y-3 lg:flex lg:w-auto lg:items-center lg:space-y-0">
            <div class="grid grid-cols-3 rounded-xl border border-line bg-canvas/70 p-1 sm:inline-flex">
              <button class="btn-sm rounded-lg px-3 font-medium text-muted hover:text-ink" data-range="today">วันนี้</button>
              <button class="btn-sm rounded-lg px-3 font-medium text-muted hover:text-ink" data-range="7days">7 วันล่าสุด</button>
              <button class="btn-sm rounded-lg px-3 font-medium text-muted hover:text-ink" data-range="month">เดือนนี้</button>
            </div>
            <div class="grid grid-cols-2 gap-2 text-sm sm:ml-2 sm:inline-flex sm:items-center">
              <input id="range-start" class="field !min-h-[44px] w-full !py-1.5 sm:w-auto" type="date" aria-label="วันที่เริ่มต้น">
              <span class="hidden text-xs text-muted sm:inline">ถึง</span>
              <input id="range-end" class="field !min-h-[44px] w-full !py-1.5 sm:w-auto" type="date" aria-label="วันที่สิ้นสุด">
              <button id="apply-range" class="btn-primary col-span-2 !min-h-[44px] px-3 !py-1.5 text-xs sm:col-span-1">แสดงผล</button>
            </div>
          </div>
          <div class="grid w-full grid-cols-2 gap-2 sm:flex sm:w-auto sm:items-center">
            <a class="btn-secondary !min-h-[44px] !py-1.5 text-xs" href="/api/v1/reports/bookings.csv">
              <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" x2="12" y1="15" y2="3"/></svg>
              <span>ส่งออก CSV</span>
            </a>
            <button class="btn-secondary !min-h-[44px] !py-1.5 text-xs" data-action="print">
              <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24"><polyline points="6 9 6 2 18 2 18 9"/><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><rect width="12" height="8" x="6" y="14"/></svg>
              <span>พิมพ์</span>
            </button>
          </div>
        </div>
        <div id="analytics"></div>
      </section>

      <!-- Page 4: Rooms Management -->
      <section id="page-rooms" data-page-panel hidden>
        <div class="mb-5 flex flex-wrap items-center justify-between gap-3">
          <div class="min-w-0">
            <h2 class="text-base font-bold text-ink">รายการห้องพักทั้งหมด</h2>
            <p class="text-xs text-muted">จัดการราคาพื้นฐาน เตียง และสิ่งอำนวยความสะดวก</p>
          </div>
          <button class="btn-primary" data-action="new-room">
            <svg class="h-4 w-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M5 12h14"/><path d="M12 5v14"/></svg>
            <span>เพิ่มห้องพัก</span>
          </button>
        </div>
        <div id="rooms-list" class="space-y-3"></div>
      </section>

      <!-- Page 5: Guests Directory -->
      <section id="page-guests" data-page-panel hidden>
        <div class="mb-5 grid grid-cols-1 gap-3 sm:flex sm:flex-wrap sm:items-center">
          <div class="relative min-w-0 flex-1">
            <input id="guest-search" class="field pl-9" placeholder="ค้นหาชื่อหรือเบอร์โทรลูกค้า">
            <div class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3 text-muted">
              <svg class="h-4 w-4" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
            </div>
          </div>
          <select id="guest-sort" class="field w-full sm:w-auto sm:min-w-[150px]">
            <option value="latest">เข้าพักล่าสุด</option>
            <option value="count">จำนวนครั้งที่พัก</option>
            <option value="value">ยอดใช้จ่ายสะสม</option>
            <option value="name">เรียงตามชื่อ</option>
          </select>
          <label class="inline-flex min-h-[44px] items-center gap-2 rounded-xl border border-line bg-white px-4 text-xs font-semibold text-ink cursor-pointer hover:border-brand-300 shadow-subtle select-none">
            <input id="regular-only" type="checkbox" class="rounded border-line text-brand-500 focus:ring-brand-500/30">
            <span>ลูกค้าประจำเท่านั้น</span>
          </label>
        </div>
        <div id="guest-list" class="grid gap-3.5 md:grid-cols-2"></div>
      </section>
    </main>
  </div>

  <!-- Mobile Bottom Navigation Bar (Quiet Luxury) -->
  <nav class="mobile-nav no-print fixed inset-x-0 bottom-0 z-40 grid grid-cols-6 border-t border-line bg-white/95 px-1 pt-1 backdrop-blur-md md:hidden shadow-dropdown" aria-label="เมนูมือถือ">
    <button class="active flex flex-col items-center justify-center py-2 text-[10px] font-semibold text-brand-700 transition" data-page="today">
      <svg class="h-4 w-4 mb-0.5" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24"><path d="M3 12h4l2-6 4 12 2-6h6"/></svg>
      <span>วันนี้</span>
    </button>
    <button class="flex flex-col items-center justify-center py-2 text-[10px] font-semibold text-muted transition" data-page="room-map">
      <svg class="h-4 w-4 mb-0.5" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24"><rect width="7" height="7" x="3" y="3" rx="1.5"/><rect width="7" height="7" x="14" y="3" rx="1.5"/><rect width="7" height="7" x="14" y="14" rx="1.5"/><rect width="7" height="7" x="3" y="14" rx="1.5"/></svg>
      <span>ผังห้อง</span>
    </button>
    <button class="flex flex-col items-center justify-center py-2 text-[10px] font-semibold text-muted transition hover:text-brand-700" data-page="bookings">
      <svg class="h-4 w-4 mb-0.5" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24"><path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/><path d="m9 16 2 2 4-4"/></svg>
      <span>Booking</span>
    </button>
    <button class="flex flex-col items-center justify-center py-2 text-[10px] font-semibold text-muted transition hover:text-brand-700" data-page="dashboard">
      <svg class="h-4 w-4 mb-0.5" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24"><path d="M3 3v18h18"/><path d="m19 9-5 5-4-4-3 3"/></svg>
      <span>ภาพรวม</span>
    </button>
    <button class="flex flex-col items-center justify-center py-2 text-[10px] font-semibold text-muted transition hover:text-brand-700" data-page="rooms" data-manager-only>
      <svg class="h-4 w-4 mb-0.5" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24"><path d="M3 9.5 12 3l9 6.5V20a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1z"/><path d="M9 21V12h6v9"/></svg>
      <span>ห้อง</span>
    </button>
    <button class="flex flex-col items-center justify-center py-2 text-[10px] font-semibold text-muted transition hover:text-brand-700" data-page="guests">
      <svg class="h-4 w-4 mb-0.5" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
      <span>ลูกค้า</span>
    </button>
  </nav>
</div>

<!-- ================= MODALS / DIALOGS ================= -->

<!-- Global command palette -->
<dialog id="command-dialog" class="w-[min(94vw,620px)] rounded-3xl p-0 shadow-dialog border border-line bg-white">
  <div class="p-4 md:p-5">
    <div class="flex items-center gap-3 border-b border-line pb-3">
      <svg class="h-5 w-5 text-brand-500" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
      <input id="command-search" class="min-w-0 flex-1 border-0 bg-transparent text-base text-ink placeholder:text-muted focus:ring-0" placeholder="ค้นหาลูกค้า เบอร์โทร ห้อง หรือเมนู…" autocomplete="off">
      <button type="button" class="btn-ghost !min-h-[34px] !px-2 text-xs" data-close>Esc</button>
    </div>
    <div id="command-results" class="mt-3 max-h-[55vh] space-y-1 overflow-y-auto" role="listbox"></div>
  </div>
</dialog>

<!-- 1. Booking Dialog -->
<dialog id="booking-dialog" class="w-[min(96vw,740px)] rounded-3xl p-0 shadow-dialog border border-line bg-white">
  <form id="booking-form" class="p-6 md:p-8">
    <div class="flex items-center justify-between pb-4 border-b border-line/60">
      <div>
        <h2 class="text-xl font-bold tracking-tight text-ink">เปิดรายการเข้าพัก</h2>
        <p class="text-xs text-muted mt-0.5">กรอกข้อมูลผู้เข้าพัก รายละเอียดห้อง และคำนวณราคา</p>
      </div>
      <button type="button" class="btn-ghost !min-h-[36px] !p-2 text-muted hover:text-ink rounded-xl" data-close aria-label="ปิด">
        <svg class="h-5 w-5" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
      </button>
    </div>

    <input type="hidden" name="id">

    <div class="mt-6 space-y-6">
      <!-- Section 1: Guest Information -->
      <div>
        <h3 class="text-xs font-bold uppercase tracking-wider text-muted mb-3">1. ข้อมูลผู้เข้าพัก</h3>
        <div class="grid gap-4 md:grid-cols-2">
          <div>
            <label class="label">เบอร์โทรศัพท์</label>
            <input class="field" name="phone" required inputmode="tel" placeholder="08x-xxx-xxxx">
            <p class="hint">ระบบจะค้นหาประวัติลูกค้าเก่าให้อัตโนมัติ</p>
          </div>
          <div>
            <label class="label">ชื่อ-นามสกุล ลูกค้า</label>
            <input class="field" name="guest_name" required minlength="2" placeholder="คุณสมชาย ใจดี">
          </div>
        </div>
      </div>

      <!-- Section 2: Dates & Room -->
      <div>
        <h3 class="text-xs font-bold uppercase tracking-wider text-muted mb-3">2. วันที่และห้องพัก</h3>
        <div class="grid gap-4 md:grid-cols-2">
          <div>
            <label class="label">วันที่เช็กอิน <span class="font-normal text-muted">(13.00 น.)</span></label>
            <input class="field" type="date" name="check_in_date" required>
          </div>
          <div>
            <label class="label">วันที่เช็กเอาต์ <span class="font-normal text-muted">(12.00 น.)</span></label>
            <input class="field" type="date" name="check_out_date" required>
          </div>
          <div class="md:col-span-2">
            <label class="label">เลือกห้องพัก</label>
            <select class="field" name="room_id" required></select>
          </div>
        </div>
      </div>

      <!-- Section 3: Guests & Add-ons -->
      <div>
        <h3 class="text-xs font-bold uppercase tracking-wider text-muted mb-3">3. ผู้เข้าพัก & บริการเสริม</h3>
        <div class="grid gap-4 md:grid-cols-2">
          <div>
            <label class="label">จำนวนผู้เข้าพัก (ท่าน)</label>
            <input class="field" type="number" name="guests" min="1" value="2" required>
          </div>
          <div>
            <label class="label">ประเภทสัตว์เลี้ยง</label>
            <select class="field" name="pet_type">
              <option value="">ไม่มี</option>
              <option value="สุนัข">สุนัข</option>
              <option value="แมว">แมว</option>
              <option value="อื่น ๆ">อื่น ๆ</option>
            </select>
          </div>
          <div>
            <label class="label">จำนวนสัตว์เลี้ยง (ตัว)</label>
            <input class="field" type="number" name="pet_count" min="0" value="0">
          </div>
          <div>
            <label class="label">ส่วนลดพิเศษ (บาท)</label>
            <input class="field" type="number" name="discount_amount" min="0" step="0.01" value="0">
          </div>
          <div>
            <label class="label">เงินมัดจำ (บาท)</label>
            <input class="field" type="number" name="deposit_amount" min="0" step="0.01" value="0">
          </div>
        </div>

        <!-- Checkbox Options Grid -->
        <div class="mt-4 grid gap-3 sm:grid-cols-2">
          <label class="flex items-center gap-3 rounded-xl border border-line bg-canvas/40 p-3 cursor-pointer hover:border-brand-300">
            <input type="checkbox" name="extra_bed" class="rounded border-line text-brand-500 focus:ring-brand-500/20">
            <span class="text-xs font-medium text-ink">เตียงเสริม (+฿200/ครั้ง)</span>
          </label>
          <label class="flex items-center gap-3 rounded-xl border border-line bg-canvas/40 p-3 cursor-pointer hover:border-brand-300">
            <input type="checkbox" name="deposit_paid" class="rounded border-line text-brand-500 focus:ring-brand-500/20">
            <span class="text-xs font-medium text-ink">ชำระมัดจำแล้ว</span>
          </label>
          <label class="flex items-center gap-3 rounded-xl border border-line bg-canvas/40 p-3 cursor-pointer hover:border-brand-300">
            <input type="checkbox" name="id_verified" class="rounded border-line text-brand-500 focus:ring-brand-500/20">
            <span class="text-xs font-medium text-ink">ตรวจสอบบัตรประชาชนแล้ว</span>
          </label>
          <label class="flex items-center gap-3 rounded-xl border border-line bg-canvas/40 p-3 cursor-pointer hover:border-brand-300">
            <input type="checkbox" name="check_in_now" class="rounded border-line text-brand-500 focus:ring-brand-500/20">
            <span class="text-xs font-medium text-ink">เช็กอินทันที (เข้าพักตอนนี้)</span>
          </label>
        </div>

        <div class="mt-4">
          <label class="label">หมายเหตุการจอง / ข้อเรียกร้องพิเศษ</label>
          <textarea class="field !min-h-[72px]" name="note" rows="2" placeholder="เช่น ขอเช็กอินสาย, มีผู้สูงอายุ, เตียงเสริม"></textarea>
        </div>
      </div>
    </div>

    <!-- Live Dynamic Price Preview Breakdown -->
    <div id="price-preview" class="mt-6 rounded-2xl border border-brand-200 bg-brand-50/70 p-4 text-sm text-ink"></div>

    <!-- Form Footer Actions -->
    <div class="dialog-actions mt-6 flex items-center justify-end gap-3 pt-4 border-t border-line/60">
      <button type="button" class="btn-secondary" data-close>ยกเลิก</button>
      <button class="btn-primary" type="submit">บันทึก Booking</button>
    </div>
  </form>
</dialog>

<!-- 2. Room Dialog -->
<dialog id="room-dialog" class="w-[min(96vw,560px)] rounded-3xl p-0 shadow-dialog border border-line bg-white">
  <form id="room-form" class="p-6 md:p-8">
    <div class="flex items-center justify-between pb-4 border-b border-line/60">
      <div>
        <h2 class="text-xl font-bold tracking-tight text-ink">ข้อมูลห้องพัก</h2>
        <p class="text-xs text-muted mt-0.5">ตั้งค่าชื่อห้อง โซน ราคา และจำนวนแขกที่รองรับ</p>
      </div>
      <button type="button" class="btn-ghost !min-h-[36px] !p-2 text-muted hover:text-ink rounded-xl" data-close aria-label="ปิด">
        <svg class="h-5 w-5" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
      </button>
    </div>

    <input type="hidden" name="id">

    <div class="mt-6 grid gap-4 md:grid-cols-2">
      <div>
        <label class="label">ชื่อห้อง / หมายเลข</label>
        <input class="field" name="name" placeholder="เช่น 1, 2, A1" required>
      </div>
      <div>
        <label class="label">โซนที่ตั้ง</label>
        <input class="field" name="zone" value="อาคารหลัก" required>
      </div>
      <div>
        <label class="label">ประเภทห้อง / เตียง</label>
        <input class="field" name="type" value="เตียงคู่" required>
      </div>
      <div>
        <label class="label">ราคาปกติ / คืน (บาท)</label>
        <input class="field" type="number" name="price" min="1" value="500" required>
      </div>
      <div>
        <label class="label">จำนวนแขกพื้นฐาน</label>
        <input class="field" type="number" name="base_guests" min="1" value="2">
      </div>
      <div>
        <label class="label">จำนวนแขกสูงสุด</label>
        <input class="field" type="number" name="max_guests" min="1" value="3">
      </div>
      <div>
        <label class="label">ค่าแขกเสริม / ท่าน / คืน</label>
        <input class="field" type="number" name="extra_guest_fee" min="0" value="100">
      </div>
      <div>
        <label class="label">ลำดับการแสดงผล</label>
        <input class="field" type="number" name="sort_order" min="0" value="0">
      </div>
      <div class="md:col-span-2 pt-2">
        <label class="flex items-center gap-3 rounded-xl border border-line bg-canvas/40 p-3 cursor-pointer hover:border-brand-300">
          <input type="checkbox" name="is_pet_friendly" class="rounded border-line text-brand-500 focus:ring-brand-500/20">
          <span class="text-xs font-semibold text-ink">อนุญาตให้นำสัตว์เลี้ยงเข้าพัก (Pet Friendly)</span>
        </label>
      </div>
    </div>

    <div class="dialog-actions mt-6 flex items-center justify-end gap-3 pt-4 border-t border-line/60">
      <button type="button" class="btn-secondary" data-close>ยกเลิก</button>
      <button class="btn-primary" type="submit">บันทึกข้อมูลห้อง</button>
    </div>
  </form>
</dialog>

<!-- 3. Stay Action Dialog (Check-out checklist, Extension, Feedback, Upload) -->
<dialog id="action-dialog" class="w-[min(96vw,580px)] rounded-3xl p-0 shadow-dialog border border-line bg-white">
  <form id="action-form" class="p-6 md:p-8">
    <div class="flex items-center justify-between pb-4 border-b border-line/60">
      <div>
        <h2 id="action-title" class="text-xl font-bold tracking-tight text-ink">ดำเนินการ</h2>
        <p class="text-xs text-muted mt-0.5">จัดการสถานะการเข้าพัก</p>
      </div>
      <button type="button" class="btn-ghost !min-h-[36px] !p-2 text-muted hover:text-ink rounded-xl" data-close aria-label="ปิด">
        <svg class="h-5 w-5" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
      </button>
    </div>

    <input type="hidden" name="stay_id">
    <input type="hidden" name="action">

    <div id="action-fields" class="mt-6 space-y-4"></div>

    <div class="dialog-actions mt-6 flex items-center justify-end gap-3 pt-4 border-t border-line/60">
      <button type="button" class="btn-secondary" data-close>ยกเลิก</button>
      <button class="btn-primary" type="submit">ยืนยัน</button>
    </div>
  </form>
</dialog>

<!-- 4. Guest Detail Dialog -->
<dialog id="guest-dialog" class="w-[min(96vw,680px)] rounded-3xl p-0 shadow-dialog border border-line bg-white">
  <form id="guest-form" class="p-6 md:p-8">
    <div class="flex items-center justify-between pb-4 border-b border-line/60">
      <div>
        <h2 class="text-xl font-bold tracking-tight text-ink">ประวัติลูกค้า</h2>
        <p class="text-xs text-muted mt-0.5">ข้อมูลสถิติ โน้ตความชอบ และประวัติการจอง</p>
      </div>
      <button type="button" class="btn-ghost !min-h-[36px] !p-2 text-muted hover:text-ink rounded-xl" data-close aria-label="ปิด">
        <svg class="h-5 w-5" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
      </button>
    </div>

    <input type="hidden" name="id">

    <div id="guest-stats" class="mt-6"></div>

    <div class="mt-6 grid gap-4 md:grid-cols-2">
      <div>
        <label class="label">ชื่อ-นามสกุล</label>
        <input class="field" name="name" required>
      </div>
      <div>
        <label class="label">เบอร์โทรศัพท์</label>
        <input class="field" name="phone" required>
      </div>
      <div>
        <label class="label">กลุ่มลูกค้า</label>
        <input class="field" name="customer_type" placeholder="เช่น ลูกค้าทั่วไป, นักท่องเที่ยว">
      </div>
      <div class="flex items-end">
        <label class="flex min-h-[44px] w-full items-center gap-3 rounded-xl border border-line bg-canvas/40 px-3.5 cursor-pointer hover:border-brand-300">
          <input type="checkbox" name="is_regular" class="rounded border-line text-brand-500 focus:ring-brand-500/20">
          <span class="text-xs font-semibold text-brand-700">ลูกค้าประจำ (VIP Regular)</span>
        </label>
      </div>
      <div class="md:col-span-2">
        <label class="label">โน้ตถาวร / ข้อมูลสำคัญ</label>
        <textarea class="field !min-h-[64px]" name="customer_note" rows="2" placeholder="เช่น ชอบห้องมุม, แพ้ขนสัตว์, มีเด็กเล็ก"></textarea>
      </div>
      <div class="md:col-span-2">
        <label class="label">ความต้องการ / ความชอบเฉพาะตัว</label>
        <textarea class="field !min-h-[64px]" name="preferences" rows="2" placeholder="เช่น เตียงเสริมเสริมหมอน, กาแฟดำ"></textarea>
      </div>
    </div>

    <div class="mt-6">
      <h3 class="text-xs font-bold uppercase tracking-wider text-muted mb-2.5">ประวัติการเข้าพักที่ผ่านมา</h3>
      <div id="guest-history" class="space-y-2 max-h-52 overflow-y-auto pr-1"></div>
    </div>

    <div class="dialog-actions mt-6 flex items-center justify-end gap-3 pt-4 border-t border-line/60">
      <button type="button" class="btn-secondary" data-close>ยกเลิก</button>
      <button class="btn-primary" type="submit">บันทึกข้อมูลลูกค้า</button>
    </div>
  </form>
</dialog>
