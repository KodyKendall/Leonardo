import { test, expect, BrowserContext } from '@playwright/test';
import { ChatPage } from '../helpers/chat-page';
import { RAILS_URL, expectNoBlockingViolations, railsAdminContext, removeRailsAdmin } from '../helpers/a11y';

/**
 * Release gate for HECVAT ITAC-08 / ITAC-17 (LP-34): zero axe critical/serious
 * violations on the baseline screens. See LlamaBot docs/accessibility/.
 */
const anonymous = { storageState: { cookies: [], origins: [] } };

test.describe('LlamaBot, signed out', () => {
  test.use(anonymous);

  test('login', async ({ page }) => {
    await page.goto('/login');
    await expectNoBlockingViolations(page, 'llamabot /login');
  });
});

test.describe('LlamaBot chat', () => {
  test('composer', async ({ page }) => {
    const chat = new ChatPage(page);
    await chat.goto();
    await expectNoBlockingViolations(page, 'chat');
  });

  // Axe only sees what is rendered, so open each panel before scanning.
  for (const [name, control] of [
    ['conversations drawer', 'hamburger-menu'],
    ['mode menu', 'execution-mode-trigger'],
    ['attach menu', 'file-attach-btn'],
    ['tools toolbar', 'tools-toggle-btn'],
    ['version history', 'checkpoint-btn'],
  ]) {
    test(name, async ({ page }) => {
      const chat = new ChatPage(page);
      await chat.goto();
      await page.locator(`[data-llamabot="${control}"]`).click();
      await page.waitForTimeout(400);
      await expectNoBlockingViolations(page, `chat: ${name}`);
    });
  }

  for (const path of ['/settings', '/users', '/prompt-library', '/git-history', '/scheduled-jobs', '/backup-history', '/leonardo-md', '/settings/environment']) {
    test(`page ${path}`, async ({ page }) => {
      const response = await page.goto(path);
      test.skip(response?.status() === 403, `${path} is admin-only and the e2e user is not an admin here`);
      expect(response?.ok(), `GET ${path}`).toBeTruthy();
      await page.waitForTimeout(500);
      await expectNoBlockingViolations(page, `llamabot ${path}`);
    });
  }
});

test.describe('LlamaBot modals', () => {
  test('new prompt', async ({ page }) => {
    await page.goto('/prompt-library');
    await page.getByRole('button', { name: /new prompt|add prompt|create/i }).first().click();
    await expect(page.locator('#promptModal')).toBeVisible();
    await expectNoBlockingViolations(page, 'llamabot prompt modal');
  });

  test('new scheduled job', async ({ page }) => {
    await page.goto('/scheduled-jobs');
    await page.getByRole('button', { name: /new job|add job|create/i }).first().click();
    await expect(page.locator('#jobModal')).toBeVisible();
    await expectNoBlockingViolations(page, 'llamabot job modal');
  });
});

test.describe('Rails, signed out', () => {
  test.use({ ...anonymous, baseURL: RAILS_URL });

  for (const [name, path] of [
    ['sign in', '/users/sign_in'],
    ['sign up', '/users/sign_up'],
    ['password reset', '/users/password/new'],
  ]) {
    test(name, async ({ page }) => {
      await page.goto(path);
      await expectNoBlockingViolations(page, `rails ${path}`);
    });
  }
});

test.describe('Rails, signed in as admin', () => {
  let context: BrowserContext;
  test.beforeAll(async ({ browser }) => {
    context = await railsAdminContext(browser);
  });
  test.afterAll(async () => {
    await context?.close();
    await removeRailsAdmin();
  });

  for (const [name, path] of [
    ['account settings', '/users/edit'],
    ['admin dashboard', '/admin'],
    ['admin users', '/admin/users'],
    ['audit log', '/llama_bot/activity'],
    ['usage', '/llama_bot/activity/usage'],
    ['feedback list', '/llama_bot/feedback'],
    ['new feedback', '/llama_bot/feedback/new'],
  ]) {
    test(name, async () => {
      const page = await context.newPage();
      const response = await page.goto(path);
      expect(response?.ok(), `GET ${path}`).toBeTruthy();
      await expectNoBlockingViolations(page, `rails ${path}`);
      await page.close();
    });
  }

  test('feedback bubble open', async () => {
    const page = await context.newPage();
    await page.goto('/users/edit');
    await page.locator('#feedback-trigger').click();
    await expect(page.locator('#feedback-panel')).toBeVisible();
    await expectNoBlockingViolations(page, 'feedback bubble');
    await page.close();
  });
});
