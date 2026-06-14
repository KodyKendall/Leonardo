import { defineConfig, devices } from '@playwright/test';
import * as dotenv from 'dotenv';
import * as path from 'path';

// Load e2e/.env (optional) — never commit secrets, see .env.example
dotenv.config({ path: path.resolve(__dirname, '.env') });

/**
 * The Leonardo stack must be running before tests start:
 *   bash bin/dev          (or: docker compose -f docker-compose-dev.yml up -d)
 *
 * Tests drive the LlamaBot FastAPI chat UI directly (default http://localhost:8000).
 * Agent runs use a REAL LLM (DeepSeek v4 Flash by default) — see README.md.
 */
// Set E2E_ARTIFACTS=1 to capture a screenshot + video + trace for EVERY test
// (passing ones too) — useful for documenting a run. CI leaves it unset and
// only keeps artifacts on failure, so green runs stay fast. All output lands
// in the gitignored test-results/ + playwright-report/ dirs, never in git.
const captureAll = !!process.env.E2E_ARTIFACTS;

export default defineConfig({
  testDir: './tests',
  // Agent turns with a real LLM are slow; individual tests override this further.
  timeout: 180_000,
  expect: { timeout: 30_000 },
  // The chat stack is stateful (threads, checkpoints, tickets) — run serially.
  fullyParallel: false,
  workers: 1,
  retries: process.env.CI ? 1 : 0,
  forbidOnly: !!process.env.CI,
  reporter: [['list'], ['html', { open: 'never' }]],
  use: {
    baseURL: process.env.E2E_BASE_URL || 'http://localhost:8000',
    trace: captureAll ? 'on' : 'retain-on-failure',
    video: captureAll ? 'on' : 'retain-on-failure',
    screenshot: captureAll ? 'on' : 'only-on-failure',
  },
  projects: [
    {
      name: 'setup',
      testMatch: /auth\.setup\.ts/,
    },
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        storageState: 'playwright/.auth/user.json',
      },
      dependencies: ['setup'],
    },
  ],
});
