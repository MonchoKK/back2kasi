import { test, describe, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';
import bcrypt from 'bcryptjs';
import app from '../src/index';
import {
  createSession,
  validateAndRotateSession,
  revokeSessionByToken,
  revokeAllUserSessions,
  listUserSessions,
  hashToken,
} from '../src/lib/sessions';
import { D1Database } from '@cloudflare/workers-types';

function createMockD1(): { sqlite: any; d1: D1Database } {
  const sqlite = new DatabaseSync(':memory:');

  // Schema for users and sessions
  sqlite.exec(`
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      first_name TEXT NOT NULL,
      last_name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE COLLATE NOCASE,
      password TEXT NOT NULL,
      phone_number TEXT NOT NULL,
      role TEXT NOT NULL DEFAULT 'USER',
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE sessions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      refresh_token_hash TEXT NOT NULL UNIQUE,
      user_agent TEXT,
      ip_address TEXT,
      is_revoked INTEGER NOT NULL DEFAULT 0,
      expires_at TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    );
  `);

  return {
    sqlite,
    d1: {
      prepare(sql: string) {
        return {
          bind(...params: any[]) {
            return {
              async first() {
                const stmt = sqlite.prepare(sql);
                const row = stmt.get(...params);
                return row || null;
              },
              async all() {
                const stmt = sqlite.prepare(sql);
                const results = stmt.all(...params);
                return { results, success: true, meta: {} };
              },
              async run() {
                const stmt = sqlite.prepare(sql);
                const info = stmt.run(...params);
                return {
                  success: true,
                  meta: {
                    changes: info.changes,
                    last_row_id: Number(info.lastInsertRowid),
                  },
                };
              },
            };
          },
        };
      },
    } as unknown as D1Database,
  };
}

describe('Sprint 33: D1 Session Tracking & Refresh Token Lifecycle', () => {
  let mock: { sqlite: any; d1: D1Database };
  let testUser: { id: number; email: string; role: any };

  beforeEach(async () => {
    mock = createMockD1();
    const hash = await bcrypt.hash('Password123!', 10);
    const now = new Date().toISOString();

    const insertStmt = mock.sqlite.prepare(`
      INSERT INTO users (first_name, last_name, email, password, phone_number, role, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, 'USER', ?, ?)
    `);
    const res = insertStmt.run('Sipho', 'Khumalo', 'sipho@example.com', hash, '+27821234567', now, now);
    testUser = {
      id: Number(res.lastInsertRowid),
      email: 'sipho@example.com',
      role: 'USER',
    };
  });

  test('createSession stores hashed token and returns raw refresh token with expiration', async () => {
    const session = await createSession(mock.d1, testUser.id, {
      userAgent: 'Back2Kasi-Android/2.0',
      ipAddress: '102.165.1.1',
      expiresInDays: 30,
    });

    assert.ok(session.sessionId > 0, 'Session ID should be created');
    assert.equal(session.refreshToken.length, 64, 'Refresh token should be 64-char hex string');
    assert.ok(new Date(session.expiresAt).getTime() > Date.now(), 'Expires at should be in future');

    // Verify D1 row has hashed token, not plain token
    const tokenHash = await hashToken(session.refreshToken);
    const row: any = mock.sqlite.prepare('SELECT * FROM sessions WHERE id = ?').get(session.sessionId);
    assert.ok(row, 'Session row must exist in D1');
    assert.equal(row.refresh_token_hash, tokenHash, 'Stored hash must match SHA-256');
    assert.notEqual(row.refresh_token_hash, session.refreshToken, 'Raw token must NEVER be stored in DB');
    assert.equal(row.is_revoked, 0, 'Session must initially be active (is_revoked = 0)');
  });

  test('validateAndRotateSession rotates valid session: revokes old, creates new', async () => {
    const initialSession = await createSession(mock.d1, testUser.id, {
      userAgent: 'Back2Kasi-Android/2.0',
      ipAddress: '102.165.1.1',
    });

    const rotated = await validateAndRotateSession(mock.d1, initialSession.refreshToken);

    assert.equal(rotated.user.id, testUser.id);
    assert.equal(rotated.user.email, 'sipho@example.com');
    assert.ok(rotated.newRefreshToken, 'Should issue new refresh token');
    assert.notEqual(rotated.newRefreshToken, initialSession.refreshToken, 'New token must differ from old');

    // Check old session is revoked
    const oldRow: any = mock.sqlite.prepare('SELECT * FROM sessions WHERE id = ?').get(initialSession.sessionId);
    assert.equal(oldRow.is_revoked, 1, 'Previous session must be marked revoked');

    // Check new session is active in D1
    const newHash = await hashToken(rotated.newRefreshToken);
    const newRow: any = mock.sqlite.prepare('SELECT * FROM sessions WHERE refresh_token_hash = ?').get(newHash);
    assert.ok(newRow, 'New session must exist in D1');
    assert.equal(newRow.is_revoked, 0, 'New session must be active');
  });

  test('validateAndRotateSession rejects revoked session (anti-reuse detection)', async () => {
    const session = await createSession(mock.d1, testUser.id);
    // Revoke the session manually
    await revokeSessionByToken(mock.d1, session.refreshToken);

    await assert.rejects(
      async () => {
        await validateAndRotateSession(mock.d1, session.refreshToken);
      },
      {
        name: 'HttpError',
        status: 401,
        message: 'Session has been revoked',
      }
    );
  });

  test('validateAndRotateSession rejects expired session', async () => {
    const session = await createSession(mock.d1, testUser.id, {
      expiresInDays: -1, // Expired yesterday
    });

    await assert.rejects(
      async () => {
        await validateAndRotateSession(mock.d1, session.refreshToken);
      },
      {
        name: 'HttpError',
        status: 401,
        message: 'Refresh token has expired',
      }
    );
  });

  test('revokeSessionByToken marks session revoked for clean logout', async () => {
    const session = await createSession(mock.d1, testUser.id);
    const success = await revokeSessionByToken(mock.d1, session.refreshToken);
    assert.equal(success, true);

    const tokenHash = await hashToken(session.refreshToken);
    const row: any = mock.sqlite.prepare('SELECT is_revoked FROM sessions WHERE refresh_token_hash = ?').get(tokenHash);
    assert.equal(row.is_revoked, 1);
  });

  test('revokeAllUserSessions revokes all sessions belonging to user', async () => {
    await createSession(mock.d1, testUser.id, { userAgent: 'Phone 1' });
    await createSession(mock.d1, testUser.id, { userAgent: 'Phone 2' });

    const count = await revokeAllUserSessions(mock.d1, testUser.id);
    assert.equal(count, 2, 'Should revoke 2 active sessions');

    const active = await listUserSessions(mock.d1, testUser.id);
    assert.equal(active.length, 0, 'No active sessions should remain');
  });
});

describe('Sprint 33: Worker HTTP Endpoints Integration', () => {
  let mock: { sqlite: any; d1: D1Database };
  let env: any;

  beforeEach(async () => {
    mock = createMockD1();
    const hash = await bcrypt.hash('SecretPass123!', 10);
    const now = new Date().toISOString();

    mock.sqlite.prepare(`
      INSERT INTO users (first_name, last_name, email, password, phone_number, role, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, 'USER', ?, ?)
    `).run('Nomsa', 'Dlamini', 'nomsa@example.com', hash, '+27831112233', now, now);

    env = {
      DB: mock.d1,
      JWT_SECRET: 'test-secret-key-1234567890',
      JWT_EXPIRATION_SECONDS: '3600',
      REFRESH_TOKEN_EXPIRATION_DAYS: '30',
    };
  });

  test('POST /api/users/login returns access token, refresh token and creates D1 session', async () => {
    const res = await app.request(
      'http://localhost/api/users/login',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Flutter Test Agent',
          'CF-Connecting-IP': '102.165.1.20',
        },
        body: JSON.stringify({
          email: 'nomsa@example.com',
          password: 'SecretPass123!',
        }),
      },
      env
    );

    assert.equal(res.status, 200);
    const body: any = await res.json();
    assert.ok(body.token, 'Should return access token');
    assert.ok(body.refreshToken, 'Should return refresh token');
    assert.equal(body.tokenType, 'Bearer');
    assert.equal(body.expiresIn, 3600);
    assert.equal(body.user.email, 'nomsa@example.com');
    assert.equal(body.user.firstName, 'Nomsa');

    // Confirm session row in D1
    const tokenHash = await hashToken(body.refreshToken);
    const row: any = mock.sqlite.prepare('SELECT * FROM sessions WHERE refresh_token_hash = ?').get(tokenHash);
    assert.ok(row, 'Session row must exist in D1');
    assert.equal(row.user_agent, 'Flutter Test Agent');
    assert.equal(row.ip_address, '102.165.1.20');
  });

  test('POST /api/users/refresh successfully renews tokens with valid refresh token', async () => {
    // 1. Login first
    const loginRes = await app.request(
      'http://localhost/api/users/login',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: 'nomsa@example.com', password: 'SecretPass123!' }),
      },
      env
    );
    const { token: initialToken, refreshToken: initialRefresh }: any = await loginRes.json();

    // 2. Call /refresh
    const refreshRes = await app.request(
      'http://localhost/api/users/refresh',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refreshToken: initialRefresh }),
      },
      env
    );

    assert.equal(refreshRes.status, 200);
    const refreshBody: any = await refreshRes.json();
    assert.ok(refreshBody.token, 'New access token issued');
    assert.ok(refreshBody.refreshToken, 'New refresh token issued');
    assert.notEqual(refreshBody.refreshToken, initialRefresh, 'Refresh token rotated');

    // 3. Re-using initial refresh token must fail with 401
    const reuseRes = await app.request(
      'http://localhost/api/users/refresh',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refreshToken: initialRefresh }),
      },
      env
    );
    assert.equal(reuseRes.status, 401, 'Reusing rotated refresh token must fail with 401');
  });

  test('POST /api/users/logout terminates session in D1', async () => {
    // 1. Login
    const loginRes = await app.request(
      'http://localhost/api/users/login',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: 'nomsa@example.com', password: 'SecretPass123!' }),
      },
      env
    );
    const { refreshToken }: any = await loginRes.json();

    // 2. Logout
    const logoutRes = await app.request(
      'http://localhost/api/users/logout',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refreshToken }),
      },
      env
    );
    assert.equal(logoutRes.status, 200);

    // 3. Subsequent /refresh must fail
    const refreshRes = await app.request(
      'http://localhost/api/users/refresh',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refreshToken }),
      },
      env
    );
    assert.equal(refreshRes.status, 401);
  });
});
