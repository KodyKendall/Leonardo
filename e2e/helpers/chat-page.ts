import { Page, Locator, expect } from '@playwright/test';

const DEFAULT_TURN_TIMEOUT_MS = Number(process.env.E2E_TURN_TIMEOUT_MS || 300_000);

/**
 * Page object for the LlamaBot FastAPI chat UI (app/frontend/chat.html).
 * All selectors use the stable data-llamabot attributes.
 */
export class ChatPage {
  readonly page: Page;
  readonly messageInput: Locator;
  readonly sendButton: Locator;
  readonly agentModeSelect: Locator;
  readonly modelSelect: Locator;
  readonly messageHistory: Locator;
  readonly aiMessages: Locator;
  readonly thinkingArea: Locator;
  readonly connectionStatus: Locator;

  constructor(page: Page) {
    this.page = page;
    this.messageInput = page.locator('[data-llamabot="message-input"]');
    this.sendButton = page.locator('[data-llamabot="send-button"]');
    this.agentModeSelect = page.locator('[data-llamabot="agent-mode-select"]');
    this.modelSelect = page.locator('[data-llamabot="model-select"]');
    this.messageHistory = page.locator('[data-llamabot="message-history"]');
    this.aiMessages = page.locator('[data-llamabot="ai-message"]');
    this.thinkingArea = page.locator('[data-llamabot="thinking-area"]');
    this.connectionStatus = page.locator('[data-llamabot="connection-status"]');
  }

  /**
   * Open the chat UI and wait until the WebSocket is connected.
   * Pass a query string (e.g. '?llm_model=gemini-3-flash') to exercise the
   * URL-param handling that runs during page init.
   */
  async goto(query = '') {
    await this.page.goto('/' + query);
    await expect(this.messageInput, 'chat UI should load (are you logged in?)').toBeVisible({
      timeout: 30_000,
    });
    await this.waitForConnected();
  }

  /** WebSocketManager sets className to "connection-status connected" once live. */
  async waitForConnected(timeoutMs = 30_000) {
    await expect(this.connectionStatus).toHaveClass(/\bconnected\b/, { timeout: timeoutMs });
  }

  /** Switch agent mode (e.g. 'ticket', 'engineer'). Dispatches a real change event. */
  async selectAgentMode(mode: string) {
    await this.agentModeSelect.evaluate((el: HTMLSelectElement, value) => {
      if (![...el.options].some((o) => o.value === value)) {
        throw new Error(
          `Agent mode "${value}" not present in selector. Available: ` +
            [...el.options].map((o) => o.value).join(', ')
        );
      }
      el.value = value;
      el.dispatchEvent(new Event('change', { bubbles: true }));
    }, mode);
  }

  /**
   * Switch LLM model. The select may be hidden behind a toggle, so set it via
   * the DOM. Unknown values (e.g. 'fake-llm') get an option injected first —
   * the value is sent verbatim to the backend as llm_model.
   */
  async selectModel(model: string) {
    await this.modelSelect.evaluate((el: HTMLSelectElement, value) => {
      if (![...el.options].some((o) => o.value === value)) {
        const opt = document.createElement('option');
        opt.value = value;
        opt.textContent = `${value} (e2e)`;
        el.appendChild(opt);
      }
      el.value = value;
      el.dispatchEvent(new Event('change', { bubbles: true }));
    }, model);
  }

  /** Type a message and click send. */
  async sendMessage(text: string) {
    await this.messageInput.fill(text);
    await this.sendButton.click();
  }

  /**
   * Wait (briefly) for the thinking indicator to appear after sending a
   * message, so an isIdle() check right after sending can't race it.
   * Tolerates very fast turns where the indicator is gone before we look.
   */
  async waitForThinkingStart(timeoutMs = 15_000) {
    await this.thinkingArea
      .waitFor({ state: 'visible', timeout: timeoutMs })
      .catch(() => {/* turn may already be over */});
  }

  /** True when no agent turn is in flight (thinking indicator hidden). */
  async isIdle(): Promise<boolean> {
    return this.thinkingArea.isHidden();
  }

  /**
   * Wait for the agent's turn to finish. The frontend shows the thinking-area
   * while the agent is working and hides it again when the turn completes
   * (or the socket drops). Note ticket-mode turns can run many minutes —
   * prefer polling for the side effect you actually care about (e.g. a DB
   * row) over waiting for idle when possible.
   */
  async waitForTurnEnd(timeoutMs = DEFAULT_TURN_TIMEOUT_MS) {
    await this.waitForThinkingStart();
    await expect(this.thinkingArea, 'agent turn should complete').toBeHidden({
      timeout: timeoutMs,
    });
    // Let trailing renders settle.
    await this.page.waitForTimeout(1_000);
  }

  /** Convenience: send + wait for the agent to finish responding. */
  async sendAndWaitForTurn(text: string, timeoutMs = DEFAULT_TURN_TIMEOUT_MS) {
    await this.sendMessage(text);
    await this.waitForTurnEnd(timeoutMs);
  }

  async lastAiMessageText(): Promise<string> {
    return (await this.aiMessages.last().innerText()).trim();
  }

  async aiMessageCount(): Promise<number> {
    return this.aiMessages.count();
  }
}
