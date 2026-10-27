import { chromium } from 'playwright-core';
import { copyFile, mkdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const outDir = path.resolve(here, '../../docs/video');
const base = process.env.BASE_URL ?? 'http://127.0.0.1:8090/';

async function tap(page, x, y, wait) {
  await page.mouse.click(x, y);
  await page.waitForTimeout(wait);
}

async function main() {
  await mkdir(outDir, { recursive: true });

  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 1,
    hasTouch: true,
    recordVideo: {
      dir: outDir,
      size: { width: 390, height: 844 },
    },
  });

  const page = await context.newPage();
  page.on('pageerror', (error) => console.log('pageerror:', error.message));

  await page.goto(`${base}?saved=1`, {
    waitUntil: 'networkidle',
    timeout: 90000,
  });
  await page.waitForSelector('#boot', { state: 'detached', timeout: 30000 });
  await page.waitForTimeout(1500);

  // Home → the featured field note.
  await tap(page, 195, 500, 1900);
  await page.mouse.move(195, 620);
  await page.mouse.wheel(0, 430);
  await page.waitForTimeout(1000);
  await tap(page, 38, 30, 900);

  // Atlas → films.
  await tap(page, 150, 798, 1500);
  await tap(page, 240, 798, 1500);

  // Featured film → player → play.
  await tap(page, 195, 300, 1900);
  await tap(page, 195, 174, 2800);

  // Back to films, then the kept journal and home.
  await tap(page, 42, 32, 1000);
  await tap(page, 329, 798, 1600);
  await tap(page, 61, 798, 1600);

  const video = page.video();
  await page.close();
  const videoPath = await video.path();
  await context.close();
  await browser.close();

  await copyFile(videoPath, path.join(outDir, 'demo.webm'));
  console.log('Demo video saved to', path.join(outDir, 'demo.webm'));
  process.exit(0);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
