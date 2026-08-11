package com.back2kasi.business.dto;

import com.back2kasi.business.entity.BusinessType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * Inbound DTO for creating a new business.
 *
 * <p>Using a Java record keeps the DTO immutable and concise — Lombok is not
 * needed. Bean Validation annotations fire at the controller boundary before
 * any service logic runs.</p>
 *
 * <p>The {@code description} field is intentionally nullable — a short tagline
 * is optional for an MVP business listing.</p>
 */
public record CreateBusinessRequest(

        /** The public display name of the business. Cannot be blank. */
        @NotBlank(message = "Business name is required")
        String name,

        /** Optional short description or tagline. */
        String description,

        /** The physical address of the business. Cannot be blank. */
        @NotBlank(message = "Address is required")
        String address,

        /** Contact phone number for the business. Cannot be blank. */
        @NotBlank(message = "Phone number is required")
        String phoneNumber,

        /** The type of rental service offered. Cannot be null. */
        @NotNull(message = "Business type is required")
        BusinessType businessType
) {}
