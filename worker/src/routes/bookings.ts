import { Hono } from 'hono';
import {
  Env,
  AuthUser,
  BookingResponse,
  BookingContactResponse,
  BookingStatus,
  RentalUnitRow,
  BusinessRow,
} from '../types';
import { requireAuth } from '../middleware/auth';
import { ConflictError, ResourceNotFoundError, UnauthorizedError, ValidationError } from '../lib/errors';
import { toLocalSaPhone, toInternationalSaPhone } from '../lib/phone';

export const bookingRoutes = new Hono<{
  Bindings: Env;
  Variables: { user: AuthUser };
}>();

// Ensure all booking routes require authentication
bookingRoutes.use('*', requireAuth);

interface BookingDetailRow {
  id: number;
  rental_unit_id: number;
  rental_unit_name: string;
  business_name: string;
  business_owner_id: number;
  customer_id: number;
  start_date: string;
  end_date: string;
  total_price: number;
  status: BookingStatus;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

function toBookingResponse(row: BookingDetailRow): BookingResponse {
  return {
    id: row.id,
    rentalUnitId: row.rental_unit_id,
    rentalUnitName: row.rental_unit_name,
    businessName: row.business_name,
    customerId: row.customer_id,
    startDate: row.start_date,
    endDate: row.end_date,
    totalPrice: Number(row.total_price),
    status: row.status,
    notes: row.notes,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

const BOOKING_SELECT_QUERY = `
  SELECT 
    b.id,
    b.rental_unit_id,
    ru.name AS rental_unit_name,
    biz.name AS business_name,
    biz.owner_id AS business_owner_id,
    b.customer_id,
    b.start_date,
    b.end_date,
    b.total_price,
    b.status,
    b.notes,
    b.created_at,
    b.updated_at
  FROM bookings b
  JOIN rental_units ru ON b.rental_unit_id = ru.id
  JOIN businesses biz ON ru.business_id = biz.id
`;

// GET /api/v1/bookings/my - Bookings made by current customer
bookingRoutes.get('/my', async (c) => {
  const currentUser = c.get('user');

  const result = await c.env.DB.prepare(
    `${BOOKING_SELECT_QUERY} WHERE b.customer_id = ? ORDER BY b.id DESC`
  )
    .bind(currentUser.id)
    .all<BookingDetailRow>();

  return c.json((result.results || []).map(toBookingResponse), 200);
});

// GET /api/v1/bookings/owner - All bookings across businesses owned by current user
bookingRoutes.get('/owner', async (c) => {
  const currentUser = c.get('user');

  const result = await c.env.DB.prepare(
    `${BOOKING_SELECT_QUERY} WHERE biz.owner_id = ? ORDER BY b.id DESC`
  )
    .bind(currentUser.id)
    .all<BookingDetailRow>();

  return c.json((result.results || []).map(toBookingResponse), 200);
});

// GET /api/v1/bookings/unit/:unitId - Bookings for a specific unit (Owner only)
bookingRoutes.get('/unit/:unitId', async (c) => {
  const currentUser = c.get('user');
  const paramUnitId = c.req.param('unitId');
  const unitId = parseInt(paramUnitId, 10);
  if (isNaN(unitId)) {
    throw new ResourceNotFoundError('Rental unit not found with id: ' + paramUnitId);
  }

  const unit = await c.env.DB.prepare('SELECT * FROM rental_units WHERE id = ?')
    .bind(unitId)
    .first<RentalUnitRow>();

  if (!unit) {
    throw new ResourceNotFoundError(`Rental unit not found with id: ${unitId}`);
  }

  const business = await c.env.DB.prepare('SELECT * FROM businesses WHERE id = ?')
    .bind(unit.business_id)
    .first<BusinessRow>();

  if (!business || business.owner_id !== currentUser.id) {
    throw new UnauthorizedError('You do not have permission to view bookings for this rental unit');
  }

  const result = await c.env.DB.prepare(
    `${BOOKING_SELECT_QUERY} WHERE b.rental_unit_id = ? ORDER BY b.id DESC`
  )
    .bind(unitId)
    .all<BookingDetailRow>();

  return c.json((result.results || []).map(toBookingResponse), 200);
});

// GET /api/v1/bookings/:id - Single booking by ID (Customer or Unit Owner)
bookingRoutes.get('/:id', async (c) => {
  const currentUser = c.get('user');
  const paramId = c.req.param('id');
  const id = parseInt(paramId, 10);
  if (isNaN(id)) {
    throw new ResourceNotFoundError('Booking not found with id: ' + paramId);
  }

  const booking = await c.env.DB.prepare(
    `${BOOKING_SELECT_QUERY} WHERE b.id = ?`
  )
    .bind(id)
    .first<BookingDetailRow>();

  if (!booking) {
    throw new ResourceNotFoundError(`Booking not found with id: ${id}`);
  }

  const isCustomer = booking.customer_id === currentUser.id;
  const isOwner = booking.business_owner_id === currentUser.id;

  if (!isCustomer && !isOwner) {
    throw new UnauthorizedError('You do not have permission to view this booking');
  }

  return c.json(toBookingResponse(booking), 200);
});

interface BookingContactRow {
  booking_id: number;
  booking_status: string;
  rental_unit_id: number;
  unit_name: string;
  customer_id: number;
  start_date: string;
  end_date: string;
  total_price: number;
  business_id: number;
  business_name: string;
  business_phone: string;
  business_whatsapp: string | null;
  business_whatsapp_enabled: number;
  business_owner_id: number;
  customer_first_name: string;
  customer_last_name: string;
  customer_phone: string;
}

// GET /api/v1/bookings/:id/contact - Booking-gated direct contact (Accepted bookings only)
bookingRoutes.get('/:id/contact', async (c) => {
  const currentUser = c.get('user');
  const paramId = c.req.param('id');
  const id = parseInt(paramId, 10);
  if (isNaN(id)) {
    throw new ResourceNotFoundError('Booking not found with id: ' + paramId);
  }

  const row = await c.env.DB.prepare(
    `SELECT 
       b.id AS booking_id,
       b.status AS booking_status,
       b.rental_unit_id,
       b.customer_id,
       b.start_date,
       b.end_date,
       b.total_price,
       ru.name AS unit_name,
       biz.id AS business_id,
       biz.name AS business_name,
       biz.phone_number AS business_phone,
       biz.whatsapp_number AS business_whatsapp,
       biz.whatsapp_enabled AS business_whatsapp_enabled,
       biz.owner_id AS business_owner_id,
       u.first_name AS customer_first_name,
       u.last_name AS customer_last_name,
       u.phone_number AS customer_phone
     FROM bookings b
     JOIN rental_units ru ON b.rental_unit_id = ru.id
     JOIN businesses biz ON ru.business_id = biz.id
     JOIN users u ON b.customer_id = u.id
     WHERE b.id = ?`
  )
    .bind(id)
    .first<BookingContactRow>();

  if (!row) {
    throw new ResourceNotFoundError(`Booking not found with id: ${id}`);
  }

  // 1. Verify caller authorization: customer or business owner
  const isCustomer = row.customer_id === currentUser.id;
  const isOwner = row.business_owner_id === currentUser.id;

  if (!isCustomer && !isOwner) {
    throw new UnauthorizedError('You do not have permission to view contact details for this booking');
  }

  // 2. Strict booking-gate: Contact is ONLY permitted while status is CONFIRMED / ACCEPTED
  const isAccepted = row.booking_status === 'CONFIRMED' || row.booking_status === 'ACCEPTED';
  if (!isAccepted) {
    return c.json(
      {
        message: 'Contact details are only available for accepted bookings.',
        status: row.booking_status,
      },
      403
    );
  }

  // 3. Bidirectional contact payloads
  if (isCustomer) {
    // Customer requesting business contact details
    const hasWhatsapp = row.business_whatsapp_enabled === 1 && !!row.business_whatsapp;
    const localPhone = toLocalSaPhone(row.business_phone) || row.business_phone;
    const localWhatsapp = hasWhatsapp ? toLocalSaPhone(row.business_whatsapp) : null;
    const intlWhatsapp = hasWhatsapp ? toInternationalSaPhone(row.business_whatsapp) : null;
    const prefilled = `Hi! I have an accepted booking (#${row.booking_id}) with ${row.business_name} on Back2Kasi for ${row.unit_name} (${row.start_date} to ${row.end_date}). I'd like to coordinate details regarding my booking.`;

    const response: BookingContactResponse = {
      bookingId: row.booking_id,
      bookingStatus: row.booking_status,
      role: 'BUSINESS',
      contactName: row.business_name,
      phoneNumber: localPhone,
      whatsappNumber: localWhatsapp,
      whatsappInternationalNumber: intlWhatsapp,
      whatsappEnabled: hasWhatsapp,
      prefilledMessage: prefilled,
    };
    return c.json(response, 200);
  } else {
    // Business owner requesting customer contact details
    const customerFullName = `${row.customer_first_name} ${row.customer_last_name}`.trim();
    const localPhone = toLocalSaPhone(row.customer_phone) || row.customer_phone;
    const intlWhatsapp = toInternationalSaPhone(row.customer_phone);
    const prefilled = `Hi ${row.customer_first_name}! This is ${row.business_name} regarding your accepted Back2Kasi booking (#${row.booking_id}) for ${row.unit_name}. Reaching out to coordinate delivery and setup.`;

    const response: BookingContactResponse = {
      bookingId: row.booking_id,
      bookingStatus: row.booking_status,
      role: 'CUSTOMER',
      contactName: customerFullName,
      phoneNumber: localPhone,
      whatsappNumber: localPhone,
      whatsappInternationalNumber: intlWhatsapp,
      whatsappEnabled: true,
      prefilledMessage: prefilled,
    };
    return c.json(response, 200);
  }
});

// POST /api/v1/bookings - Create new booking
bookingRoutes.post('/', async (c) => {
  const currentUser = c.get('user');
  let body: any;
  try {
    body = await c.req.json();
  } catch {
    throw new ValidationError({ body: 'Malformed JSON request body' }, 'Malformed JSON request body');
  }

  const { rentalUnitId, startDate, endDate, notes } = body || {};
  const fieldErrors: Record<string, string> = {};

  if (!rentalUnitId || isNaN(Number(rentalUnitId))) {
    fieldErrors.rentalUnitId = 'Rental unit ID is required';
  }
  if (!startDate || typeof startDate !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(startDate)) {
    fieldErrors.startDate = 'Start date is required in YYYY-MM-DD format';
  }
  if (!endDate || typeof endDate !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(endDate)) {
    fieldErrors.endDate = 'End date is required in YYYY-MM-DD format';
  }

  if (Object.keys(fieldErrors).length > 0) {
    throw new ValidationError(fieldErrors);
  }

  const unitId = Number(rentalUnitId);
  const today = new Date().toISOString().substring(0, 10);

  if (startDate < today) {
    throw new ConflictError('Start date cannot be in the past');
  }
  if (startDate > endDate) {
    throw new ConflictError('Start date must not be after end date');
  }

  // Check unit exists
  const unit = await c.env.DB.prepare('SELECT * FROM rental_units WHERE id = ?')
    .bind(unitId)
    .first<RentalUnitRow>();

  if (!unit) {
    throw new ResourceNotFoundError(`Rental unit not found with id: ${unitId}`);
  }

  // Overlap check with CONFIRMED bookings
  const overlap = await c.env.DB.prepare(
    `SELECT id FROM bookings
     WHERE rental_unit_id = ?
       AND status = 'CONFIRMED'
       AND (start_date <= ? AND end_date >= ?)`
  )
    .bind(unitId, endDate, startDate)
    .first();

  if (overlap) {
    throw new ConflictError('The rental unit is already booked for the requested date range');
  }

  // Calculate days (inclusive)
  const startMs = new Date(startDate).getTime();
  const endMs = new Date(endDate).getTime();
  const days = Math.round((endMs - startMs) / (1000 * 60 * 60 * 24)) + 1;
  const totalPrice = days * Number(unit.price_per_day);
  const now = new Date().toISOString();

  const insertResult = await c.env.DB.prepare(
    `INSERT INTO bookings (rental_unit_id, customer_id, start_date, end_date, total_price, status, notes, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, 'PENDING', ?, ?, ?)`
  )
    .bind(unitId, currentUser.id, startDate, endDate, totalPrice, notes?.trim() || null, now, now)
    .run();

  const newBookingId = insertResult.meta.last_row_id;
  const created = await c.env.DB.prepare(
    `${BOOKING_SELECT_QUERY} WHERE b.id = ?`
  )
    .bind(newBookingId)
    .first<BookingDetailRow>();

  return c.json(toBookingResponse(created!), 201);
});

// PATCH /api/v1/bookings/:id/status - Lifecycle status transitions
bookingRoutes.patch('/:id/status', async (c) => {
  const currentUser = c.get('user');
  const paramId = c.req.param('id');
  const id = parseInt(paramId, 10);
  if (isNaN(id)) {
    throw new ResourceNotFoundError('Booking not found with id: ' + paramId);
  }

  let body: any;
  try {
    body = await c.req.json();
  } catch {
    throw new ValidationError({ body: 'Malformed JSON request body' }, 'Malformed JSON request body');
  }

  const { status: newStatus } = body || {};
  if (!newStatus || !['CONFIRMED', 'COMPLETED', 'CANCELLED'].includes(newStatus)) {
    throw new ValidationError({ status: 'Status must be CONFIRMED, COMPLETED, or CANCELLED' });
  }

  const booking = await c.env.DB.prepare(
    `${BOOKING_SELECT_QUERY} WHERE b.id = ?`
  )
    .bind(id)
    .first<BookingDetailRow>();

  if (!booking) {
    throw new ResourceNotFoundError(`Booking not found with id: ${id}`);
  }

  // Guard: terminal states
  if (booking.status === 'COMPLETED' || booking.status === 'CANCELLED') {
    throw new ConflictError(`Cannot change status of a ${booking.status} booking`);
  }

  const isOwner = booking.business_owner_id === currentUser.id;
  const isCustomer = booking.customer_id === currentUser.id;

  if (!isOwner && !isCustomer) {
    throw new UnauthorizedError('You do not have permission to update this booking');
  }

  const now = new Date().toISOString();

  if (newStatus === 'CONFIRMED') {
    if (!isOwner) {
      throw new UnauthorizedError('Only the business owner can confirm a booking');
    }

    // Atomic conditional update: only update if no overlapping CONFIRMED booking exists in the database.
    // This executes atomically within SQLite's exclusive write lock, eliminating concurrency race conditions.
    const updateResult = await c.env.DB.prepare(
      `UPDATE bookings
       SET status = 'CONFIRMED', updated_at = ?
       WHERE id = ?
         AND status = 'PENDING'
         AND NOT EXISTS (
           SELECT 1 FROM bookings b2
           WHERE b2.rental_unit_id = bookings.rental_unit_id
             AND b2.status = 'CONFIRMED'
             AND b2.id != bookings.id
             AND (b2.start_date <= bookings.end_date AND b2.end_date >= bookings.start_date)
         )`
    )
      .bind(now, id)
      .run();

    if (updateResult.meta.changes === 0) {
      throw new ConflictError(
        'Cannot confirm booking: The rental unit is already booked for the requested date range'
      );
    }

    // Exactly one winner marks the rental unit as RENTED
    await c.env.DB.prepare(
      "UPDATE rental_units SET status = 'RENTED', updated_at = ? WHERE id = ?"
    )
      .bind(now, booking.rental_unit_id)
      .run();
  } else if (newStatus === 'COMPLETED') {
    if (!isOwner) {
      throw new UnauthorizedError('Only the business owner can complete a booking');
    }
    if (booking.status !== 'CONFIRMED') {
      throw new ConflictError('Only a CONFIRMED booking can be marked COMPLETED');
    }

    // Update booking to COMPLETED and unit back to AVAILABLE
    await c.env.DB.batch([
      c.env.DB.prepare('UPDATE bookings SET status = ?, updated_at = ? WHERE id = ?')
        .bind('COMPLETED', now, id),
      c.env.DB.prepare("UPDATE rental_units SET status = 'AVAILABLE', updated_at = ? WHERE id = ?")
        .bind(now, booking.rental_unit_id),
    ]);
  } else if (newStatus === 'CANCELLED') {
    if (isCustomer && !isOwner && booking.status !== 'PENDING') {
      throw new ConflictError('Customers may only cancel a PENDING booking');
    }

    // If it was confirmed, revert unit to AVAILABLE
    const queries = [
      c.env.DB.prepare('UPDATE bookings SET status = ?, updated_at = ? WHERE id = ?')
        .bind('CANCELLED', now, id),
    ];

    if (booking.status === 'CONFIRMED') {
      queries.push(
        c.env.DB.prepare("UPDATE rental_units SET status = 'AVAILABLE', updated_at = ? WHERE id = ?")
          .bind(now, booking.rental_unit_id)
      );
    }

    await c.env.DB.batch(queries);
  }

  const updated = await c.env.DB.prepare(
    `${BOOKING_SELECT_QUERY} WHERE b.id = ?`
  )
    .bind(id)
    .first<BookingDetailRow>();

  return c.json(toBookingResponse(updated!), 200);
});
