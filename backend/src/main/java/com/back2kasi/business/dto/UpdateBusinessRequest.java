package com.back2kasi.business.dto;

import com.back2kasi.business.entity.BusinessType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * Inbound DTO for updating an existing business.
 *
 * <p>A separate record from {@link CreateBusinessRequest} keeps the create and
 * update contracts independent. If future requirements differ (e.g. partial
 * updates, or additional fields only settable at creation), the two records
 * can diverge without coupling.</p>
 *
 * <p>All non-system fields are updatable in a single request.</p>
 */
public record UpdateBusinessRequest(

        /** The new display name for the business. Cannot be blank. */
        @NotBlank(message = "Business name is required")
        String name,

        /** Updated description or tagline. Nullable. */
        String description,

        /** The new physical address. Cannot be blank. */
        @NotBlank(message = "Address is required")
        String address,

        /** The new business contact phone number. Cannot be blank. */
        @NotBlank(message = "Phone number is required")
        String phoneNumber,

        /** The updated rental service type. Cannot be null. */
        @NotNull(message = "Business type is required")
        BusinessType businessType
) {}
