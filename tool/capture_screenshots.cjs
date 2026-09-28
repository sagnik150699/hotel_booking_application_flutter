#!/usr/bin/env node
/**
 * Drives the built web app through its main flows in headless Chromium and
 * saves screenshots for the README, at phone, tablet and desktop sizes.
 *
 * The app must be built with semantics enabled so the accessibility DOM is
 * available for Playwright to click:
 *
 *   flutter build web --release --no-web-resources-cdn --dart-define=SCREENSHOT_MODE=true
 *   NODE_PATH="$(npm root -g)" node tool/capture_screenshots.cjs
 */
const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const ROOT = path.resolve(__dirname, '..');
const WEB_DIR = process.env.WEB_DIR ? path.resolve(process.env.WEB_DIR) : path.join(ROOT, 'build', 'web');
const OUT_DIR = path.join(ROOT, 'docs', 'screenshots');
const PORT = Number(process.env.PORT || 8090);

const MIME = {
  '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json', '.wasm': 'application/wasm',
  '.png': 'image/png', '.jpg': 'image/jpeg', '.css': 'text/css', '.ttf': 'font/ttf', '.otf': 'font/otf',
};

function serve(dir) {
  return http.createServer((req, res) => {
    const url = decodeURIComponent(req.url.split('?')[0]);
    const file = path.join(dir, url === '/' ? 'index.html' : url);
    if (!file.startsWith(dir) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) { res.writeHead(404); return res.end(); }
    res.writeHead(200, { 'Content-Type': MIME[path.extname(file)] || 'application/octet-stream' });
    fs.createReadStream(file).pipe(res);
  });
}

const VIEWPORTS = {
  phone: { viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true, locale: 'en-US' },
  tablet: { viewport: { width: 1180, height: 820 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true, locale: 'en-US' },
  desktop: { viewport: { width: 1440, height: 900 }, deviceScaleFactor: 2, locale: 'en-US' },
};

/**
 * Flutter's web semantics tree renders buttons as <flt-semantics role="button">
 * whose label is text content, and lazily built list items only exist once
 * they are near the viewport. So we locate nodes by role + text, scroll with
 * the mouse wheel until they are on screen, and click their centre on the
 * canvas, which is exactly what a user does.
 */
async function findNode(page, { role, text, label }) {
  return page.evaluate(({ role, text, label }) => {
    const nodes = [...document.querySelectorAll('flt-semantics')];
    const matches = (el, wantRole) => {
      if (wantRole && el.getAttribute('role') !== wantRole) return false;
      const content = (el.textContent || '').trim();
      const aria = el.getAttribute('aria-label') || '';
      // Buttons expose their label as text content; other nodes as aria-label.
      // Plain text is often merged into an ancestor group's label, so match on
      // substrings and prefer the smallest node, which is the control itself.
      if (text && !content.includes(text) && !aria.includes(text)) return false;
      if (label && !aria.includes(label) && !content.includes(label)) return false;
      return true;
    };
    // Chips, for example, are exposed as checkboxes even when they act as
    // buttons, so fall back to ignoring the role if nothing matched.
    let candidates = nodes.filter((el) => matches(el, role));
    if (candidates.length === 0 && role) candidates = nodes.filter((el) => matches(el, null));
    if (candidates.length === 0) return null;
    const rects = candidates
      .map((el) => el.getBoundingClientRect())
      .filter((r) => r.width > 0 && r.height > 0);
    if (rects.length === 0) return null;
    const r = rects.reduce((best, cur) => (cur.width * cur.height < best.width * best.height ? cur : best));
    return { x: r.x, y: r.y, width: r.width, height: r.height };
  }, { role, text, label });
}

async function scrollNodeIntoView(page, match, { bottomInset = 0 } = {}) {
  const viewport = page.viewportSize();
  const usableBottom = viewport.height - bottomInset - 8;
  for (let attempt = 0; attempt < 14; attempt++) {
    const rect = await findNode(page, match);
    if (rect) {
      const cy = rect.y + rect.height / 2;
      // Clicking the centre is enough; edge-flush elements such as the tab
      // bar never fit entirely inside the inset area.
      if (cy >= 8 && cy <= usableBottom && rect.height > 4) {
        return rect;
      }
    }
    const delta = rect ? rect.y + rect.height / 2 - viewport.height / 2 : 500;
    await page.mouse.move(viewport.width / 2, Math.min(viewport.height / 2, usableBottom - 40));
    await page.mouse.wheel(0, Math.round(delta));
    await page.waitForTimeout(700);
  }
  throw new Error(`Could not bring node into view: ${JSON.stringify(match)}`);
}

async function clickNode(page, match, options) {
  const rect = await scrollNodeIntoView(page, match, options);
  await page.mouse.click(rect.x + rect.width / 2, rect.y + rect.height / 2);
}

async function waitForApp(page) {
  await page.waitForSelector('flutter-view', { state: 'attached', timeout: 60000 });
  await page.waitForSelector('flt-semantics-host', { state: 'attached', timeout: 60000 });
  // Semantics nodes appear once the first frame with content is rendered.
  await page.waitForFunction(() => document.querySelectorAll('flt-semantics').length > 20, null, { timeout: 60000 });
  await page.waitForTimeout(1800); // let entrance animations finish
}

async function shoot(page, name) {
  fs.mkdirSync(OUT_DIR, { recursive: true });
  const file = path.join(OUT_DIR, `${name}.png`);
  await page.screenshot({ path: file });
  console.log('wrote', path.relative(ROOT, file));
}

/** Fills the checkout form. Inputs are real DOM elements in document order. */
async function fillGuestForm(page) {
  const values = ['Priya Sharma', 'priya@example.com', '+91 98765 43210'];
  for (let i = 0; i < values.length; i++) {
    const input = page.locator('flutter-view input').nth(i);
    await input.scrollIntoViewIfNeeded().catch(() => {});
    await input.click();
    await input.fill(values[i]);
    await page.waitForTimeout(250);
  }
  await page.keyboard.press('Tab');
  await page.waitForTimeout(400);
}

const PHONE_NAV_INSET = 72; // bottom navigation bar height

async function openApp(browser, contextOptions) {
  const context = await browser.newContext(contextOptions);
  const page = await context.newPage();
  await page.goto(`http://127.0.0.1:${PORT}/`);
  await waitForApp(page);
  return { context, page };
}

async function scrollToTop(page) {
  const viewport = page.viewportSize();
  await page.mouse.move(viewport.width / 2, viewport.height / 2);
  for (let i = 0; i < 6; i++) await page.mouse.wheel(0, -2000);
  await page.waitForTimeout(600);
}

async function phoneFlow(browser) {
  const inset = { bottomInset: PHONE_NAV_INSET };
  const { context, page } = await openApp(browser, VIEWPORTS.phone);

  // 1. Explore.
  await shoot(page, 'phone-01-explore');

  // 2. Live search results.
  const search = page.locator('flutter-view input').first();
  await search.click();
  await search.fill('Goa');
  await page.keyboard.press('Enter');
  await page.waitForTimeout(900);
  await scrollNodeIntoView(page, { role: 'button', text: 'View' }, inset);
  await page.waitForTimeout(600);
  await shoot(page, 'phone-02-search-results');
  await clickNode(page, { role: 'button', text: 'Clear destination' }, inset);
  await page.waitForTimeout(600);

  // 3. Date range picker.
  await clickNode(page, { role: 'button', text: 'Choose check-in and check-out dates' }, inset);
  await page.waitForTimeout(1400);
  await shoot(page, 'phone-03-date-picker');
  await page.keyboard.press('Escape');
  await page.waitForTimeout(900);

  // 4. Filters applied.
  await scrollToTop(page);
  await clickNode(page, { role: 'checkbox', text: 'Free cancellation' }, inset);
  await page.waitForTimeout(500);
  await clickNode(page, { role: 'checkbox', text: 'Rated 4.5+' }, inset);
  await page.waitForTimeout(700);
  await scrollNodeIntoView(page, { role: 'button', text: 'View' }, inset);
  await page.waitForTimeout(500);
  await shoot(page, 'phone-04-filters');
  await clickNode(page, { role: 'button', text: 'Clear (' }, inset);
  await page.waitForTimeout(600);

  // 5. Details.
  await clickNode(page, { role: 'button', text: 'View' }, inset);
  await page.waitForTimeout(1800);
  await shoot(page, 'phone-05-details');

  // 6. Stay planner with the price breakdown.
  await scrollNodeIntoView(page, { text: 'Your stay' }, { bottomInset: 84 });
  await page.waitForTimeout(600);
  await shoot(page, 'phone-06-details-planner');

  // 7. Checkout validation.
  await clickNode(page, { role: 'button', text: 'Reserve' });
  await page.waitForTimeout(1400);
  await clickNode(page, { role: 'button', text: 'Confirm booking' });
  await page.waitForTimeout(900);
  await scrollToTop(page);
  await scrollNodeIntoView(page, { text: 'Guest details' });
  await page.waitForTimeout(400);
  await shoot(page, 'phone-07-checkout-validation');

  // 8. Checkout filled in.
  await fillGuestForm(page);
  await clickNode(page, { role: 'checkbox', text: 'I agree' });
  await page.waitForTimeout(300);
  await scrollNodeIntoView(page, { text: 'Guest details' });
  await page.waitForTimeout(400);
  await shoot(page, 'phone-08-checkout');

  // 9. Confirmation.
  await clickNode(page, { role: 'button', text: 'Confirm booking' });
  await page.waitForTimeout(2600);
  await shoot(page, 'phone-09-confirmation');

  // 10. Trips.
  await clickNode(page, { role: 'button', text: 'View my trips' });
  await page.waitForTimeout(1600);
  await shoot(page, 'phone-10-trips');

  // 11. Saved stays.
  await clickNode(page, { role: 'tab', text: 'Explore' });
  await page.waitForTimeout(900);
  await clickNode(page, { role: 'button', text: 'Save ' }, inset);
  await page.waitForTimeout(700);
  await clickNode(page, { role: 'tab', text: 'Saved' });
  await page.waitForTimeout(1400);
  await shoot(page, 'phone-11-saved');

  await context.close();
}

async function phoneDarkFlow(browser) {
  const { context, page } = await openApp(browser, { ...VIEWPORTS.phone, colorScheme: 'dark' });
  await shoot(page, 'phone-12-explore-dark');
  await clickNode(page, { role: 'button', text: 'View' }, { bottomInset: PHONE_NAV_INSET });
  await page.waitForTimeout(1800);
  await shoot(page, 'phone-13-details-dark');
  await context.close();
}

async function tabletFlow(browser) {
  const { context, page } = await openApp(browser, VIEWPORTS.tablet);
  await shoot(page, 'tablet-01-explore');
  await clickNode(page, { role: 'button', text: 'View' });
  await page.waitForTimeout(1800);
  await shoot(page, 'tablet-02-details');
  await context.close();
}

async function desktopFlow(browser) {
  const { context, page } = await openApp(browser, VIEWPORTS.desktop);
  await shoot(page, 'desktop-01-explore');

  await clickNode(page, { role: 'button', text: 'View' });
  await page.waitForTimeout(1800);
  await shoot(page, 'desktop-02-details');

  await clickNode(page, { role: 'button', text: 'Reserve' });
  await page.waitForTimeout(1400);
  await fillGuestForm(page);
  await clickNode(page, { role: 'checkbox', text: 'I agree' });
  await page.waitForTimeout(300);
  await shoot(page, 'desktop-03-checkout');

  await clickNode(page, { role: 'button', text: 'Confirm booking' });
  await page.waitForTimeout(2600);
  await shoot(page, 'desktop-04-confirmation');

  await clickNode(page, { role: 'button', text: 'View my trips' });
  await page.waitForTimeout(1600);
  await shoot(page, 'desktop-05-trips');

  await clickNode(page, { role: 'tab', text: 'Explore' });
  await page.waitForTimeout(900);
  await clickNode(page, { role: 'button', text: 'Save ' });
  await page.waitForTimeout(700);
  await clickNode(page, { role: 'tab', text: 'Saved' });
  await page.waitForTimeout(1400);
  await shoot(page, 'desktop-06-saved');
  await context.close();

  const dark = await openApp(browser, { ...VIEWPORTS.desktop, colorScheme: 'dark' });
  await shoot(dark.page, 'desktop-07-explore-dark');
  await dark.context.close();
}

async function main() {
  const server = serve(WEB_DIR);
  await new Promise((resolve) => server.listen(PORT, '127.0.0.1', resolve));
  const browser = await chromium.launch({ args: ['--enable-unsafe-swiftshader'] });
  try {
    await phoneFlow(browser);
    await phoneDarkFlow(browser);
    await tabletFlow(browser);
    await desktopFlow(browser);
  } finally {
    await browser.close();
    server.close();
  }
}

main().catch((error) => { console.error(error); process.exit(1); });
