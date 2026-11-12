import { sign, verify } from 'hono/jwt';
import { Env, JwtPayload, Role } from '../types';

export function getJwtSecret(env: Env): string {
  return env.JWT_SECRET || env.DEFAULT_JWT_SECRET || 'back2kasi-jwt-secret-free-tier-2026-key';
}

export function getJwtExpirationSeconds(env: Env): number {
  return env.JWT_EXPIRATION_SECONDS ? parseInt(env.JWT_EXPIRATION_SECONDS, 10) : 3600;
}

export async function generateToken(
  user: { id: number; email: string; role: Role },
  secret: string,
  expiresInSeconds: number
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const payload: JwtPayload = {
    sub: user.email,
    userId: user.id,
    role: user.role,
    iat: now,
    exp: now + expiresInSeconds,
  };
  return await sign(payload, secret, 'HS256');
}

export async function verifyToken(token: string, secret: string): Promise<JwtPayload> {
  const payload = await verify(token, secret, 'HS256');
  return payload as unknown as JwtPayload;
}
