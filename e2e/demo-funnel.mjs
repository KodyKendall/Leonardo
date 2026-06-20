// Records a slowed-down, watchable demo of the ?llm_model= funnel behavior.
// Not a test — a documentation recorder. Output mp4 lands in the gitignored
// test-results/ dir. Run from e2e/:  node demo-funnel.mjs
import { chromium } from '@playwright/test';

const baseURL = process.env.E2E_BASE_URL || 'http://localhost:8000';
const outDir = 'test-results/demo-funnel';

// Big on-screen caption so the video is self-explanatory regardless of CSS.
async function caption(page, text, color) {
  await page.evaluate(({ text, color }) => {
    let el = document.getElementById('__demo_banner');
    if (!el) {
      el = document.createElement('div');
      el.id = '__demo_banner';
      el.style.cssText =
        'position:fixed;top:0;left:0;right:0;z-index:99999;padding:14px 20px;' +
        'font:600 20px/1.3 system-ui,sans-serif;color:#fff;text-align:center;' +
        'box-shadow:0 2px 12px rgba(0,0,0,.4)';
      document.body.appendChild(el);
    }
    el.style.background = color;
    el.textContent = text;
  }, { text, color });
}

// Reveal the model dropdown (hidden behind a toggle by default) and read its value.
async function revealModel(page) {
  await page.evaluate(() => {
    document
      .querySelector('[data-llamabot="model-selector-container"]')
      ?.classList.remove('hidden');
  });
  return page.locator('[data-llamabot="model-select"]').inputValue();
}

const browser = await chromium.launch({ slowMo: 350 });
const context = await browser.newContext({
  storageState: 'playwright/.auth/user.json',
  viewport: { width: 1280, height: 720 },
  recordVideo: { dir: outDir, size: { width: 1280, height: 720 } },
});
const page = await context.newPage();

// ── Scene 1: plain visit, no funnel param → the image-blind default ──────────
await page.goto(`${baseURL}/`);
await page.waitForSelector('[data-llamabot="message-input"]', { timeout: 30_000 });
await caption(page, 'Scene 1 — plain visit, no funnel param', '#6b21a8');
await page.waitForTimeout(2000);
let m = await revealModel(page);
await caption(page, `Default model = ${m}  (DeepSeek — cannot view images)`, '#b91c1c');
await page.waitForTimeout(3500);

// ── Scene 2: arrive via the funnel link with ?llm_model=gemini-3-flash ────────
await caption(page, 'Scene 2 — arriving from the picture-to-html funnel link…', '#6b21a8');
await page.waitForTimeout(1500);
await page.goto(`${baseURL}/?llm_model=gemini-3-flash`);
await page.waitForSelector('[data-llamabot="message-input"]');
await page.waitForTimeout(1500);
m = await revealModel(page);
await caption(page, `Model pinned = ${m}  (Gemini — can view images) ✓  URL param stripped`, '#15803d');
await page.waitForTimeout(3500);

// ── Scene 3: reload with no param → still Gemini (sticky cookie) ──────────────
await caption(page, 'Scene 3 — reload with NO param (mid-session re-upload)…', '#6b21a8');
await page.waitForTimeout(1500);
await page.goto(`${baseURL}/`);
await page.waitForSelector('[data-llamabot="message-input"]');
await page.waitForTimeout(1500);
m = await revealModel(page);
await caption(page, `Still ${m}  — sticky for the whole session ✓`, '#15803d');
await page.waitForTimeout(3500);

await context.close(); // finalizes the video file
await browser.close();

// Print the raw video path so the caller can transcode it.
const fs = await import('node:fs');
const file = fs.readdirSync(outDir).find((f) => f.endsWith('.webm'));
console.log('VIDEO_WEBM=' + outDir + '/' + file);
