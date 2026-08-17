package com.back2kasi.integration;

import com.back2kasi.booking.repository.BookingRepository;
import com.back2kasi.business.repository.BusinessRepository;
import com.back2kasi.rentalunit.repository.RentalUnitRepository;
import com.back2kasi.user.repository.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Base class for all integration tests.
 *
 * <h2>What "integration test" means here</h2>
 * <p>These tests load the <strong>full Spring application context</strong> and
 * hit real HTTP endpoints via {@link MockMvc}. The only difference from production
 * is the database: the {@code test} profile swaps PostgreSQL for an in-memory H2
 * database, so tests are self-contained, fast, and require no external services.</p>
 *
 * <h2>Annotations</h2>
 * <ul>
 *   <li>{@code @SpringBootTest} — starts the complete application context.</li>
 *   <li>{@code @AutoConfigureMockMvc} — configures a MockMvc that talks to the
 *       full servlet stack (including the JWT security filter chain).</li>
 *   <li>{@code @ActiveProfiles("test")} — activates {@code application-test.properties}
 *       which points to H2 instead of PostgreSQL.</li>
 *   <li>{@code @DirtiesContext} — resets the application context (and H2 database)
 *       between test classes to prevent state bleed.</li>
 * </ul>
 *
 * <h2>Helper methods</h2>
 * <p>Provides {@link #registerAndLogin(String, String)} so each test class can
 * obtain a real JWT in a single line and focus on the feature under test.</p>
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
public abstract class BaseIntegrationTest {

    @Autowired
    protected MockMvc mockMvc;

    @Autowired
    protected ObjectMapper objectMapper;

    @Autowired
    private BookingRepository bookingRepository;

    @Autowired
    private RentalUnitRepository rentalUnitRepository;

    @Autowired
    private BusinessRepository businessRepository;

    @Autowired
    private UserRepository userRepository;

    /**
     * Clear all tables before each test method to ensure complete database isolation.
     * Deletions are ordered to avoid foreign key constraint violations.
     */
    @BeforeEach
    void cleanDatabase() {
        bookingRepository.deleteAll();
        rentalUnitRepository.deleteAll();
        businessRepository.deleteAll();
        userRepository.deleteAll();
    }

    // --- Helper constants ---

    protected static final String CONTENT_TYPE_JSON = MediaType.APPLICATION_JSON_VALUE;

    // --- Auth helpers ---

    /**
     * Register a new user and immediately login to obtain a JWT.
     *
     * <p>This simulates the exact flow a real client performs:
     * {@code POST /api/users/register} → {@code POST /api/users/login} → JWT.</p>
     *
     * @param email    the user's email address (must be unique within the test run)
     * @param password the plain-text password
     * @return the JWT string (without the "Bearer " prefix)
     */
    protected String registerAndLogin(String email, String password) throws Exception {
        // Register
        String registerBody = """
                {
                    "firstName":   "Test",
                    "lastName":    "User",
                    "email":       "%s",
                    "password":    "%s",
                    "phoneNumber": "+27711234567"
                }
                """.formatted(email, password);

        mockMvc.perform(post("/api/users/register")
                        .contentType(CONTENT_TYPE_JSON)
                        .content(registerBody))
                .andExpect(status().isCreated());

        // Login and extract JWT
        String loginBody = """
                {
                    "email":    "%s",
                    "password": "%s"
                }
                """.formatted(email, password);

        MvcResult result = mockMvc.perform(post("/api/users/login")
                        .contentType(CONTENT_TYPE_JSON)
                        .content(loginBody))
                .andExpect(status().isOk())
                .andReturn();

        String responseJson = result.getResponse().getContentAsString();
        return objectMapper.readTree(responseJson).get("token").asText();
    }

    /**
     * Build an {@code Authorization: Bearer <token>} header value.
     *
     * @param token the raw JWT string
     * @return the full header value, prefixed with "Bearer "
     */
    protected static String bearer(String token) {
        return "Bearer " + token;
    }
}
