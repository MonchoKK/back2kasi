// verify-concurrency-and-security.mjs
// Port of Spring Boot's ProductionHardeningIntegrationTest & concurrentBookingApproval_strictlyOneConfirmed

const BASE_URL = process.env.TEST_BASE_URL || 'http://127.0.0.1:8787';

async function runHardeningSuite() {
  console.log('🛡️  Starting Back2Kasi Concurrency & Security Hardening Test Suite...');
  console.log(`🌐 Testing against: ${BASE_URL}\n`);

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

  const timestamp = Date.now();

  // Helper: register & login
  async function registerAndLogin(email, password, firstName, lastName, phone) {
    await fetch(`${BASE_URL}/api/users/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        firstName,
        lastName,
        email,
        password,
        phoneNumber: phone,
      }),
    });

    const res = await fetch(`${BASE_URL}/api/users/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });
    const json = await res.json();
    return json.token;
  }

  // =========================================================================
  // SETUP ACTORS
  // =========================================================================
  console.log('--- Setting up Actors ---');
  const ownerAToken = await registerAndLogin(
    `ownerA_${timestamp}@kasi.co.za`,
    'OwnerPass123!',
    'OwnerA',
    'Smith',
    '+27711111111'
  );
  const ownerBToken = await registerAndLogin(
    `ownerB_${timestamp}@kasi.co.za`,
    'OwnerPass123!',
    'OwnerB',
    'Jones',
    '+27722222222'
  );
  const customerAToken = await registerAndLogin(
    `custA_${timestamp}@kasi.co.za`,
    'CustPass123!',
    'CustomerA',
    'Dlamini',
    '+27733333333'
  );
  const customerBToken = await registerAndLogin(
    `custB_${timestamp}@kasi.co.za`,
    'CustPass123!',
    'CustomerB',
    'Zulu',
    '+27744444444'
  );

  // Owner A creates Business A
  const bizARes = await fetch(`${BASE_URL}/api/v1/businesses`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${ownerAToken}`,
    },
    body: JSON.stringify({
      name: 'Owner A Sanitation',
      address: '10 Mandela St, Soweto',
      phoneNumber: '+27711111111',
      businessType: 'TOILET_RENTAL',
    }),
  });
  const bizA = await bizARes.json();
  const businessAId = bizA.id;

  // Owner B creates Business B
  const bizBRes = await fetch(`${BASE_URL}/api/v1/businesses`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${ownerBToken}`,
    },
    body: JSON.stringify({
      name: 'Owner B Cold Storage',
      address: '20 Vilakazi St, Orlando West',
      phoneNumber: '+27722222222',
      businessType: 'COLD_ROOM_RENTAL',
    }),
  });
  const bizB = await bizBRes.json();
  const businessBId = bizB.id;

  // Owner A creates Toilet #1
  const unitARes = await fetch(`${BASE_URL}/api/v1/rental-units`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${ownerAToken}`,
    },
    body: JSON.stringify({
      businessId: businessAId,
      name: 'VIP Portable Toilet #1',
      description: 'Flushable event toilet with sanitizer',
      pricePerDay: 450.0,
      capacity: 1,
      rentalUnitType: 'VIP_TOILET',
    }),
  });
  const unitA = await unitARes.json();
  const unitAId = unitA.id;

  assert(unitAId !== undefined, 'Setup complete: Owner A, Owner B, Toilet #1 created');

  // =========================================================================
  // 1. AUTHENTICATION SECURITY
  // =========================================================================
  console.log('\n--- 1. Authentication Security ---');
  // Wrong password
  const wrongPassRes = await fetch(`${BASE_URL}/api/users/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: `ownerA_${timestamp}@kasi.co.za`,
      password: 'CompletelyWrongPassword!',
    }),
  });
  assert(wrongPassRes.status === 401, 'Wrong password rejected with 401 Unauthorized');

  // Missing Authorization header
  const noAuthRes = await fetch(`${BASE_URL}/api/v1/businesses/my`);
  assert(noAuthRes.status === 401, 'Missing JWT on protected endpoint rejected with 401');

  // Tampered JWT
  const tamperedToken = ownerAToken.substring(0, ownerAToken.length - 8) + 'ABCDEF12';
  const tamperedRes = await fetch(`${BASE_URL}/api/v1/businesses/my`, {
    headers: { Authorization: `Bearer ${tamperedToken}` },
  });
  assert(tamperedRes.status === 401, 'Tampered JWT signature rejected with 401');

  // =========================================================================
  // 2. AUTHORIZATION & TENANT ISOLATION
  // =========================================================================
  console.log('\n--- 2. Authorization & Tenant Isolation ---');

  // Owner B attempts to update Owner A's business -> 403
  const hijackBizRes = await fetch(`${BASE_URL}/api/v1/businesses/${businessAId}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${ownerBToken}`,
    },
    body: JSON.stringify({
      name: 'Hijacked Business Name',
      address: '123 Fake St',
      phoneNumber: '+27722222222',
      businessType: 'TOILET_RENTAL',
    }),
  });
  assert(hijackBizRes.status === 403, 'Owner B cannot modify Owner A business (403 Forbidden)');

  // Owner B attempts to add rental unit to Owner A's business -> 403
  const hijackUnitRes = await fetch(`${BASE_URL}/api/v1/rental-units`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${ownerBToken}`,
    },
    body: JSON.stringify({
      businessId: businessAId,
      name: 'Trojan Horse Toilet',
      pricePerDay: 50.0,
      capacity: 1,
      rentalUnitType: 'STANDARD_TOILET',
    }),
  });
  assert(hijackUnitRes.status === 403, 'Owner B cannot add unit to Owner A business (403 Forbidden)');

  // Customer A attempts to delete Owner A's rental unit -> 403
  const custDelUnitRes = await fetch(`${BASE_URL}/api/v1/rental-units/${unitAId}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${customerAToken}` },
  });
  assert(custDelUnitRes.status === 403, 'Customer cannot delete rental unit (403 Forbidden)');

  // =========================================================================
  // 3. CONCURRENCY: SIMULTANEOUS BOOKING APPROVAL (The Race Condition Test)
  // =========================================================================
  console.log('\n--- 3. Concurrency & Double-Booking Protection ---');
  console.log('Scenario: Customer A and Customer B both submit PENDING requests for Toilet #1 on identical dates.');
  console.log('Owner A attempts to simultaneously approve BOTH bookings.');

  const startDate = '2026-11-15';
  const endDate = '2026-11-18'; // 4 days

  // Customer A submits booking
  const bookARes = await fetch(`${BASE_URL}/api/v1/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${customerAToken}`,
    },
    body: JSON.stringify({
      rentalUnitId: unitAId,
      startDate,
      endDate,
      notes: 'Customer A event booking',
    }),
  });
  assert(bookARes.status === 201, 'Customer A submitted PENDING booking (201 Created)');
  const bookA = await bookARes.json();
  const bookingAId = bookA.id;

  // Customer B submits booking for the EXACT SAME dates on Toilet #1
  const bookBRes = await fetch(`${BASE_URL}/api/v1/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${customerBToken}`,
    },
    body: JSON.stringify({
      rentalUnitId: unitAId,
      startDate,
      endDate,
      notes: 'Customer B competing event booking',
    }),
  });
  assert(bookBRes.status === 201, 'Customer B submitted PENDING booking for identical dates (201 Created)');
  const bookB = await bookBRes.json();
  const bookingBId = bookB.id;

  // Simultaneous approvals via Promise.all
  console.log('⚡ Firing simultaneous approval requests for Booking A and Booking B...');
  const [approvalARes, approvalBRes] = await Promise.all([
    fetch(`${BASE_URL}/api/v1/bookings/${bookingAId}/status`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${ownerAToken}`,
      },
      body: JSON.stringify({ status: 'CONFIRMED' }),
    }),
    fetch(`${BASE_URL}/api/v1/bookings/${bookingBId}/status`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${ownerAToken}`,
      },
      body: JSON.stringify({ status: 'CONFIRMED' }),
    }),
  ]);

  const statuses = [approvalARes.status, approvalBRes.status];
  console.log(`  Received status codes: [${statuses.join(', ')}]`);

  const winCount = statuses.filter((s) => s === 200).length;
  const conflictCount = statuses.filter((s) => s === 409).length;

  assert(winCount === 1, 'Exactly ONE approval succeeded with 200 OK');
  assert(conflictCount === 1, 'The competing approval was REJECTED with 409 Conflict');

  // Verify database state: exactly one is CONFIRMED, the other remains PENDING
  const checkARes = await fetch(`${BASE_URL}/api/v1/bookings/${bookingAId}`, {
    headers: { Authorization: `Bearer ${ownerAToken}` },
  });
  const finalA = await checkARes.json();

  const checkBRes = await fetch(`${BASE_URL}/api/v1/bookings/${bookingBId}`, {
    headers: { Authorization: `Bearer ${ownerAToken}` },
  });
  const finalB = await checkBRes.json();

  const aConfirmed = finalA.status === 'CONFIRMED';
  const bConfirmed = finalB.status === 'CONFIRMED';

  // XOR: exactly one is confirmed
  assert(
    (aConfirmed || bConfirmed) && !(aConfirmed && bConfirmed),
    `Database state: exactly one booking is CONFIRMED (A: ${finalA.status}, B: ${finalB.status})`
  );

  // Verify rental unit status transitioned to RENTED
  const finalUnitRes = await fetch(`${BASE_URL}/api/v1/rental-units/${unitAId}`);
  const finalUnit = await finalUnitRes.json();
  assert(finalUnit.status === 'RENTED', 'Rental unit status is now RENTED');

  // =========================================================================
  // 4. CASCADE DELETE INTEGRITY
  // =========================================================================
  console.log('\n--- 4. Relational Cascade Delete Integrity ---');
  // Deleting Business B should succeed
  const delBizBRes = await fetch(`${BASE_URL}/api/v1/businesses/${businessBId}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${ownerBToken}` },
  });
  assert(delBizBRes.status === 204, 'Owner B successfully deleted Business B (204 No Content)');

  // Business B no longer exists
  const getBizBRes = await fetch(`${BASE_URL}/api/v1/businesses/${businessBId}`);
  assert(getBizBRes.status === 404, 'Deleted business returns 404 Not Found');

  console.log(`\n========================================`);
  console.log(`RESULTS: ${passed} passed, ${failed} failed.`);
  console.log(`========================================`);

  if (failed > 0) {
    process.exit(1);
  }
}

runHardeningSuite().catch((err) => {
  console.error('Fatal test error:', err);
  process.exit(1);
});
