import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { Env, AuthUser } from './types';
import { HttpError, formatApiError } from './lib/errors';
import { authRoutes } from './routes/auth';
import { businessRoutes } from './routes/businesses';
import { rentalUnitRoutes } from './routes/rental-units';
import { bookingRoutes } from './routes/bookings';

const app = new Hono<{
  Bindings: Env;
  Variables: { user?: AuthUser };
}>();

// Logging middleware
app.use('*', logger());

// Global CORS - permits mobile app and web clients
app.use(
  '*',
  cors({
    origin: '*',
    allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowHeaders: ['Content-Type', 'Authorization'],
    maxAge: 86400,
  })
);

// Health check / welcome
app.get('/', (c) => {
  return c.json({
    status: 'UP',
    platform: 'Back2Kasi Cloudflare Edge Worker API',
    timestamp: new Date().toISOString(),
  });
});

app.get('/health', (c) => {
  return c.json({ status: 'UP' });
});

// Image delivery endpoint from R2 bucket
app.get('/api/v1/images/*', async (c) => {
  const key = c.req.path.replace(/^\/api\/v1\/images\//, '');
  if (!key) {
    return c.json(formatApiError(400, 'Bad Request', 'Image key is required'), 400);
  }

  const object = await c.env.IMAGES_BUCKET.get(key);
  if (!object) {
    return c.json(formatApiError(404, 'Not Found', `Image not found with key: ${key}`), 404);
  }

  const headers = new Headers();
  headers.set('Content-Type', object.httpMetadata?.contentType || 'image/jpeg');
  headers.set('Cache-Control', 'public, max-age=31536000, immutable');
  if (object.httpEtag) {
    headers.set('ETag', object.httpEtag);
  }

  return new Response(object.body, { headers });
});

// Route registration
app.route('/api/users', authRoutes);
app.route('/api/v1/businesses', businessRoutes);
app.route('/api/v1/rental-units', rentalUnitRoutes);
app.route('/api/v1/bookings', bookingRoutes);

// Standard 404 handler
app.notFound((c) => {
  return c.json(
    formatApiError(404, 'Not Found', `Path not found: ${c.req.method} ${c.req.path}`),
    404
  );
});

// Global Error Handler matching Spring Boot ApiError structure
app.onError((err, c) => {
  console.error('Unhandled API Error:', err);

  if (err instanceof HttpError) {
    return c.json(
      formatApiError(err.status, err.error, err.message, err.fieldErrors),
      err.status as any
    );
  }

  return c.json(
    formatApiError(
      500,
      'Internal Server Error',
      'An unexpected error occurred. Please try again later.'
    ),
    500
  );
});

export default app;
