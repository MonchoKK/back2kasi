package com.back2kasi.rentalunit.dto;

import com.back2kasi.rentalunit.entity.RentalUnitStatus;
import com.back2kasi.rentalunit.entity.RentalUnitType;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

/**
 * Inbound DTO for updating an existing rental unit.
 *
 * <p>Kept separate from {@link CreateRentalUnitRequest} so the create and update
 * contracts can evolve independently. Key differences from the create request:</p>
 * <ul>
 *   <li>{@code businessId} is <strong>omitted</strong> — units cannot be moved
 *       between businesses after creation.</li>
 *   <li>{@code status} is <strong>included</strong> — the owner can manually
 *       set a unit to {@code UNDER_MAINTENANCE} or back to {@code AVAILABLE}.</li>
 * </ul>
 */
public record UpdateRentalUnitRequest(

        /** Updated display label for the unit. */
        @NotBlank(message = "Unit name is required")
        String name,

        /** Updated description or marketing copy. Nullable. */
        String description,

        /** Updated daily price in ZAR. Must be at least R 0.01. */
        @NotNull(message = "Price per day is required")
        @DecimalMin(value = "0.01", message = "Price per day must be at least 0.01")
        BigDecimal pricePerDay,

        /** Updated maximum occupancy or capacity. Must be at least 1. */
        @NotNull(message = "Capacity is required")
        @Min(value = 1, message = "Capacity must be at least 1")
        Integer capacity,

        /** Updated sub-type. */
        @NotNull(message = "Rental unit type is required")
        RentalUnitType rentalUnitType,

        /** Updated operational status. The owner can mark a unit as under maintenance. */
        @NotNull(message = "Status is required")
        RentalUnitStatus status
) {}
