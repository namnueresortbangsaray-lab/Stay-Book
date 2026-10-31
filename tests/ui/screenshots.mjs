// Captures every screen and dialog per theme and width into <outDir>/<theme>/<width>/.
// Usage: BASE_URL=http://localhost:8097 node screenshots.mjs <outDir> [light,dark] [390,768,1024,1440]
// Themes are applied through the OS colour scheme (the app's default "System" setting). Widths below 1280
// emulate a touch device (phone below 640), so touch sizing applies as on an iPad or phone.
import { mkdirSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { chromium } from 'playwright';

const base = process.env.BASE_URL ?? 'http://localhost:8097';
const out = resolve(process.argv[2] ?? 'shots');
const themes = (process.argv[3] ?? 'light').split(',');
const heights = { 390: 844, 768: 1024, 1024: 768, 1180: 820, 1440: 900 };
const widths = (process.argv[4] ?? '390,768,1024,1440').split(',').map(Number);

const ready = page => page.waitForFunction(() => !document.querySelector('#splash') && document.querySelector('#loading')?.hidden !== false, null, { timeout: 15000 });
const go = async (page, hash) => {
  await page.evaluate(h => { window.location.hash = h; }, hash);
  await page.waitForTimeout(250);
};
const openDialog = async (page, selector, dialog) => {
  await page.locator(selector).first().click();
  await page.locator(`${dialog}[open]`).waitFor();
  await page.waitForTimeout(300);
};
const closeDialogs = page => page.evaluate(() => document.querySelectorAll('dialog[open]').forEach(d => d.close()));

const screens = [
  ['01-today', p => go(p, 'today')],
  ['02-room-map', p => go(p, 'room-map')],
  ['03-bookings-list', p => go(p, 'bookings')],
  ['04-bookings-calendar', async p => { await go(p, 'bookings'); await p.locator('[data-view="calendar"]').click(); await p.locator('[data-calendar-today]').click(); await p.waitForTimeout(200); }],
  ['05-reports', async p => { await go(p, 'bookings'); await p.locator('[data-view="list"]').click(); await go(p, 'dashboard'); }],
  ['06-rooms', p => go(p, 'rooms')],
  ['07-guests', p => go(p, 'guests')],
  ['08-guest-profile', async p => { await go(p, 'guests'); await openDialog(p, '[data-action="guest-details"]:visible', '#guest-dialog'); }],
  ['09-booking-form', async p => { await go(p, 'today'); await openDialog(p, '[data-action="new-booking"]:visible', '#booking-dialog'); }],
  ['10-checkout', async p => { await go(p, 'bookings'); await openDialog(p, '#booking-list [data-action="checkout"]:visible', '#action-dialog'); }],
  ['11-command-palette', async p => { await go(p, 'today'); await p.keyboard.press('Control+k'); await p.locator('#command-dialog[open]').waitFor(); await p.keyboard.type('สมศรี'); await p.waitForTimeout(200); }],
  ['12-confirm', async p => { await go(p, 'bookings'); await openDialog(p, '#booking-list [data-action="check-in"]:visible', '#confirm-dialog'); }],
];

const browser = await chromium.launch();
for (const theme of themes) {
  for (const width of widths) {
    const height = heights[width] ?? 900;
    const dir = join(out, theme, String(width));
    mkdirSync(dir, { recursive: true });
    const context = await browser.newContext({
      viewport: { width, height }, colorScheme: theme, locale: 'th-TH', timezoneId: 'Asia/Bangkok', deviceScaleFactor: 1,
      hasTouch: width < 1280, isMobile: width < 640,
    });
    const page = await context.newPage();

    await page.goto(`${base}/login`);
    await page.screenshot({ path: join(dir, '00-login.png'), fullPage: true });
    await page.fill('#email', 'admin@staybook.local');
    await page.fill('#password', 'wrong-password');
    await page.click('button[type="submit"]');
    await page.screenshot({ path: join(dir, '00-login-error.png'), fullPage: true });
    await page.fill('#email', 'admin@staybook.local');
    await page.fill('#password', process.env.DEMO_ADMIN_PASSWORD ?? 'ChangeMe123!');
    await page.click('button[type="submit"]');
    await page.waitForURL(`${base}/`);
    await ready(page);

    for (const [name, action] of screens) {
      await closeDialogs(page);
      await action(page);
      // Full-page captures stitch fixed layers at the current scroll offset, so start from the top.
      await page.evaluate(() => window.scrollTo(0, 0));
      await page.waitForTimeout(100);
      await page.screenshot({ path: join(dir, `${name}.png`), fullPage: !name.match(/dialog|form|profile|checkout|palette|confirm/) });
    }
    await closeDialogs(page);
    if (width < 640) {
      await page.locator('[data-action="mobile-more"]:visible').first().click();
      await page.waitForTimeout(300);
      await page.screenshot({ path: join(dir, '13-mobile-menu.png') });
    }
    await page.goto(`${base}/does-not-exist`);
    await page.screenshot({ path: join(dir, '14-error-404.png'), fullPage: true });
    await context.close();
    console.log(`${theme}/${width} done`);
  }
}
await browser.close();
