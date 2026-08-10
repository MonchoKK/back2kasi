package com.back2kasi.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;

/**
 * Payload received when a user attempts to log in.
 *
 * <p>Intentionally minimal — only the credentials needed to authenticate.
 * Role is never accepted from the client; it is read from the database.</p>
 *
 * <p>Bean Validation annotations here mean Spring rejects malformed requests
 * at the controller boundary before the service layer is ever invoked.</p>
 */
@Getter
public class LoginRequest {

    @NotBlank(message = "Email is required")
    @Email(message = "Email must be a valid email address")
    private String email;

    /**
     * Plain-text password as typed by the user.
     * It is compared against the BCrypt hash stored in the database —
     * it is never logged, stored, or transmitted in plain text.
     */
    @NotBlank(message = "Password is required")
    private String password;
}
