import { test as setup, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';
import { provisionTestUser } from '../helpers/stack';

const AUTH_FILE = path.resolve(__dirname, '..', 'playwright', '.auth', 'user.json');
const USERNAME = process.env.E2E_USERNAME || 'leonardo-e2e';
const PASSWORD = process.env.E2E_PASSWORD || 'leonardo-e2e-password-change-me';

setup('authenticate', async ({ page, baseURL }) => {
  // Ensure the test user exists (runs inside the llamabot container).
  // Set E2E_PROVISION_USER=false when the stack isn't reachable via docker
  // compose from this machine — then the user must already exist.
  if (process.env.E2E_PROVISION_USER !== 'false') {
    try {
      const result = await provisionTestUser(USERNAME, PASSWORD);
      console.log(`[auth.setup] test user "${USERNAME}": ${result}`);
    } catch (err) {
      throw new Error(
        `Could not provision test user via docker compose. Is the stack up ` +
          `(bash bin/dev)? Or set E2E_PROVISION_USER=false and create the ` +
          `user manually.\n${err}`
      );
    }
  }

  let response;
  try {
    response = await page.goto('/');
  } catch (err) {
    throw new Error(
      `Could not reach ${baseURL} — start the stack first (bash bin/dev), ` +
        `or point E2E_BASE_URL at the right host.\n${err}`
    );
  }
  expect(response?.ok(), `GET ${baseURL} should succeed`).toBeTruthy();

  // Unauthenticated browsers get redirected to /login (or /register on a
  // fresh instance with zero users).
  if (page.url().includes('/register')) {
    await page.fill('#username', USERNAME);
    await page.fill('#password', PASSWORD);
    await page.fill('#confirm', PASSWORD);
    await page.click('button[type="submit"]');
    await page.waitForURL('**/', { timeout: 15_000 });
  } else if (page.url().includes('/login')) {
    await page.fill('#username', USERNAME);
    await page.fill('#password', PASSWORD);
    await page.click('#submitBtn');
    await page.waitForURL((url) => !url.pathname.includes('/login'), { timeout: 15_000 });
  }

  // We should now be on the chat page; wait for it to boot so the WS token
  // lands in localStorage before we snapshot storage state.
  await expect(page.locator('[data-llamabot="message-input"]')).toBeVisible({ timeout: 30_000 });

  fs.mkdirSync(path.dirname(AUTH_FILE), { recursive: true });
  await page.context().storageState({ path: AUTH_FILE });
});
