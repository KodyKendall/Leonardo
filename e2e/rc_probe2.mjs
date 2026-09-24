// What box does Region Capture actually hand back, and how does it relate to
// the frame's own viewport coordinates? Measured three ways.
import { chromium } from '@playwright/test';

const browser = await chromium.launch({ args: ['--auto-accept-this-tab-capture'] });
const context = await browser.newContext({
  storageState: '/home/ubuntu/dev/Leonardo/e2e/playwright/.auth/user.json',
  viewport: { width: 1600, height: 900 },
});
const page = await context.newPage();
await page.goto('http://localhost:8000/');
await page.waitForSelector('[data-llamabot="message-input"]', { timeout: 30000 });
await page.waitForTimeout(5000);

const frame = page.frames().find((f) => f.url().includes(':3000') && !f.url().includes('activity'));
if (!frame) { console.log('NO FRAME'); await browser.close(); process.exit(1); }

await frame.evaluate(() => {
  // Make the page taller than the viewport so a scrolled state is testable.
  const filler = document.createElement('div');
  filler.style.cssText = 'height:2000px';
  document.body.appendChild(filler);

  const btn = document.createElement('button');
  btn.id = 'rc-probe';
  btn.textContent = 'probe';
  btn.style.cssText = 'position:fixed;top:0;left:0;z-index:2147483647;width:80px;height:30px';
  btn.addEventListener('click', async () => {
    const results = {};
    const measure = async (name, makeEl) => {
      const el = makeEl();
      const stream = await navigator.mediaDevices.getDisplayMedia({
        video: { displaySurface: 'browser' }, preferCurrentTab: true, selfBrowserSurface: 'include',
      });
      const track = stream.getVideoTracks()[0];
      let err = null;
      try { await track.cropTo(await window.CropTarget.fromElement(el)); }
      catch (e) { err = String(e); }
      await new Promise((r) => setTimeout(r, 500));
      const bmp = await new ImageCapture(track).grabFrame();
      stream.getTracks().forEach((t) => t.stop());
      const r = el.getBoundingClientRect();
      results[name] = {
        err,
        bitmap: { w: bmp.width, h: bmp.height },
        rect: { left: Math.round(r.left), top: Math.round(r.top), w: Math.round(r.width), h: Math.round(r.height) },
      };
    };

    const viewport = { w: innerWidth, h: innerHeight, dpr: devicePixelRatio };

    window.scrollTo(0, 0);
    await measure('documentElement@scroll0', () => document.documentElement);
    const overlay = document.createElement('div');
    overlay.style.cssText = 'position:fixed;inset:0;pointer-events:none;z-index:2147483646';
    document.body.appendChild(overlay);
    await measure('fixedOverlay@scroll0', () => overlay);

    window.scrollTo(0, 600);
    await new Promise((r) => setTimeout(r, 200));
    await measure('documentElement@scroll600', () => document.documentElement);
    await measure('fixedOverlay@scroll600', () => overlay);

    window.__rc = { viewport, scrollHeight: document.documentElement.scrollHeight, results };
  });
  document.body.appendChild(btn);
});

await frame.click('#rc-probe');
await page.waitForFunction(() => !!window.__rc, null, { timeout: 60000 }).catch(() => {});
console.log(JSON.stringify(await frame.evaluate(() => window.__rc || { pending: true }), null, 2));
await browser.close();
