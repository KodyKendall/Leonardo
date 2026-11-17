import { test, expect, BrowserContext, Page } from '@playwright/test';
import { ChatPage } from '../helpers/chat-page';
import { RAILS_URL, allowPlainHttpRails, expectVisibleFocusRing, railsAdminContext, removeRailsAdmin, tabTo } from '../helpers/a11y';

/**
 * HECVAT ITAC-17 (LP-34): everything here is driven by the keyboard alone. Axe cannot
 * see traps, focus return or Escape, so they get asserted directly.
 */
const llamabot = (name: string) => `[data-llamabot="${name}"]`;
const focusedIs = (page: Page, selector: string) =>
  page.evaluate((s) => !!document.activeElement?.matches(s), selector);

test.describe('Chat by keyboard', () => {
  let chat: ChatPage;
  test.beforeEach(async ({ page }) => {
    chat = new ChatPage(page);
    await chat.goto();
    await page.evaluate(() => (document.activeElement as HTMLElement)?.blur());
  });

  test('the first Tab stop is a skip link that lands in the composer', async ({ page }) => {
    await page.keyboard.press('Tab');
    await expect(page.locator(':focus')).toHaveText('Skip to main content');
    await expectVisibleFocusRing(page);
    await page.keyboard.press('Enter');
    expect(await focusedIs(page, llamabot('message-input'))).toBe(true);
  });

  test('every control in the header shows a focus ring and has a name', async ({ page }) => {
    await tabTo(page, llamabot('hamburger-menu'));
    await expectVisibleFocusRing(page);
    await expect(page.locator(':focus')).toHaveAccessibleName(/.+/);
  });

  test('the closed drawer takes no Tab stops', async ({ page }) => {
    await expect(page.locator(llamabot('menu-drawer'))).toBeHidden();
  });

  test('drawer: Enter opens and moves focus in, Escape closes and returns focus', async ({ page }) => {
    await tabTo(page, llamabot('hamburger-menu'));
    await page.keyboard.press('Enter');
    await expect(page.locator(llamabot('menu-drawer'))).toBeVisible();
    await expect(page.locator(llamabot('hamburger-menu'))).toHaveAttribute('aria-expanded', 'true');
    await expect.poll(() => focusedIs(page, `${llamabot('menu-drawer')} *`)).toBe(true);
    await page.keyboard.press('Escape');
    await expect(page.locator(llamabot('menu-drawer'))).toBeHidden();
    expect(await focusedIs(page, llamabot('hamburger-menu'))).toBe(true);
  });

  test('mode switch: pick Plan with the keyboard', async ({ page }) => {
    const trigger = page.locator(llamabot('execution-mode-trigger'));
    await tabTo(page, llamabot('execution-mode-trigger'));
    await page.keyboard.press('Enter');
    await expect(trigger).toHaveAttribute('aria-expanded', 'true');
    await page.keyboard.press('ArrowDown');
    expect(await focusedIs(page, '.execution-mode-option[data-mode="plan"]')).toBe(true);
    await page.keyboard.press('Enter');
    await expect(page.locator(llamabot('execution-mode-label'))).toHaveText(/plan/i);
    await expect(page.locator(llamabot('execution-mode-menu'))).toBeHidden();
    await expect.poll(() => focusedIs(page, llamabot('execution-mode-trigger'))).toBe(true);
  });

  test('file upload: the attach menu opens a file chooser from the keyboard', async ({ page }) => {
    await tabTo(page, llamabot('file-attach-btn'));
    await page.keyboard.press('Enter');
    await expect(page.locator(llamabot('file-attach-menu'))).toBeVisible();
    await page.keyboard.press('Escape');
    await expect(page.locator(llamabot('file-attach-menu'))).toBeHidden();
    expect(await focusedIs(page, llamabot('file-attach-btn'))).toBe(true);

    await page.keyboard.press('Enter');
    await expect.poll(() => focusedIs(page, llamabot('attach-for-ai-btn'))).toBe(true);
    const chooser = page.waitForEvent('filechooser');
    await page.keyboard.press('Enter');
    await chooser;
  });

  test('send and stop: the same button, renamed for what it does', async ({ page }) => {
    const button = page.locator(llamabot('send-button'));
    await page.locator(llamabot('message-input')).fill('hello');
    await expect(button).toHaveAccessibleName(/send/i);
    await tabTo(page, llamabot('send-button'));
    await expectVisibleFocusRing(page);

    await page.locator(llamabot('message-input')).fill('');
    await page.evaluate(() => (window as any).chatApp?.setAgentRunning?.(true));
    await expect(button).toHaveAccessibleName(/stop/i);
    await page.evaluate(() => (window as any).chatApp?.setAgentRunning?.(false));
  });

  test('browser tabs switch by keyboard', async ({ page }) => {
    await tabTo(page, '.tab[data-target="inboxFrame"] .tab-text');
    await page.keyboard.press('Enter');
    await expect(page.locator('.tab[data-target="inboxFrame"]')).toHaveClass(/\bactive\b/);
    await expect(page.locator('.tab[data-target="inboxFrame"] .tab-text')).toHaveAttribute('aria-current', 'page');
  });

  test('the panel divider resizes with arrow keys', async ({ page }) => {
    await tabTo(page, llamabot('resize-handle'));
    await expect(page.locator(':focus')).toHaveAttribute('role', 'separator');
    const before = await page.locator('.chat-section').evaluate((el) => el.getBoundingClientRect().width);
    await page.keyboard.press('ArrowRight');
    await expect
      .poll(() => page.locator('.chat-section').evaluate((el) => el.getBoundingClientRect().width))
      .toBeGreaterThan(before);
  });

  test('a modal traps Tab, Escape closes it, focus goes back to its opener', async ({ page }) => {
    await page.locator(llamabot('file-attach-btn')).click();
    await page.locator(llamabot('browse-files-btn')).click();
    await page.locator(llamabot('file-browser-expand')).focus();
    await page.keyboard.press('Enter');
    const modal = page.locator(llamabot('asset-modal'));
    await expect(modal).toBeVisible();
    await expect(modal).toHaveAttribute('role', 'dialog');
    await expect(modal).toHaveAttribute('aria-modal', 'true');
    await expect.poll(() => focusedIs(page, `${llamabot('asset-modal')} *`)).toBe(true);
    for (let i = 0; i < 12; i++) {
      await page.keyboard.press('Tab');
      expect(await focusedIs(page, `${llamabot('asset-modal')} *`), `Tab ${i} escaped the modal`).toBe(true);
    }
    await page.keyboard.press('Escape');
    await expect(modal).toBeHidden();
    await expect.poll(() => focusedIs(page, ':not(body)')).toBe(true);
  });

  test('agent status is announced politely without moving focus', async ({ page }) => {
    const announcer = page.locator(llamabot('status-announcer'));
    await expect(announcer).toHaveAttribute('aria-live', 'polite');
    await page.locator(llamabot('message-input')).focus();

    await page.evaluate(() => (window as any).chatApp.setAgentRunning(true));
    await expect(announcer).toHaveText(/working/i);
    await page.evaluate(() => (window as any).chatApp.setAgentRunning(false));
    await expect(announcer).toHaveText(/finished/i);

    expect(await focusedIs(page, llamabot('message-input'))).toBe(true);
  });

  test('a lost connection is announced', async ({ page }) => {
    const announcer = page.locator(llamabot('status-announcer'));
    await page.locator(llamabot('connection-status')).evaluate((el) => {
      el.className = 'connection-status disconnected';
    });
    await expect(announcer).toHaveText(/connection lost/i);
  });
});

test.describe('LlamaBot pages by keyboard', () => {
  test('prompt library: the modal traps Tab and Escape closes it', async ({ page }) => {
    await page.goto('/prompt-library');
    const opener = page.getByRole('button', { name: /new prompt|add prompt|create/i }).first();
    await opener.focus();
    await page.keyboard.press('Enter');
    const modal = page.locator('#promptModal');
    await expect(modal).toBeVisible();
    await expect(modal).toHaveAttribute('role', 'dialog');
    await expect.poll(() => focusedIs(page, '#promptModal *')).toBe(true);
    for (let i = 0; i < 12; i++) {
      await page.keyboard.press('Tab');
      expect(await focusedIs(page, '#promptModal *'), `Tab ${i} escaped the modal`).toBe(true);
    }
    await page.keyboard.press('Escape');
    await expect(modal).toBeHidden();
    await expect(opener).toBeFocused();
  });

  test('settings: a toggle is reachable and shows its ring on the switch', async ({ page }) => {
    await page.goto('/settings');
    await tabTo(page, '#autoBackupToggle');
    const ring = await page.locator('#autoBackupToggle + span').evaluate((el) => getComputedStyle(el).outlineStyle);
    expect(ring).toBe('solid');
  });
});

test.describe('LlamaBot sign-in by keyboard', () => {
  test.use({ storageState: { cookies: [], origins: [] } });

  test('skip link, focus ring, labelled fields', async ({ page }) => {
    await page.goto('/login');
    // The username field has autofocus, so assert the skip link's place in the order.
    const first = page.locator('a[href], button, input, select, textarea').first();
    await expect(first).toHaveText('Skip to main content');
    await first.focus();
    await expect(first).toBeInViewport();
    await tabTo(page, '#username');
    await expectVisibleFocusRing(page);
    await expect(page.getByLabel(/username/i)).toBeVisible();
    await expect(page.getByLabel(/password/i)).toBeVisible();
  });
});

test.describe('Rails by keyboard', () => {
  test.describe('signed out', () => {
    test.use({ storageState: { cookies: [], origins: [] }, baseURL: RAILS_URL });
    test.beforeEach(async ({ context }) => {
      await allowPlainHttpRails(context);
    });

    test('sign in: skip link and a visible ring on every field', async ({ page }) => {
      await page.goto('/users/sign_in');
      // The email field has autofocus, so assert the skip link's place in the order.
      const first = page.locator('a[href], button, input:not([type="hidden"]), select, textarea').first();
      await expect(first).toHaveText('Skip to main content');
      await first.focus();
      await expect(first).toBeInViewport();
      await page.keyboard.press('Enter');
      await expect(page.locator('main')).toBeFocused();

      await tabTo(page, 'input[type="email"]');
      await expectVisibleFocusRing(page);
      await tabTo(page, 'input[type="password"]');
      await expectVisibleFocusRing(page);
    });

    test('a failed sign-in is announced', async ({ page }) => {
      await page.goto('/users/sign_in');
      await page.fill('input[type="email"]', 'nobody@example.com');
      await page.fill('input[type="password"]', 'wrong-password');
      await page.keyboard.press('Enter');
      await expect(page.locator('[role="alert"]').first()).toBeVisible();
    });

    test('sign-up errors are announced and tied to their fields', async ({ page }) => {
      await page.goto('/users/sign_up');
      await page.fill('input[type="email"]', `a11y-${Date.now()}@example.com`);
      await page.locator('input[type="password"]').first().fill('short');
      await page.keyboard.press('Enter');
      await expect(page.locator('#error_explanation')).toHaveAttribute('role', 'alert');
      const invalid = page.locator('input[aria-invalid="true"]').first();
      await expect(invalid).toHaveAttribute('aria-describedby', 'error_explanation');
    });
  });

  test.describe('feedback bubble', () => {
    let context: BrowserContext;
    test.beforeAll(async ({ browser }) => {
      context = await railsAdminContext(browser);
    });
    test.afterAll(async () => {
      await context?.close();
      await removeRailsAdmin();
    });

    test('opens from the keyboard, traps Tab, Escape closes and returns focus', async () => {
      const page = await context.newPage();
      await page.goto('/users/edit');
      await tabTo(page, '#feedback-trigger', 120);
      await expectVisibleFocusRing(page);
      await expect(page.locator('#feedback-trigger')).toHaveAccessibleName(/feedback/i);
      await expect(page.locator('#feedback-trigger')).toHaveAttribute('aria-expanded', 'false');

      await page.keyboard.press('Enter');
      const panel = page.locator('#feedback-panel');
      await expect(panel).toBeVisible();
      await expect(panel).toHaveAttribute('role', 'dialog');
      await expect(page.locator('#feedback-trigger')).toHaveAttribute('aria-expanded', 'true');
      await expect.poll(() => focusedIs(page, '#feedback-panel *')).toBe(true);

      for (let i = 0; i < 25; i++) {
        await page.keyboard.press('Tab');
        expect(await focusedIs(page, '#feedback-panel *'), `Tab ${i} escaped the panel`).toBe(true);
      }

      await page.keyboard.press('Escape');
      await expect(panel).toBeHidden();
      expect(await focusedIs(page, '#feedback-trigger')).toBe(true);
      await page.close();
    });

    test('the panel tabs are named and switch by keyboard', async () => {
      const page = await context.newPage();
      await page.goto('/users/edit');
      await page.locator('#feedback-trigger').focus();
      await page.keyboard.press('Enter');
      for (const id of ['#tab-feedback', '#tab-messages', '#tab-notifications']) {
        await expect(page.locator(id)).toHaveAccessibleName(/.+/);
      }
      await page.locator('#tab-messages').focus();
      await page.keyboard.press('Enter');
      await expect(page.locator('#content-feedback')).toBeHidden();
      await page.close();
    });
  });
});
