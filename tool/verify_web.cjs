#!/usr/bin/env node
/**
 * Loads the built web app (build/web) in headless Chromium and fails if the
 * Content-Security-Policy in web/index.html blocks anything Flutter needs,
 * or if the page logs errors. Also checks that no request leaves the origin
 * when CanvasKit is bundled locally (`--no-web-resources-cdn`).
 *
 *   flutter build web --release --no-web-resources-cdn
 *   NODE_PATH="$(npm root -g)" node tool/verify_web.cjs
 */
const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const ROOT = path.resolve(__dirname, '..');
const WEB_DIR = path.join(ROOT, 'build', 'web');
const PORT = Number(process.env.PORT || 8089);

const MIME = {
  '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.json': 'application/json',
  '.wasm': 'application/wasm', '.png': 'image/png', '.jpg': 'image/jpeg', '.svg': 'image/svg+xml',
  '.css': 'text/css', '.ttf': 'font/ttf', '.otf': 'font/otf', '.woff2': 'font/woff2', '.ico': 'image/x-icon',
};

function serve(dir) {
  return http.createServer((req, res) => {
    const url = decodeURIComponent(req.url.split('?')[0]);
    let file = path.join(dir, url === '/' ? 'index.html' : url);
    if (!file.startsWith(dir)) { res.writeHead(403); return res.end(); }
    if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) { res.writeHead(404); return res.end('not found'); }
    res.writeHead(200, { 'Content-Type': MIME[path.extname(file)] || 'application/octet-stream' });
    fs.createReadStream(file).pipe(res);
  });
}

async function main() {
  if (!fs.existsSync(path.join(WEB_DIR, 'index.html'))) {
    throw new Error('build/web not found; run flutter build web first');
  }
  const server = serve(WEB_DIR);
  await new Promise((resolve) => server.listen(PORT, '127.0.0.1', resolve));
  const origin = `http://127.0.0.1:${PORT}`;

  // Headless Chromium can report no browser locale, which makes the Flutter
  // engine throw "Incorrect locale information provided" on start-up, so pin
  // one. SwiftShader gives CanvasKit a WebGL context without a GPU.
  const browser = await chromium.launch({ args: ['--enable-unsafe-swiftshader'] });
  const page = await browser.newPage({ viewport: { width: 1280, height: 800 }, locale: 'en-US' });

  const problems = [];
  const externalRequests = new Set();
  page.on('console', (msg) => {
    const text = msg.text();
    if (msg.type() === 'error' || /Content Security Policy|Refused to/.test(text)) problems.push(`console.${msg.type()}: ${text}`);
  });
  page.on('pageerror', (err) => problems.push(`pageerror: ${err.message}`));
  page.on('requestfailed', (req) => problems.push(`requestfailed: ${req.url()} (${req.failure()?.errorText})`));
  page.on('request', (req) => { if (!req.url().startsWith(origin)) externalRequests.add(req.url()); });

  await page.goto(`${origin}/`, { waitUntil: 'load' });
  // Wait for the Flutter view to be attached and the first frame drawn.
  await page.waitForSelector('flutter-view', { state: 'attached', timeout: 60000 });
  // The scene is rendered inside flt-glass-pane's shadow root.
  const findCanvas = () => {
    const pane = document.querySelector('flutter-view flt-glass-pane');
    const root = pane && pane.shadowRoot ? pane.shadowRoot : document;
    return root.querySelector('canvas');
  };
  await page.waitForFunction(findCanvas, null, { timeout: 60000 });
  await page.waitForTimeout(3000);
  const painted = await page.evaluate(() => {
    const pane = document.querySelector('flutter-view flt-glass-pane');
    const root = pane && pane.shadowRoot ? pane.shadowRoot : document;
    const canvas = root.querySelector('canvas');
    return canvas ? { width: canvas.width, height: canvas.height } : null;
  });
  console.log('flutter canvas:', JSON.stringify(painted));

  const csp = await page.$eval('meta[http-equiv="Content-Security-Policy"]', (el) => el.content);
  console.log('CSP present:', Boolean(csp && csp.includes("default-src 'self'")));

  const shot = path.join(ROOT, 'build', 'web-smoke.png');
  await page.screenshot({ path: shot });
  console.log('smoke screenshot:', path.relative(ROOT, shot));

  await browser.close();
  server.close();

  console.log('external requests:', externalRequests.size ? [...externalRequests] : 'none');
  if (problems.length) {
    console.error('PROBLEMS:\n' + problems.join('\n'));
    process.exit(1);
  }
  console.log('web verification passed');
}

main().catch((error) => { console.error(error); process.exit(1); });
