import { execFile } from 'child_process';
import { promisify } from 'util';
import * as path from 'path';

const pExecFile = promisify(execFile);

export const REPO_ROOT = path.resolve(__dirname, '..', '..');
// Colon-separated list of compose files, e.g. "docker-compose.yml:ci.override.yml"
export const COMPOSE_FILE = process.env.E2E_COMPOSE_FILE || 'docker-compose-dev.yml';
const COMPOSE_FILE_ARGS = COMPOSE_FILE.split(':').flatMap((f) => ['-f', f]);
const PG_USER = process.env.E2E_PG_USER || 'postgres';

// ASCII unit separator — never appears in ticket text, safe column delimiter.
const SEP = '\u001F';

async function compose(args: string[]): Promise<string> {
  const { stdout } = await pExecFile(
    'docker',
    ['compose', ...COMPOSE_FILE_ARGS, ...args],
    { cwd: REPO_ROOT, maxBuffer: 16 * 1024 * 1024 }
  );
  return stdout;
}

/**
 * The database Rails actually writes tickets into. database.yml may map the
 * dev environment to a non-obvious name (e.g. development →
 * llamapress_production in this repo), so unless E2E_RAILS_DB is set we ask
 * the Rails app itself, once, and cache the answer.
 */
let railsDbPromise: Promise<string> | null = null;
export function railsDb(): Promise<string> {
  if (process.env.E2E_RAILS_DB) return Promise.resolve(process.env.E2E_RAILS_DB);
  if (!railsDbPromise) {
    railsDbPromise = compose([
      'exec', '-T', 'llamapress',
      'bin/rails', 'runner', 'puts ActiveRecord::Base.connection_db_config.database',
    ]).then((out) => {
      const lines = out.trim().split('\n').filter(Boolean);
      const db = lines[lines.length - 1]?.trim();
      if (!db) throw new Error('could not detect the Rails database name via bin/rails runner');
      console.log(`[stack] detected Rails database: ${db}`);
      return db;
    });
  }
  return railsDbPromise;
}

/** Run SQL against the Rails Postgres DB inside the db container. */
export async function psql(sql: string): Promise<string[][]> {
  const db = await railsDb();
  const stdout = await compose([
    'exec', '-T', 'db',
    'psql', '-U', PG_USER, '-d', db, '-At', '-F', SEP, '-c', sql,
  ]);
  const trimmed = stdout.trim();
  if (!trimmed) return [];
  return trimmed.split('\n').map((line) => line.split(SEP));
}

export interface TicketRow {
  id: number;
  title: string;
  status: string;
  descriptionLength: number;
  researchNotesLength: number;
  notesLength: number;
  pointsEstimate: number | null;
}

/**
 * Tickets created at/after the given ISO timestamp (UTC), newest first.
 * With a marker, only tickets whose title/description contain it.
 */
export async function ticketsCreatedSince(isoUtc: string, marker?: string): Promise<TicketRow[]> {
  const markerClause = marker
    ? `AND (description LIKE '%${marker}%' OR title LIKE '%${marker}%')`
    : '';
  const rows = await psql(
    `SELECT id, title, status,
            COALESCE(LENGTH(description), 0),
            COALESCE(LENGTH(research_notes), 0),
            COALESCE(LENGTH(notes), 0),
            points_estimate
       FROM llama_bot_rails_tickets
      WHERE created_at >= '${isoUtc}' ${markerClause}
      ORDER BY created_at DESC`
  );
  return rows.map((r) => ({
    id: Number(r[0]),
    title: r[1],
    status: r[2],
    descriptionLength: Number(r[3]),
    researchNotesLength: Number(r[4]),
    notesLength: Number(r[5]),
    pointsEstimate: r[6] === '' ? null : Number(r[6]),
  }));
}

/** Remove a test-created ticket (and its comments/traces) from the Rails DB. */
export async function deleteTicket(id: number): Promise<void> {
  await psql(`DELETE FROM llama_bot_rails_ticket_comments WHERE ticket_id = ${id}`);
  await psql(`DELETE FROM llama_bot_rails_ticket_traces WHERE ticket_id = ${id}`);
  await psql(`DELETE FROM llama_bot_rails_tickets WHERE id = ${id}`);
}

/**
 * Snapshot of `git status --porcelain` lines for the Leonardo repo. Ticket
 * mode's research can write real files (spec skeletons, even models or
 * migrations) into the working tree — tests diff these snapshots to report
 * what the agent touched.
 */
export async function gitStatusLines(): Promise<Set<string>> {
  const { stdout } = await pExecFile('git', ['status', '--porcelain'], { cwd: REPO_ROOT });
  return new Set(stdout.split('\n').filter(Boolean));
}

/**
 * Idempotently create (or reset the password of) the e2e user, using
 * LlamaBot's own user_service inside the llamabot container. This is the
 * same code path the /register endpoint uses (bcrypt via app.services).
 */
export async function provisionTestUser(username: string, password: string): Promise<string> {
  const script = `
import sys, os
sys.path.insert(0, '/app')
from sqlmodel import Session
from app.db import engine
from app.services import user_service

username = os.environ['E2E_PROVISION_USERNAME']
password = os.environ['E2E_PROVISION_PASSWORD']

with Session(engine) as session:
    user = user_service.get_user_by_username(session, username)
    if user is None:
        user_service.create_user(session, username, password)
        print('created')
    else:
        user.password_hash = user_service.hash_password(password)
        user.is_active = True
        session.add(user)
        session.commit()
        print('updated')
`;
  const stdout = await compose([
    'exec', '-T',
    '-e', `E2E_PROVISION_USERNAME=${username}`,
    '-e', `E2E_PROVISION_PASSWORD=${password}`,
    'llamabot', 'python', '-c', script,
  ]);
  const lines = stdout.trim().split('\n').filter(Boolean);
  return lines[lines.length - 1] ?? '';
}
