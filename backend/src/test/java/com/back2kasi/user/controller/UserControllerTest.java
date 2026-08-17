package com.back2kasi.user.controller;

import com.back2kasi.auth.dto.AuthResponse;
import com.back2kasi.auth.filter.JwtAuthenticationFilter;
import com.back2kasi.auth.service.JwtService;
import com.back2kasi.config.SecurityConfig;
import com.back2kasi.user.service.UserService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * MVC slice test for {@link UserController}.
 *
 * <p>This is a <strong>web-layer integration test</strong>. {@code @WebMvcTest} loads
 * only the Spring MVC components (controllers, filters, exception handlers) — it does
 * NOT start a real server or load the full application context. This makes it fast
 * while still exercising the full HTTP stack.</p>
 *
 * <p>Key concepts used here:</p>
 * <ul>
 *   <li>{@code @WebMvcTest} — spins up only the web layer for the specified controller.</li>
 *   <li>{@code @MockBean} — replaces a Spring-managed bean with a Mockito mock inside the context.</li>
 *   <li>{@link MockMvc} — simulates HTTP requests without starting a real HTTP server.</li>
 *   <li>{@code @Valid} on the controller parameter means Bean Validation fires automatically
 *       before the method body executes — we test that here too.</li>
 * </ul>
 */
@WebMvcTest(UserController.class)
@Import({SecurityConfig.class, JwtAuthenticationFilter.class})
class UserControllerTest {

    /** Simulates HTTP requests against the full Spring MVC pipeline. */
    @Autowired
    private MockMvc mockMvc;

    /**
     * Replaced with a Mockito mock inside the Spring context.
     * The controller depends on this bean — the mock satisfies that dependency
     * without loading any real service or database logic.
     * Because {@link UserService} implements {@code UserDetailsService}, this mock
     * also satisfies the {@code UserDetailsService} dependency in
     * {@link JwtAuthenticationFilter}.
     */
    @MockBean
    private UserService userService;

    /**
     * Mocked so that {@link JwtAuthenticationFilter} can be constructed in the
     * web-layer test context. The filter needs {@code JwtService} to validate tokens,
     * but in these tests the endpoints are public and the filter short-circuits
     * immediately (no {@code Authorization} header is sent).
     */
    @MockBean
    private JwtService jwtService;

    // =========================================================
    // Happy path
    // =========================================================

    /**
     * A fully valid registration payload must:
     * <ul>
     *   <li>Return HTTP {@code 201 Created}.</li>
     *   <li>Return a plain-text confirmation body.</li>
     *   <li>Delegate to the service layer exactly once.</li>
     * </ul>
     */
    @Test
    void register_returns201_whenRequestIsValid() throws Exception {
        mockMvc.perform(post("/api/users/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "firstName":   "Kabelo",
                                    "lastName":    "Kekana",
                                    "email":       "kabelo@back2kasi.co.za",
                                    "password":    "secret123",
                                    "phoneNumber": "+27712345678"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(content().string("User registered successfully"));

        // Verify that the service was actually invoked
        verify(userService).register(any());
    }

    // =========================================================
    // Validation — 400 Bad Request scenarios
    // =========================================================

    /**
     * When all required fields are completely blank, validation must fire
     * before the service is ever called.
     *
     * <p>Expected: {@code 400 Bad Request} with a JSON body containing field errors.</p>
     */
    @Test
    void register_returns400_whenFieldsAreMissing() throws Exception {
        mockMvc.perform(post("/api/users/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "firstName":   "",
                                    "lastName":    "",
                                    "email":       "",
                                    "password":    "",
                                    "phoneNumber": ""
                                }
                                """))
                .andExpect(status().isBadRequest())
                // The response body must contain at least the firstName error
                .andExpect(jsonPath("$.fieldErrors.firstName").exists());
    }

    /**
     * A syntactically invalid email (missing {@code @}) must fail the
     * {@code @Email} constraint and return {@code 400 Bad Request}.
     */
    @Test
    void register_returns400_whenEmailIsInvalid() throws Exception {
        mockMvc.perform(post("/api/users/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "firstName":   "Kabelo",
                                    "lastName":    "Kekana",
                                    "email":       "not-an-email",
                                    "password":    "secret123",
                                    "phoneNumber": "0712345678"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.email").exists());
    }

    /**
     * A password shorter than 7 characters must fail the {@code @Size(min = 7)}
     * constraint and return {@code 400 Bad Request}.
     *
     * <p>Uses a 6-character password — one below the minimum — to confirm the
     * boundary is enforced correctly.</p>
     */
    @Test
    void register_returns400_whenPasswordIsTooShort() throws Exception {
        mockMvc.perform(post("/api/users/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "firstName":   "Kabelo",
                                    "lastName":    "Kekana",
                                    "email":       "kabelo@back2kasi.co.za",
                                    "password":    "abc123",
                                    "phoneNumber": "+27712345678"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.password").exists());
    }

    /**
     * A phone number that is not in South African {@code +27} international
     * format must fail the {@code @Pattern} constraint and return
     * {@code 400 Bad Request}.
     *
     * <p>Examples of invalid values: local format {@code 0712345678},
     * a random string, or a number with the wrong country code.</p>
     */
    @Test
    void register_returns400_whenPhoneNumberIsNotSouthAfrican() throws Exception {
        mockMvc.perform(post("/api/users/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "firstName":   "Kabelo",
                                    "lastName":    "Kekana",
                                    "email":       "kabelo@back2kasi.co.za",
                                    "password":    "secret123",
                                    "phoneNumber": "0712345678"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.phoneNumber").exists());
    }

    // =========================================================
    // Conflict — 409 Duplicate email
    // =========================================================

    /**
     * When the service throws {@link IllegalStateException} (duplicate email),
     * the {@code GlobalExceptionHandler} must translate it to {@code 409 Conflict}
     * with an {@code "error"} field in the response body.
     *
     * <p>This test verifies that the controller + exception handler work together
     * correctly end-to-end at the HTTP layer.</p>
     */
    @Test
    void register_returns409_whenEmailAlreadyExists() throws Exception {
        // Stub the service to simulate a duplicate-email scenario
        doThrow(new IllegalStateException("An account with this email address already exists: kabelo@back2kasi.co.za"))
                .when(userService).register(any());

        mockMvc.perform(post("/api/users/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "firstName":   "Kabelo",
                                    "lastName":    "Kekana",
                                    "email":       "kabelo@back2kasi.co.za",
                                    "password":    "secret123",
                                    "phoneNumber": "+27712345678"
                                }
                                """))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").exists());
    }

    // =========================================================
    // Login — Happy path
    // =========================================================

    /**
     * Valid credentials must return {@code 200 OK} with a JSON body containing
     * {@code token}, {@code tokenType}, and {@code expiresIn}.
     */
    @Test
    void login_returns200WithToken_whenCredentialsAreValid() throws Exception {
        AuthResponse authResponse = new AuthResponse("jwt.token.here", "Bearer", 86_400L);
        when(userService.login(any())).thenReturn(authResponse);

        mockMvc.perform(post("/api/users/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "email":    "kabelo@back2kasi.co.za",
                                    "password": "secret123"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").value("jwt.token.here"))
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.expiresIn").value(86_400));
    }

    // =========================================================
    // Login — 401 Unauthorized scenarios
    // =========================================================

    /**
     * When the email is not registered, the service throws
     * {@link BadCredentialsException} and the {@code GlobalExceptionHandler}
     * must translate it to {@code 401 Unauthorized}.
     *
     * <p>Note: the response message is the same as for a wrong password —
     * intentional, to prevent email enumeration.</p>
     */
    @Test
    void login_returns401_whenEmailNotFound() throws Exception {
        doThrow(new BadCredentialsException("Invalid email or password"))
                .when(userService).login(any());

        mockMvc.perform(post("/api/users/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "email":    "nobody@back2kasi.co.za",
                                    "password": "secret123"
                                }
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").exists());
    }

    /**
     * When the password does not match, the service throws
     * {@link BadCredentialsException} — same status and message as a missing email.
     */
    @Test
    void login_returns401_whenPasswordIsWrong() throws Exception {
        doThrow(new BadCredentialsException("Invalid email or password"))
                .when(userService).login(any());

        mockMvc.perform(post("/api/users/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "email":    "kabelo@back2kasi.co.za",
                                    "password": "wrongpassword"
                                }
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").exists());
    }
}
