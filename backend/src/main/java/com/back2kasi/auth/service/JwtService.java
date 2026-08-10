package com.back2kasi.auth.service;

import com.back2kasi.user.entity.User;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.function.Function;

/**
 * Service responsible for all JWT operations: generation, parsing, and validation.
 *
 * <p>A JWT has three parts separated by dots: {@code header.payload.signature}</p>
 * <ul>
 *   <li><strong>Header</strong>  — algorithm used to sign ({@code HS256}).</li>
 *   <li><strong>Payload</strong> — the claims (data inside the token): who the user is,
 *       their role, when the token was issued, when it expires.</li>
 *   <li><strong>Signature</strong> — HMAC of header + payload using our secret key.
 *       Tampering with the payload invalidates the signature.</li>
 * </ul>
 *
 * <p>The secret key is read from {@code app.jwt.secret} (application.properties),
 * which in turn reads from the {@code JWT_SECRET} environment variable.
 * It never appears in source code.</p>
 */
@Service
public class JwtService {

    /**
     * The HMAC-SHA256 secret key used to sign and verify tokens.
     * Must be at least 32 characters (256 bits) for HS256.
     */
    @Value("${app.jwt.secret}")
    private String jwtSecret;

    /**
     * How long a token lives, in milliseconds.
     * Default: 86 400 000 ms = 24 hours.
     */
    @Value("${app.jwt.expiration-ms}")
    private long jwtExpirationMs;

    // =========================================================
    // Public API
    // =========================================================

    /**
     * Generate a signed JWT for the given user.
     *
     * <p>Claims embedded in the token:</p>
     * <ul>
     *   <li>{@code sub}    — the user's email (standard JWT subject).</li>
     *   <li>{@code userId} — database ID; avoids a DB lookup on every request.</li>
     *   <li>{@code role}   — platform role ({@code USER} / {@code ADMIN}).</li>
     *   <li>{@code iat}    — issued-at timestamp.</li>
     *   <li>{@code exp}    — expiry timestamp.</li>
     * </ul>
     *
     * @param user the authenticated user
     * @return a compact, URL-safe JWT string
     */
    public String generateToken(User user) {
        Date now    = new Date();
        Date expiry = new Date(now.getTime() + jwtExpirationMs);

        return Jwts.builder()
                .subject(user.getEmail())                   // who the token belongs to
                .claim("userId", user.getId())              // avoid DB lookup later
                .claim("role",   user.getRole().name())     // for role-based access control
                .issuedAt(now)
                .expiration(expiry)
                .signWith(getSigningKey())                  // HS256, derived from jwtSecret
                .compact();
    }

    /**
     * Extract the email address (subject) from a token.
     *
     * @param token the raw JWT string
     * @return the email stored in the {@code sub} claim
     */
    public String extractEmail(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    /**
     * Return the token lifetime in <strong>seconds</strong> (for the response body).
     */
    public long getExpirationSeconds() {
        return jwtExpirationMs / 1000;
    }

    /**
     * Validate a token against a loaded {@link UserDetails}.
     *
     * <p>Two things are checked:</p>
     * <ol>
     *   <li>The subject (email) in the token matches the loaded user.</li>
     *   <li>The token has not expired.</li>
     * </ol>
     *
     * @param token       the JWT to validate
     * @param userDetails the user loaded from the database
     * @return {@code true} if the token is genuine and unexpired for this user
     */
    public boolean isTokenValid(String token, UserDetails userDetails) {
        final String email = extractEmail(token);
        return email.equals(userDetails.getUsername()) && !isTokenExpired(token);
    }

    // =========================================================
    // Private helpers
    // =========================================================

    private boolean isTokenExpired(String token) {
        return extractExpiration(token).before(new Date());
    }

    private Date extractExpiration(String token) {
        return extractClaim(token, Claims::getExpiration);
    }

    /**
     * Generic claim extractor — applies a function to the parsed claims map.
     *
     * @param token          the raw JWT string
     * @param claimsResolver a function that picks one value out of the claims
     * @param <T>            the type of the extracted claim
     * @return the extracted claim value
     */
    private <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }

    /**
     * Parse and verify the token's signature, then return all claims.
     *
     * <p>JJWT throws a runtime exception if the signature is invalid or
     * the token is expired — this naturally propagates as a 401.</p>
     */
    private Claims extractAllClaims(String token) {
        return Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    /**
     * Derive the HMAC-SHA256 {@link SecretKey} from the configured secret string.
     *
     * <p>The secret string is converted to raw bytes (UTF-8) and fed into
     * {@link Keys#hmacShaKeyFor(byte[])}, which validates the key length and
     * returns a correctly typed {@link SecretKey} for HS256.</p>
     */
    private SecretKey getSigningKey() {
        byte[] keyBytes = jwtSecret.getBytes(StandardCharsets.UTF_8);
        return Keys.hmacShaKeyFor(keyBytes);
    }
}
