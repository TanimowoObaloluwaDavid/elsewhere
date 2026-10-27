import { chromium } from 'playwright-core';
import { mkdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const outDir = path.resolve(here, '../../docs/screenshots');
const base = process.env.BASE_URL ?? 'http://127.0.0.1:8090/';

const screens = [
  { name: '01-journal', query: '' },
  { name: '02-atlas', query: '?screen=explore' },
  { name: '03-place', query: '?place=lofoten' },
  { name: '04-films', query: '?screen=films' },
  { name: '05-film-player', query: '?film=north-of-silence' },
  { name: '06-kept', query: '?screen=saved&saved=1' },
];

async function waitForApp(page) {
  await page.waitForSelector('flutter-view', { timeout: 45000 }).catch(() => {});
  await page
    .waitForSelector('#boot', { state: 'detached', timeout: 30000 })
    .catch(() => {});
  await page.waitForTimeout(2600);
}

async function main() {
  await mkdir(outDir, { recursive: true });
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 2,
    hasTouch: true,
  });
  const page = await context.newPage();
  page.on('pageerror', (error) => console.log('pageerror:', error.message));

  for (const screen of screens) {
    const url = `${base}${screen.query}`;
    console.log(`Capturing ${screen.name} — ${url}`);
    await page.goto(url, { waitUntil: 'networkidle', timeout: 90000 }).catch(() => {});
    await waitForApp(page);
    await page.screenshot({
      path: path.join(outDir, `${screen.name}.png`),
      animations: 'disabled',
    });
  }

  await context.close();
  await browser.close();
  console.log('Screenshots saved to', outDir);
  process.exit(0);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
