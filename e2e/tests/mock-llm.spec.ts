import { test, expect } from '@playwright/test';
import { ChatPage } from '../helpers/chat-page';

/**
 * Mocked-LLM plumbing test: exercises the full browser → WebSocket →
 * LangGraph agent → streamed-response → UI-render loop with zero LLM cost
 * and full determinism, by selecting the 'fake-llm' model.
 *
 * Requires LLAMABOT_ENABLE_FAKE_LLM=true in the llamabot container env
 * (Leonardo root .env) and a container restart. Enable the test itself with
 * E2E_MOCK_LLM=true.
 */
test.describe('Mocked LLM plumbing', () => {
  test.skip(
    process.env.E2E_MOCK_LLM !== 'true',
    'set E2E_MOCK_LLM=true (and LLAMABOT_ENABLE_FAKE_LLM=true in the llamabot container) to run'
  );

  test('round-trips a message through the agent stack without a real LLM', async ({ page }) => {
    const chat = new ChatPage(page);
    await chat.goto();
    await chat.selectAgentMode('ticket');
    await chat.selectModel('fake-llm');

    const before = await chat.aiMessageCount();
    await chat.sendAndWaitForTurn('ping — plumbing check', 60_000);

    await expect(async () => {
      expect(await chat.aiMessageCount()).toBeGreaterThan(before);
    }).toPass({ timeout: 15_000 });

    expect(await chat.lastAiMessageText()).toContain('FAKE_LLM_RESPONSE');
  });
});
