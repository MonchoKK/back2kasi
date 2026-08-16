package com.back2kasi.booking.dto;

import com.back2kasi.booking.entity.Booking;
import com.back2kasi.booking.entity.BookingStatus;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Outbound DTO representing a booking returned to the client.
 *
 * <p>The full {@link Booking} entity is never exposed directly. This record
 * defines the stable, public API shape. Key design decisions:</p>
 * <ul>
 *   <li>Only {@code rentalUnitId} and {@code customerId} are included — not the
 *       full related entities — to avoid over-fetching and to keep the response
 *       payload small.</li>
 *   <li>{@code totalPrice} reflects the price locked in at booking creation time,
 *       not the unit's current {@code pricePerDay}.</li>
 *   <li>The static factory method {@link #from(Booking)} is the single canonical
 *       mapping point — any schema change only needs updating here.</li>
 * </ul>
 *
 * @param id           the booking's primary key
 * @param rentalUnitId the primary key of the booked rental unit
 * @param customerId   the primary key of the customer who made the booking
 * @param startDate    the inclusive start date of the rental period
 * @param endDate      the inclusive end date of the rental period
 * @param totalPrice   the total price locked in at creation time
 * @param status       the current lifecycle status of the booking
 * @param notes        optional customer note
 * @param createdAt    when the booking record was first created
 * @param updatedAt    when the booking record was last modified
 */
public record BookingResponse(
        Long id,
        Long rentalUnitId,
        Long customerId,
        LocalDate startDate,
        LocalDate endDate,
        BigDecimal totalPrice,
        BookingStatus status,
        String notes,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {

    /**
     * Map a {@link Booking} entity to a {@link BookingResponse} DTO.
     *
     * @param booking the entity to map; must not be {@code null}
     * @return a fully populated response DTO
     */
    public static BookingResponse from(Booking booking) {
        return new BookingResponse(
                booking.getId(),
                booking.getRentalUnit().getId(),
                booking.getCustomer().getId(),
                booking.getStartDate(),
                booking.getEndDate(),
                booking.getTotalPrice(),
                booking.getStatus(),
                booking.getNotes(),
                booking.getCreatedAt(),
                booking.getUpdatedAt()
        );
    }
}
