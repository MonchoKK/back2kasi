package com.back2kasi.booking.dto;

import com.back2kasi.booking.entity.BookingStatus;
import jakarta.validation.constraints.NotNull;

/**
 * Inbound DTO for changing a booking's lifecycle status.
 *
 * <p>Which transitions are permitted depends on the caller's role, enforced in
 * {@code BookingServiceImpl}:</p>
 * <ul>
 *   <li><strong>Business owner</strong> — may set {@code CONFIRMED}, {@code COMPLETED},
 *       or {@code CANCELLED}.</li>
 *   <li><strong>Customer</strong> — may only set {@code CANCELLED} (and only while
 *       the booking is still {@code PENDING}).</li>
 * </ul>
 *
 * @param status the desired new status; must not be null
 */
public record UpdateBookingStatusRequest(

        @NotNull(message = "Status is required")
        BookingStatus status
) {
}
