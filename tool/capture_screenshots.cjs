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

const label = (page, text) => page.locator(`flt-semantics[aria-label="${text}"], [aria-label="${text}"]`).first();
const button = (page, name) => page.getByRole('button', { name, exact: true }).first();

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

async function typeInto(page, ariaLabel, text) {
  const input = page.locator(`input[aria-label="${ariaLabel}"], textarea[aria-label="${ariaLabel}"], [aria-label="${ariaLabel}"] input`).first();
  await input.click();
  await input.fill(text);
}

async function phoneFlow(browser, colorScheme) {
  const context = await browser.newContext({ ...VIEWPORTS.phone, colorScheme });
  const page = await context.newPage();
  const suffix = colorScheme === 'dark' ? '-dark' : '';
  await page.goto(`http://127.0.0.1:${PORT}/`);
  await waitForApp(page);
  await shoot(page, `phone-explore${suffix}`);

  if (colorScheme === 'dark') { await context.close(); return; }

  // Details.
  await button(page, 'View').click();
  await page.waitForTimeout(1600);
  await shoot(page, 'phone-details');

  // Checkout.
  await button(page, 'Reserve').click();
  await page.waitForTimeout(1200);
  await typeInto(page, 'Full name', 'Priya Sharma');
  await typeInto(page, 'E-mail', 'priya@example.com');
  await typeInto(page, 'Phone', '+91 98765 43210');
  await page.keyboard.press('Tab');
  await page.waitForTimeout(400);
  await shoot(page, 'phone-booking');

  // Confirmation.
  await page.getByRole('checkbox').first().click();
  await page.waitForTimeout(300);
  await button(page, 'Confirm booking').click();
  await page.waitForTimeout(2400);
  await shoot(page, 'phone-confirmation');

  // Trips.
  await button(page, 'View my trips').click();
  await page.waitForTimeout(1400);
  await shoot(page, 'phone-trips');

  await context.close();
}

async function tabletFlow(browser) {
  const context = await browser.newContext(VIEWPORTS.tablet);
  const page = await context.newPage();
  await page.goto(`http://127.0.0.1:${PORT}/`);
  await waitForApp(page);
  await shoot(page, 'tablet-explore');
  await context.close();
}

async function desktopFlow(browser) {
  const context = await browser.newContext(VIEWPORTS.desktop);
  const page = await context.newPage();
  await page.goto(`http://127.0.0.1:${PORT}/`);
  await waitForApp(page);
  await shoot(page, 'desktop-explore');

  await button(page, 'View').click();
  await page.waitForTimeout(1600);
  await shoot(page, 'desktop-details');

  await button(page, 'Reserve').click();
  await page.waitForTimeout(1200);
  await shoot(page, 'desktop-booking');
  await context.close();

  const dark = await browser.newContext({ ...VIEWPORTS.desktop, colorScheme: 'dark' });
  const darkPage = await dark.newPage();
  await darkPage.goto(`http://127.0.0.1:${PORT}/`);
  await waitForApp(darkPage);
  await shoot(darkPage, 'desktop-explore-dark');
  await dark.close();
}

async function main() {
  const server = serve(WEB_DIR);
  await new Promise((resolve) => server.listen(PORT, '127.0.0.1', resolve));
  const browser = await chromium.launch({ args: ['--enable-unsafe-swiftshader'] });
  try {
    await phoneFlow(browser, 'light');
    await phoneFlow(browser, 'dark');
    await tabletFlow(browser);
    await desktopFlow(browser);
  } finally {
    await browser.close();
    server.close();
  }
}

main().catch((error) => { console.error(error); process.exit(1); });
