package com.back2kasi.auth.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * Response body returned after a successful login.
 *
 * <p>Flutter stores this token and attaches it to every subsequent request
 * as an HTTP header: {@code Authorization: Bearer <token>}</p>
 *
 * <p>Fields:</p>
 * <ul>
 *   <li>{@code token}     — the signed JWT string.</li>
 *   <li>{@code tokenType} — always {@code "Bearer"}; tells the client how to use the token.</li>
 *   <li>{@code expiresIn} — seconds until the token expires (86 400 = 24 hours).</li>
 * </ul>
 */
@Getter
@AllArgsConstructor
public class AuthResponse {

    private final String token;
    private final String tokenType;
    private final long expiresIn;
}
