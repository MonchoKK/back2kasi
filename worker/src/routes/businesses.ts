import { Hono } from 'hono';
import { Env, AuthUser, BusinessResponse, BusinessRow, BusinessType } from '../types';
import { requireAuth } from '../middleware/auth';
import { ResourceNotFoundError, UnauthorizedError, ValidationError } from '../lib/errors';

export const businessRoutes = new Hono<{
  Bindings: Env;
  Variables: { user: AuthUser };
}>();

const VALID_BUSINESS_TYPES: BusinessType[] = ['TOILET_RENTAL', 'COLD_ROOM_RENTAL'];

function toBusinessResponse(row: BusinessRow): BusinessResponse {
  return {
    id: row.id,
    name: row.name,
    description: row.description,
    address: row.address,
    phoneNumber: row.phone_number,
    businessType: row.business_type,
    ownerId: row.owner_id,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

// GET /api/v1/businesses - Public discovery
businessRoutes.get('/', async (c) => {
  const result = await c.env.DB.prepare(
    'SELECT * FROM businesses ORDER BY id DESC'
  ).all<BusinessRow>();

  const businesses = (result.results || []).map(toBusinessResponse);
  return c.json(businesses, 200);
});

// GET /api/v1/businesses/my - Scoped to authenticated owner
businessRoutes.get('/my', requireAuth, async (c) => {
  const currentUser = c.get('user');

  const result = await c.env.DB.prepare(
    'SELECT * FROM businesses WHERE owner_id = ? ORDER BY id DESC'
  )
    .bind(currentUser.id)
    .all<BusinessRow>();

  const businesses = (result.results || []).map(toBusinessResponse);
  return c.json(businesses, 200);
});

// GET /api/v1/businesses/:id - Public discovery by ID
businessRoutes.get('/:id', async (c) => {
  const paramId = c.req.param('id') || '';
  const id = parseInt(paramId, 10);
  if (isNaN(id)) {
    throw new ResourceNotFoundError('Business not found with id: ' + paramId);
  }

  const business = await c.env.DB.prepare('SELECT * FROM businesses WHERE id = ?')
    .bind(id)
    .first<BusinessRow>();

  if (!business) {
    throw new ResourceNotFoundError(`Business not found with id: ${id}`);
  }

  return c.json(toBusinessResponse(business), 200);
});

// POST /api/v1/businesses - Create a new business (JWT required)
businessRoutes.post('/', requireAuth, async (c) => {
  const currentUser = c.get('user');
  let body: any;
  try {
    body = await c.req.json();
  } catch {
    throw new ValidationError({ body: 'Malformed JSON request body' }, 'Malformed JSON request body');
  }

  const { name, description, address, phoneNumber, businessType } = body || {};
  const fieldErrors: Record<string, string> = {};

  if (!name || typeof name !== 'string' || !name.trim()) {
    fieldErrors.name = 'Business name is required';
  }
  if (!address || typeof address !== 'string' || !address.trim()) {
    fieldErrors.address = 'Address is required';
  }
  if (!phoneNumber || typeof phoneNumber !== 'string' || !phoneNumber.trim()) {
    fieldErrors.phoneNumber = 'Phone number is required';
  }
  if (!businessType || !VALID_BUSINESS_TYPES.includes(businessType)) {
    fieldErrors.businessType = 'Business type must be TOILET_RENTAL or COLD_ROOM_RENTAL';
  }

  if (Object.keys(fieldErrors).length > 0) {
    throw new ValidationError(fieldErrors);
  }

  const now = new Date().toISOString();

  const insertResult = await c.env.DB.prepare(
    `INSERT INTO businesses (name, description, address, phone_number, business_type, owner_id, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
  )
    .bind(
      name.trim(),
      description?.trim() || null,
      address.trim(),
      phoneNumber.trim(),
      businessType,
      currentUser.id,
      now,
      now
    )
    .run();

  const insertedId = insertResult.meta.last_row_id;
  const created = await c.env.DB.prepare('SELECT * FROM businesses WHERE id = ?')
    .bind(insertedId)
    .first<BusinessRow>();

  if (!created) {
    throw new Error('Failed to retrieve newly created business');
  }

  return c.json(toBusinessResponse(created), 201);
});

// PUT /api/v1/businesses/:id - Update business (JWT + Owner check)
businessRoutes.put('/:id', requireAuth, async (c) => {
  const currentUser = c.get('user');
  const paramId = c.req.param('id') || '';
  const id = parseInt(paramId, 10);
  if (isNaN(id)) {
    throw new ResourceNotFoundError('Business not found with id: ' + paramId);
  }

  const existing = await c.env.DB.prepare('SELECT * FROM businesses WHERE id = ?')
    .bind(id)
    .first<BusinessRow>();

  if (!existing) {
    throw new ResourceNotFoundError(`Business not found with id: ${id}`);
  }

  if (existing.owner_id !== currentUser.id) {
    throw new UnauthorizedError('You do not have permission to access this business');
  }

  let body: any;
  try {
    body = await c.req.json();
  } catch {
    throw new ValidationError({ body: 'Malformed JSON request body' }, 'Malformed JSON request body');
  }

  const { name, description, address, phoneNumber, businessType } = body || {};
  const fieldErrors: Record<string, string> = {};

  if (!name || typeof name !== 'string' || !name.trim()) {
    fieldErrors.name = 'Business name is required';
  }
  if (!address || typeof address !== 'string' || !address.trim()) {
    fieldErrors.address = 'Address is required';
  }
  if (!phoneNumber || typeof phoneNumber !== 'string' || !phoneNumber.trim()) {
    fieldErrors.phoneNumber = 'Phone number is required';
  }
  if (!businessType || !VALID_BUSINESS_TYPES.includes(businessType)) {
    fieldErrors.businessType = 'Business type must be TOILET_RENTAL or COLD_ROOM_RENTAL';
  }

  if (Object.keys(fieldErrors).length > 0) {
    throw new ValidationError(fieldErrors);
  }

  const now = new Date().toISOString();

  await c.env.DB.prepare(
    `UPDATE businesses
     SET name = ?, description = ?, address = ?, phone_number = ?, business_type = ?, updated_at = ?
     WHERE id = ?`
  )
    .bind(
      name.trim(),
      description?.trim() || null,
      address.trim(),
      phoneNumber.trim(),
      businessType,
      now,
      id
    )
    .run();

  const updated = await c.env.DB.prepare('SELECT * FROM businesses WHERE id = ?')
    .bind(id)
    .first<BusinessRow>();

  return c.json(toBusinessResponse(updated!), 200);
});

// DELETE /api/v1/businesses/:id - Delete business (JWT + Owner check)
businessRoutes.delete('/:id', requireAuth, async (c) => {
  const currentUser = c.get('user');
  const paramId = c.req.param('id') || '';
  const id = parseInt(paramId, 10);
  if (isNaN(id)) {
    throw new ResourceNotFoundError('Business not found with id: ' + paramId);
  }

  const existing = await c.env.DB.prepare('SELECT * FROM businesses WHERE id = ?')
    .bind(id)
    .first<BusinessRow>();

  if (!existing) {
    throw new ResourceNotFoundError(`Business not found with id: ${id}`);
  }

  if (existing.owner_id !== currentUser.id) {
    throw new UnauthorizedError('You do not have permission to access this business');
  }

  await c.env.DB.prepare('DELETE FROM businesses WHERE id = ?').bind(id).run();

  return new Response(null, { status: 204 });
});
