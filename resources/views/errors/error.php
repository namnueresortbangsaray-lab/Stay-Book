<?php use App\Core\View; ?>
<main class="flex min-h-screen items-center justify-center bg-canvas p-6">
  <section class="card max-w-md w-full text-center p-8 sm:p-10 border border-line shadow-dialog">
    <div class="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-brand-50 text-brand-500">
      <svg class="h-8 w-8" fill="none" stroke="currentColor" stroke-width="1.75" viewBox="0 0 24 24" aria-hidden="true">
        <circle cx="12" cy="12" r="10"/>
        <line x1="12" y1="8" x2="12" y2="12"/>
        <line x1="12" y1="16" x2="12.01" y2="16"/>
      </svg>
    </div>
    <p class="text-4xl font-bold tracking-tight text-brand-500 sm:text-5xl"><?= View::e($status) ?></p>
    <h1 class="mt-3 text-lg font-semibold text-ink"><?= View::e($message) ?></h1>
    <p class="mt-2 text-sm text-muted">หากพบปัญหาต่อเนื่อง กรุณาติดต่อผู้ดูแลระบบ</p>
    <div class="mt-7">
      <a href="/" class="btn-primary w-full">กลับหน้าหลัก</a>
    </div>
  </section>
</main>
