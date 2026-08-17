package com.back2kasi.integration;

import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Integration tests for the User registration and authentication flows.
 *
 * <p>Tests the full stack: HTTP request → SecurityFilter → Controller → Service
 * → Repository → H2 database → Response.</p>
 *
 * <p>Scenarios covered:</p>
 * <ul>
 *   <li>Successful registration returns 201 with user data</li>
 *   <li>Duplicate email registration returns 409 Conflict</li>
 *   <li>Invalid registration payload returns 400 with field errors</li>
 *   <li>Successful login returns 200 with JWT</li>
 *   <li>Wrong password returns 401 with ApiError</li>
 *   <li>Login with unregistered email returns 401</li>
 * </ul>
 */
class UserIntegrationTest extends BaseIntegrationTest {

    // =========================================================
    // Registration
    // =========================================================

    @Test
    void register_returns201_withUserData_whenRequestIsValid() throws Exception {
        mockMvc.perform(post("/api/users/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "firstName":   "Kabelo",
                                    "lastName":    "Kekana",
                                    "email":       "kabelo.register@test.co.za",
                                    "password":    "secret123",
                                    "phoneNumber": "+27712345678"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(content().string("User registered successfully"));
    }

    @Test
    void register_returns409_whenEmailAlreadyExists() throws Exception {
        String body = """
                {
                    "firstName":   "Kabelo",
                    "lastName":    "Kekana",
                    "email":       "duplicate@test.co.za",
                    "password":    "secret123",
                    "phoneNumber": "+27712345678"
                }
                """;

        // First registration succeeds
        mockMvc.perform(post("/api/users/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated());

        // Second registration with same email → 409
        mockMvc.perform(post("/api/users/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.status").value(409))
                .andExpect(jsonPath("$.error").value("Conflict"))
                .andExpect(jsonPath("$.message").isNotEmpty());
    }

    @Test
    void register_returns400_whenRequiredFieldsAreMissing() throws Exception {
        mockMvc.perform(post("/api/users/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "firstName": "",
                                    "email":     "incomplete@test.co.za"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.fieldErrors").isNotEmpty());
    }

    // =========================================================
    // Login
    // =========================================================

    @Test
    void login_returns200_withJwt_whenCredentialsAreCorrect() throws Exception {
        // Register first
        registerAndLogin("kabelo.login@test.co.za", "secret123");

        // Explicit login assertion
        mockMvc.perform(post("/api/users/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "email":    "kabelo.login@test.co.za",
                                    "password": "secret123"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty());
    }

    @Test
    void login_returns401_whenPasswordIsWrong() throws Exception {
        registerAndLogin("wrongpass@test.co.za", "correct");

        mockMvc.perform(post("/api/users/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "email":    "wrongpass@test.co.za",
                                    "password": "WRONG"
                                }
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.status").value(401))
                .andExpect(jsonPath("$.message").value("Invalid email or password"));
    }

    @Test
    void login_returns401_whenEmailIsNotRegistered() throws Exception {
        mockMvc.perform(post("/api/users/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "email":    "nobody@test.co.za",
                                    "password": "doesntmatter"
                                }
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.status").value(401));
    }
}
