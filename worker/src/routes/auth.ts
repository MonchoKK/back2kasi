import { Hono } from 'hono';
import bcrypt from 'bcryptjs';
import { Env, AuthResponse, UserRow } from '../types';
import { generateToken, getJwtSecret, getJwtExpirationSeconds } from '../lib/jwt';
import { BadCredentialsError, ConflictError, ValidationError } from '../lib/errors';

export const authRoutes = new Hono<{ Bindings: Env }>();

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
    'SELECT id, email, password, role FROM users WHERE email = ?'
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

  const response: AuthResponse = {
    token,
    tokenType: 'Bearer',
    expiresIn,
  };

  return c.json(response, 200);
});
