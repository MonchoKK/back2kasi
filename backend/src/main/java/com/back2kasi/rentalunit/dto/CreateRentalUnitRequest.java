package com.back2kasi.rentalunit.dto;

import com.back2kasi.rentalunit.entity.RentalUnitType;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

/**
 * Inbound DTO for creating a new rental unit under an existing business.
 *
 * <p>{@code businessId} is included in the request body so a single endpoint
 * can accept units for any business the caller owns — rather than nesting the
 * URL as {@code /businesses/{id}/rental-units}, which is harder to extend
 * and inconsistent with the flat URL design used elsewhere in the API.</p>
 *
 * <p>{@code pricePerDay} uses {@link BigDecimal} to avoid the floating-point
 * rounding errors that accumulate in financial calculations with {@code double}.</p>
 */
public record CreateRentalUnitRequest(

        /** The ID of the business this unit will belong to. */
        @NotNull(message = "Business ID is required")
        Long businessId,

        /** Display label for the unit — e.g. "Unit A", "VIP Toilet 3". */
        @NotBlank(message = "Unit name is required")
        String name,

        /** Optional description visible to customers. */
        String description,

        /** Daily rental price in ZAR. Must be at least R 0.01. */
        @NotNull(message = "Price per day is required")
        @DecimalMin(value = "0.01", message = "Price per day must be at least 0.01")
        BigDecimal pricePerDay,

        /** Maximum occupancy or booking capacity. Must be at least 1. */
        @NotNull(message = "Capacity is required")
        @Min(value = 1, message = "Capacity must be at least 1")
        Integer capacity,

        /** The sub-type of rental unit. */
        @NotNull(message = "Rental unit type is required")
        RentalUnitType rentalUnitType
) {}
