package com.back2kasi.user.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;

/**
 * Payload received when a new user registers on the platform.
 *
 * <p>This DTO is the public API contract for registration. It is separate from
 * the {@code User} entity by design: the API shape and the database schema should
 * be able to evolve independently without breaking each other.</p>
 *
 * <p>Bean Validation annotations are applied here so that invalid input is
 * rejected at the controller boundary — before the data ever reaches the
 * service or repository layer.</p>
 */
@Getter
public class RegisterRequest {

    @NotBlank(message = "First name is required")
    private String firstName;

    @NotBlank(message = "Last name is required")
    private String lastName;

    /**
     * Must be a well-formed email address and serve as the unique login identity.
     */
    @NotBlank(message = "Email is required")
    @Email(message = "Email must be a valid email address")
    private String email;

    /**
     * Plain-text password supplied by the user.
     * It will be hashed in the service layer before being stored.
     * It is never persisted in plain text.
     */
    @NotBlank(message = "Password is required")
    @Size(min = 8, message = "Password must be at least 8 characters")
    private String password;

    @NotBlank(message = "Phone number is required")
    private String phoneNumber;
}
