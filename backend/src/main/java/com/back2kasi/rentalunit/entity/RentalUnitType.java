package com.back2kasi.rentalunit.entity;

/**
 * The sub-type of a rental unit within a business category.
 *
 * <p>Stored as a {@code STRING} column so values remain human-readable in the
 * database and are resilient to enum reordering. New unit types can be added
 * here without breaking existing rows.</p>
 *
 * <p>Toilet rental sub-types:</p>
 * <ul>
 *   <li>{@link #STANDARD_TOILET} — basic portable toilet unit</li>
 *   <li>{@link #VIP_TOILET} — premium toilet unit with additional amenities</li>
 *   <li>{@link #CHEMICAL_TOILET} — self-contained chemical sanitation unit</li>
 * </ul>
 *
 * <p>Cold room rental sub-types:</p>
 * <ul>
 *   <li>{@link #STANDARD_COLD_ROOM} — fixed-location refrigerated room</li>
 *   <li>{@link #MOBILE_COLD_ROOM} — trailer-mounted cold room for events</li>
 * </ul>
 */
public enum RentalUnitType {

    /** Basic portable toilet unit. */
    STANDARD_TOILET,

    /** Premium portable toilet with additional amenities (e.g. running water, mirror). */
    VIP_TOILET,

    /** Self-contained chemical sanitation unit — no water connection required. */
    CHEMICAL_TOILET,

    /** Fixed-location refrigerated room for food or beverage storage. */
    STANDARD_COLD_ROOM,

    /** Trailer-mounted cold room, transportable to events or sites. */
    MOBILE_COLD_ROOM
}
