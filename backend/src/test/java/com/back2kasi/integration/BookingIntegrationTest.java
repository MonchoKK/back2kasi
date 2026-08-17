package com.back2kasi.integration;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Integration tests for the Booking API.
 *
 * <p>Key scenarios covered:</p>
 * <ul>
 *   <li>Customer creates a booking → PENDING, total price calculated</li>
 *   <li>Owner confirms booking → unit status becomes RENTED</li>
 *   <li>Owner completes booking → unit status reverts to AVAILABLE</li>
 *   <li>Customer can cancel their own booking</li>
 *   <li>Overlapping bookings (on CONFIRMED dates) are rejected with 409</li>
 *   <li>Only the owner may confirm or complete; only parties involved may cancel</li>
 * </ul>
 */
class BookingIntegrationTest extends BaseIntegrationTest {

    private static final DateTimeFormatter DATE = DateTimeFormatter.ISO_LOCAL_DATE;

    private String ownerToken;
    private String customerToken;
    private String otherToken;

    private long unitId;

    @BeforeEach
    void setUp() throws Exception {
        ownerToken   = registerAndLogin("book.owner@test.co.za",    "secret123");
        customerToken = registerAndLogin("book.customer@test.co.za", "secret123");
        otherToken   = registerAndLogin("book.other@test.co.za",     "secret123");

        // Owner: create business + rental unit
        String bizJson = mockMvc.perform(post("/api/v1/businesses")
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "name":         "Kasi Toilets",
                                    "address":      "123 Soweto Rd",
                                    "phoneNumber":  "+27711234567",
                                    "businessType": "TOILET_RENTAL"
                                }
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        long businessId = objectMapper.readTree(bizJson).get("id").asLong();

        String unitJson = mockMvc.perform(post("/api/v1/rental-units")
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "businessId":     %d,
                                    "name":           "Unit A",
                                    "pricePerDay":    100.00,
                                    "capacity":       1,
                                    "rentalUnitType": "STANDARD_TOILET"
                                }
                                """.formatted(businessId)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        unitId = objectMapper.readTree(unitJson).get("id").asLong();
    }

    // =========================================================
    // Create booking (customer)
    // =========================================================

    @Test
    void createBooking_returns201_withPriceCalculated() throws Exception {
        String start = LocalDate.now().plusDays(10).format(DATE);
        String end   = LocalDate.now().plusDays(11).format(DATE); // 2 days (inclusive: start date + end date)

        mockMvc.perform(post("/api/v1/bookings")
                        .header("Authorization", bearer(customerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "rentalUnitId": %d,
                                    "startDate":    "%s",
                                    "endDate":      "%s"
                                }
                                """.formatted(unitId, start, end)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.status").value("PENDING"))
                .andExpect(jsonPath("$.totalPrice").value(200.00)) // 100 x 2 days
                .andExpect(jsonPath("$.customerId").isNumber());
    }

    @Test
    void createBooking_returns403_whenNotAuthenticated() throws Exception {
        mockMvc.perform(post("/api/v1/bookings")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                { "rentalUnitId": %d, "startDate": "2027-01-01", "endDate": "2027-01-03" }
                                """.formatted(unitId)))
                .andExpect(status().isForbidden());
    }

    // =========================================================
    // Status lifecycle: PENDING → CONFIRMED → COMPLETED
    // =========================================================

    @Test
    void bookingLifecycle_pendingToConfirmedToCompleted() throws Exception {
        // Customer creates booking
        String start = LocalDate.now().plusDays(20).format(DATE);
        String end   = LocalDate.now().plusDays(21).format(DATE);

        String bookingJson = mockMvc.perform(post("/api/v1/bookings")
                        .header("Authorization", bearer(customerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                { "rentalUnitId": %d, "startDate": "%s", "endDate": "%s" }
                                """.formatted(unitId, start, end)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.status").value("PENDING"))
                .andReturn().getResponse().getContentAsString();

        long bookingId = objectMapper.readTree(bookingJson).get("id").asLong();

        // Owner confirms → unit should become RENTED
        mockMvc.perform(patch("/api/v1/bookings/" + bookingId + "/status")
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{ \"status\": \"CONFIRMED\" }"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("CONFIRMED"));

        // Unit is now RENTED (public read)
        mockMvc.perform(get("/api/v1/rental-units/" + unitId))
                .andExpect(jsonPath("$.status").value("RENTED"));

        // Owner marks complete → unit should revert to AVAILABLE
        mockMvc.perform(patch("/api/v1/bookings/" + bookingId + "/status")
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{ \"status\": \"COMPLETED\" }"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("COMPLETED"));

        // Unit is AVAILABLE again
        mockMvc.perform(get("/api/v1/rental-units/" + unitId))
                .andExpect(jsonPath("$.status").value("AVAILABLE"));
    }

    // =========================================================
    // Cancellation
    // =========================================================

    @Test
    void customer_canCancelTheirOwnPendingBooking() throws Exception {
        String start = LocalDate.now().plusDays(30).format(DATE);
        String end   = LocalDate.now().plusDays(31).format(DATE);

        String bookingJson = mockMvc.perform(post("/api/v1/bookings")
                        .header("Authorization", bearer(customerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                { "rentalUnitId": %d, "startDate": "%s", "endDate": "%s" }
                                """.formatted(unitId, start, end)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        long bookingId = objectMapper.readTree(bookingJson).get("id").asLong();

        mockMvc.perform(patch("/api/v1/bookings/" + bookingId + "/status")
                        .header("Authorization", bearer(customerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{ \"status\": \"CANCELLED\" }"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("CANCELLED"));
    }

    @Test
    void unrelatedUser_cannotCancelSomeoneElsesBooking() throws Exception {
        String start = LocalDate.now().plusDays(40).format(DATE);
        String end   = LocalDate.now().plusDays(41).format(DATE);

        String bookingJson = mockMvc.perform(post("/api/v1/bookings")
                        .header("Authorization", bearer(customerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                { "rentalUnitId": %d, "startDate": "%s", "endDate": "%s" }
                                """.formatted(unitId, start, end)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        long bookingId = objectMapper.readTree(bookingJson).get("id").asLong();

        // otherToken is neither customer nor owner
        mockMvc.perform(patch("/api/v1/bookings/" + bookingId + "/status")
                        .header("Authorization", bearer(otherToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{ \"status\": \"CANCELLED\" }"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.status").value(403));
    }

    // =========================================================
    // Overlap detection
    // =========================================================

    @Test
    void createBooking_returns409_whenDatesOverlapConfirmedBooking() throws Exception {
        String start = LocalDate.now().plusDays(50).format(DATE);
        String end   = LocalDate.now().plusDays(53).format(DATE);

        // Customer books days 50–53
        String firstJson = mockMvc.perform(post("/api/v1/bookings")
                        .header("Authorization", bearer(customerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                { "rentalUnitId": %d, "startDate": "%s", "endDate": "%s" }
                                """.formatted(unitId, start, end)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        long firstId = objectMapper.readTree(firstJson).get("id").asLong();

        // Owner confirms it
        mockMvc.perform(patch("/api/v1/bookings/" + firstId + "/status")
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{ \"status\": \"CONFIRMED\" }"))
                .andExpect(status().isOk());

        // Another customer tries to book overlapping dates (days 51–54)
        String overlapStart = LocalDate.now().plusDays(51).format(DATE);
        String overlapEnd   = LocalDate.now().plusDays(54).format(DATE);

        mockMvc.perform(post("/api/v1/bookings")
                        .header("Authorization", bearer(otherToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                { "rentalUnitId": %d, "startDate": "%s", "endDate": "%s" }
                                """.formatted(unitId, overlapStart, overlapEnd)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.status").value(409))
                .andExpect(jsonPath("$.error").value("Conflict"));
    }
}
