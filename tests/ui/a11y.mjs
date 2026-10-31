// axe-core scan of every screen and dialog in light and dark. Fails on serious or critical issues.
// Usage: BASE_URL=http://localhost:8097 node a11y.mjs
import AxeBuilder from '@axe-core/playwright';
import { chromium } from 'playwright';

const base = process.env.BASE_URL ?? 'http://localhost:8097';
const tags = ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'];
const results = [];

async function scan(page, name, include) {
  const builder = new AxeBuilder({ page }).withTags(tags);
  if (include) builder.include(include);
  const { violations } = await builder.analyze();
  for (const v of violations) {
    results.push({ name, impact: v.impact, id: v.id, help: v.help, nodes: v.nodes.slice(0, 3).map(n => n.target.join(' ')) });
  }
}

const go = async (page, hash) => {
  await page.evaluate(h => { window.location.hash = h; }, hash);
  await page.waitForTimeout(200);
};
const open = async (page, selector, dialog) => {
  await page.locator(selector).first().click();
  await page.locator(`${dialog}[open]`).waitFor();
  await page.waitForTimeout(250);
};
const closeAll = page => page.evaluate(() => document.querySelectorAll('dialog[open]').forEach(d => d.close()));

const browser = await chromium.launch();
for (const theme of ['light', 'dark']) {
  for (const [device, viewport] of [['desktop', { width: 1440, height: 900 }], ['mobile', { width: 390, height: 844 }]]) {
    const context = await browser.newContext({ viewport, colorScheme: theme, locale: 'th-TH' });
    const page = await context.newPage();
    const label = name => `${theme}/${device}/${name}`;

    await page.goto(`${base}/login`);
    await scan(page, label('login'));
    await page.fill('#email', 'admin@staybook.local');
    await page.fill('#password', process.env.DEMO_ADMIN_PASSWORD ?? 'ChangeMe123!');
    await page.click('button[type="submit"]');
    await page.waitForURL(`${base}/`);
    await page.waitForFunction(() => !document.querySelector('#splash'));

    for (const hash of ['today', 'room-map', 'bookings', 'guests', 'dashboard', 'rooms']) {
      await go(page, hash);
      await scan(page, label(hash));
    }
    await go(page, 'bookings');
    await page.locator('[data-view="calendar"]').click();
    await page.locator('[data-calendar-today]').click();
    await scan(page, label('calendar'));
    await page.locator('[data-view="list"]').click();

    const dialogs = [
      ['booking-form', 'today', '[data-action="new-booking"]:visible', '#booking-dialog'],
      ['guest-profile', 'guests', '[data-action="guest-details"]:visible', '#guest-dialog'],
      ['room-form', 'rooms', '[data-action="new-room"]:visible', '#room-dialog'],
      ['checkout', 'bookings', '#booking-list [data-action="checkout"]:visible', '#action-dialog'],
      ['confirm', 'bookings', '#booking-list [data-action="check-in"]:visible', '#confirm-dialog'],
    ];
    for (const [name, hash, trigger, dialog] of dialogs) {
      await closeAll(page);
      await go(page, hash);
      await open(page, trigger, dialog);
      await scan(page, label(name), dialog);
    }
    await closeAll(page);
    await page.keyboard.press('Control+k');
    await page.locator('#command-dialog[open]').waitFor();
    await scan(page, label('command-palette'), '#command-dialog');
    await closeAll(page);

    await page.goto(`${base}/does-not-exist`);
    await scan(page, label('error-404'));
    await context.close();
  }
}
await browser.close();

const blocking = results.filter(r => r.impact === 'serious' || r.impact === 'critical');
for (const r of results) console.log(`${r.impact.padEnd(8)} ${r.name.padEnd(32)} ${r.id}: ${r.help}\n         ${r.nodes.join('\n         ')}`);
console.log(`${results.length} issue(s), ${blocking.length} serious or critical`);
process.exit(blocking.length ? 1 : 0);
