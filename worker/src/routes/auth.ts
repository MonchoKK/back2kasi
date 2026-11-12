import { Hono } from 'hono';
import bcrypt from 'bcryptjs';
import { Env, AuthResponse, UserRow, AuthUser } from '../types';
import { generateToken, getJwtSecret, getJwtExpirationSeconds, verifyToken } from '../lib/jwt';
import { BadCredentialsError, ConflictError, ValidationError } from '../lib/errors';
import {
  createSession,
  validateAndRotateSession,
  revokeSessionByToken,
  revokeAllUserSessions,
  listUserSessions,
  getRefreshTokenExpirationDays,
} from '../lib/sessions';
import { requireAuth } from '../middleware/auth';

export const authRoutes = new Hono<{
  Bindings: Env;
  Variables: { user?: AuthUser };
}>();

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const PHONE_REGEX = /^\+27[0-9]{9}$/;

authRoutes.post('/register', async (c) => {
  let body: any;
  try {
    body = await c.req.json();
  } catch {
    throw new ValidationError({ body: 'Malformed JSON request body' }, 'Malformed JSON request body');
  }

  const { firstName, lastName, email, password, phoneNumber } = body || {};
  const fieldErrors: Record<string, string> = {};

  if (!firstName || typeof firstName !== 'string' || !firstName.trim()) {
    fieldErrors.firstName = 'First name is required';
  }
  if (!lastName || typeof lastName !== 'string' || !lastName.trim()) {
    fieldErrors.lastName = 'Last name is required';
  }
  if (!email || typeof email !== 'string' || !email.trim()) {
    fieldErrors.email = 'Email is required';
  } else if (!EMAIL_REGEX.test(email.trim())) {
    fieldErrors.email = 'Email must be a valid email address';
  }
  if (!password || typeof password !== 'string') {
    fieldErrors.password = 'Password is required';
  } else if (password.length < 7) {
    fieldErrors.password = 'Password must be at least 7 characters';
  }
  if (!phoneNumber || typeof phoneNumber !== 'string' || !phoneNumber.trim()) {
    fieldErrors.phoneNumber = 'Phone number is required';
  } else if (!PHONE_REGEX.test(phoneNumber.trim())) {
    fieldErrors.phoneNumber =
      'Phone number must be a valid South African number in +27 format (e.g. +27712345678)';
  }

  if (Object.keys(fieldErrors).length > 0) {
    throw new ValidationError(fieldErrors);
  }

  const cleanEmail = email.trim().toLowerCase();
  const cleanPhone = phoneNumber.trim();

  // Check for duplicate email
  const existing = await c.env.DB.prepare('SELECT id FROM users WHERE email = ?')
    .bind(cleanEmail)
    .first();

  if (existing) {
    throw new ConflictError(`An account with this email address already exists: ${cleanEmail}`);
  }

  // Hash password using Worker-compatible bcryptjs
  const hashedPassword = await bcrypt.hash(password, 10);
  const now = new Date().toISOString();

  await c.env.DB.prepare(
    `INSERT INTO users (first_name, last_name, email, password, phone_number, role, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, 'USER', ?, ?)`
  )
    .bind(firstName.trim(), lastName.trim(), cleanEmail, hashedPassword, cleanPhone, now, now)
    .run();

  return c.text('User registered successfully', 201);
});

authRoutes.post('/login', async (c) => {
  let body: any;
  try {
    body = await c.req.json();
  } catch {
    throw new ValidationError({ body: 'Malformed JSON request body' }, 'Malformed JSON request body');
  }

  const { email, password } = body || {};
  const fieldErrors: Record<string, string> = {};

  if (!email || typeof email !== 'string' || !email.trim()) {
    fieldErrors.email = 'Email is required';
  }
  if (!password || typeof password !== 'string') {
    fieldErrors.password = 'Password is required';
  }

  if (Object.keys(fieldErrors).length > 0) {
    throw new ValidationError(fieldErrors);
  }

  const cleanEmail = email.trim().toLowerCase();

  const user = await c.env.DB.prepare(
    'SELECT id, first_name, last_name, email, password, role FROM users WHERE email = ?'
  )
    .bind(cleanEmail)
    .first<UserRow>();

  if (!user) {
    throw new BadCredentialsError('Invalid email or password');
  }

  const passwordMatches = await bcrypt.compare(password, user.password);
  if (!passwordMatches) {
    throw new BadCredentialsError('Invalid email or password');
  }

  const secret = getJwtSecret(c.env);
  const expiresIn = getJwtExpirationSeconds(c.env);
  const token = await generateToken(user, secret, expiresIn);

  // Extract client metadata for session tracking
  const userAgent = c.req.header('user-agent') || null;
  const ipAddress = c.req.header('cf-connecting-ip') || c.req.header('x-forwarded-for') || null;
  const days = getRefreshTokenExpirationDays(c.env);

  // Persist session in D1
  const session = await createSession(c.env.DB, user.id, {
    userAgent,
    ipAddress,
    expiresInDays: days,
  });

  const response: AuthResponse = {
    token,
    refreshToken: session.refreshToken,
    tokenType: 'Bearer',
    expiresIn,
    user: {
      id: user.id,
      email: user.email,
      firstName: user.first_name,
      lastName: user.last_name,
      role: user.role,
    },
  };

  return c.json(response, 200);
});

authRoutes.post('/refresh', async (c) => {
  let body: any;
  try {
    body = await c.req.json();
  } catch {
    throw new ValidationError({ body: 'Malformed JSON request body' }, 'Malformed JSON request body');
  }

  const { refreshToken } = body || {};
  if (!refreshToken || typeof refreshToken !== 'string' || !refreshToken.trim()) {
    throw new ValidationError({ refreshToken: 'Refresh token is required' }, 'Refresh token is required');
  }

  const userAgent = c.req.header('user-agent') || null;
  const ipAddress = c.req.header('cf-connecting-ip') || c.req.header('x-forwarded-for') || null;
  const days = getRefreshTokenExpirationDays(c.env);

  // Validate refresh token and rotate (revokes current session and creates new one)
  const rotated = await validateAndRotateSession(c.env.DB, refreshToken.trim(), {
    userAgent,
    ipAddress,
    expiresInDays: days,
  });

  const secret = getJwtSecret(c.env);
  const expiresIn = getJwtExpirationSeconds(c.env);
  const newAccessToken = await generateToken(rotated.user, secret, expiresIn);

  const response: AuthResponse = {
    token: newAccessToken,
    refreshToken: rotated.newRefreshToken,
    tokenType: 'Bearer',
    expiresIn,
    user: rotated.user,
  };

  return c.json(response, 200);
});

authRoutes.post('/logout', async (c) => {
  let refreshToken: string | undefined;

  try {
    const body = await c.req.json();
    if (body && typeof body.refreshToken === 'string') {
      refreshToken = body.refreshToken.trim();
    }
  } catch {
    // Body optional if Bearer header is passed
  }

  let revoked = false;

  // 1. If refreshToken provided, revoke that specific session
  if (refreshToken) {
    revoked = await revokeSessionByToken(c.env.DB, refreshToken);
  }

  // 2. If Authorization header present, verify and optionally revoke user session
  const authHeader = c.req.header('Authorization');
  if (authHeader && authHeader.startsWith('Bearer ')) {
    try {
      const token = authHeader.substring(7).trim();
      const secret = getJwtSecret(c.env);
      const payload = await verifyToken(token, secret);
      if (!refreshToken && payload.userId) {
        // If no specific refreshToken was supplied, revoke all sessions for this authenticated user
        await revokeAllUserSessions(c.env.DB, payload.userId);
        revoked = true;
      }
    } catch {
      // Ignored for logout endpoint
    }
  }

  return c.json({
    message: 'Logged out successfully',
    revoked,
  }, 200);
});

// List user's active sessions
authRoutes.get('/sessions', requireAuth as any, async (c) => {
  const user = c.get('user');
  if (!user) {
    throw new BadCredentialsError('Not authenticated');
  }

  const sessions = await listUserSessions(c.env.DB, user.id);
  return c.json({ sessions }, 200);
});

// Revoke all active sessions for current user
authRoutes.post('/sessions/revoke-all', requireAuth as any, async (c) => {
  const user = c.get('user');
  if (!user) {
    throw new BadCredentialsError('Not authenticated');
  }

  const count = await revokeAllUserSessions(c.env.DB, user.id);
  return c.json({
    message: 'All active sessions revoked successfully',
    revokedCount: count,
  }, 200);
});
