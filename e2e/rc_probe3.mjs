// One getDisplayMedia per real click — user activation is spent by the first await.
import { chromium } from '@playwright/test';

const browser = await chromium.launch({ args: ['--auto-accept-this-tab-capture', '--use-fake-ui-for-media-stream'] });
const context = await browser.newContext({
  storageState: '/home/ubuntu/dev/Leonardo/e2e/playwright/.auth/user.json',
  viewport: { width: 1600, height: 900 },
});
const page = await context.newPage();
await page.goto('http://localhost:8000/');
await page.waitForSelector('[data-llamabot="message-input"]', { timeout: 30000 });
await page.waitForTimeout(5000);

const frame = page.frames().find((f) => f.url().includes(':3000') && !f.url().includes('activity'));

await frame.evaluate(() => {
  const filler = document.createElement('div');
  filler.style.cssText = 'height:2000px';
  document.body.appendChild(filler);

  const overlay = document.createElement('div');
  overlay.style.cssText = 'position:fixed;inset:0;pointer-events:none;z-index:2147483646';
  document.body.appendChild(overlay);
  window.__overlay = overlay;

  const btn = document.createElement('button');
  btn.id = 'rc-probe';
  btn.textContent = 'probe';
  btn.style.cssText = 'position:fixed;top:0;left:0;z-index:2147483647;width:80px;height:30px';
  btn.addEventListener('click', async () => {
    const mode = window.__rcMode;
    const el = mode.startsWith('doc') ? document.documentElement : window.__overlay;
    const out = { mode, viewport: { w: innerWidth, h: innerHeight, dpr: devicePixelRatio, scrollY: window.scrollY } };
    try {
      const stream = await navigator.mediaDevices.getDisplayMedia({
        video: { displaySurface: 'browser' }, preferCurrentTab: true, selfBrowserSurface: 'include',
      });
      const track = stream.getVideoTracks()[0];
      try { await track.cropTo(await window.CropTarget.fromElement(el)); }
      catch (e) { out.cropErr = String(e); }
      await new Promise((r) => setTimeout(r, 500));
      const bmp = await new ImageCapture(track).grabFrame();
      stream.getTracks().forEach((t) => t.stop());
      out.bitmap = { w: bmp.width, h: bmp.height };
    } catch (e) { out.err = String(e); }
    const r = el.getBoundingClientRect();
    out.rect = { left: Math.round(r.left), top: Math.round(r.top), w: Math.round(r.width), h: Math.round(r.height) };
    out.scrollHeight = document.documentElement.scrollHeight;
    (window.__rcResults ||= []).push(out);
  });
  document.body.appendChild(btn);
});

for (const [mode, scroll] of [['doc', 0], ['overlay', 0], ['doc', 600], ['overlay', 600]]) {
  await frame.evaluate(([m, s]) => { window.__rcMode = m; window.scrollTo(0, s); }, [mode, scroll]);
  await page.waitForTimeout(300);
  const before = await frame.evaluate(() => (window.__rcResults || []).length);
  await frame.click('#rc-probe');
  await page.waitForFunction((n) => (window.__rcResults || []).length > n, before, { timeout: 30000 }).catch(() => {});
}
console.log(JSON.stringify(await frame.evaluate(() => window.__rcResults), null, 2));
await browser.close();
