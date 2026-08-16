package com.back2kasi.booking.entity;

/**
 * Lifecycle states of a {@link Booking}.
 *
 * <p>Status transitions:</p>
 * <pre>
 *   PENDING ──────────────────→ CONFIRMED ──→ COMPLETED
 *      │                              │
 *      └──→ CANCELLED                └──→ CANCELLED
 * </pre>
 *
 * <p>Only the business owner may move a booking to {@code CONFIRMED} or
 * {@code COMPLETED}. Either party (customer or owner) may cancel a booking
 * that has not yet been completed.</p>
 *
 * <p>Side effects on the parent {@link com.back2kasi.rentalunit.entity.RentalUnit}:</p>
 * <ul>
 *   <li>{@code CONFIRMED} → sets the unit's status to
 *       {@link com.back2kasi.rentalunit.entity.RentalUnitStatus#RENTED}.</li>
 *   <li>{@code COMPLETED} or {@code CANCELLED} → reverts the unit's status to
 *       {@link com.back2kasi.rentalunit.entity.RentalUnitStatus#AVAILABLE}.</li>
 * </ul>
 */
public enum BookingStatus {

    /** Booking has been submitted by the customer; awaiting owner confirmation. */
    PENDING,

    /** Owner has confirmed the booking; the rental unit is now {@code RENTED}. */
    CONFIRMED,

    /** Booking has ended successfully; the rental unit reverts to {@code AVAILABLE}. */
    COMPLETED,

    /** Booking was cancelled by either party; the rental unit reverts to {@code AVAILABLE}. */
    CANCELLED
}
