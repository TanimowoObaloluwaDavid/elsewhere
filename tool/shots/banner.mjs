import { chromium } from 'playwright-core';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const banner = path.resolve(here, '../../docs/banner.html');
const output = path.resolve(here, '../../docs/banner.png');
const url = new URL(`file:///${banner.replace(/\\/g, '/')}`).href;

const browser = await chromium.launch({ channel: 'chrome', headless: true });
const page = await browser.newPage({
  viewport: { width: 1600, height: 800 },
  deviceScaleFactor: 2,
});
await page.goto(url, { waitUntil: 'load' });
await page.evaluate(() => document.fonts.ready);
await page.waitForTimeout(700);
await page.screenshot({ path: output, animations: 'disabled' });
console.log('Banner saved to', output);
process.exit(0);
