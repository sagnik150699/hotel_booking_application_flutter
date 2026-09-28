#!/usr/bin/env node
/**
 * Generates every raster image the project ships from vector definitions:
 *
 *   • assets/images/hotels/<id>.jpg       illustrated cover art per hotel
 *   • Android launcher icons              legacy mipmaps + adaptive foreground
 *   • iOS AppIcon set + LaunchImage       all sizes listed in Contents.json
 *   • web icons + favicon                 regular and maskable variants
 *   • docs/images/banner.png              README hero banner
 *   • docs/images/architecture.png        README architecture diagram
 *
 * Rendering uses headless Chromium through Playwright so the output is
 * identical on every machine. Run from the repository root:
 *
 *   npm install -g playwright && npx playwright install chromium
 *   NODE_PATH="$(npm root -g)" node tool/generate_images.cjs
 */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const ROOT = path.resolve(__dirname, '..');
const out = (...p) => path.join(ROOT, ...p);
const ensureDir = (file) => fs.mkdirSync(path.dirname(file), { recursive: true });

// ---------------------------------------------------------------------------
// Brand
// ---------------------------------------------------------------------------
const BRAND = {
  seed: '#0E6B5C',
  seedLight: '#17907A',
  seedDark: '#0A4E43',
  accent: '#E8734A',
  star: '#F2B84B',
};

/** Logo glyph (façade + sun) in a 512 viewBox. */
function brandGlyph(scale = 1, offset = 0) {
  const s = (v) => offset + v * scale;
  const windows = [
    [156, 212], [230, 212], [304, 212], [156, 292], [304, 292],
  ]
    .map(([x, y]) => `<rect x="${s(x)}" y="${s(y)}" width="${52 * scale}" height="${52 * scale}" rx="${12 * scale}" fill="${BRAND.seed}"/>`)
    .join('');
  return `
    <circle cx="${s(372)}" cy="${s(150)}" r="${46 * scale}" fill="${BRAND.star}"/>
    <rect x="${s(120)}" y="${s(176)}" width="${272 * scale}" height="${216 * scale}" rx="${28 * scale}" fill="#FFFFFF"/>
    ${windows}
    <path d="M ${s(226)} ${s(392)} V ${s(322)} a ${30 * scale} ${30 * scale} 0 0 1 ${60 * scale} 0 V ${s(392)} Z" fill="${BRAND.accent}"/>
  `;
}

function brandTileSvg({ rounded = true, transparentBg = false, glyphScale = 1, background = true } = {}) {
  const offset = (512 - 512 * glyphScale) / 2;
  const rx = rounded ? 112 : 0;
  const bg = background
    ? `<rect width="512" height="512" rx="${rx}" fill="url(#tile)"/>`
    : '';
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
    <defs>
      <linearGradient id="tile" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stop-color="${BRAND.seedLight}"/>
        <stop offset="0.55" stop-color="${BRAND.seed}"/>
        <stop offset="1" stop-color="${BRAND.seedDark}"/>
      </linearGradient>
    </defs>
    ${transparentBg ? '' : bg}
    ${brandGlyph(glyphScale, offset)}
  </svg>`;
}

// ---------------------------------------------------------------------------
// Scene primitives (1200 x 800 canvas)
// ---------------------------------------------------------------------------
const W = 1200;
const H = 800;

const sky = (top, bottom, id = 'sky') => `
  <defs><linearGradient id="${id}" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="${top}"/><stop offset="1" stop-color="${bottom}"/>
  </linearGradient></defs>
  <rect width="${W}" height="${H}" fill="url(#${id})"/>`;

const glow = (cx, cy, r, color, opacity = 0.35) => `
  <defs><radialGradient id="glow${cx}${cy}" cx="50%" cy="50%" r="50%">
    <stop offset="0" stop-color="${color}" stop-opacity="${opacity}"/>
    <stop offset="1" stop-color="${color}" stop-opacity="0"/>
  </radialGradient></defs>
  <circle cx="${cx}" cy="${cy}" r="${r}" fill="url(#glow${cx}${cy})"/>`;

const sun = (cx, cy, r, color) => `${glow(cx, cy, r * 2.6, color)}<circle cx="${cx}" cy="${cy}" r="${r}" fill="${color}"/>`;

const stars = (count, seed, color = '#FFFFFF', maxY = 380) => {
  let s = seed;
  const rnd = () => { s = (s * 9301 + 49297) % 233280; return s / 233280; };
  let svg = '';
  for (let i = 0; i < count; i++) {
    const x = rnd() * W; const y = rnd() * maxY; const r = 0.8 + rnd() * 1.8;
    svg += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${r.toFixed(1)}" fill="${color}" opacity="${(0.5 + rnd() * 0.5).toFixed(2)}"/>`;
  }
  return svg;
};

const cloud = (x, y, s, color = '#FFFFFF', opacity = 0.7) => `
  <g transform="translate(${x} ${y}) scale(${s})" fill="${color}" opacity="${opacity}">
    <ellipse cx="0" cy="0" rx="60" ry="26"/><ellipse cx="40" cy="-14" rx="44" ry="30"/>
    <ellipse cx="-40" cy="-8" rx="38" ry="24"/><ellipse cx="80" cy="4" rx="36" ry="20"/>
  </g>`;

/** Smooth ridge across the canvas. pts: [[x,y],...] */
const ridge = (pts, color, baseY = H) => {
  let d = `M 0 ${baseY} L ${pts[0][0]} ${pts[0][1]}`;
  for (let i = 1; i < pts.length; i++) {
    const [x0, y0] = pts[i - 1]; const [x1, y1] = pts[i];
    const cx = (x0 + x1) / 2;
    d += ` Q ${x0} ${y0} ${cx} ${(y0 + y1) / 2}`;
    if (i === pts.length - 1) d += ` T ${x1} ${y1}`;
  }
  d += ` L ${W} ${baseY} Z`;
  return `<path d="${d}" fill="${color}"/>`;
};

const jaggedRidge = (pts, color, baseY = H) => {
  const d = `M 0 ${baseY} ` + pts.map(([x, y]) => `L ${x} ${y}`).join(' ') + ` L ${W} ${baseY} Z`;
  return `<path d="${d}" fill="${color}"/>`;
};

const ground = (y, color) => `<rect x="0" y="${y}" width="${W}" height="${H - y}" fill="${color}"/>`;

const waterWithReflection = (y, color, shimmer = '#FFFFFF') => `
  ${ground(y, color)}
  ${[0, 1, 2, 3, 4, 5, 6].map((i) => `<rect x="${80 + i * 170}" y="${y + 30 + (i % 3) * 40}" width="${90 + (i % 2) * 50}" height="4" rx="2" fill="${shimmer}" opacity="${0.18 + (i % 3) * 0.08}"/>`).join('')}
`;

const waves = (y, color) => {
  let d = `M 0 ${y}`;
  for (let x = 0; x <= W; x += 100) d += ` q 25 -18 50 0 t 50 0`;
  d += ` L ${W} ${H} L 0 ${H} Z`;
  return `<path d="${d}" fill="${color}"/>`;
};

/** Simple building block with optional window grid. */
const building = (x, y, w, h, color, { windows = true, winColor = '#FFE9B0', cols = 3, rows = 0, rx = 4, winOpacity = 0.85 } = {}) => {
  let svg = `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${rx}" fill="${color}"/>`;
  if (windows) {
    const gap = 8;
    const ww = (w - gap * (cols + 1)) / cols;
    const wh = Math.min(ww * 1.3, 26);
    const rr = rows || Math.floor((h - gap) / (wh + gap * 1.6));
    let s = x * 31 + y * 17;
    const rnd = () => { s = (s * 9301 + 49297) % 233280; return s / 233280; };
    for (let r = 0; r < rr; r++) {
      for (let c = 0; c < cols; c++) {
        if (rnd() < 0.22) continue;
        svg += `<rect x="${(x + gap + c * (ww + gap)).toFixed(1)}" y="${(y + gap + r * (wh + gap * 1.6)).toFixed(1)}" width="${ww.toFixed(1)}" height="${wh.toFixed(1)}" rx="2" fill="${winColor}" opacity="${winOpacity}"/>`;
      }
    }
  }
  return svg;
};

const dome = (cx, baseY, r, color, finial = true) => `
  <path d="M ${cx - r} ${baseY} A ${r} ${r} 0 0 1 ${cx + r} ${baseY} Z" fill="${color}"/>
  ${finial ? `<rect x="${cx - 3}" y="${baseY - r - 26}" width="6" height="28" fill="${color}"/><circle cx="${cx}" cy="${baseY - r - 30}" r="7" fill="${color}"/>` : ''}`;

const arch = (x, y, w, h, color) => `<path d="M ${x} ${y + h} V ${y + w / 2} A ${w / 2} ${w / 2} 0 0 1 ${x + w} ${y + w / 2} V ${y + h} Z" fill="${color}"/>`;

const palm = (x, y, s, trunk = '#3B2A1E', leaf = '#1F7A55') => {
  const leaves = [-70, -40, -10, 20, 50, 80].map((a) => `<path d="M 0 0 q ${Math.cos((a * Math.PI) / 180) * 70} ${Math.sin((a * Math.PI) / 180) * 70 - 40} ${Math.cos((a * Math.PI) / 180) * 150} ${Math.sin((a * Math.PI) / 180) * 150 - 20} q ${-Math.cos((a * Math.PI) / 180) * 60} ${-Math.sin((a * Math.PI) / 180) * 60 + 10} ${-Math.cos((a * Math.PI) / 180) * 150} ${-Math.sin((a * Math.PI) / 180) * 150 + 20} Z" fill="${leaf}"/>`).join('');
  return `<g transform="translate(${x} ${y}) scale(${s})">
    <path d="M -8 0 q 30 -140 -10 -300 l 22 0 q 48 160 14 300 Z" fill="${trunk}"/>
    <g transform="translate(6 -300)">${leaves}</g>
    <circle cx="6" cy="-300" r="12" fill="${trunk}"/>
  </g>`;
};

const tree = (x, y, s, color = '#2F7A4B', trunk = '#4A3323') => `
  <g transform="translate(${x} ${y}) scale(${s})">
    <rect x="-7" y="-40" width="14" height="60" fill="${trunk}"/>
    <circle cx="0" cy="-90" r="58" fill="${color}"/>
    <circle cx="-40" cy="-60" r="42" fill="${color}"/>
    <circle cx="42" cy="-64" r="44" fill="${color}"/>
  </g>`;

const scrim = () => `<defs><linearGradient id="scrim" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0.55" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.28"/>
</linearGradient></defs><rect width="${W}" height="${H}" fill="url(#scrim)"/>`;

const wrap = (inner) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" width="${W}" height="${H}">${inner}${scrim()}</svg>`;

// ---------------------------------------------------------------------------
// Scenes
// ---------------------------------------------------------------------------
const scenes = {
  'kol-park-residency': () => wrap(`
    ${sky('#6B3A7D', '#E98A7B')}
    ${sun(880, 250, 70, '#FFC98A')}
    ${cloud(200, 200, 1.2, '#FFFFFF', 0.35)} ${cloud(700, 130, 0.9, '#FFFFFF', 0.3)}
    ${ridge([[0, 520], [200, 500], [420, 515], [640, 495], [860, 510], [1200, 500]], '#4A2A57')}
    ${building(120, 330, 210, 300, '#7A4F86', { cols: 3, winColor: '#FFE1A6' })}
    ${building(360, 280, 300, 350, '#F1E1CF', { cols: 4, winColor: '#5E3A6B', winOpacity: 0.9 })}
    ${arch(390, 300, 60, 90, '#5E3A6B')} ${arch(480, 300, 60, 90, '#5E3A6B')} ${arch(570, 300, 60, 90, '#5E3A6B')}
    ${building(700, 360, 180, 270, '#5B3A69', { cols: 3, winColor: '#FFE1A6' })}
    ${building(900, 400, 160, 230, '#8B5B96', { cols: 2, winColor: '#FFE1A6' })}
    ${tree(80, 640, 1.1, '#2E6B4A')} ${tree(1120, 645, 1.25, '#2E6B4A')} ${tree(690, 650, 0.9, '#3A7A56')}
    ${ground(628, '#2B1E33')}
    <rect x="0" y="628" width="${W}" height="6" fill="#F5C38A" opacity="0.4"/>
  `),

  'kol-riverside-grand': () => wrap(`
    ${sky('#0E1F45', '#3B6CB6')}
    ${stars(70, 7)}
    ${sun(240, 190, 44, '#F6F1D6')}
    ${jaggedRidge([[0, 520], [140, 480], [300, 500], [440, 470], [600, 495], [760, 465], [900, 490], [1060, 470], [1200, 500]], '#122650')}
    <!-- cantilever bridge -->
    <g fill="#1C3D78">
      <rect x="0" y="520" width="${W}" height="14"/>
      <rect x="260" y="330" width="16" height="200"/> <rect x="900" y="330" width="16" height="200"/>
      <path d="M 268 330 L 590 470 L 908 330" stroke="#1C3D78" stroke-width="12" fill="none"/>
      <path d="M 268 330 Q 590 240 908 330" stroke="#1C3D78" stroke-width="10" fill="none"/>
      ${[300, 360, 420, 480, 540, 640, 700, 760, 820, 880].map((x) => `<rect x="${x}" y="${330 + Math.abs(590 - x) * 0.25}" width="4" height="${200 - Math.abs(590 - x) * 0.25}"/>`).join('')}
    </g>
    ${building(60, 380, 150, 150, '#1B3466', { cols: 3 })}
    ${building(1000, 360, 170, 170, '#1B3466', { cols: 3 })}
    ${waterWithReflection(534, '#22497F', '#9FC4FF')}
  `),

  'kol-salt-lake-suites': () => wrap(`
    ${sky('#4FA5C9', '#DDF0F7')}
    ${cloud(260, 160, 1.3, '#FFFFFF', 0.85)} ${cloud(820, 110, 1.0, '#FFFFFF', 0.8)} ${cloud(1050, 220, 0.8, '#FFFFFF', 0.7)}
    ${building(140, 250, 230, 380, '#F4F1EA', { cols: 4, winColor: '#5C93B5', winOpacity: 0.95 })}
    ${building(400, 300, 200, 330, '#E5DED2', { cols: 3, winColor: '#5C93B5', winOpacity: 0.95 })}
    ${building(640, 220, 260, 410, '#FAF7F0', { cols: 4, winColor: '#4F86A8', winOpacity: 0.95 })}
    ${building(930, 340, 170, 290, '#E5DED2', { cols: 3, winColor: '#5C93B5', winOpacity: 0.95 })}
    ${ground(628, '#B9D7A3')}
    <rect x="300" y="660" width="560" height="90" rx="26" fill="#63BEE0"/>
    <rect x="320" y="676" width="520" height="58" rx="20" fill="#8BD4EE" opacity="0.7"/>
    ${tree(90, 700, 0.9, '#3F8F5E')} ${tree(1120, 700, 0.95, '#3F8F5E')}
  `),

  'goa-anjuna-shore': () => wrap(`
    ${sky('#FF9A6B', '#FFD79A')}
    ${sun(700, 330, 90, '#FFF0B8')}
    ${cloud(180, 150, 1.1, '#FFFFFF', 0.55)} ${cloud(980, 200, 0.9, '#FFFFFF', 0.5)}
    ${ground(440, '#4FB3C2')}
    ${waves(560, '#2C97A8')}
    ${waves(640, '#F2E2B8')}
    ${ground(700, '#F7E8C4')}
    <!-- villa -->
    <rect x="720" y="520" width="240" height="120" rx="10" fill="#FFF7EA"/>
    <path d="M 700 530 L 840 440 L 980 530 Z" fill="#B9603E"/>
    <rect x="820" y="580" width="40" height="60" rx="6" fill="#2C97A8"/>
    ${palm(190, 690, 1.15)} ${palm(330, 700, 0.9, '#3B2A1E', '#2A8F63')} ${palm(1080, 700, 1.05)}
  `),

  'goa-panjim-latin': () => wrap(`
    ${sky('#7FC6E8', '#F6E7C8')}
    ${sun(1000, 170, 56, '#FFE38A')}
    ${cloud(300, 140, 1.0, '#FFFFFF', 0.85)}
    ${ridge([[0, 460], [300, 430], [600, 455], [900, 425], [1200, 450]], '#8DB58A')}
    ${[['#F2C14E', 120], ['#E8734A', 300], ['#7BA7D7', 480], ['#F49AC2', 660], ['#67B98A', 840], ['#F2C14E', 1020]].map(([c, x], i) => `
      ${building(x, 380 + (i % 2) * 30, 180, 250 - (i % 2) * 30, c, { windows: false })}
      ${[0, 1, 2].map((k) => `<rect x="${x + 22 + k * 52}" y="${410 + (i % 2) * 30}" width="34" height="56" rx="6" fill="#FFFFFF" opacity="0.9"/><rect x="${x + 22 + k * 52}" y="${410 + (i % 2) * 30}" width="34" height="8" fill="#3B2A1E" opacity="0.6"/>`).join('')}
      ${[0, 1, 2].map((k) => `<rect x="${x + 22 + k * 52}" y="${500 + (i % 2) * 30}" width="34" height="56" rx="6" fill="#FFFFFF" opacity="0.9"/>`).join('')}
      <rect x="${x}" y="${372 + (i % 2) * 30}" width="180" height="14" fill="#B9603E"/>
    `).join('')}
    ${ground(628, '#D9C7A5')}
    ${tree(60, 660, 0.8, '#3F8F5E')} ${tree(1140, 660, 0.85, '#3F8F5E')}
  `),

  'mum-marine-drive': () => wrap(`
    ${sky('#0B1A3A', '#1F3F7A')}
    ${stars(90, 3)}
    ${sun(960, 200, 40, '#FDF5D8')}
    ${[[40, 300, 120, 330], [180, 250, 140, 380], [340, 320, 110, 310], [470, 210, 150, 420], [640, 290, 130, 340], [790, 240, 120, 390], [930, 330, 110, 300], [1060, 270, 130, 360]].map(([x, y, w, h]) => building(x, y, w, h, '#2A4A86', { cols: 3, winColor: '#FFD98A' })).join('')}
    ${[[180, 250, 140], [470, 210, 150], [790, 240, 120]].map(([x, y, w]) => `<rect x="${x + w / 2 - 16}" y="${y - 40}" width="32" height="40" rx="6" fill="#2A4A86"/>`).join('')}
    <path d="M 0 640 Q 600 560 1200 640 L 1200 800 L 0 800 Z" fill="#0D1F45"/>
    <path d="M 0 630 Q 600 550 1200 630" stroke="#FFD98A" stroke-width="6" fill="none" stroke-dasharray="26 22" opacity="0.9"/>
    ${waterWithReflection(660, '#0A1834', '#7FA6FF')}
  `),

  'mum-bkc-loft': () => wrap(`
    ${sky('#1B2A4A', '#6C9BD1')}
    ${sun(220, 220, 60, '#FFE8B0')}
    ${cloud(600, 120, 1.1, '#FFFFFF', 0.25)}
    ${building(120, 180, 170, 450, '#2D4F86', { cols: 4, winColor: '#BFE1FF', winOpacity: 0.7 })}
    ${building(320, 260, 150, 370, '#3B62A3', { cols: 3, winColor: '#BFE1FF', winOpacity: 0.7 })}
    ${building(500, 120, 220, 510, '#28477B', { cols: 5, winColor: '#D8ECFF', winOpacity: 0.75 })}
    ${building(760, 220, 180, 410, '#3B62A3', { cols: 4, winColor: '#BFE1FF', winOpacity: 0.7 })}
    ${building(980, 300, 150, 330, '#2D4F86', { cols: 3, winColor: '#BFE1FF', winOpacity: 0.7 })}
    <rect x="500" y="100" width="220" height="30" rx="8" fill="#E8734A"/>
    ${ground(628, '#1B2A4A')}
    <rect x="0" y="640" width="${W}" height="10" fill="#FFFFFF" opacity="0.25"/>
    ${tree(80, 700, 0.8, '#2F7A4B')} ${tree(1130, 700, 0.8, '#2F7A4B')}
  `),

  'jai-haveli-amber': () => wrap(`
    ${sky('#F3A0A8', '#FFE1C4')}
    ${sun(260, 220, 70, '#FFF1C2')}
    ${ridge([[0, 470], [250, 440], [500, 465], [750, 430], [1000, 455], [1200, 440]], '#D9838C')}
    <!-- hawa mahal style facade -->
    <rect x="200" y="330" width="800" height="300" rx="10" fill="#E07B86"/>
    ${[0, 1, 2, 3, 4].map((r) => [0, 1, 2, 3, 4, 5, 6, 7].map((c) => `
      ${arch(230 + c * 96, 350 + r * 56, 44, 44, '#FFF3E2')}
      <rect x="${234 + c * 96}" y="${372 + r * 56}" width="36" height="20" fill="#C9646E" opacity="0.7"/>`).join('')).join('')}
    ${[240, 400, 560, 720, 880].map((cx) => dome(cx + 30, 330, 40, '#C9646E', false)).join('')}
    ${[280, 600, 920].map((cx) => dome(cx, 296, 30, '#F2B84B', true)).join('')}
    ${ground(628, '#B96F55')}
    <rect x="0" y="628" width="${W}" height="8" fill="#FFD9B0" opacity="0.6"/>
  `),

  'blr-indiranagar-loft': () => wrap(`
    ${sky('#B8A1E3', '#FFD5C2')}
    ${sun(940, 240, 62, '#FFF0D2')}
    ${cloud(220, 170, 1.1, '#FFFFFF', 0.6)}
    ${ridge([[0, 500], [300, 480], [600, 505], [900, 475], [1200, 495]], '#8C79B8')}
    ${building(180, 380, 260, 250, '#F4E9E1', { cols: 2, rows: 2, winColor: '#5C4B7A', winOpacity: 0.9 })}
    ${building(470, 320, 300, 310, '#E8734A', { cols: 3, rows: 3, winColor: '#FFF1E6', winOpacity: 0.95 })}
    ${building(800, 400, 220, 230, '#F4E9E1', { cols: 2, rows: 2, winColor: '#5C4B7A', winOpacity: 0.9 })}
    <rect x="470" y="300" width="300" height="22" rx="6" fill="#5C4B7A"/>
    <rect x="530" y="560" width="70" height="70" rx="8" fill="#5C4B7A"/>
    ${tree(110, 650, 1.1, '#3F8F5E')} ${tree(1110, 650, 1.05, '#3F8F5E')} ${tree(780, 655, 0.7, '#4EA26F')}
    ${ground(628, '#5C4B7A')}
    <rect x="0" y="634" width="${W}" height="4" fill="#FFD5C2" opacity="0.5"/>
  `),

  'blr-whitefield-inn': () => wrap(`
    ${sky('#7CC3F0', '#EAF6E5')}
    ${sun(220, 200, 58, '#FFF3B0')}
    ${cloud(700, 130, 1.0, '#FFFFFF', 0.85)} ${cloud(1000, 250, 0.7, '#FFFFFF', 0.75)}
    ${ridge([[0, 520], [400, 490], [800, 515], [1200, 495]], '#9CCB8E')}
    ${building(330, 330, 540, 300, '#FAF7F0', { cols: 6, rows: 3, winColor: '#5D9BC4', winOpacity: 0.95 })}
    <rect x="330" y="310" width="540" height="26" rx="6" fill="#4C9C63"/>
    <rect x="560" y="560" width="80" height="70" rx="8" fill="#4C9C63"/>
    <rect x="380" y="240" width="120" height="70" rx="10" fill="#F2C14E"/>
    ${ground(628, '#6E9E5C')}
    <rect x="0" y="690" width="${W}" height="60" fill="#5C5B60"/>
    <rect x="0" y="716" width="${W}" height="6" fill="#FFFFFF" opacity="0.7" stroke-dasharray="40 30"/>
    ${tree(150, 660, 1.2, '#3F8F5E')} ${tree(1060, 660, 1.1, '#3F8F5E')}
  `),

  'del-lodhi-garden': () => wrap(`
    ${sky('#F7C89C', '#FCEBD2')}
    ${sun(300, 190, 66, '#FFF3C4')}
    ${ridge([[0, 560], [300, 530], [600, 555], [900, 525], [1200, 545]], '#A9C48F')}
    <rect x="450" y="420" width="300" height="200" rx="8" fill="#C98A5B"/>
    ${dome(600, 420, 110, '#C98A5B', true)}
    ${arch(570, 500, 60, 120, '#7A4E32')} ${arch(480, 520, 40, 100, '#7A4E32')} ${arch(680, 520, 40, 100, '#7A4E32')}
    ${[470, 730].map((x) => `<rect x="${x - 10}" y="380" width="20" height="60" rx="6" fill="#C98A5B"/>`).join('')}
    ${tree(140, 640, 1.4, '#2F7A4B')} ${tree(330, 640, 1.0, '#3F8F5E')} ${tree(880, 640, 1.1, '#3F8F5E')} ${tree(1080, 640, 1.35, '#2F7A4B')}
    ${ground(620, '#7FB069')}
    <rect x="0" y="690" width="${W}" height="30" rx="14" fill="#63B0C8" opacity="0.7"/>
  `),

  'udp-lake-palace-view': () => wrap(`
    ${sky('#C9B6E8', '#FFD9C2')}
    ${sun(880, 250, 64, '#FFF2D4')}
    ${ridge([[0, 460], [300, 420], [600, 450], [900, 415], [1200, 445]], '#9E8DC4')}
    <rect x="360" y="410" width="480" height="150" rx="8" fill="#FFF6E9"/>
    ${dome(600, 410, 70, '#FFF6E9', true)} ${dome(420, 410, 40, '#FFF6E9', false)} ${dome(780, 410, 40, '#FFF6E9', false)}
    ${[0, 1, 2, 3, 4, 5, 6].map((k) => arch(380 + k * 66, 440, 36, 80, '#B98FD1')).join('')}
    ${waterWithReflection(560, '#7EA6D9', '#FFFFFF')}
    <rect x="360" y="560" width="480" height="150" fill="#FFF6E9" opacity="0.18"/>
    ${palm(120, 560, 0.7, '#4A3323', '#2F7A4B')} ${palm(1090, 560, 0.75, '#4A3323', '#2F7A4B')}
  `),

  'drj-tea-estate': () => wrap(`
    ${sky('#A9D6EA', '#EAF4EE')}
    ${sun(960, 180, 52, '#FFF6D0')}
    ${jaggedRidge([[0, 400], [150, 300], [300, 360], [430, 230], [560, 330], [700, 250], [860, 350], [1000, 280], [1200, 380]], '#F1F5F8', 460)}
    ${jaggedRidge([[0, 420], [150, 330], [300, 380], [430, 270], [560, 360], [700, 300], [860, 380], [1000, 320], [1200, 410]], '#B9C9D6', 480)}
    ${ridge([[0, 520], [300, 480], [600, 510], [900, 470], [1200, 500]], '#4E8F63')}
    ${ridge([[0, 600], [300, 570], [600, 600], [900, 560], [1200, 590]], '#3E7C54')}
    ${[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].map((k) => `<ellipse cx="${60 + k * 100}" cy="${690 + (k % 2) * 18}" rx="52" ry="26" fill="#2F6B45"/>`).join('')}
    ${[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map((k) => `<ellipse cx="${110 + k * 100}" cy="${745}" rx="56" ry="28" fill="#286040"/>`).join('')}
    <rect x="470" y="470" width="260" height="110" rx="8" fill="#F8F1E3"/>
    <path d="M 450 480 L 600 400 L 750 480 Z" fill="#8B4A3B"/>
    <rect x="580" y="520" width="40" height="60" rx="6" fill="#3E7C54"/>
    ${tree(330, 590, 0.9, '#2F6B45')} ${tree(880, 590, 0.85, '#2F6B45')}
  `),
};

// ---------------------------------------------------------------------------
// Docs images
// ---------------------------------------------------------------------------
function bannerHtml() {
  return `<!doctype html><html><head><meta charset="utf-8"><style>
    body{margin:0;width:1600px;height:640px;font-family:Inter,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
      background:linear-gradient(135deg,#0A4E43 0%,#0E6B5C 55%,#17907A 100%);color:#fff;position:relative;overflow:hidden}
    .blob{position:absolute;border-radius:50%;filter:blur(2px);opacity:.18;background:#fff}
    .wrap{position:absolute;inset:0;display:flex;align-items:center;gap:64px;padding:0 120px}
    h1{font-size:76px;margin:0 0 14px;letter-spacing:-1.5px;font-weight:800}
    p{font-size:28px;margin:0 0 30px;opacity:.9;max-width:900px;line-height:1.35}
    .pills{display:flex;gap:14px;flex-wrap:wrap}
    .pill{padding:12px 20px;border-radius:999px;background:rgba(255,255,255,.14);border:1px solid rgba(255,255,255,.35);font-size:22px;font-weight:600}
    .pill.accent{background:#E8734A;border-color:#E8734A}
  </style></head><body>
    <div class="blob" style="width:520px;height:520px;right:-120px;top:-160px"></div>
    <div class="blob" style="width:360px;height:360px;left:-140px;bottom:-200px"></div>
    <div class="wrap">
      <div style="width:220px;height:220px;flex:none;filter:drop-shadow(0 24px 40px rgba(0,0,0,.28))">${brandTileSvg().replace('width="512" height="512"', 'width="220" height="220"')}</div>
      <div>
        <h1>Hotel Booking App</h1>
        <p>A production-style Flutter sample: search, filter and book stays with a polished, animated UI that runs on Android, iOS and the web.</p>
        <div class="pills"><span class="pill accent">Flutter 3</span><span class="pill">Material 3</span><span class="pill">Android</span><span class="pill">iOS</span><span class="pill">Web</span><span class="pill">Tested</span><span class="pill">Hardened</span></div>
      </div>
    </div>
  </body></html>`;
}

function architectureHtml() {
  const layer = (title, note, items, color) => `
    <div class="layer" style="--c:${color}">
      <div class="head"><b>${title}</b><span>${note}</span></div>
      <div class="items">${items.map((i) => `<code>${i}</code>`).join('')}</div>
    </div>`;
  return `<!doctype html><html><head><meta charset="utf-8"><style>
    body{margin:0;width:1400px;height:900px;background:#F6FAF8;font-family:Inter,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;color:#172026;padding:48px 56px;box-sizing:border-box}
    h1{margin:0 0 6px;font-size:36px;letter-spacing:-.5px}
    .sub{margin:0 0 28px;color:#52616A;font-size:20px}
    .grid{display:grid;grid-template-columns:1fr 1fr;gap:22px}
    .layer{background:#fff;border:2px solid var(--c);border-radius:20px;padding:22px 24px}
    .layer.full{grid-column:1/3}
    .head{display:flex;justify-content:space-between;align-items:baseline;margin-bottom:14px}
    .head b{font-size:24px;color:var(--c)} .head span{color:#52616A;font-size:16px}
    .items{display:flex;flex-wrap:wrap;gap:10px}
    code{background:#F1F5F3;border-radius:10px;padding:8px 12px;font-size:16px;font-family:"JetBrains Mono",Menlo,Consolas,monospace}
    .arrow{grid-column:1/3;text-align:center;color:#52616A;font-size:18px;margin:-6px 0}
    .arrow b{color:#0E6B5C}
  </style></head><body>
    <h1>Architecture: feature-first, dependency-free state</h1>
    <p class="sub">Widgets depend only on controllers; controllers depend only on repository interfaces; the domain depends on nothing.</p>
    <div class="grid">
      ${layer('Presentation', 'Flutter widgets, Material 3, animations', ['HomeShell', 'ExplorePage', 'HotelDetailsPage', 'BookingPage', 'BookingConfirmationPage', 'SavedHotelsPage', 'TripsPage', 'HotelCard', 'StaySearchPanel'], '#E8734A').replace('class="layer"', 'class="layer full"')}
      <div class="arrow">rebuilds via <b>ListenableBuilder</b> · reads controllers from <b>AppScope</b> (InheritedWidget)</div>
      ${layer('Application', 'ChangeNotifier controllers', ['HotelSearchController', 'SavedHotelsController', 'BookingsController', 'ShellController'], '#0E6B5C').replace('class="layer"', 'class="layer full"')}
      <div class="arrow">calls <b>pure domain logic</b> and <b>repository interfaces</b></div>
      ${layer('Domain', 'plain Dart, fully unit tested', ['Hotel', 'StaySearch', 'StayQuote', 'HotelFilters', 'HotelSearchEngine', 'GuestDetails + Validator', 'BookingPolicy', 'ConfirmationCodeGenerator'], '#1F3B73')}
      ${layer('Data', 'swappable implementations', ['HotelRepository → InMemoryHotelRepository', 'BookingRepository → InMemoryBookingRepository', 'sampleHotels'], '#6D3B7A')}
    </div>
  </body></html>`;
}

// ---------------------------------------------------------------------------
// Renderer
// ---------------------------------------------------------------------------
async function renderSvg(page, svg, size, file, { transparent = false, type = 'png', quality } = {}) {
  await page.setViewportSize({ width: size.width, height: size.height });
  await page.setContent(`<!doctype html><html><head><meta charset="utf-8"><style>html,body{margin:0;padding:0;${transparent ? 'background:transparent' : ''}}svg{display:block;width:${size.width}px;height:${size.height}px}</style></head><body>${svg}</body></html>`);
  ensureDir(file);
  await page.screenshot({ path: file, omitBackground: transparent, type, quality, clip: { x: 0, y: 0, width: size.width, height: size.height } });
  console.log('wrote', path.relative(ROOT, file));
}

async function renderHtml(page, html, size, file) {
  await page.setViewportSize({ width: size.width, height: size.height });
  await page.setContent(html);
  ensureDir(file);
  await page.screenshot({ path: file, clip: { x: 0, y: 0, width: size.width, height: size.height } });
  console.log('wrote', path.relative(ROOT, file));
}

async function main() {
  const browser = await chromium.launch();
  const page = await browser.newPage({ deviceScaleFactor: 1 });

  // Hotel covers
  for (const [id, scene] of Object.entries(scenes)) {
    await renderSvg(page, scene(), { width: W, height: H }, out('assets', 'images', 'hotels', `${id}.jpg`), { type: 'jpeg', quality: 84 });
  }

  // Brand mark for in-app use (splash/about) — transparent rounded tile.
  await renderSvg(page, brandTileSvg(), { width: 512, height: 512 }, out('assets', 'images', 'brand', 'logo.png'), { transparent: true });

  // Android legacy launcher icons (rounded tile, transparent corners).
  const android = { mdpi: 48, hdpi: 72, xhdpi: 96, xxhdpi: 144, xxxhdpi: 192 };
  for (const [density, px] of Object.entries(android)) {
    await renderSvg(page, brandTileSvg(), { width: px, height: px }, out('android', 'app', 'src', 'main', 'res', `mipmap-${density}`, 'ic_launcher.png'), { transparent: true });
  }
  // Android adaptive foreground: glyph centred in the 66% safe zone on a 108dp canvas.
  const adaptive = { mdpi: 108, hdpi: 162, xhdpi: 216, xxhdpi: 324, xxxhdpi: 432 };
  for (const [density, px] of Object.entries(adaptive)) {
    await renderSvg(page, brandTileSvg({ transparentBg: true, glyphScale: 0.62 }), { width: px, height: px }, out('android', 'app', 'src', 'main', 'res', `mipmap-${density}`, 'ic_launcher_foreground.png'), { transparent: true });
  }
  // Android splash logo.
  const splash = { mdpi: 96, hdpi: 144, xhdpi: 192, xxhdpi: 288, xxxhdpi: 384 };
  for (const [density, px] of Object.entries(splash)) {
    await renderSvg(page, brandTileSvg(), { width: px, height: px }, out('android', 'app', 'src', 'main', 'res', `drawable-${density}`, 'launch_logo.png'), { transparent: true });
  }

  // iOS app icons: opaque, square (iOS applies its own mask). No alpha allowed.
  const ios = [
    ['Icon-App-20x20@1x.png', 20], ['Icon-App-20x20@2x.png', 40], ['Icon-App-20x20@3x.png', 60],
    ['Icon-App-29x29@1x.png', 29], ['Icon-App-29x29@2x.png', 58], ['Icon-App-29x29@3x.png', 87],
    ['Icon-App-40x40@1x.png', 40], ['Icon-App-40x40@2x.png', 80], ['Icon-App-40x40@3x.png', 120],
    ['Icon-App-60x60@2x.png', 120], ['Icon-App-60x60@3x.png', 180],
    ['Icon-App-76x76@1x.png', 76], ['Icon-App-76x76@2x.png', 152],
    ['Icon-App-83.5x83.5@2x.png', 167], ['Icon-App-1024x1024@1x.png', 1024],
  ];
  for (const [name, px] of ios) {
    await renderSvg(page, brandTileSvg({ rounded: false }), { width: px, height: px }, out('ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset', name));
  }
  // iOS launch image (transparent rounded tile shown on the launch storyboard).
  for (const [name, px] of [['LaunchImage.png', 120], ['LaunchImage@2x.png', 240], ['LaunchImage@3x.png', 360]]) {
    await renderSvg(page, brandTileSvg(), { width: px, height: px }, out('ios', 'Runner', 'Assets.xcassets', 'LaunchImage.imageset', name), { transparent: true });
  }

  // Web icons.
  for (const px of [192, 512]) {
    await renderSvg(page, brandTileSvg(), { width: px, height: px }, out('web', 'icons', `Icon-${px}.png`), { transparent: true });
    await renderSvg(page, brandTileSvg({ rounded: false, glyphScale: 0.8 }), { width: px, height: px }, out('web', 'icons', `Icon-maskable-${px}.png`));
  }
  await renderSvg(page, brandTileSvg(), { width: 64, height: 64 }, out('web', 'favicon.png'), { transparent: true });

  // Docs.
  await renderHtml(page, bannerHtml(), { width: 1600, height: 640 }, out('docs', 'images', 'banner.png'));
  await renderHtml(page, architectureHtml(), { width: 1400, height: 900 }, out('docs', 'images', 'architecture.png'));

  await browser.close();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
