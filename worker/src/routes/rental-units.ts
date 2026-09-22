import { Hono } from 'hono';
import {
  Env,
  AuthUser,
  RentalUnitResponse,
  RentalUnitRow,
  RentalUnitType,
  RentalUnitStatus,
  BusinessRow,
} from '../types';
import { requireAuth } from '../middleware/auth';
import { ResourceNotFoundError, UnauthorizedError, ValidationError } from '../lib/errors';

export const rentalUnitRoutes = new Hono<{
  Bindings: Env;
  Variables: { user: AuthUser };
}>();

const VALID_UNIT_TYPES: RentalUnitType[] = [
  'STANDARD_TOILET',
  'VIP_TOILET',
  'CHEMICAL_TOILET',
  'STANDARD_COLD_ROOM',
  'MOBILE_COLD_ROOM',
];

const VALID_UNIT_STATUSES: RentalUnitStatus[] = [
  'AVAILABLE',
  'RENTED',
  'UNDER_MAINTENANCE',
];

function toRentalUnitResponse(row: RentalUnitRow): RentalUnitResponse {
  return {
    id: row.id,
    name: row.name,
    description: row.description,
    pricePerDay: Number(row.price_per_day),
    capacity: row.capacity,
    rentalUnitType: row.rental_unit_type,
    status: row.status,
    businessId: row.business_id,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

// GET /api/v1/rental-units - Public browse (filter by businessId or return all AVAILABLE)
rentalUnitRoutes.get('/', async (c) => {
  const businessIdParam = c.req.query('businessId');

  if (businessIdParam !== undefined && businessIdParam !== null && businessIdParam !== '') {
    const businessId = parseInt(businessIdParam, 10);
    if (isNaN(businessId)) {
      return c.json([], 200);
    }
    const result = await c.env.DB.prepare(
      'SELECT * FROM rental_units WHERE business_id = ? ORDER BY id DESC'
    )
      .bind(businessId)
      .all<RentalUnitRow>();

    return c.json((result.results || []).map(toRentalUnitResponse), 200);
  }

  // Public browse: return all AVAILABLE units across platform
  const result = await c.env.DB.prepare(
    "SELECT * FROM rental_units WHERE status = 'AVAILABLE' ORDER BY id DESC"
  ).all<RentalUnitRow>();

  return c.json((result.results || []).map(toRentalUnitResponse), 200);
});

// GET /api/v1/rental-units/:id - Public details by ID
rentalUnitRoutes.get('/:id', async (c) => {
  const paramId = c.req.param('id') || '';
  const id = parseInt(paramId, 10);
  if (isNaN(id)) {
    throw new ResourceNotFoundError('Rental unit not found with id: ' + paramId);
  }

  const unit = await c.env.DB.prepare('SELECT * FROM rental_units WHERE id = ?')
    .bind(id)
    .first<RentalUnitRow>();

  if (!unit) {
    throw new ResourceNotFoundError(`Rental unit not found with id: ${id}`);
  }

  return c.json(toRentalUnitResponse(unit), 200);
});

// POST /api/v1/rental-units - Create a rental unit under a business (JWT + Owner check)
rentalUnitRoutes.post('/', requireAuth, async (c) => {
  const currentUser = c.get('user');
  let body: any;
  try {
    body = await c.req.json();
  } catch {
    throw new ValidationError({ body: 'Malformed JSON request body' }, 'Malformed JSON request body');
  }

  const { businessId, name, description, pricePerDay, capacity, rentalUnitType } = body || {};
  const fieldErrors: Record<string, string> = {};

  if (businessId === undefined || businessId === null || isNaN(Number(businessId))) {
    fieldErrors.businessId = 'Business ID is required';
  }
  if (!name || typeof name !== 'string' || !name.trim()) {
    fieldErrors.name = 'Unit name is required';
  }
  if (pricePerDay === undefined || pricePerDay === null || isNaN(Number(pricePerDay)) || Number(pricePerDay) < 0.01) {
    fieldErrors.pricePerDay = 'Price per day must be at least 0.01';
  }
  if (capacity === undefined || capacity === null || !Number.isInteger(Number(capacity)) || Number(capacity) < 1) {
    fieldErrors.capacity = 'Capacity must be at least 1';
  }
  if (!rentalUnitType || !VALID_UNIT_TYPES.includes(rentalUnitType)) {
    fieldErrors.rentalUnitType = 'Invalid rental unit type';
  }

  if (Object.keys(fieldErrors).length > 0) {
    throw new ValidationError(fieldErrors);
  }

  const numBusinessId = Number(businessId);

  // Check if business exists
  const business = await c.env.DB.prepare('SELECT * FROM businesses WHERE id = ?')
    .bind(numBusinessId)
    .first<BusinessRow>();

  if (!business) {
    throw new ResourceNotFoundError(`Business not found with id: ${numBusinessId}`);
  }

  if (business.owner_id !== currentUser.id) {
    throw new UnauthorizedError('You do not have permission to add units to this business');
  }

  const now = new Date().toISOString();

  const insertResult = await c.env.DB.prepare(
    `INSERT INTO rental_units (name, description, price_per_day, capacity, rental_unit_type, status, business_id, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, 'AVAILABLE', ?, ?, ?)`
  )
    .bind(
      name.trim(),
      description?.trim() || null,
      Number(pricePerDay),
      Number(capacity),
      rentalUnitType,
      numBusinessId,
      now,
      now
    )
    .run();

  const insertedId = insertResult.meta.last_row_id;
  const created = await c.env.DB.prepare('SELECT * FROM rental_units WHERE id = ?')
    .bind(insertedId)
    .first<RentalUnitRow>();

  return c.json(toRentalUnitResponse(created!), 201);
});

// PUT /api/v1/rental-units/:id - Update unit (JWT + Owner check)
rentalUnitRoutes.put('/:id', requireAuth, async (c) => {
  const currentUser = c.get('user');
  const paramId = c.req.param('id') || '';
  const id = parseInt(paramId, 10);
  if (isNaN(id)) {
    throw new ResourceNotFoundError('Rental unit not found with id: ' + paramId);
  }

  const unit = await c.env.DB.prepare('SELECT * FROM rental_units WHERE id = ?')
    .bind(id)
    .first<RentalUnitRow>();

  if (!unit) {
    throw new ResourceNotFoundError(`Rental unit not found with id: ${id}`);
  }

  // Check ownership via business
  const business = await c.env.DB.prepare('SELECT * FROM businesses WHERE id = ?')
    .bind(unit.business_id)
    .first<BusinessRow>();

  if (!business || business.owner_id !== currentUser.id) {
    throw new UnauthorizedError('You do not have permission to modify this rental unit');
  }

  let body: any;
  try {
    body = await c.req.json();
  } catch {
    throw new ValidationError({ body: 'Malformed JSON request body' }, 'Malformed JSON request body');
  }

  const { name, description, pricePerDay, capacity, rentalUnitType, status } = body || {};
  const fieldErrors: Record<string, string> = {};

  if (!name || typeof name !== 'string' || !name.trim()) {
    fieldErrors.name = 'Unit name is required';
  }
  if (pricePerDay === undefined || pricePerDay === null || isNaN(Number(pricePerDay)) || Number(pricePerDay) < 0.01) {
    fieldErrors.pricePerDay = 'Price per day must be at least 0.01';
  }
  if (capacity === undefined || capacity === null || !Number.isInteger(Number(capacity)) || Number(capacity) < 1) {
    fieldErrors.capacity = 'Capacity must be at least 1';
  }
  if (!rentalUnitType || !VALID_UNIT_TYPES.includes(rentalUnitType)) {
    fieldErrors.rentalUnitType = 'Invalid rental unit type';
  }
  if (!status || !VALID_UNIT_STATUSES.includes(status)) {
    fieldErrors.status = 'Invalid unit status';
  }

  if (Object.keys(fieldErrors).length > 0) {
    throw new ValidationError(fieldErrors);
  }

  const now = new Date().toISOString();

  await c.env.DB.prepare(
    `UPDATE rental_units
     SET name = ?, description = ?, price_per_day = ?, capacity = ?, rental_unit_type = ?, status = ?, updated_at = ?
     WHERE id = ?`
  )
    .bind(
      name.trim(),
      description?.trim() || null,
      Number(pricePerDay),
      Number(capacity),
      rentalUnitType,
      status,
      now,
      id
    )
    .run();

  const updated = await c.env.DB.prepare('SELECT * FROM rental_units WHERE id = ?')
    .bind(id)
    .first<RentalUnitRow>();

  return c.json(toRentalUnitResponse(updated!), 200);
});

// DELETE /api/v1/rental-units/:id - Delete unit (JWT + Owner check)
rentalUnitRoutes.delete('/:id', requireAuth, async (c) => {
  const currentUser = c.get('user');
  const paramId = c.req.param('id') || '';
  const id = parseInt(paramId, 10);
  if (isNaN(id)) {
    throw new ResourceNotFoundError('Rental unit not found with id: ' + paramId);
  }

  const unit = await c.env.DB.prepare('SELECT * FROM rental_units WHERE id = ?')
    .bind(id)
    .first<RentalUnitRow>();

  if (!unit) {
    throw new ResourceNotFoundError(`Rental unit not found with id: ${id}`);
  }

  const business = await c.env.DB.prepare('SELECT * FROM businesses WHERE id = ?')
    .bind(unit.business_id)
    .first<BusinessRow>();

  if (!business || business.owner_id !== currentUser.id) {
    throw new UnauthorizedError('You do not have permission to modify this rental unit');
  }

  await c.env.DB.prepare('DELETE FROM rental_units WHERE id = ?').bind(id).run();

  return new Response(null, { status: 204 });
});
