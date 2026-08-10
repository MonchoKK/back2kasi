package com.back2kasi.auth.service;

import com.back2kasi.user.entity.Role;
import com.back2kasi.user.entity.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link JwtService}.
 *
 * <p>{@link JwtService} has {@code @Value} fields injected by Spring at runtime.
 * In a unit test there is no Spring context, so we use
 * {@link ReflectionTestUtils#setField} to inject the values directly — it is the
 * standard Spring testing utility for this purpose.</p>
 *
 * <p>We create a real {@link JwtService} instance (not a mock) because we want
 * to exercise the actual JWT generation and parsing logic.</p>
 */
class JwtServiceTest {

    private JwtService jwtService;

    /** A representative user used across all tests. */
    private User testUser;

    @BeforeEach
    void setUp() {
        jwtService = new JwtService();

        // Inject @Value fields that Spring would normally populate from application.properties.
        // The secret must be >= 32 characters (256 bits) for HS256.
        ReflectionTestUtils.setField(jwtService, "jwtSecret",
                "back2kasi-test-secret-key-that-is-long-enough-for-hs256");
        ReflectionTestUtils.setField(jwtService, "jwtExpirationMs", 86_400_000L);

        testUser = User.builder()
                .id(1L)
                .firstName("Kabelo")
                .lastName("Kekana")
                .email("kabelo@back2kasi.co.za")
                .password("hashed_password")
                .phoneNumber("+27712345678")
                .role(Role.USER)
                .build();
    }

    // =========================================================
    // Token generation
    // =========================================================

    /**
     * A freshly generated token must be a non-empty JWT string
     * (three Base64url segments separated by dots).
     */
    @Test
    void generateToken_returnsWellFormedJwt() {
        String token = jwtService.generateToken(testUser);

        assertThat(token).isNotNull().isNotBlank();
        // A JWT always has exactly two dots: header.payload.signature
        assertThat(token.chars().filter(ch -> ch == '.').count()).isEqualTo(2);
    }

    // =========================================================
    // Claim extraction
    // =========================================================

    /**
     * The email embedded in the token's {@code sub} claim must match
     * the email of the user the token was generated for.
     */
    @Test
    void extractEmail_returnsEmailFromSubjectClaim() {
        String token = jwtService.generateToken(testUser);

        String extracted = jwtService.extractEmail(token);

        assertThat(extracted).isEqualTo("kabelo@back2kasi.co.za");
    }

    // =========================================================
    // Token validation
    // =========================================================

    /**
     * A token generated for a user must be valid when checked against
     * the same user's {@code UserDetails}.
     */
    @Test
    void isTokenValid_returnsTrue_forFreshTokenAndMatchingUser() {
        String token = jwtService.generateToken(testUser);

        assertThat(jwtService.isTokenValid(token, testUser)).isTrue();
    }

    /**
     * A token generated for one user must NOT be valid when checked against
     * a different user — even if the signature itself is intact.
     *
     * <p>This prevents one user from using another's token.</p>
     */
    @Test
    void isTokenValid_returnsFalse_whenUserEmailDoesNotMatchSubject() {
        String token = jwtService.generateToken(testUser);

        User differentUser = User.builder()
                .id(2L)
                .email("different@back2kasi.co.za")
                .password("hashed")
                .role(Role.USER)
                .build();

        assertThat(jwtService.isTokenValid(token, differentUser)).isFalse();
    }

    // =========================================================
    // Expiration helper
    // =========================================================

    /**
     * {@code getExpirationSeconds()} must return the expiration in seconds,
     * not milliseconds. 86 400 000 ms → 86 400 s.
     */
    @Test
    void getExpirationSeconds_convertsMsToSeconds() {
        assertThat(jwtService.getExpirationSeconds()).isEqualTo(86_400L);
    }
}
