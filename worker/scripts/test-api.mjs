// End-to-end integration test for Back2Kasi Cloudflare Worker API
const BASE_URL = 'http://127.0.0.1:8787';

async function testApi() {
  console.log('🚀 Starting Back2Kasi Cloudflare Worker API Test Suite...');
  let passed = 0;
  let failed = 0;

  function assert(condition, message) {
    if (condition) {
      console.log(`  ✅ PASS: ${message}`);
      passed++;
    } else {
      console.error(`  ❌ FAIL: ${message}`);
      failed++;
    }
  }

  // 1. Health check
  console.log('\n--- 1. Health Check ---');
  const healthRes = await fetch(`${BASE_URL}/`);
  const healthJson = await healthRes.json();
  assert(healthRes.status === 200, 'GET / returns 200 OK');
  assert(healthJson.status === 'UP', 'Health check status is UP');

  // 2. Auth - Validation error on invalid phone
  console.log('\n--- 2. Auth Validation ---');
  const badPhoneRes = await fetch(`${BASE_URL}/api/users/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      firstName: 'Test',
      lastName: 'Owner',
      email: 'owner@test.com',
      password: 'password123',
      phoneNumber: '0712345678', // Invalid (missing +27)
    }),
  });
  const badPhoneJson = await badPhoneRes.json();
  assert(badPhoneRes.status === 400, 'Invalid phone number returns 400 Bad Request');
  assert(
    badPhoneJson.fieldErrors && badPhoneJson.fieldErrors.phoneNumber !== undefined,
    'Field error indicates invalid phone format'
  );

  // 3. Auth - Register Owner and Customer
  console.log('\n--- 3. User Registration ---');
  const regOwnerRes = await fetch(`${BASE_URL}/api/users/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      firstName: 'Kabelo',
      lastName: 'Owner',
      email: 'owner@kasi.co.za',
      password: 'password123',
      phoneNumber: '+27821234567',
    }),
  });
  const regOwnerText = await regOwnerRes.text();
  assert(regOwnerRes.status === 201, 'Owner registered successfully (201 Created)');
  assert(regOwnerText.includes('User registered successfully'), 'Registration response message correct');

  const regCustRes = await fetch(`${BASE_URL}/api/users/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      firstName: 'Lerato',
      lastName: 'Customer',
      email: 'customer@kasi.co.za',
      password: 'password123',
      phoneNumber: '+27839876543',
    }),
  });
  assert(regCustRes.status === 201, 'Customer registered successfully (201 Created)');

  // 4. Auth - Duplicate email prevention
  console.log('\n--- 4. Duplicate Email Check ---');
  const dupRes = await fetch(`${BASE_URL}/api/users/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      firstName: 'Another',
      lastName: 'Person',
      email: 'owner@kasi.co.za',
      password: 'password123',
      phoneNumber: '+27821234567',
    }),
  });
  const dupJson = await dupRes.json();
  assert(dupRes.status === 409, 'Duplicate email registration returns 409 Conflict');
  assert(dupJson.error === 'Conflict', 'Error response is Conflict');

  // 5. Auth - Login
  console.log('\n--- 5. User Login & JWT ---');
  const badLoginRes = await fetch(`${BASE_URL}/api/users/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: 'owner@kasi.co.za',
      password: 'wrongpassword',
    }),
  });
  assert(badLoginRes.status === 401, 'Wrong password returns 401 Unauthorized');

  const ownerLoginRes = await fetch(`${BASE_URL}/api/users/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: 'owner@kasi.co.za',
      password: 'password123',
    }),
  });
  const ownerAuth = await ownerLoginRes.json();
  assert(ownerLoginRes.status === 200, 'Owner login returns 200 OK');
  assert(ownerAuth.token && ownerAuth.tokenType === 'Bearer', 'JWT Bearer token received');
  const ownerToken = ownerAuth.token;

  const custLoginRes = await fetch(`${BASE_URL}/api/users/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: 'customer@kasi.co.za',
      password: 'password123',
    }),
  });
  const custAuth = await custLoginRes.json();
  assert(custLoginRes.status === 200, 'Customer login returns 200 OK');
  const custToken = custAuth.token;

  // 6. Business Management
  console.log('\n--- 6. Business Management ---');
  const createBizRes = await fetch(`${BASE_URL}/api/v1/businesses`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${ownerToken}`,
    },
    body: JSON.stringify({
      name: 'Kasi Clean Sanitation',
      description: 'Premium event toilets and cold rooms in Soweto',
      address: '124 Vilakazi Street, Orlando West, Soweto',
      phoneNumber: '+27821234567',
      businessType: 'TOILET_RENTAL',
    }),
  });
  const bizJson = await createBizRes.json();
  assert(createBizRes.status === 201, 'Business created successfully (201 Created)');
  assert(bizJson.id !== undefined && bizJson.name === 'Kasi Clean Sanitation', 'Business shape valid');
  const businessId = bizJson.id;

  // Public discovery of businesses
  const allBizRes = await fetch(`${BASE_URL}/api/v1/businesses`);
  const allBizJson = await allBizRes.json();
  assert(allBizRes.status === 200, 'Public GET /api/v1/businesses returns 200 OK');
  assert(allBizJson.length >= 1, 'Business appears in public listing');

  // Owner my businesses
  const myBizRes = await fetch(`${BASE_URL}/api/v1/businesses/my`, {
    headers: { Authorization: `Bearer ${ownerToken}` },
  });
  const myBizJson = await myBizRes.json();
  assert(myBizJson.some((b) => b.id === businessId), 'Owner sees created business in /my');

  const custMyBizRes = await fetch(`${BASE_URL}/api/v1/businesses/my`, {
    headers: { Authorization: `Bearer ${custToken}` },
  });
  const custMyBizJson = await custMyBizRes.json();
  assert(custMyBizJson.length === 0, 'Customer sees 0 businesses in /my');

  // 7. Rental Unit Management
  console.log('\n--- 7. Rental Unit Management ---');
  const createUnitRes = await fetch(`${BASE_URL}/api/v1/rental-units`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${ownerToken}`,
    },
    body: JSON.stringify({
      businessId: businessId,
      name: 'VIP Executive Mobile Toilet',
      description: 'Solar lighting, hand wash basin, mirror',
      pricePerDay: 450.0,
      capacity: 1,
      rentalUnitType: 'VIP_TOILET',
    }),
  });
  const unitJson = await createUnitRes.json();
  assert(createUnitRes.status === 201, 'Rental unit created successfully (201 Created)');
  assert(unitJson.status === 'AVAILABLE', 'Initial unit status is AVAILABLE');
  const unitId = unitJson.id;

  // Customer attempts to modify unit (should 403)
  const custModUnitRes = await fetch(`${BASE_URL}/api/v1/rental-units/${unitId}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${custToken}`,
    },
    body: JSON.stringify({
      name: 'Hacked Unit',
      pricePerDay: 10.0,
      capacity: 1,
      rentalUnitType: 'VIP_TOILET',
      status: 'AVAILABLE',
    }),
  });
  assert(custModUnitRes.status === 403, 'Non-owner update rejected with 403 Forbidden');

  // 8. Bookings Lifecycle
  console.log('\n--- 8. Bookings Lifecycle ---');
  const createBookingRes = await fetch(`${BASE_URL}/api/v1/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${custToken}`,
    },
    body: JSON.stringify({
      rentalUnitId: unitId,
      startDate: '2026-10-10',
      endDate: '2026-10-12', // 3 days inclusive: 10, 11, 12
      notes: 'Please deliver by 08:00 AM on Saturday',
    }),
  });
  const bookingJson = await createBookingRes.json();
  assert(createBookingRes.status === 201, 'Booking created (201 Created)');
  assert(bookingJson.status === 'PENDING', 'New booking starts in PENDING status');
  assert(bookingJson.totalPrice === 1350.0, 'Total price is correct (450 * 3 days = 1350)');
  const bookingId = bookingJson.id;

  // Customer checks my bookings
  const myBookingsRes = await fetch(`${BASE_URL}/api/v1/bookings/my`, {
    headers: { Authorization: `Bearer ${custToken}` },
  });
  const myBookingsJson = await myBookingsRes.json();
  assert(myBookingsJson.some((b) => b.id === bookingId), 'Customer sees booking in /bookings/my');

  // Owner confirms booking
  const confirmRes = await fetch(`${BASE_URL}/api/v1/bookings/${bookingId}/status`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${ownerToken}`,
    },
    body: JSON.stringify({ status: 'CONFIRMED' }),
  });
  const confirmedBooking = await confirmRes.json();
  assert(confirmRes.status === 200, 'Owner confirmed booking (200 OK)');
  assert(confirmedBooking.status === 'CONFIRMED', 'Booking status is now CONFIRMED');

  // Verify rental unit status transitioned to RENTED
  const rentedUnitRes = await fetch(`${BASE_URL}/api/v1/rental-units/${unitId}`);
  const rentedUnitJson = await rentedUnitRes.json();
  assert(rentedUnitJson.status === 'RENTED', 'Rental unit status automatically transitioned to RENTED');

  // Test Overlap Check: Try to book overlapping dates on confirmed booking
  console.log('\n--- 9. Booking Overlap Prevention ---');
  const overlapRes = await fetch(`${BASE_URL}/api/v1/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${custToken}`,
    },
    body: JSON.stringify({
      rentalUnitId: unitId,
      startDate: '2026-10-11', // Overlaps with 2026-10-10 to 2026-10-12
      endDate: '2026-10-15',
    }),
  });
  const overlapJson = await overlapRes.json();
  assert(overlapRes.status === 409, 'Overlapping booking blocked with 409 Conflict');
  assert(
    overlapJson.message.includes('already booked'),
    'Error message explains overlapping booking conflict'
  );

  // Complete booking
  console.log('\n--- 10. Complete Booking & Revert Status ---');
  const completeRes = await fetch(`${BASE_URL}/api/v1/bookings/${bookingId}/status`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${ownerToken}`,
    },
    body: JSON.stringify({ status: 'COMPLETED' }),
  });
  const completedBooking = await completeRes.json();
  assert(completeRes.status === 200, 'Owner completed booking (200 OK)');
  assert(completedBooking.status === 'COMPLETED', 'Booking status is now COMPLETED');

  // Verify rental unit status reverted to AVAILABLE
  const availUnitRes = await fetch(`${BASE_URL}/api/v1/rental-units/${unitId}`);
  const availUnitJson = await availUnitRes.json();
  assert(availUnitJson.status === 'AVAILABLE', 'Rental unit status reverted to AVAILABLE');

  console.log(`\n========================================`);
  console.log(`RESULTS: ${passed} passed, ${failed} failed.`);
  console.log(`========================================`);

  if (failed > 0) {
    process.exit(1);
  }
}

testApi().catch((err) => {
  console.error('Fatal test error:', err);
  process.exit(1);
});
