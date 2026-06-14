import { test, expect } from '@playwright/test';
import { ChatPage } from '../helpers/chat-page';

/**
 * Fast, no-LLM smoke checks: the chat UI loads behind auth, the WebSocket
 * connects, and the agent-mode / model selectors expose what the agent
 * tests depend on. Safe to run on every commit.
 */
test.describe('Chat UI smoke', () => {
  test('loads the chat UI with a live WebSocket connection', async ({ page }) => {
    const chat = new ChatPage(page);
    await chat.goto();

    await expect(chat.messageInput).toBeEditable();
    await expect(chat.sendButton).toBeVisible();
    await expect(chat.messageHistory).toBeVisible();
  });

  test('exposes ticket mode and the DeepSeek test model', async ({ page }) => {
    const chat = new ChatPage(page);
    await chat.goto();

    const modes = await chat.agentModeSelect.evaluate((el: HTMLSelectElement) =>
      [...el.options].map((o) => o.value)
    );
    expect(modes).toContain('ticket');

    const models = await chat.modelSelect.evaluate((el: HTMLSelectElement) =>
      [...el.options].map((o) => o.value)
    );
    expect(models).toContain(process.env.E2E_LLM_MODEL || 'deepseek-v4-flash');
  });
});

/**
 * ?llm_model= URL-param handling (checkModelParam in chat/index.js).
 * Lets a funnel (e.g. the mothership picture-to-html flow) land users on an
 * image-capable model instead of the image-blind DeepSeek default. Pure
 * frontend behavior — no LLM, fully deterministic.
 */
test.describe('llm_model URL param', () => {
  const FUNNEL_MODEL = 'gemini-3-flash';

  test('pins the dropdown to a valid ?llm_model= and strips the param', async ({ page }) => {
    const chat = new ChatPage(page);
    await chat.goto(`?llm_model=${FUNNEL_MODEL}`);

    // Param is stripped on load so a refresh can't re-apply it after a manual switch.
    expect(new URL(page.url()).searchParams.has('llm_model')).toBe(false);

    // gemini-3-flash needs GOOGLE/GEMINI_API_KEY to be a usable option; if the
    // stack has no key the option is disabled and fetchAvailableModels() falls
    // back, so only assert the pin when the model is actually selectable.
    const available = await chat.modelSelect.evaluate((el: HTMLSelectElement) => {
      const opt = [...el.options].find((o) => o.value === 'gemini-3-flash');
      return !!opt && !opt.disabled;
    });
    test.skip(!available, 'gemini-3-flash not configured in this stack (no GOOGLE/GEMINI key)');

    await expect(chat.modelSelect).toHaveValue(FUNNEL_MODEL);
    // Sticky for the session: the choice is persisted to the llmModel cookie.
    const cookies = await page.evaluate(() => document.cookie);
    expect(cookies).toContain(`llmModel=${FUNNEL_MODEL}`);
  });

  test('ignores an unknown ?llm_model= value', async ({ page }) => {
    const chat = new ChatPage(page);
    await chat.goto('?llm_model=definitely-not-a-real-model');

    // Param still stripped, and the bogus value is never selected (no crash).
    expect(new URL(page.url()).searchParams.has('llm_model')).toBe(false);
    await expect(chat.modelSelect).not.toHaveValue('definitely-not-a-real-model');
  });
});
