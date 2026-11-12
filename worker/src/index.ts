import { Hono, Context } from 'hono';
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

// Image delivery helper supporting both Cloudflare R2 and D1 SQLite fallback
async function handleImageDelivery(
  c: Context<{ Bindings: Env; Variables: { user?: AuthUser } }>,
  rawKey: string
) {
  const key = rawKey ? decodeURIComponent(rawKey) : '';
  if (!key) {
    return c.json(formatApiError(400, 'Bad Request', 'Image key is required'), 400);
  }

  // 1. Try R2 bucket if bound and available
  if (c.env.IMAGES_BUCKET) {
    try {
      const object = await c.env.IMAGES_BUCKET.get(key);
      if (object) {
        const headers = new Headers();
        headers.set('Content-Type', object.httpMetadata?.contentType || 'image/jpeg');
        headers.set('Cache-Control', 'public, max-age=31536000, immutable');
        if (object.httpEtag) {
          headers.set('ETag', object.httpEtag);
        }
        return new Response(object.body, { headers });
      }
    } catch (err) {
      console.warn('R2 image retrieval failed, checking D1:', err);
    }
  }

  // 2. Fallback to D1 database table rental_unit_images
  try {
    const row = await c.env.DB.prepare(
      'SELECT content_type, image_data FROM rental_unit_images WHERE r2_key = ? OR r2_key = ?'
    )
      .bind(key, rawKey)
      .first<{ content_type: string; image_data: string | null }>();

    if (row && row.image_data) {
      const binaryStr = atob(row.image_data);
      const bytes = new Uint8Array(binaryStr.length);
      for (let i = 0; i < binaryStr.length; i++) {
        bytes[i] = binaryStr.charCodeAt(i);
      }
      const headers = new Headers();
      headers.set('Content-Type', row.content_type || 'image/jpeg');
      headers.set('Cache-Control', 'public, max-age=31536000, immutable');
      return new Response(bytes.buffer, { headers });
    }
  } catch (err) {
    console.error('D1 image fallback query failed:', err);
  }

  return c.json(formatApiError(404, 'Not Found', `Image not found with key: ${key}`), 404);
}

// Image delivery routes (supporting both /api/v1/images/* and /api/images/*)
app.get('/api/v1/images/*', async (c) => {
  const rawKey = c.req.path.replace(/^\/api\/v1\/images\//, '');
  return handleImageDelivery(c, rawKey);
});

app.get('/api/images/*', async (c) => {
  const rawKey = c.req.path.replace(/^\/api\/images\//, '');
  return handleImageDelivery(c, rawKey);
});

// Route registration - Dual aliases for both versioned (/api/v1/*) and unversioned (/api/*)
app.route('/api/users', authRoutes);
app.route('/api/v1/users', authRoutes);

app.route('/api/businesses', businessRoutes);
app.route('/api/v1/businesses', businessRoutes);

app.route('/api/rental-units', rentalUnitRoutes);
app.route('/api/v1/rental-units', rentalUnitRoutes);

app.route('/api/catalogue-items', rentalUnitRoutes);
app.route('/api/v1/catalogue-items', rentalUnitRoutes);

app.route('/api/bookings', bookingRoutes);
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
