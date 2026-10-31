// Accessibility and responsive checks against a running instance. Exits 1 on any failure.
// 1. axe-core on every screen and dialog in light and dark at phone, iPad and desktop widths (serious/critical fail).
// 2. Responsive sweep at phone, split-view, iPad and desktop widths: no horizontal page scroll; on touch widths
//    every control is at least 44x44px and inputs use 16px text (iOS zooms below that).
// Usage: BASE_URL=http://localhost:8097 node a11y.mjs
import AxeBuilder from '@axe-core/playwright';
import { chromium } from 'playwright';

const base = process.env.BASE_URL ?? 'http://localhost:8097';
const password = process.env.DEMO_ADMIN_PASSWORD ?? 'ChangeMe123!';
const tags = ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'];
const sections = ['today', 'room-map', 'bookings', 'guests', 'dashboard', 'rooms', 'users'];
// On phones the account actions live in the menu drawer.
const openPhoneMenu = async page => {
  const menu = page.locator('.topbar [data-action="mobile-more"]');
  if (await menu.isVisible()) {
    await menu.click();
    await page.locator('#mobile-more-dialog[open]').waitFor();
  }
};
const dialogs = [
  ['booking-form', 'today', '[data-action="new-booking"]:visible', '#booking-dialog'],
  ['guest-profile', 'guests', '[data-action="guest-details"]:visible', '#guest-dialog'],
  ['room-form', 'rooms', '[data-action="new-room"]:visible', '#room-dialog', '#rooms-tab-rooms'],
  ['checkout', 'bookings', '#booking-list [data-action="checkout"]:visible', '#action-dialog'],
  ['confirm', 'bookings', '#booking-list [data-action="check-in"]:visible', '#confirm-dialog'],
  ['zone-form', 'rooms', '[data-action="new-zone"]:visible', '#zone-dialog', '#rooms-tab-zones'],
  ['type-form', 'rooms', '[data-action="new-type"]:visible', '#type-dialog', '#rooms-tab-types'],
  ['user-form', 'users', '[data-action="new-user"]:visible', '#user-dialog'],
  ['account-password', 'today', '[data-action="change-password"]:visible', '#account-password-dialog', openPhoneMenu],
];
const violations = [];
const layout = [];

const context = (browser, width, theme = 'light') => browser.newContext({
  viewport: { width, height: width < 640 ? 844 : 900 }, colorScheme: theme, locale: 'th-TH', hasTouch: width < 1280, isMobile: width < 640,
});
async function signIn(page) {
  await page.goto(`${base}/login`);
  await page.fill('#email', 'admin@staybook.local');
  await page.fill('#password', password);
  await page.click('button[type="submit"]');
  await page.waitForURL(`${base}/`);
  await page.waitForFunction(() => !document.querySelector('#splash'));
}
const go = async (page, hash) => {
  await page.evaluate(h => { window.location.hash = h; }, hash);
  await page.waitForTimeout(200);
};
const closeAll = page => page.evaluate(() => document.querySelectorAll('dialog[open]').forEach(d => d.close()));
async function openDialog(page, hash, trigger, dialog, tab) {
  await closeAll(page);
  await go(page, hash);
  if (typeof tab === 'function') await tab(page);
  else if (tab) await page.locator(tab).click();
  await page.locator(trigger).first().click();
  await page.locator(`${dialog}[open]`).waitFor();
  await page.waitForTimeout(250);
}

async function axe(page, name, include) {
  const builder = new AxeBuilder({ page }).withTags(tags);
  if (include) builder.include(include);
  for (const v of (await builder.analyze()).violations) {
    violations.push({ name, impact: v.impact, id: v.id, help: v.help, nodes: v.nodes.slice(0, 3).map(n => n.target.join(' ')) });
  }
}

// Runs in the page: horizontal page scroll, controls under 44px and inputs under 16px (in the open dialog, if any).
function measure(touch) {
  const clipped = el => {
    for (let a = el.parentElement; a; a = a.parentElement) {
      const box = a.getBoundingClientRect();
      if (getComputedStyle(a).overflow === 'hidden' && (box.width <= 1 || box.height <= 1)) return true;
    }
    return false;
  };
  const shown = el => el.checkVisibility() && !el.closest('[hidden], [inert]') && !clipped(el);
  const result = { scroll: document.documentElement.scrollWidth > innerWidth ? `${document.documentElement.scrollWidth}px wide` : null, small: [], fonts: [] };
  if (!touch) return result;
  const scope = document.querySelector('dialog[open]') ?? document;
  for (const el of scope.querySelectorAll('a[href], button, input:not([type=hidden]), select, textarea, [role=tab]')) {
    if (!shown(el) || el.matches('.skip-link') || (el.matches('a:not(.btn)') && el.closest('p, li, td'))) continue; // inline text links are exempt
    const box = el.matches('input[type=checkbox], input[type=radio]') ? el.closest('label')?.getBoundingClientRect() ?? el.getBoundingClientRect() : el.getBoundingClientRect();
    if (box.width < 43.5 || box.height < 43.5) result.small.push(`${(el.getAttribute('aria-label') || el.textContent || el.name || el.tagName).trim().slice(0, 24)} ${Math.round(box.width)}x${Math.round(box.height)}`);
  }
  for (const el of scope.querySelectorAll('input:not([type=checkbox]):not([type=radio]):not([type=hidden]), select, textarea')) {
    if (shown(el) && parseFloat(getComputedStyle(el).fontSize) < 16) result.fonts.push(`${el.id || el.name} ${getComputedStyle(el).fontSize}`);
  }
  return result;
}
async function sweep(page, name, touch) {
  const r = await page.evaluate(measure, touch);
  if (r.scroll) layout.push(`${name}: horizontal page scroll (${r.scroll})`);
  for (const s of new Set(r.small)) layout.push(`${name}: target under 44px: ${s}`);
  for (const f of r.fonts) layout.push(`${name}: input text under 16px: ${f}`);
}

const browser = await chromium.launch();

for (const theme of ['light', 'dark']) {
  for (const width of [390, 768, 1440]) {
    const page = await (await context(browser, width, theme)).newPage();
    const label = name => `${theme}/${width}/${name}`;
    await page.goto(`${base}/login`);
    await axe(page, label('login'));
    await signIn(page);
    for (const hash of sections) {
      await go(page, hash);
      await axe(page, label(hash));
    }
    await go(page, 'bookings');
    await page.locator('[data-view="calendar"]').click();
    await page.locator('[data-calendar-today]').click();
    await axe(page, label('calendar'));
    await page.locator('[data-view="list"]').click();
    for (const tab of ['zones', 'types']) {
      await go(page, 'rooms');
      await page.locator(`#rooms-tab-${tab}`).click();
      await axe(page, label(`rooms-${tab}`));
    }
    for (const [name, hash, trigger, dialog, tab] of dialogs) {
      await openDialog(page, hash, trigger, dialog, tab);
      await axe(page, label(name), dialog);
    }
    await closeAll(page);
    await page.locator('[data-action="command"]:visible').first().click();
    await page.locator('#command-dialog[open]').waitFor();
    await axe(page, label('command-palette'), '#command-dialog');
    await page.goto(`${base}/does-not-exist`);
    await axe(page, label('error-404'));
    await page.context().close();
  }
}

for (const width of [390, 507, 640, 678, 768, 1024, 1180, 1440]) {
  const touch = width < 1280;
  const page = await (await context(browser, width)).newPage();
  await page.goto(`${base}/login`);
  await sweep(page, `${width}/login`, touch);
  await signIn(page);
  for (const hash of sections) {
    await go(page, hash);
    await sweep(page, `${width}/${hash}`, touch);
  }
  await go(page, 'bookings');
  await page.locator('[data-view="calendar"]').click();
  await sweep(page, `${width}/calendar`, touch);
  await page.locator('[data-view="list"]').click();
  for (const tab of ['zones', 'types']) {
    await go(page, 'rooms');
    await page.locator(`#rooms-tab-${tab}`).click();
    await sweep(page, `${width}/rooms-${tab}`, touch);
  }
  for (const [name, hash, trigger, dialog, tab] of dialogs) {
    await openDialog(page, hash, trigger, dialog, tab);
    await sweep(page, `${width}/${name}`, touch);
  }
  await page.context().close();
}
await browser.close();

for (const v of violations) console.log(`${v.impact.padEnd(8)} ${v.name.padEnd(30)} ${v.id}: ${v.help}\n         ${v.nodes.join('\n         ')}`);
for (const l of layout) console.log(`layout   ${l}`);
const blocking = violations.filter(v => v.impact === 'serious' || v.impact === 'critical');
console.log(`axe: ${violations.length} issue(s), ${blocking.length} serious or critical · layout: ${layout.length} issue(s)`);
process.exit(blocking.length || layout.length ? 1 : 0);
