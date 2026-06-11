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
