<?php use App\Core\Session; use App\Core\View; ?>
<main class="flex min-h-screen items-center justify-center bg-canvas px-4 py-12 sm:px-6 lg:px-8">
  <div class="w-full max-w-md">
    <!-- Brand Emblem & Warm Hospitality Intro -->
    <div class="text-center mb-8">
      <img src="/images/logo_banner.webp" alt="น้ำเหนือรีสอร์ท บางเสร่" class="mx-auto h-20 w-auto object-contain drop-shadow-sm">
      <h1 class="mt-5 text-2xl font-bold tracking-tight text-ink sm:text-3xl">เข้าสู่ระบบพนักงาน</h1>
      <p class="mt-2 text-sm text-muted">ระบบบริหารห้องพักและสมุดบันทึกผู้เข้าพัก · บางเสร่</p>
    </div>

    <!-- Login Card -->
    <section class="card bg-white p-7 sm:p-9 border border-line shadow-dialog">
      <?php if ($error): ?>
        <div role="alert" class="mb-6 flex items-center gap-3 rounded-xl border border-red-200 bg-red-50/70 p-3.5 text-sm text-red-700">
          <svg class="h-5 w-5 shrink-0 text-red-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
            <circle cx="12" cy="12" r="10"/>
            <line x1="12" y1="8" x2="12" y2="12"/>
            <line x1="12" y1="16" x2="12.01" y2="16"/>
          </svg>
          <span class="font-medium"><?= View::e($error) ?></span>
        </div>
      <?php endif; ?>

      <form method="post" action="/login" class="space-y-5">
        <input type="hidden" name="_token" value="<?= View::e(Session::csrf()) ?>">

        <div>
          <label class="label" for="email">อีเมลเข้าใช้งาน</label>
          <input
            class="field"
            id="email"
            name="email"
            type="email"
            placeholder="admin@staybook.local"
            autocomplete="username"
            required
            autofocus
          >
        </div>

        <div>
          <div class="flex items-center justify-between mb-1.5">
            <label class="label !mb-0" for="password">รหัสผ่าน</label>
          </div>
          <input
            class="field"
            id="password"
            name="password"
            type="password"
            placeholder="••••••••••••"
            autocomplete="current-password"
            required
          >
        </div>

        <div class="pt-2">
          <button class="btn-primary btn-lg w-full text-base font-medium" type="submit">
            เข้าสู่ระบบ
          </button>
        </div>
      </form>
    </section>

    <!-- Quiet Footer Reassurance -->
    <p class="mt-8 text-center text-xs text-muted/80">
      น้ำเหนือรีสอร์ท บางเสร่ · ที่พักหลักร้อย สะดวก สะอาด ปลอดภัย
    </p>
  </div>
</main>
