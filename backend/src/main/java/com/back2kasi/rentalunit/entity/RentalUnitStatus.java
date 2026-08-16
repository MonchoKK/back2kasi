package com.back2kasi.rentalunit.entity;

/**
 * The current operational status of a rental unit.
 *
 * <p>Stored as a {@code STRING} column so values are human-readable in the
 * database. The status field allows the platform to track a unit's availability
 * without requiring a booking query on every listing request.</p>
 *
 * <p>Status transitions:</p>
 * <pre>
 *   AVAILABLE ──────────────→ RENTED (when a booking is confirmed)
 *      ↑                          │
 *      │                          ↓
 *   UNDER_MAINTENANCE ←────── AVAILABLE (when booking ends)
 * </pre>
 *
 * <p>In Sprint 4 the status is managed manually by the business owner.
 * Sprint 5 (Booking) will automate transitions.</p>
 */
public enum RentalUnitStatus {

    /** The unit is ready to accept new bookings. */
    AVAILABLE,

    /** The unit is currently rented out. */
    RENTED,

    /** The unit is taken offline for cleaning, repair, or inspection. */
    UNDER_MAINTENANCE
}
