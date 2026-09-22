import { Context, Next } from 'hono';
import { Env, AuthUser } from '../types';
import { getJwtSecret, verifyToken } from '../lib/jwt';
import { BadCredentialsError } from '../lib/errors';

export async function requireAuth(
  c: Context<{ Bindings: Env; Variables: { user: AuthUser } }>,
  next: Next
) {
  const authHeader = c.req.header('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new BadCredentialsError('Missing or invalid Authorization header');
  }

  const token = authHeader.substring(7).trim();
  const secret = getJwtSecret(c.env);

  try {
    const payload = await verifyToken(token, secret);

    const user = await c.env.DB.prepare(
      'SELECT id, email, role FROM users WHERE id = ?'
    )
      .bind(payload.userId)
      .first<{ id: number; email: string; role: any }>();

    if (!user) {
      throw new BadCredentialsError('User account associated with this token no longer exists');
    }

    c.set('user', {
      id: user.id,
      email: user.email,
      role: user.role,
    });

    await next();
  } catch (err: any) {
    if (err instanceof BadCredentialsError) throw err;
    throw new BadCredentialsError('Invalid or expired authentication token');
  }
}
