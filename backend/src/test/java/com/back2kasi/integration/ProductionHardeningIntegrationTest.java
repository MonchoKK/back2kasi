package com.back2kasi.integration;

import com.back2kasi.auth.service.JwtService;
import com.back2kasi.booking.entity.Booking;
import com.back2kasi.booking.entity.BookingStatus;
import com.back2kasi.booking.repository.BookingRepository;
import com.back2kasi.user.entity.User;
import com.back2kasi.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Sprint 19 — Production Hardening & Release Candidate Integration Test Suite.
 *
 * <p>Deliberately tests the uncomfortable and edge-case scenarios before real customers do:
 * <ul>
 *   <li>Authentication: wrong password, missing JWT, invalid JWT, expired JWT.</li>
 *   <li>Authorization: Customer -> owner endpoint, Owner A -> Owner B business,
 *       Owner A -> Owner B booking, Customer -> another customer's data.</li>
 *   <li>Booking: valid booking, past dates, inverted dates, overlapping dates,
 *       cancel pending, approve pending, decline pending.</li>
 *   <li>Concurrency: multi-threaded simultaneous approval of overlapping pending bookings
 *       for the same rental unit (Customer A vs Customer B for Toilet #1).</li>
 * </ul>
 */
class ProductionHardeningIntegrationTest extends BaseIntegrationTest {

    private static final DateTimeFormatter DATE = DateTimeFormatter.ISO_LOCAL_DATE;

    @Autowired
    private JwtService jwtService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private BookingRepository bookingRepository;

    private String ownerAToken;
    private String ownerBToken;
    private String customerAToken;
    private String customerBToken;

    private long businessAId;
    private long businessBId;
    private long unitAId;

    @BeforeEach
    void setUp() throws Exception {
        ownerAToken    = registerAndLogin("ownerA@kasi.co.za",    "SecretPass123!");
        ownerBToken    = registerAndLogin("ownerB@kasi.co.za",    "SecretPass123!");
        customerAToken = registerAndLogin("customerA@kasi.co.za", "SecretPass123!");
        customerBToken = registerAndLogin("customerB@kasi.co.za", "SecretPass123!");

        // Owner A creates Business A
        String bizA = mockMvc.perform(post("/api/v1/businesses")
                        .header("Authorization", bearer(ownerAToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "name":         "Owner A Toilet Hire",
                                    "address":      "10 Mandela St, Soweto",
                                    "phoneNumber":  "+27711234567",
                                    "businessType": "TOILET_RENTAL"
                                }
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        businessAId = objectMapper.readTree(bizA).get("id").asLong();

        // Owner B creates Business B
        String bizB = mockMvc.perform(post("/api/v1/businesses")
                        .header("Authorization", bearer(ownerBToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "name":         "Owner B Cold Storage",
                                    "address":      "22 Vilakazi St, Orlando West",
                                    "phoneNumber":  "+27729876543",
                                    "businessType": "COLD_ROOM_RENTAL"
                                }
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        businessBId = objectMapper.readTree(bizB).get("id").asLong();

        // Owner A creates Toilet #1 under Business A
        String unitA = mockMvc.perform(post("/api/v1/rental-units")
                        .header("Authorization", bearer(ownerAToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "name":           "VIP Portable Toilet #1",
                                    "description":    "Flushable event toilet with sanitizer",
                                    "pricePerDay":    450.00,
                                    "capacity":       1,
                                    "rentalUnitType": "VIP_TOILET",
                                    "businessId":     %d
                                }
                                """.formatted(businessAId)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        unitAId = objectMapper.readTree(unitA).get("id").asLong();
    }

    // =========================================================================
    // 1. Authentication
    // =========================================================================
    @Nested
    @DisplayName("1. Authentication Edge Cases")
    class AuthenticationTests {

        @Test
        @DisplayName("Wrong password should be rejected with 401 Unauthorized")
        void wrongPassword_rejected() throws Exception {
            mockMvc.perform(post("/api/users/login")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {
                                        "email":    "ownerA@kasi.co.za",
                                        "password": "WrongPassword!"
                                    }
                                    """))
                    .andExpect(status().isUnauthorized())
                    .andExpect(jsonPath("$.status").value(401))
                    .andExpect(jsonPath("$.message").value("Invalid email or password"));
        }

        @Test
        @DisplayName("Missing JWT on protected endpoint should be rejected with 403 Forbidden")
        void missingJwt_rejected() throws Exception {
            mockMvc.perform(get("/api/v1/businesses/my"))
                    .andExpect(status().isForbidden());
        }

        @Test
        @DisplayName("Malformed/Invalid JWT should be rejected with 403 Forbidden")
        void invalidJwt_rejected() throws Exception {
            mockMvc.perform(get("/api/v1/businesses/my")
                            .header("Authorization", "Bearer invalid.malformed.token.xyz"))
                    .andExpect(status().isForbidden());
        }

        @Test
        @DisplayName("Expired JWT session should be cleanly rejected with 403 Forbidden")
        void expiredJwt_rejected() throws Exception {
            User customer = userRepository.findByEmail("customerA@kasi.co.za").orElseThrow();

            // Temporarily set expiration to negative to produce an already expired token
            long originalExp = (long) ReflectionTestUtils.getField(jwtService, "jwtExpirationMs");
            try {
                ReflectionTestUtils.setField(jwtService, "jwtExpirationMs", -10000L);
                String expiredToken = jwtService.generateToken(customer);

                mockMvc.perform(get("/api/v1/bookings/my")
                                .header("Authorization", bearer(expiredToken)))
                        .andExpect(status().isForbidden());
            } finally {
                ReflectionTestUtils.setField(jwtService, "jwtExpirationMs", originalExp);
            }
        }
    }

    // =========================================================================
    // 2. Authorization
    // =========================================================================
    @Nested
    @DisplayName("2. Authorization Matrix & Cross-Tenant Protection")
    class AuthorizationTests {

        @Test
        @DisplayName("Customer cannot create a rental unit under another user's business (403)")
        void customer_cannotAddRentalUnitToOwnerBusiness() throws Exception {
            mockMvc.perform(post("/api/v1/rental-units")
                            .header("Authorization", bearer(customerAToken))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {
                                        "name":           "Illicit Unit",
                                        "description":    "Attempt by customer",
                                        "pricePerDay":    100.00,
                                        "capacity":       1,
                                        "rentalUnitType": "VIP_TOILET",
                                        "businessId":     %d
                                    }
                                    """.formatted(businessAId)))
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.status").value(403));
        }

        @Test
        @DisplayName("Owner A cannot update Owner B's business profile (403)")
        void ownerA_cannotUpdateOwnerBBusiness() throws Exception {
            mockMvc.perform(put("/api/v1/businesses/" + businessBId)
                            .header("Authorization", bearer(ownerAToken))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {
                                        "name":         "Hacked Name",
                                        "address":      "Hacked Address",
                                        "phoneNumber":  "+27711234567",
                                        "businessType": "TOILET_RENTAL"
                                    }
                                    """))
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.status").value(403));
        }

        @Test
        @DisplayName("Owner A cannot delete Owner B's business profile (403)")
        void ownerA_cannotDeleteOwnerBBusiness() throws Exception {
            mockMvc.perform(delete("/api/v1/businesses/" + businessBId)
                            .header("Authorization", bearer(ownerAToken)))
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.status").value(403));
        }

        @Test
        @DisplayName("Owner A cannot modify status of Owner B's booking (403)")
        void ownerA_cannotModifyOwnerBBooking() throws Exception {
            // Owner B creates a unit under Business B
            String unitB = mockMvc.perform(post("/api/v1/rental-units")
                            .header("Authorization", bearer(ownerBToken))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {
                                        "name":           "Cold Room Trailer A",
                                        "description":    "Event chiller",
                                        "pricePerDay":    800.00,
                                        "capacity":       1,
                                        "rentalUnitType": "MOBILE_COLD_ROOM",
                                        "businessId":     %d
                                    }
                                    """.formatted(businessBId)))
                    .andExpect(status().isCreated())
                    .andReturn().getResponse().getContentAsString();
            long unitBId = objectMapper.readTree(unitB).get("id").asLong();

            // Customer A books unit under Owner B
            LocalDate start = LocalDate.now().plusDays(5);
            LocalDate end   = LocalDate.now().plusDays(7);
            String bookingJson = mockMvc.perform(post("/api/v1/bookings")
                            .header("Authorization", bearer(customerAToken))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {
                                        "rentalUnitId": %d,
                                        "startDate":    "%s",
                                        "endDate":      "%s"
                                    }
                                    """.formatted(unitBId, start.format(DATE), end.format(DATE))))
                    .andExpect(status().isCreated())
                    .andReturn().getResponse().getContentAsString();
            long bookingId = objectMapper.readTree(bookingJson).get("id").asLong();

            // Owner A tries to CONFIRM Owner B's booking -> 403
            mockMvc.perform(patch("/api/v1/bookings/" + bookingId + "/status")
                            .header("Authorization", bearer(ownerAToken))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{\"status\": \"CONFIRMED\"}"))
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.status").value(403));
        }

        @Test
        @DisplayName("Customer A cannot view or cancel Customer B's booking (403)")
        void customerA_cannotAccessCustomerBBooking() throws Exception {
            LocalDate start = LocalDate.now().plusDays(10);
            LocalDate end   = LocalDate.now().plusDays(12);

            // Customer B creates a booking on Unit A
            String bJson = mockMvc.perform(post("/api/v1/bookings")
                            .header("Authorization", bearer(customerBToken))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {
                                        "rentalUnitId": %d,
                                        "startDate":    "%s",
                                        "endDate":      "%s"
                                    }
                                    """.formatted(unitAId, start.format(DATE), end.format(DATE))))
                    .andExpect(status().isCreated())
                    .andReturn().getResponse().getContentAsString();
            long bookingBId = objectMapper.readTree(bJson).get("id").asLong();

            // Customer A tries to view Customer B's booking -> 403
            mockMvc.perform(get("/api/v1/bookings/" + bookingBId)
                            .header("Authorization", bearer(customerAToken)))
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.status").value(403));

            // Customer A tries to cancel Customer B's booking -> 403
            mockMvc.perform(patch("/api/v1/bookings/" + bookingBId + "/status")
                            .header("Authorization", bearer(customerAToken))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{\"status\": \"CANCELLED\"}"))
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.status").value(403));
        }
    }

    // =========================================================================
    // 3. Booking Lifecycle & Validation
    // =========================================================================
    @Nested
    @DisplayName("3. Booking Lifecycle & Validation Rules")
    class BookingLifecycleTests {

        @Test
        @DisplayName("Valid booking creates PENDING status and calculates total price")
        void validBooking_createsPending() throws Exception {
            LocalDate start = LocalDate.now().plusDays(1);
            LocalDate end   = LocalDate.now().plusDays(3); // 3 days inclusive

            mockMvc.perform(post("/api/v1/bookings")
                            .header("Authorization", bearer(customerAToken))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {
                                        "rentalUnitId": %d,
                                        "startDate":    "%s",
                                        "endDate":      "%s",
                                        "notes":        "Family weekend gathering"
                                    }
                                    """.formatted(unitAId, start.format(DATE), end.format(DATE))))
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$.status").value("PENDING"))
                    .andExpect(jsonPath("$.totalPrice").value(1350.00)) // 3 * 450.00
                    .andExpect(jsonPath("$.notes").value("Family weekend gathering"));
        }

        @Test
        @DisplayName("Past dates are rejected with 400 Bad Request")
        void pastDates_rejected() throws Exception {
            LocalDate pastDate = LocalDate.now().minusDays(2);

            mockMvc.perform(post("/api/v1/bookings")
                            .header("Authorization", bearer(customerAToken))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {
                                        "rentalUnitId": %d,
                                        "startDate":    "%s",
                                        "endDate":      "%s"
                                    }
                                    """.formatted(unitAId, pastDate.format(DATE), pastDate.plusDays(2).format(DATE))))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.status").value(400));
        }

        @Test
        @DisplayName("Inverted date range (endDate < startDate) is rejected with 409 Conflict")
        void invertedDateRange_rejected() throws Exception {
            LocalDate start = LocalDate.now().plusDays(5);
            LocalDate end   = LocalDate.now().plusDays(2); // end before start

            mockMvc.perform(post("/api/v1/bookings")
                            .header("Authorization", bearer(customerAToken))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {
                                        "rentalUnitId": %d,
                                        "startDate":    "%s",
                                        "endDate":      "%s"
                                    }
                                    """.formatted(unitAId, start.format(DATE), end.format(DATE))))
                    .andExpect(status().isConflict())
                    .andExpect(jsonPath("$.status").value(409))
                    .andExpect(jsonPath("$.message").value("Start date must not be after end date"));
        }

        @Test
        @DisplayName("Booking overlapping an already CONFIRMED booking is rejected with 409 Conflict")
        void overlappingBooking_rejected() throws Exception {
            LocalDate start = LocalDate.now().plusDays(15);
            LocalDate end   = LocalDate.now().plusDays(18);

            // Customer A books dates
            String bJson = mockMvc.perform(post("/api/v1/bookings")
                            .header("Authorization", bearer(customerAToken))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {
                                        "rentalUnitId": %d,
                                        "startDate":    "%s",
                                        "endDate":      "%s"
                                    }
                                    """.formatted(unitAId, start.format(DATE), end.format(DATE))))
                    .andExpect(status().isCreated())
                    .andReturn().getResponse().getContentAsString();
            long bookingId = objectMapper.readTree(bJson).get("id").asLong();

            // Owner confirms Customer A's booking
            mockMvc.perform(patch("/api/v1/bookings/" + bookingId + "/status")
                            .header("Authorization", bearer(ownerAToken))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{\"status\": \"CONFIRMED\"}"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.status").value("CONFIRMED"));

            // Customer B tries to book overlapping range (day 16 to day 19)
            LocalDate overlapStart = LocalDate.now().plusDays(16);
            LocalDate overlapEnd   = LocalDate.now().plusDays(19);

            mockMvc.perform(post("/api/v1/bookings")
                            .header("Authorization", bearer(customerBToken))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {
                                        "rentalUnitId": %d,
                                        "startDate":    "%s",
                                        "endDate":      "%s"
                                    }
                                    """.formatted(unitAId, overlapStart.format(DATE), overlapEnd.format(DATE))))
                    .andExpect(status().isConflict())
                    .andExpect(jsonPath("$.status").value(409));
        }

        @Test
        @DisplayName("Customer can cancel their own PENDING booking")
        void customer_canCancelPendingBooking() throws Exception {
            LocalDate start = LocalDate.now().plusDays(20);
            LocalDate end   = LocalDate.now().plusDays(22);

            String bJson = mockMvc.perform(post("/api/v1/bookings")
                            .header("Authorization", bearer(customerAToken))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {
                                        "rentalUnitId": %d,
                                        "startDate":    "%s",
                                        "endDate":      "%s"
                                    }
                                    """.formatted(unitAId, start.format(DATE), end.format(DATE))))
                    .andExpect(status().isCreated())
                    .andReturn().getResponse().getContentAsString();
            long bookingId = objectMapper.readTree(bJson).get("id").asLong();

            mockMvc.perform(patch("/api/v1/bookings/" + bookingId + "/status")
                            .header("Authorization", bearer(customerAToken))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{\"status\": \"CANCELLED\"}"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.status").value("CANCELLED"));
        }

        @Test
        @DisplayName("Owner can decline (cancel) a PENDING booking")
        void owner_canDeclinePendingBooking() throws Exception {
            LocalDate start = LocalDate.now().plusDays(25);
            LocalDate end   = LocalDate.now().plusDays(27);

            String bJson = mockMvc.perform(post("/api/v1/bookings")
                            .header("Authorization", bearer(customerAToken))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {
                                        "rentalUnitId": %d,
                                        "startDate":    "%s",
                                        "endDate":      "%s"
                                    }
                                    """.formatted(unitAId, start.format(DATE), end.format(DATE))))
                    .andExpect(status().isCreated())
                    .andReturn().getResponse().getContentAsString();
            long bookingId = objectMapper.readTree(bJson).get("id").asLong();

            mockMvc.perform(patch("/api/v1/bookings/" + bookingId + "/status")
                            .header("Authorization", bearer(ownerAToken))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{\"status\": \"CANCELLED\"}"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.status").value("CANCELLED"));
        }
    }

    // =========================================================================
    // 4. Concurrency & Race Condition Prevention
    // =========================================================================
    @Nested
    @DisplayName("4. Concurrency & Double-Booking Race Condition")
    class ConcurrencyTests {

        /**
         * Scenario:
         * Customer A wants Toilet #1 (20–22 October)
         * Customer B wants Toilet #1 (20–22 October)
         *
         * Both create PENDING requests.
         * The owner (or concurrent incoming approval requests) simultaneously attempts
         * to approve both bookings.
         *
         * Expected:
         * Exactly ONE approval succeeds (200 OK -> CONFIRMED).
         * The competing approval is rejected (409 Conflict).
         * The database ends up with exactly ONE CONFIRMED booking.
         */
        @Test
        @DisplayName("Simultaneous approvals for overlapping bookings result in exactly ONE win and ONE 409 Conflict")
        void concurrentBookingApproval_strictlyOneConfirmed() throws Exception {
            LocalDate start = LocalDate.now().plusDays(30);
            LocalDate end   = LocalDate.now().plusDays(32);

            // Customer A submits booking
            String jsonA = mockMvc.perform(post("/api/v1/bookings")
                            .header("Authorization", bearer(customerAToken))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {
                                        "rentalUnitId": %d,
                                        "startDate":    "%s",
                                        "endDate":      "%s",
                                        "notes":        "Customer A booking"
                                    }
                                    """.formatted(unitAId, start.format(DATE), end.format(DATE))))
                    .andExpect(status().isCreated())
                    .andReturn().getResponse().getContentAsString();
            long bookingAId = objectMapper.readTree(jsonA).get("id").asLong();

            // Customer B submits booking for the EXACT same dates on Toilet #1
            String jsonB = mockMvc.perform(post("/api/v1/bookings")
                            .header("Authorization", bearer(customerBToken))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {
                                        "rentalUnitId": %d,
                                        "startDate":    "%s",
                                        "endDate":      "%s",
                                        "notes":        "Customer B booking"
                                    }
                                    """.formatted(unitAId, start.format(DATE), end.format(DATE))))
                    .andExpect(status().isCreated())
                    .andReturn().getResponse().getContentAsString();
            long bookingBId = objectMapper.readTree(jsonB).get("id").asLong();

            // Prepare concurrent race
            int threadCount = 2;
            ExecutorService executor = Executors.newFixedThreadPool(threadCount);
            CountDownLatch startLatch = new CountDownLatch(1);
            CountDownLatch doneLatch  = new CountDownLatch(threadCount);

            List<Integer> responseStatuses = Collections.synchronizedList(new ArrayList<>());
            AtomicInteger successCount = new AtomicInteger(0);
            AtomicInteger conflictCount = new AtomicInteger(0);

            // Task 1: Approve Booking A
            executor.submit(() -> {
                try {
                    startLatch.await();
                    int statusCode = mockMvc.perform(patch("/api/v1/bookings/" + bookingAId + "/status")
                                    .header("Authorization", bearer(ownerAToken))
                                    .contentType(MediaType.APPLICATION_JSON)
                                    .content("{\"status\": \"CONFIRMED\"}"))
                            .andReturn().getResponse().getStatus();
                    responseStatuses.add(statusCode);
                    if (statusCode == 200) successCount.incrementAndGet();
                    if (statusCode == 409) conflictCount.incrementAndGet();
                } catch (Exception e) {
                    // unexpected error
                } finally {
                    doneLatch.countDown();
                }
            });

            // Task 2: Approve Booking B
            executor.submit(() -> {
                try {
                    startLatch.await();
                    int statusCode = mockMvc.perform(patch("/api/v1/bookings/" + bookingBId + "/status")
                                    .header("Authorization", bearer(ownerAToken))
                                    .contentType(MediaType.APPLICATION_JSON)
                                    .content("{\"status\": \"CONFIRMED\"}"))
                            .andReturn().getResponse().getStatus();
                    responseStatuses.add(statusCode);
                    if (statusCode == 200) successCount.incrementAndGet();
                    if (statusCode == 409) conflictCount.incrementAndGet();
                } catch (Exception e) {
                    // unexpected error
                } finally {
                    doneLatch.countDown();
                }
            });

            // Release threads simultaneously
            startLatch.countDown();
            boolean finished = doneLatch.await(10, TimeUnit.SECONDS);
            executor.shutdown();

            assertThat(finished).isTrue();
            assertThat(responseStatuses).hasSize(2);

            // Exactly one must succeed (200) and exactly one must fail with conflict (409)
            assertThat(successCount.get())
                    .as("Exactly ONE approval must succeed")
                    .isEqualTo(1);
            assertThat(conflictCount.get())
                    .as("Competing approval must be rejected with 409 Conflict")
                    .isEqualTo(1);

            // Verify in database: exactly ONE is CONFIRMED, the other remains PENDING
            Booking bookingA = bookingRepository.findById(bookingAId).orElseThrow();
            Booking bookingB = bookingRepository.findById(bookingBId).orElseThrow();

            boolean aIsConfirmed = bookingA.getStatus() == BookingStatus.CONFIRMED;
            boolean bIsConfirmed = bookingB.getStatus() == BookingStatus.CONFIRMED;

            // XOR: exactly one is true
            assertThat(aIsConfirmed ^ bIsConfirmed)
                    .as("Database must have exactly one confirmed booking for these dates")
                    .isTrue();
        }
    }
}
