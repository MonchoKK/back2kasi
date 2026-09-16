# Sprint 19 — Production Hardening & Release Candidate

## Overview
Sprint 19 focused on stress-testing Back2Kasi against uncomfortable real-world scenarios: authentication failures, authorization boundary attempts, booking date edge cases, network drops, and critical booking concurrency race conditions (double-booking prevention).

---

## Key Engineering Decisions & Implementations

### 1. Concurrency & Race Condition Elimination (Pessimistic Locking)
* **Risk**: When two customers concurrently request the same rental unit (e.g. Toilet #1) for overlapping dates, simultaneous approvals could cause both bookings to be marked `CONFIRMED`.
* **Solution**:
  * Added `findByIdWithLock` in `RentalUnitRepository` using `@Lock(LockModeType.PESSIMISTIC_WRITE)` (`SELECT ... FOR UPDATE`).
  * In `BookingServiceImpl.updateBookingStatus`, transitioning to `CONFIRMED` acquires the pessimistic row lock before re-verifying that no overlapping `CONFIRMED` booking exists.
  * If a conflicting booking exists, the second request is immediately rejected with `409 Conflict`.
* **Automated Verification**: Multi-threaded race condition test using `ExecutorService` and `CountDownLatch` proves that exactly one approval succeeds and competing approvals fail with `409 Conflict`.

### 2. Authentication & Session Resilience
* Wrapped JWT extraction in `JwtAuthenticationFilter` with safe try-catch handling so expired/malformed tokens do not leak internal servlet errors.
* Sanitized credential validation in `GlobalExceptionHandler` and `UserService` returning `401 Unauthorized` with generic message.
* Converted low-level Flutter network errors (`SocketException`, `ClientException`, `TimeoutException`) into user-friendly messages.

### 3. Cross-Tenant Authorization Matrix
* Verified and enforced strict ownership boundaries:
  * Customers cannot create rental units under another user's business (403).
  * Owners cannot update or delete other owners' businesses or rental units (403).
  * Owners cannot view or modify bookings belonging to other owners' businesses (403).
  * Customers cannot view or cancel bookings belonging to other customers (403).
  * Customers cannot confirm or complete bookings (403).

### 4. Booking Validation & Lifecycle
* Rejected past dates using `@FutureOrPresent` on `CreateBookingRequest` and defensive validation in service layer (400 Bad Request).
* Rejected inverted date ranges (`endDate < startDate`) with 409 Conflict.
* Verified owner decline moves pending booking to `CANCELLED` and unit remains `AVAILABLE`.

### 5. Sensitive Data Sanitization
* Fallback exception handler in `GlobalExceptionHandler` returning generic 500 while logging full details internally.

---

## Test Verification
* **Backend**: 144 tests passing (`mvn test`), including all 16 tests in `ProductionHardeningIntegrationTest`.
* **Flutter Client**: 16 tests passing (`flutter test`).
