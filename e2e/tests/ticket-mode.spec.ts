import { test, expect } from '@playwright/test';
import { ChatPage } from '../helpers/chat-page';
import {
  ticketsCreatedSince,
  deleteTicket,
  gitStatusLines,
  TicketRow,
} from '../helpers/stack';

/**
 * Full-stack, REAL-LLM test of ticket mode:
 *
 *   browser → FastAPI chat UI → WebSocket → rails_ticket_mode_agent
 *   (LangGraph + DeepSeek v4 Flash) → bin/rails runner →
 *   llama_bot_rails_tickets row in Postgres
 *
 * Success is detected by polling the database for the ticket row WHILE the
 * agent works — a ticket-mode turn keeps running after the ticket is written
 * (research artifacts, spec skeletons), so waiting for the UI to go idle
 * would time out. If a turn ends without a ticket (the agent's
 * story-confirmation interrupt), the test replies affirmatively and keeps
 * polling, up to a bounded number of rounds.
 *
 * Assertions are structural (row exists, fields populated), never
 * exact-text — LLM phrasing varies run to run.
 *
 * Requires DEEPSEEK_API_KEY in the llamabot container env. Costs a few
 * cents and takes 2–8 minutes. NOTE: ticket-mode research may write real
 * files (specs, even models/migrations) into the Leonardo working tree —
 * the test reports what was touched but does NOT delete files. Prefer a
 * clean checkout / disposable environment in CI.
 */

const LLM_MODEL = process.env.E2E_LLM_MODEL || 'deepseek-v4-flash';
const TEST_TIMEOUT = Number(process.env.E2E_TICKET_TIMEOUT_MS || 720_000);
const POLL_INTERVAL_MS = 10_000;
const MAX_CONFIRMATION_ROUNDS = 3;

// Marker lets us assert on (and clean up) our own ticket only, even if real
// users are working in the same environment.
const RUN_MARKER = `e2e-${Date.now().toString(36)}`;

const OBSERVATION = [
  `I was on the public welcome page (path: /welcome) of our app.`,
  `Current behavior: the page has no way for a visitor to leave their email to get product updates.`,
  `Desired behavior: add a simple email signup field with a "Notify me" button under the main heading on /welcome.`,
  `When a visitor submits a valid email, it should be saved so we can contact them later, and they should see a confirmation message on the same page.`,
  `Submitting an invalid or blank email should show a validation error and save nothing.`,
  `Acceptance criteria: (1) email input + "Notify me" button visible on /welcome, (2) valid submission persists the email and shows a confirmation, (3) invalid submission shows an error and persists nothing.`,
  `Reference ID for this request: ${RUN_MARKER}. Please include this reference ID in the ticket description.`,
  `I have given you everything I know — do not ask me any follow-up questions.`,
  `Please confirm the story exactly as I described it and write the final ticket now.`,
].join(' ');

const CONFIRMATION_REPLY =
  'Yes, confirmed — everything in that story is correct as written. ' +
  'Do not ask anything else; please write the final ticket now.';

test.describe('Ticket mode (real LLM)', () => {
  const createdTicketIds: number[] = [];

  test.afterEach(async () => {
    if (process.env.E2E_KEEP_TICKETS === 'true') return;
    for (const id of createdTicketIds.splice(0)) {
      await deleteTicket(id).catch((err) =>
        console.warn(`[cleanup] could not delete ticket ${id}: ${err}`)
      );
    }
  });

  test('creates an implementation-ready ticket from a user observation', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);

    // 60s slack absorbs clock skew between test runner and DB container.
    const startedAt = new Date(Date.now() - 60_000).toISOString();
    const worktreeBefore = await gitStatusLines();

    const chat = new ChatPage(page);
    await chat.goto();
    await chat.selectAgentMode('ticket');
    await chat.selectModel(LLM_MODEL);

    await chat.sendMessage(OBSERVATION);
    await chat.waitForThinkingStart();

    // Poll the DB while the agent works; nudge past confirmation interrupts.
    const deadline = Date.now() + TEST_TIMEOUT - 45_000;
    let ticket: TicketRow | null = null;
    let confirmationRounds = 0;
    while (!ticket && Date.now() < deadline) {
      await page.waitForTimeout(POLL_INTERVAL_MS);
      ticket = await findOurTicket(startedAt);
      if (ticket) break;

      if (await chat.isIdle()) {
        const lastMessage = truncate(await chat.lastAiMessageText(), 200);
        if (confirmationRounds >= MAX_CONFIRMATION_ROUNDS) {
          throw new Error(
            `agent went idle ${confirmationRounds + 1} times without creating a ticket. ` +
              `Last agent message: ${lastMessage}`
          );
        }
        confirmationRounds++;
        console.log(
          `[ticket-mode] turn ended without a ticket — confirming ` +
            `(round ${confirmationRounds}). Agent said: ${lastMessage}`
        );
        await chat.sendMessage(CONFIRMATION_REPLY);
        await chat.waitForThinkingStart();
      }
    }

    expect(ticket, 'agent should create a ticket before the deadline').toBeTruthy();
    createdTicketIds.push(ticket!.id);
    console.log(
      `[ticket-mode] ticket #${ticket!.id}: "${ticket!.title}" ` +
        `(description ${ticket!.descriptionLength} chars, ` +
        `research ${ticket!.researchNotesLength} chars, ` +
        `points ${ticket!.pointsEstimate ?? 'n/a'})`
    );

    // Structural quality gates — the contract of ticket mode.
    expect(ticket!.title.trim().length, 'ticket title should be substantial').toBeGreaterThan(5);
    expect(ticket!.status).toBe('backlog');
    expect(
      ticket!.descriptionLength,
      'description should contain the user story'
    ).toBeGreaterThan(100);
    expect(
      ticket!.researchNotesLength,
      'research notes should contain engineering findings'
    ).toBeGreaterThan(0);

    // Ticket-mode research can write real files into the Leonardo working
    // tree (spec skeletons, sometimes models/migrations). Surface — but do
    // not delete — anything it touched, so operators see the side effects.
    const worktreeAfter = await gitStatusLines();
    const touched = [...worktreeAfter].filter((line) => !worktreeBefore.has(line));
    if (touched.length > 0) {
      console.warn(
        `[ticket-mode] agent research modified the working tree (left in place):\n` +
          touched.map((l) => `  ${l}`).join('\n')
      );
    }
  });

  /** Our ticket (newest first), identified by the run marker we asked for;
   *  falls back to any ticket created since the test started, since the
   *  marker is a request to the LLM, not a guarantee. */
  async function findOurTicket(sinceIso: string): Promise<TicketRow | null> {
    const marked = await ticketsCreatedSince(sinceIso, RUN_MARKER);
    if (marked.length > 0) return marked[0];
    const all = await ticketsCreatedSince(sinceIso);
    return all[0] ?? null;
  }
});

function truncate(s: string, n: number): string {
  return s.length > n ? s.slice(0, n) + '…' : s;
}
