import { Hono } from 'hono';
import {
  Env,
  AuthUser,
  BusinessResponse,
  BusinessRow,
  BusinessType,
  BusinessContactResponse,
} from '../types';
import { requireAuth } from '../middleware/auth';
import { ResourceNotFoundError, UnauthorizedError, ValidationError } from '../lib/errors';
import {
  toLocalSaPhone,
  toInternationalSaPhone,
  validateAndNormalizeSaLocalPhone,
} from '../lib/phone';

export const businessRoutes = new Hono<{
  Bindings: Env;
  Variables: { user: AuthUser };
}>();

const VALID_BUSINESS_CATEGORIES = [
  'BEAUTY',
  'FOOD',
  'AUTOMOTIVE',
  'RETAIL',
  'HOME_SERVICES',
  'EVENTS_RENTALS',
];

const VALID_BUSINESS_TYPES: string[] = [
  'TOILET_RENTAL',
  'COLD_ROOM_RENTAL',
  ...VALID_BUSINESS_CATEGORIES,
];

function toBusinessResponse(row: BusinessRow): BusinessResponse {
  const category = row.category || (
    row.business_type === 'TOILET_RENTAL' || row.business_type === 'COLD_ROOM_RENTAL'
      ? 'EVENTS_RENTALS'
      : row.business_type
  );

  return {
    id: row.id,
    name: row.name,
    description: row.description,
    address: row.address,
    phoneNumber: toLocalSaPhone(row.phone_number) || row.phone_number,
    businessType: row.business_type,
    category: category,
    isVerified: row.is_verified === 1,
    isSuspended: row.is_suspended === 1,
    ownerId: row.owner_id,
    whatsappNumber: toLocalSaPhone(row.whatsapp_number),
    whatsappEnabled: row.whatsapp_enabled === 1,
    whatsappMessage: row.whatsapp_message ?? null,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

// GET /api/v1/businesses - Public discovery (filters out suspended businesses)
businessRoutes.get('/', async (c) => {
  const categoryParam = c.req.query('category');
  let result;

  if (categoryParam && categoryParam !== 'ALL') {
    result = await c.env.DB.prepare(
      'SELECT * FROM businesses WHERE (category = ? OR business_type = ?) AND (is_suspended IS NULL OR is_suspended = 0) ORDER BY id DESC'
    )
      .bind(categoryParam, categoryParam)
      .all<BusinessRow>();
  } else {
    result = await c.env.DB.prepare(
      'SELECT * FROM businesses WHERE (is_suspended IS NULL OR is_suspended = 0) ORDER BY id DESC'
    ).all<BusinessRow>();
  }

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

// GET /api/v1/businesses/:id - Public discovery by ID (hidden if suspended)
businessRoutes.get('/:id', async (c) => {
  const paramId = c.req.param('id') || '';
  const id = parseInt(paramId, 10);
  if (isNaN(id)) {
    throw new ResourceNotFoundError('Business not found with id: ' + paramId);
  }

  const business = await c.env.DB.prepare('SELECT * FROM businesses WHERE id = ?')
    .bind(id)
    .first<BusinessRow>();

  if (!business || business.is_suspended === 1) {
    throw new ResourceNotFoundError(`Business not found with id: ${id}`);
  }

  return c.json(toBusinessResponse(business), 200);
});

// GET /api/v1/businesses/:id/contact-settings - Owner retrieves their contact settings
businessRoutes.get('/:id/contact-settings', requireAuth, async (c) => {
  const currentUser = c.get('user');
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

  if (business.owner_id !== currentUser.id) {
    throw new UnauthorizedError('You do not have permission to view contact settings for this business');
  }

  const contact: BusinessContactResponse = {
    businessId: business.id,
    businessName: business.name,
    phoneNumber: toLocalSaPhone(business.phone_number) || business.phone_number,
    whatsappNumber: toLocalSaPhone(business.whatsapp_number),
    whatsappEnabled: business.whatsapp_enabled === 1,
    whatsappMessage: business.whatsapp_message ?? null,
  };

  return c.json(contact, 200);
});

// PUT /api/v1/businesses/:id/contact-settings - Owner updates WhatsApp number & availability
businessRoutes.put('/:id/contact-settings', requireAuth, async (c) => {
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

  const { whatsappNumber, whatsappEnabled, whatsappMessage } = body || {};
  const fieldErrors: Record<string, string> = {};

  let normalizedWhatsappNumber: string | null = null;
  if (whatsappNumber !== undefined && whatsappNumber !== null && String(whatsappNumber).trim() !== '') {
    const { normalized, error } = validateAndNormalizeSaLocalPhone(String(whatsappNumber));
    if (error) {
      fieldErrors.whatsappNumber = error;
    } else {
      normalizedWhatsappNumber = normalized;
    }
  }

  if (whatsappEnabled !== undefined && typeof whatsappEnabled !== 'boolean') {
    fieldErrors.whatsappEnabled = 'whatsappEnabled must be a boolean';
  }

  if (Object.keys(fieldErrors).length > 0) {
    throw new ValidationError(fieldErrors);
  }

  const isEnabled = whatsappEnabled === true ? 1 : 0;
  const message = whatsappMessage !== undefined ? (whatsappMessage?.trim() || null) : (existing.whatsapp_message ?? null);
  const now = new Date().toISOString();

  await c.env.DB.prepare(
    `UPDATE businesses
     SET whatsapp_number = ?, whatsapp_enabled = ?, whatsapp_message = ?, updated_at = ?
     WHERE id = ?`
  )
    .bind(normalizedWhatsappNumber, isEnabled, message, now, id)
    .run();

  const updated = await c.env.DB.prepare('SELECT * FROM businesses WHERE id = ?')
    .bind(id)
    .first<BusinessRow>();

  const contact: BusinessContactResponse = {
    businessId: updated!.id,
    businessName: updated!.name,
    phoneNumber: toLocalSaPhone(updated!.phone_number) || updated!.phone_number,
    whatsappNumber: toLocalSaPhone(updated!.whatsapp_number),
    whatsappEnabled: updated!.whatsapp_enabled === 1,
    whatsappMessage: updated!.whatsapp_message ?? null,
  };

  return c.json(contact, 200);
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

  const {
    name,
    description,
    address,
    phoneNumber,
    businessType,
    category,
    whatsappNumber,
    whatsappEnabled,
    whatsappMessage,
  } = body || {};
  const fieldErrors: Record<string, string> = {};

  if (!name || typeof name !== 'string' || !name.trim()) {
    fieldErrors.name = 'Business name is required';
  }
  if (!address || typeof address !== 'string' || !address.trim()) {
    fieldErrors.address = 'Address is required';
  }
  let normalizedPhone: string = '';
  if (!phoneNumber || typeof phoneNumber !== 'string' || !phoneNumber.trim()) {
    fieldErrors.phoneNumber = 'Phone number is required';
  } else {
    const { normalized, error } = validateAndNormalizeSaLocalPhone(phoneNumber);
    if (error) {
      fieldErrors.phoneNumber = error;
    } else {
      normalizedPhone = normalized!;
    }
  }

  const resolvedCategory = (category || businessType || 'EVENTS_RENTALS').toString().trim();
  if (!VALID_BUSINESS_TYPES.includes(resolvedCategory)) {
    fieldErrors.category = `Invalid category. Must be one of: ${VALID_BUSINESS_CATEGORIES.join(', ')}`;
  }

  let normalizedWhatsappNumber: string | null = null;
  if (whatsappNumber !== undefined && whatsappNumber !== null && String(whatsappNumber).trim() !== '') {
    const { normalized, error } = validateAndNormalizeSaLocalPhone(String(whatsappNumber));
    if (error) {
      fieldErrors.whatsappNumber = error;
    } else {
      normalizedWhatsappNumber = normalized;
    }
  }

  if (whatsappEnabled !== undefined && typeof whatsappEnabled !== 'boolean') {
    fieldErrors.whatsappEnabled = 'whatsappEnabled must be a boolean';
  }

  if (Object.keys(fieldErrors).length > 0) {
    throw new ValidationError(fieldErrors);
  }

  const isEnabled = whatsappEnabled === true ? 1 : 0;
  const message = whatsappMessage?.trim() || null;
  const now = new Date().toISOString();

  const insertResult = await c.env.DB.prepare(
    `INSERT INTO businesses (name, description, address, phone_number, business_type, category, is_verified, owner_id, whatsapp_number, whatsapp_enabled, whatsapp_message, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, 0, ?, ?, ?, ?, ?, ?)`
  )
    .bind(
      name.trim(),
      description?.trim() || null,
      address.trim(),
      normalizedPhone,
      resolvedCategory,
      resolvedCategory,
      currentUser.id,
      normalizedWhatsappNumber,
      isEnabled,
      message,
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

  const {
    name,
    description,
    address,
    phoneNumber,
    businessType,
    category,
    whatsappNumber,
    whatsappEnabled,
    whatsappMessage,
  } = body || {};
  const fieldErrors: Record<string, string> = {};

  if (!name || typeof name !== 'string' || !name.trim()) {
    fieldErrors.name = 'Business name is required';
  }
  if (!address || typeof address !== 'string' || !address.trim()) {
    fieldErrors.address = 'Address is required';
  }
  let normalizedPhone = existing.phone_number;
  if (!phoneNumber || typeof phoneNumber !== 'string' || !phoneNumber.trim()) {
    fieldErrors.phoneNumber = 'Phone number is required';
  } else {
    const { normalized, error } = validateAndNormalizeSaLocalPhone(phoneNumber);
    if (error) {
      fieldErrors.phoneNumber = error;
    } else {
      normalizedPhone = normalized!;
    }
  }

  const resolvedCategory = (category || businessType || existing.category || existing.business_type || 'EVENTS_RENTALS').toString().trim();
  if (!VALID_BUSINESS_TYPES.includes(resolvedCategory)) {
    fieldErrors.category = `Invalid category. Must be one of: ${VALID_BUSINESS_CATEGORIES.join(', ')}`;
  }

  let normalizedWhatsappNumber = existing.whatsapp_number ?? null;
  if (whatsappNumber !== undefined) {
    if (whatsappNumber === null || String(whatsappNumber).trim() === '') {
      normalizedWhatsappNumber = null;
    } else {
      const { normalized, error } = validateAndNormalizeSaLocalPhone(String(whatsappNumber));
      if (error) {
        fieldErrors.whatsappNumber = error;
      } else {
        normalizedWhatsappNumber = normalized;
      }
    }
  }

  const isEnabled =
    whatsappEnabled !== undefined
      ? (whatsappEnabled === true ? 1 : 0)
      : (existing.whatsapp_enabled ?? 0);
  const message =
    whatsappMessage !== undefined
      ? (whatsappMessage?.trim() || null)
      : (existing.whatsapp_message ?? null);

  if (Object.keys(fieldErrors).length > 0) {
    throw new ValidationError(fieldErrors);
  }

  const now = new Date().toISOString();

  await c.env.DB.prepare(
    `UPDATE businesses
     SET name = ?, description = ?, address = ?, phone_number = ?, business_type = ?, category = ?, whatsapp_number = ?, whatsapp_enabled = ?, whatsapp_message = ?, updated_at = ?
     WHERE id = ?`
  )
    .bind(
      name.trim(),
      description?.trim() || null,
      address.trim(),
      normalizedPhone,
      resolvedCategory,
      resolvedCategory,
      normalizedWhatsappNumber,
      isEnabled,
      message,
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
