import { D1Database } from '@cloudflare/workers-types';
import { Env, Role, UserRow, SessionRow, SessionResponse } from '../types';
import { BadCredentialsError } from './errors';

/**
 * Generates a cryptographically secure random token string (64 characters hex).
 */
export function generateSecureToken(): string {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  return Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

/**
 * Computes a SHA-256 hash of a plain refresh token string.
 */
export async function hashToken(token: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(token);
  const digest = await crypto.subtle.digest('SHA-256', data);
  const bytes = new Uint8Array(digest);
  return Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

export function getRefreshTokenExpirationDays(env: Env): number {
  return env.REFRESH_TOKEN_EXPIRATION_DAYS
    ? parseInt(env.REFRESH_TOKEN_EXPIRATION_DAYS, 10)
    : 30;
}

export interface SessionUserInfo {
  id: number;
  email: string;
  firstName: string;
  lastName: string;
  role: Role;
}

export interface CreatedSession {
  sessionId: number;
  refreshToken: string;
  expiresAt: string;
}

export interface RotatedSession {
  user: SessionUserInfo;
  newRefreshToken: string;
  expiresAt: string;
}

/**
 * Creates a new active session record in D1, storing only the SHA-256 hash.
 */
export async function createSession(
  db: D1Database,
  userId: number,
  options: {
    userAgent?: string | null;
    ipAddress?: string | null;
    expiresInDays?: number;
  } = {}
): Promise<CreatedSession> {
  const refreshToken = generateSecureToken();
  const tokenHash = await hashToken(refreshToken);
  const days = options.expiresInDays ?? 30;
  const expiresAt = new Date(Date.now() + days * 24 * 60 * 60 * 1000).toISOString();
  const now = new Date().toISOString();

  const result = await db
    .prepare(
      `INSERT INTO sessions (user_id, refresh_token_hash, user_agent, ip_address, is_revoked, expires_at, created_at, updated_at)
       VALUES (?, ?, ?, ?, 0, ?, ?, ?)`
    )
    .bind(
      userId,
      tokenHash,
      options.userAgent ?? null,
      options.ipAddress ?? null,
      expiresAt,
      now,
      now
    )
    .run();

  const sessionId = result.meta?.last_row_id as number;

  return {
    sessionId,
    refreshToken,
    expiresAt,
  };
}

/**
 * Validates a refresh token against D1, checks revocation and expiry,
 * then rotates the token (revokes current session and issues a new one).
 */
export async function validateAndRotateSession(
  db: D1Database,
  rawRefreshToken: string,
  options: {
    userAgent?: string | null;
    ipAddress?: string | null;
    expiresInDays?: number;
  } = {}
): Promise<RotatedSession> {
  if (!rawRefreshToken || typeof rawRefreshToken !== 'string' || !rawRefreshToken.trim()) {
    throw new BadCredentialsError('Refresh token is required');
  }

  const tokenHash = await hashToken(rawRefreshToken.trim());

  interface JoinedSessionRow {
    id: number;
    user_id: number;
    is_revoked: number;
    expires_at: string;
    email: string;
    first_name: string;
    last_name: string;
    role: Role;
  }

  const session = await db
    .prepare(
      `SELECT s.id, s.user_id, s.is_revoked, s.expires_at,
              u.email, u.first_name, u.last_name, u.role
       FROM sessions s
       JOIN users u ON s.user_id = u.id
       WHERE s.refresh_token_hash = ?`
    )
    .bind(tokenHash)
    .first<JoinedSessionRow>();

  if (!session) {
    throw new BadCredentialsError('Invalid refresh token');
  }

  if (session.is_revoked === 1) {
    // Refresh token reuse / revocation detection
    throw new BadCredentialsError('Session has been revoked');
  }

  const nowEpoch = Date.now();
  const expiryEpoch = new Date(session.expires_at).getTime();
  if (isNaN(expiryEpoch) || expiryEpoch <= nowEpoch) {
    throw new BadCredentialsError('Refresh token has expired');
  }

  const nowIso = new Date().toISOString();

  // Revoke old session to enforce rotation
  await db
    .prepare(
      `UPDATE sessions
       SET is_revoked = 1, updated_at = ?
       WHERE id = ?`
    )
    .bind(nowIso, session.id)
    .run();

  // Create rotated new session
  const newCreated = await createSession(db, session.user_id, {
    userAgent: options.userAgent,
    ipAddress: options.ipAddress,
    expiresInDays: options.expiresInDays,
  });

  return {
    user: {
      id: session.user_id,
      email: session.email,
      firstName: session.first_name,
      lastName: session.last_name,
      role: session.role,
    },
    newRefreshToken: newCreated.refreshToken,
    expiresAt: newCreated.expiresAt,
  };
}

/**
 * Revokes a session given its plain refresh token.
 */
export async function revokeSessionByToken(
  db: D1Database,
  rawRefreshToken: string
): Promise<boolean> {
  if (!rawRefreshToken || typeof rawRefreshToken !== 'string' || !rawRefreshToken.trim()) {
    return false;
  }
  const tokenHash = await hashToken(rawRefreshToken.trim());
  const now = new Date().toISOString();

  const result = await db
    .prepare(
      `UPDATE sessions
       SET is_revoked = 1, updated_at = ?
       WHERE refresh_token_hash = ? AND is_revoked = 0`
    )
    .bind(now, tokenHash)
    .run();

  return (result.meta?.changes ?? 0) > 0;
}

/**
 * Revokes all active sessions for a given user.
 */
export async function revokeAllUserSessions(
  db: D1Database,
  userId: number
): Promise<number> {
  const now = new Date().toISOString();
  const result = await db
    .prepare(
      `UPDATE sessions
       SET is_revoked = 1, updated_at = ?
       WHERE user_id = ? AND is_revoked = 0`
    )
    .bind(now, userId)
    .run();

  return result.meta?.changes ?? 0;
}

/**
 * Lists all active (non-revoked, unexpired) sessions for a user.
 */
export async function listUserSessions(
  db: D1Database,
  userId: number
): Promise<SessionResponse[]> {
  const now = new Date().toISOString();
  const rows = await db
    .prepare(
      `SELECT id, user_agent, ip_address, is_revoked, expires_at, created_at, updated_at
       FROM sessions
       WHERE user_id = ? AND is_revoked = 0 AND expires_at > ?
       ORDER BY created_at DESC`
    )
    .bind(userId, now)
    .all<SessionRow>();

  return (rows.results || []).map((row) => ({
    id: row.id,
    userAgent: row.user_agent,
    ipAddress: row.ip_address,
    isRevoked: row.is_revoked === 1,
    expiresAt: row.expires_at,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  }));
}

