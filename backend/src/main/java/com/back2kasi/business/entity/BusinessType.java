package com.back2kasi.business.entity;

/**
 * The type of rental business operated on the Back2Kasi platform.
 *
 * <p>Stored as a {@code STRING} column in the database so that the values are
 * human-readable and resilient to enum reordering.</p>
 *
 * <p>Future rental categories (e.g. {@code EVENT_EQUIPMENT}) can be added here
 * without breaking existing rows.</p>
 */
public enum BusinessType {

    /** A business that rents out portable toilets and sanitation units. */
    TOILET_RENTAL,

    /** A business that rents out refrigerated cold rooms for food storage or events. */
    COLD_ROOM_RENTAL
}
