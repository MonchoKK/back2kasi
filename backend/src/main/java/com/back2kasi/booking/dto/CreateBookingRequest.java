package com.back2kasi.booking.dto;

import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;

/**
 * Inbound DTO for creating a new booking.
 *
 * <p>Bean Validation annotations are enforced by {@code @Valid} in the controller.
 * Business-level rules (overlap check, date ordering, unit availability) are
 * validated in the service layer, not here.</p>
 *
 * @param rentalUnitId the primary key of the rental unit to book; must not be null
 * @param startDate    the inclusive start date; must be a future date
 * @param endDate      the inclusive end date; must be a future date
 * @param notes        optional note from the customer (e.g. special requirements)
 */
public record CreateBookingRequest(

        @NotNull(message = "Rental unit ID is required")
        Long rentalUnitId,

        @NotNull(message = "Start date is required")
        @Future(message = "Start date must be in the future")
        LocalDate startDate,

        @NotNull(message = "End date is required")
        @Future(message = "End date must be in the future")
        LocalDate endDate,

        String notes
) {
}
