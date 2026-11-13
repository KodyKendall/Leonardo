import { Browser, BrowserContext, Page, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
import { randomUUID } from 'crypto';
import * as fs from 'fs';
import { compose } from './stack';

/** WCAG 2.0 + 2.1, levels A and AA: the HECVAT ITAC-08 bar. */
const WCAG_TAGS = ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'];

/** The release gate fails on these impacts. */
const BLOCKING_IMPACTS = ['critical', 'serious'];

export const RAILS_URL = process.env.E2E_RAILS_URL || 'https://rails-llamapress-dev.llamapress.ai';
export const RAILS_EMAIL = 'a11y-admin@example.com';
// Random per run: this is a real admin on whatever stack the tests point at, and dev
// boxes are public, so its password must never be something written in the repo.
const RAILS_PASSWORD = randomUUID();

/**
 * Scan the page as it stands and fail on any critical/serious violation.
 *
 * Iframes are excluded: the chat page's preview iframe is the customer's own app,
 * which gets scanned on its own URL when it is one of ours.
 *
 * E2E_A11Y_REPORT=<file> appends every violation (every impact) as JSON lines, which
 * is how docs/accessibility/ gets its data.
 */
export async function expectNoBlockingViolations(page: Page, surface: string) {
  const { violations } = await new AxeBuilder({ page })
    .withTags(WCAG_TAGS)
    .exclude('iframe')
    .analyze();

  if (process.env.E2E_A11Y_REPORT) {
    const rows = violations.map((v) => ({
      surface,
      rule: v.id,
      impact: v.impact,
      tags: v.tags.filter((t) => /^wcag\d/.test(t) && !WCAG_TAGS.includes(t)),
      help: v.help,
      nodes: v.nodes.map((n) => ({ target: n.target.join(' '), summary: n.failureSummary })),
    }));
    if (rows.length) {
      fs.appendFileSync(process.env.E2E_A11Y_REPORT, rows.map((r) => JSON.stringify(r)).join('\n') + '\n');
    }
  }

  const blocking = violations
    .filter((v) => BLOCKING_IMPACTS.includes(v.impact ?? ''))
    .map((v) => `${v.impact} ${v.id} (${v.nodes.length}): ${v.nodes[0]?.target.join(' ')}`);
  expect(blocking, `axe critical/serious violations on ${surface}`).toEqual([]);
}

/** Press Tab until `selector` holds focus, proving it is keyboard reachable. */
export async function tabTo(page: Page, selector: string, maxPresses = 60) {
  for (let i = 0; i < maxPresses; i++) {
    await page.keyboard.press('Tab');
    if (await page.evaluate((s) => !!document.activeElement?.matches(s), selector)) return;
  }
  throw new Error(`${selector} not reached after ${maxPresses} Tab presses`);
}

/** The focused element draws a visible 2px ring (outline or Tailwind's box-shadow ring). */
export async function expectVisibleFocusRing(page: Page) {
  const ring = await page.evaluate(() => {
    const el = document.activeElement as HTMLElement;
    const s = getComputedStyle(el);
    return {
      element: el.outerHTML.slice(0, 120),
      outline: s.outlineStyle !== 'none' && parseFloat(s.outlineWidth) >= 2,
      boxShadow: s.boxShadow !== 'none',
    };
  });
  expect(ring.outline || ring.boxShadow, `no focus ring on ${ring.element}`).toBe(true);
}

/**
 * Dev Rails sets assume_ssl (it normally sits behind an SSL proxy), so over plain
 * http://localhost, which is what CI uses, every POST fails its CSRF origin check.
 * Send the origin Rails expects. A no-op when RAILS_URL is already https.
 */
export async function allowPlainHttpRails(context: BrowserContext) {
  if (!RAILS_URL.startsWith('http://')) return;
  const origin = RAILS_URL.replace('http://', 'https://');
  await context.route(`${RAILS_URL}/**`, async (route) => {
    const request = route.request();
    if (request.method() === 'GET') return route.continue();
    // route.fetch, because Chromium keeps its own Origin on route.continue. No redirect
    // following, so Turbo still sees the 303 it expects. Rails builds that redirect
    // from the https address it believes it has, so point it back at http.
    const response = await route.fetch({ headers: { ...request.headers(), origin }, maxRedirects: 0 });
    const headers = response.headers();
    if (headers.location) headers.location = headers.location.replace(origin, RAILS_URL);
    return route.fulfill({ response, headers });
  });
}

/** Create (or reset) the Rails admin the signed-in scans use. Idempotent. */
export async function provisionRailsAdmin() {
  const code = `
    u = User.find_or_initialize_by(email: ${JSON.stringify(RAILS_EMAIL)})
    u.password = u.password_confirmation = ${JSON.stringify(RAILS_PASSWORD)}
    u.admin = true
    u.name = "A11y Admin" if u.respond_to?(:name=)
    u.save!
  `;
  await compose(['exec', '-T', 'llamapress', 'bundle', 'exec', 'rails', 'runner', code]);
}

/** Remove that admin again, so a run leaves nothing behind on a shared database. */
export async function removeRailsAdmin() {
  const code = `User.find_by(email: ${JSON.stringify(RAILS_EMAIL)})&.destroy`;
  await compose(['exec', '-T', 'llamapress', 'bundle', 'exec', 'rails', 'runner', code]);
}

/** A fresh browser context signed in to Rails as the admin. */
export async function railsAdminContext(browser: Browser): Promise<BrowserContext> {
  await provisionRailsAdmin();
  const context = await browser.newContext({ baseURL: RAILS_URL });
  await allowPlainHttpRails(context);
  const page = await context.newPage();
  await page.goto('/users/sign_in');
  await page.fill('input[type="email"]', RAILS_EMAIL);
  await page.fill('input[type="password"]', RAILS_PASSWORD);
  await page.locator('input[type="submit"], button[type="submit"]').first().click();
  await page.waitForURL((u) => !u.pathname.includes('sign_in'), { timeout: 20_000 });
  await page.close();
  return context;
}

