import { Hono } from 'hono';
import {
  Env,
  AuthUser,
  RentalUnitResponse,
  RentalUnitRow,
  RentalUnitImageResponse,
  RentalUnitImageRow,
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

const VALID_UNIT_TYPES: string[] = [
  'STANDARD_TOILET',
  'VIP_TOILET',
  'CHEMICAL_TOILET',
  'STANDARD_COLD_ROOM',
  'MOBILE_COLD_ROOM',
  'GENERAL_PRODUCT',
  'GENERAL_SERVICE',
];

const VALID_UNIT_STATUSES: RentalUnitStatus[] = [
  'AVAILABLE',
  'RENTED',
  'UNDER_MAINTENANCE',
];

function toImageResponse(row: RentalUnitImageRow, origin: string): RentalUnitImageResponse {
  const fullUrl = row.image_url.startsWith('http')
    ? row.image_url
    : `${origin}${row.image_url.startsWith('/') ? '' : '/'}${row.image_url}`;
  return {
    id: row.id,
    rentalUnitId: row.rental_unit_id,
    imageUrl: fullUrl,
    contentType: row.content_type,
    fileSize: row.file_size,
    isPrimary: row.is_primary === 1,
    displayOrder: row.display_order,
    createdAt: row.created_at,
  };
}

function toRentalUnitResponse(
  row: RentalUnitRow,
  images: RentalUnitImageRow[] = [],
  origin = ''
): RentalUnitResponse {
  const imageResponses = images.map((img) => toImageResponse(img, origin));
  const primary = imageResponses.find((img) => img.isPrimary);
  const primaryImageUrl = primary ? primary.imageUrl : imageResponses.length > 0 ? imageResponses[0].imageUrl : null;
  const isPriceOnRequest = row.is_price_on_request === 1;
  const priceVal = row.price !== undefined && row.price !== null ? Number(row.price) : Number(row.price_per_day);
  const itemType = (row.item_type as any) === 'PRODUCT' ? 'PRODUCT' : 'SERVICE';

  return {
    id: row.id,
    name: row.name,
    description: row.description,
    pricePerDay: priceVal,
    price: priceVal,
    isPriceOnRequest,
    priceUnit: row.price_unit ?? (itemType === 'PRODUCT' ? null : 'per day'),
    itemType,
    capacity: row.capacity ?? 1,
    rentalUnitType: row.rental_unit_type,
    status: row.status,
    businessId: row.business_id,
    images: imageResponses,
    primaryImageUrl,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

// GET /api/v1/rental-units - Public browse (filter by businessId or return all AVAILABLE)
rentalUnitRoutes.get('/', async (c) => {
  const origin = new URL(c.req.url).origin;
  const businessIdParam = c.req.query('businessId');

  let units: RentalUnitRow[] = [];
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

    units = result.results || [];
  } else {
    // Public browse: return all AVAILABLE units across platform
    const result = await c.env.DB.prepare(
      "SELECT * FROM rental_units WHERE status = 'AVAILABLE' ORDER BY id DESC"
    ).all<RentalUnitRow>();
    units = result.results || [];
  }

  if (units.length === 0) {
    return c.json([], 200);
  }

  // Fetch images for all returned units in a single query
  const unitIds = units.map((u) => u.id);
  const placeholders = unitIds.map(() => '?').join(',');
  const imagesResult = await c.env.DB.prepare(
    `SELECT * FROM rental_unit_images WHERE rental_unit_id IN (${placeholders}) ORDER BY is_primary DESC, display_order ASC, id ASC`
  )
    .bind(...unitIds)
    .all<RentalUnitImageRow>();

  const imagesByUnit = new Map<number, RentalUnitImageRow[]>();
  for (const img of imagesResult.results || []) {
    if (!imagesByUnit.has(img.rental_unit_id)) {
      imagesByUnit.set(img.rental_unit_id, []);
    }
    imagesByUnit.get(img.rental_unit_id)!.push(img);
  }

  const responses = units.map((u) =>
    toRentalUnitResponse(u, imagesByUnit.get(u.id) || [], origin)
  );

  return c.json(responses, 200);
});

// GET /api/v1/rental-units/:id - Public details by ID
rentalUnitRoutes.get('/:id', async (c) => {
  const origin = new URL(c.req.url).origin;
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

  const imagesResult = await c.env.DB.prepare(
    'SELECT * FROM rental_unit_images WHERE rental_unit_id = ? ORDER BY is_primary DESC, display_order ASC, id ASC'
  )
    .bind(id)
    .all<RentalUnitImageRow>();

  return c.json(toRentalUnitResponse(unit, imagesResult.results || [], origin), 200);
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

  const {
    businessId,
    name,
    description,
    price,
    pricePerDay,
    isPriceOnRequest,
    priceUnit,
    itemType,
    capacity,
    rentalUnitType,
  } = body || {};
  const fieldErrors: Record<string, string> = {};

  if (businessId === undefined || businessId === null || isNaN(Number(businessId))) {
    fieldErrors.businessId = 'Business ID is required';
  }
  if (!name || typeof name !== 'string' || !name.trim()) {
    fieldErrors.name = 'Item name is required';
  }

  const effectiveIsPriceOnRequest = isPriceOnRequest === true || isPriceOnRequest === 1;
  const effectivePrice = price !== undefined ? Number(price) : (pricePerDay !== undefined ? Number(pricePerDay) : 0);

  if (!effectiveIsPriceOnRequest && (isNaN(effectivePrice) || effectivePrice < 0.01)) {
    fieldErrors.price = 'Price must be at least 0.01 unless Price on Request is enabled';
  }

  const effectiveItemType = itemType === 'PRODUCT' ? 'PRODUCT' : 'SERVICE';
  const effectiveCapacity = capacity !== undefined && !isNaN(Number(capacity)) ? Number(capacity) : 1;
  const effectiveUnitType = rentalUnitType || (effectiveItemType === 'PRODUCT' ? 'GENERAL_PRODUCT' : 'GENERAL_SERVICE');
  const effectivePriceUnit = priceUnit !== undefined ? (priceUnit?.trim() || null) : (effectiveItemType === 'PRODUCT' ? null : 'per day');

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
    `INSERT INTO rental_units (name, description, price_per_day, price, is_price_on_request, price_unit, item_type, capacity, rental_unit_type, status, business_id, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'AVAILABLE', ?, ?, ?)`
  )
    .bind(
      name.trim(),
      description?.trim() || null,
      effectivePrice,
      effectivePrice,
      effectiveIsPriceOnRequest ? 1 : 0,
      effectivePriceUnit,
      effectiveItemType,
      effectiveCapacity,
      effectiveUnitType,
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

  const {
    name,
    description,
    price,
    pricePerDay,
    isPriceOnRequest,
    priceUnit,
    itemType,
    capacity,
    rentalUnitType,
    status,
  } = body || {};
  const fieldErrors: Record<string, string> = {};

  if (!name || typeof name !== 'string' || !name.trim()) {
    fieldErrors.name = 'Item name is required';
  }

  const effectiveIsPriceOnRequest =
    isPriceOnRequest !== undefined
      ? (isPriceOnRequest === true || isPriceOnRequest === 1)
      : (unit.is_price_on_request === 1);

  const effectivePrice =
    price !== undefined
      ? Number(price)
      : (pricePerDay !== undefined ? Number(pricePerDay) : Number(unit.price ?? unit.price_per_day));

  if (!effectiveIsPriceOnRequest && (isNaN(effectivePrice) || effectivePrice < 0.01)) {
    fieldErrors.price = 'Price must be at least 0.01 unless Price on Request is enabled';
  }

  const effectiveItemType = itemType !== undefined ? (itemType === 'PRODUCT' ? 'PRODUCT' : 'SERVICE') : (unit.item_type || 'SERVICE');
  const effectiveCapacity = capacity !== undefined && !isNaN(Number(capacity)) ? Number(capacity) : (unit.capacity ?? 1);
  const effectiveUnitType = rentalUnitType || unit.rental_unit_type || (effectiveItemType === 'PRODUCT' ? 'GENERAL_PRODUCT' : 'GENERAL_SERVICE');
  const effectivePriceUnit = priceUnit !== undefined ? (priceUnit?.trim() || null) : (unit.price_unit ?? null);
  const effectiveStatus = status || unit.status || 'AVAILABLE';

  if (!VALID_UNIT_STATUSES.includes(effectiveStatus as RentalUnitStatus)) {
    fieldErrors.status = 'Invalid unit status';
  }

  if (Object.keys(fieldErrors).length > 0) {
    throw new ValidationError(fieldErrors);
  }

  const now = new Date().toISOString();

  await c.env.DB.prepare(
    `UPDATE rental_units
     SET name = ?, description = ?, price_per_day = ?, price = ?, is_price_on_request = ?, price_unit = ?, item_type = ?, capacity = ?, rental_unit_type = ?, status = ?, updated_at = ?
     WHERE id = ?`
  )
    .bind(
      name.trim(),
      description?.trim() || null,
      effectivePrice,
      effectivePrice,
      effectiveIsPriceOnRequest ? 1 : 0,
      effectivePriceUnit,
      effectiveItemType,
      effectiveCapacity,
      effectiveUnitType,
      effectiveStatus,
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

// GET /api/v1/rental-units/:id/images - List all images for a rental unit
rentalUnitRoutes.get('/:id/images', async (c) => {
  const origin = new URL(c.req.url).origin;
  const paramId = c.req.param('id') || '';
  const id = parseInt(paramId, 10);
  if (isNaN(id)) {
    throw new ResourceNotFoundError('Rental unit not found with id: ' + paramId);
  }

  const unit = await c.env.DB.prepare('SELECT id FROM rental_units WHERE id = ?')
    .bind(id)
    .first<{ id: number }>();
  if (!unit) {
    throw new ResourceNotFoundError(`Rental unit not found with id: ${id}`);
  }

  const result = await c.env.DB.prepare(
    'SELECT * FROM rental_unit_images WHERE rental_unit_id = ? ORDER BY is_primary DESC, display_order ASC, id ASC'
  )
    .bind(id)
    .all<RentalUnitImageRow>();

  return c.json((result.results || []).map((row) => toImageResponse(row, origin)), 200);
});

// POST /api/v1/rental-units/:id/images - Upload image (JWT + Owner check, max 5MB, JPEG/PNG/WebP, max 5 images)
rentalUnitRoutes.post('/:id/images', requireAuth, async (c) => {
  const currentUser = c.get('user');
  const origin = new URL(c.req.url).origin;
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
    throw new UnauthorizedError('You do not have permission to manage photos for this rental unit');
  }

  // Count existing images
  const countRow = await c.env.DB.prepare(
    'SELECT COUNT(*) as count FROM rental_unit_images WHERE rental_unit_id = ?'
  )
    .bind(id)
    .first<{ count: number }>();
  const currentCount = countRow?.count ?? 0;

  if (currentCount >= 5) {
    throw new ValidationError({ image: 'Maximum of 5 images allowed per rental unit' });
  }

  // Parse multipart form
  let formData: FormData;
  try {
    formData = await c.req.formData();
  } catch {
    throw new ValidationError({ image: 'Invalid multipart/form-data request' });
  }

  const file = (formData.get('image') || formData.get('file')) as unknown;
  if (!file || !(file instanceof File)) {
    throw new ValidationError({ image: 'Image file is required' });
  }

  // Validate MIME type
  const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
  const mimeType = file.type.toLowerCase();
  if (!allowedTypes.includes(mimeType)) {
    throw new ValidationError({
      image: 'Only JPEG, PNG and WebP images are allowed. Received: ' + file.type,
    });
  }

  // Validate size: 5MB
  const MAX_SIZE = 5 * 1024 * 1024;
  if (file.size > MAX_SIZE) {
    throw new ValidationError({
      image: 'Image exceeds maximum 5 MB limit (size: ' + (file.size / (1024 * 1024)).toFixed(2) + ' MB)',
    });
  }

  // Extension
  let ext = 'jpg';
  if (mimeType === 'image/png') ext = 'png';
  else if (mimeType === 'image/webp') ext = 'webp';

  const r2Key = `rental-units/${id}/${crypto.randomUUID()}.${ext}`;
  const arrayBuffer = await file.arrayBuffer();

  // Store in R2 bucket
  await c.env.IMAGES_BUCKET.put(r2Key, arrayBuffer, {
    httpMetadata: {
      contentType: mimeType,
    },
  });

  const relativeUrl = `/api/v1/images/${r2Key}`;
  const isPrimaryRequested = formData.get('isPrimary') === 'true';
  const shouldBePrimary = currentCount === 0 || isPrimaryRequested;

  if (shouldBePrimary && currentCount > 0) {
    await c.env.DB.prepare('UPDATE rental_unit_images SET is_primary = 0 WHERE rental_unit_id = ?')
      .bind(id)
      .run();
  }

  const now = new Date().toISOString();
  const insertResult = await c.env.DB.prepare(
    `INSERT INTO rental_unit_images (rental_unit_id, r2_key, image_url, content_type, file_size, is_primary, display_order, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
  )
    .bind(
      id,
      r2Key,
      relativeUrl,
      mimeType,
      file.size,
      shouldBePrimary ? 1 : 0,
      currentCount,
      now,
      now
    )
    .run();

  const insertedId = insertResult.meta.last_row_id;
  const createdImage = await c.env.DB.prepare('SELECT * FROM rental_unit_images WHERE id = ?')
    .bind(insertedId)
    .first<RentalUnitImageRow>();

  return c.json(toImageResponse(createdImage!, origin), 201);
});

// PATCH /api/v1/rental-units/:id/images/:imageId/primary - Select primary image (JWT + Owner check)
rentalUnitRoutes.patch('/:id/images/:imageId/primary', requireAuth, async (c) => {
  const currentUser = c.get('user');
  const origin = new URL(c.req.url).origin;
  const paramId = c.req.param('id') || '';
  const paramImageId = c.req.param('imageId') || '';
  const id = parseInt(paramId, 10);
  const imageId = parseInt(paramImageId, 10);

  if (isNaN(id) || isNaN(imageId)) {
    throw new ResourceNotFoundError('Invalid rental unit ID or image ID');
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

  const targetImage = await c.env.DB.prepare(
    'SELECT * FROM rental_unit_images WHERE id = ? AND rental_unit_id = ?'
  )
    .bind(imageId, id)
    .first<RentalUnitImageRow>();

  if (!targetImage) {
    throw new ResourceNotFoundError(`Image not found with id: ${imageId} for unit: ${id}`);
  }

  const now = new Date().toISOString();
  await c.env.DB.batch([
    c.env.DB.prepare('UPDATE rental_unit_images SET is_primary = 0, updated_at = ? WHERE rental_unit_id = ?').bind(now, id),
    c.env.DB.prepare('UPDATE rental_unit_images SET is_primary = 1, updated_at = ? WHERE id = ?').bind(now, imageId),
  ]);

  const updatedImage = await c.env.DB.prepare('SELECT * FROM rental_unit_images WHERE id = ?')
    .bind(imageId)
    .first<RentalUnitImageRow>();

  return c.json(toImageResponse(updatedImage!, origin), 200);
});

// DELETE /api/v1/rental-units/:id/images/:imageId - Delete image (JWT + Owner check, removes from R2 and D1)
rentalUnitRoutes.delete('/:id/images/:imageId', requireAuth, async (c) => {
  const currentUser = c.get('user');
  const paramId = c.req.param('id') || '';
  const paramImageId = c.req.param('imageId') || '';
  const id = parseInt(paramId, 10);
  const imageId = parseInt(paramImageId, 10);

  if (isNaN(id) || isNaN(imageId)) {
    throw new ResourceNotFoundError('Invalid rental unit ID or image ID');
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

  const targetImage = await c.env.DB.prepare(
    'SELECT * FROM rental_unit_images WHERE id = ? AND rental_unit_id = ?'
  )
    .bind(imageId, id)
    .first<RentalUnitImageRow>();

  if (!targetImage) {
    throw new ResourceNotFoundError(`Image not found with id: ${imageId} for unit: ${id}`);
  }

  // Delete from R2
  try {
    await c.env.IMAGES_BUCKET.delete(targetImage.r2_key);
  } catch (err) {
    console.error('Failed to delete object from R2:', err);
  }

  // Delete from D1
  await c.env.DB.prepare('DELETE FROM rental_unit_images WHERE id = ?').bind(imageId).run();

  // If deleted image was primary, promote next remaining image to primary
  if (targetImage.is_primary === 1) {
    const nextImage = await c.env.DB.prepare(
      'SELECT id FROM rental_unit_images WHERE rental_unit_id = ? ORDER BY display_order ASC, id ASC LIMIT 1'
    )
      .bind(id)
      .first<{ id: number }>();

    if (nextImage) {
      const now = new Date().toISOString();
      await c.env.DB.prepare('UPDATE rental_unit_images SET is_primary = 1, updated_at = ? WHERE id = ?')
        .bind(now, nextImage.id)
        .run();
    }
  }

  return new Response(null, { status: 204 });
});
