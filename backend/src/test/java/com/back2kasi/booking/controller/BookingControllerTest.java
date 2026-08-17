package com.back2kasi.booking.controller;

import com.back2kasi.auth.filter.JwtAuthenticationFilter;
import com.back2kasi.auth.service.JwtService;
import com.back2kasi.booking.dto.BookingResponse;
import com.back2kasi.booking.entity.BookingStatus;
import com.back2kasi.booking.service.BookingService;
import com.back2kasi.common.exception.ResourceNotFoundException;
import com.back2kasi.common.exception.UnauthorizedException;
import com.back2kasi.config.SecurityConfig;
import com.back2kasi.user.entity.Role;
import com.back2kasi.user.entity.User;
import com.back2kasi.user.service.UserService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * MVC slice test for {@link BookingController}.
 *
 * <h2>All-protected model</h2>
 * <p>Unlike the rental-unit controller, <em>every</em> booking endpoint requires
 * a JWT. Tests that exercise protected routes use {@code .with(user(...))} to
 * inject a principal; tests that verify "no JWT" behaviour omit it and expect
 * {@code 403 Forbidden}.</p>
 *
 * <p>Role-based logic is tested at the service level. Controller tests here
 * only verify HTTP mechanics: status codes, JSON shapes, and delegation to the
 * service mock.</p>
 */
@WebMvcTest(BookingController.class)
@Import({SecurityConfig.class, JwtAuthenticationFilter.class})
class BookingControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private BookingService bookingService;

    @MockBean
    private UserService userService;

    @MockBean
    private JwtService jwtService;

    private User customer;
    private User owner;
    private BookingResponse sampleResponse;

    private static final LocalDate START = LocalDate.now().plusDays(5);
    private static final LocalDate END   = LocalDate.now().plusDays(7);

    @BeforeEach
    void setUp() {
        customer = User.builder()
                .id(2L).firstName("Thabo").lastName("Nkosi")
                .email("thabo@kasi.co.za").password("hashed")
                .phoneNumber("+27799999999").role(Role.USER)
                .build();

        owner = User.builder()
                .id(1L).firstName("Kabelo").lastName("Kekana")
                .email("kabelo@back2kasi.co.za").password("hashed")
                .phoneNumber("+27712345678").role(Role.USER)
                .build();

        sampleResponse = new BookingResponse(
                200L, 100L, 2L,
                START, END,
                new BigDecimal("450.00"),
                BookingStatus.PENDING,
                null,
                LocalDateTime.now(), LocalDateTime.now()
        );
    }

    // =========================================================
    // POST /api/v1/bookings  (JWT required)
    // =========================================================

    @Test
    void createBooking_returns201_whenValidRequest() throws Exception {
        when(bookingService.createBooking(any(), eq(2L))).thenReturn(sampleResponse);

        mockMvc.perform(post("/api/v1/bookings")
                        .with(user(customer))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "rentalUnitId": 100,
                                    "startDate":    "%s",
                                    "endDate":      "%s"
                                }
                                """.formatted(START, END)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(200))
                .andExpect(jsonPath("$.status").value("PENDING"))
                .andExpect(jsonPath("$.totalPrice").value(450.00))
                .andExpect(jsonPath("$.rentalUnitId").value(100));

        verify(bookingService).createBooking(any(), eq(2L));
    }

    @Test
    void createBooking_returns400_whenRentalUnitIdMissing() throws Exception {
        mockMvc.perform(post("/api/v1/bookings")
                        .with(user(customer))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "startDate": "%s",
                                    "endDate":   "%s"
                                }
                                """.formatted(START, END)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.rentalUnitId").exists());

        verify(bookingService, never()).createBooking(any(), any());
    }

    @Test
    void createBooking_returns403_whenNotAuthenticated() throws Exception {
        // No .with(user(...)) — simulates request with no JWT
        mockMvc.perform(post("/api/v1/bookings")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "rentalUnitId": 100,
                                    "startDate":    "%s",
                                    "endDate":      "%s"
                                }
                                """.formatted(START, END)))
                .andExpect(status().isForbidden());
    }

    @Test
    void createBooking_returns409_whenOverlapExists() throws Exception {
        when(bookingService.createBooking(any(), eq(2L)))
                .thenThrow(new IllegalStateException("The rental unit is already booked for the requested date range"));

        mockMvc.perform(post("/api/v1/bookings")
                        .with(user(customer))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "rentalUnitId": 100,
                                    "startDate":    "%s",
                                    "endDate":      "%s"
                                }
                                """.formatted(START, END)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").exists());
    }

    // =========================================================
    // GET /api/v1/bookings/{id}  (JWT required)
    // =========================================================

    @Test
    void getBookingById_returns200_whenCustomerRequestsOwn() throws Exception {
        when(bookingService.getBookingById(200L, 2L)).thenReturn(sampleResponse);

        mockMvc.perform(get("/api/v1/bookings/200")
                        .with(user(customer)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(200))
                .andExpect(jsonPath("$.customerId").value(2));
    }

    @Test
    void getBookingById_returns403_whenThirdPartyRequests() throws Exception {
        when(bookingService.getBookingById(200L, 2L))
                .thenThrow(new UnauthorizedException("You do not have permission to view this booking"));

        mockMvc.perform(get("/api/v1/bookings/200")
                        .with(user(customer)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error").exists());
    }

    @Test
    void getBookingById_returns403_whenNotAuthenticated() throws Exception {
        mockMvc.perform(get("/api/v1/bookings/200"))
                .andExpect(status().isForbidden());
    }

    // =========================================================
    // GET /api/v1/bookings/my  (JWT required)
    // =========================================================

    @Test
    void getMyBookings_returns200_withList() throws Exception {
        when(bookingService.getBookingsByCustomer(2L)).thenReturn(List.of(sampleResponse));

        mockMvc.perform(get("/api/v1/bookings/my")
                        .with(user(customer)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].status").value("PENDING"));
    }

    @Test
    void getMyBookings_returns403_whenNotAuthenticated() throws Exception {
        mockMvc.perform(get("/api/v1/bookings/my"))
                .andExpect(status().isForbidden());
    }

    // =========================================================
    // PATCH /api/v1/bookings/{id}/status  (JWT required)
    // =========================================================

    @Test
    void updateBookingStatus_returns200_whenOwnerConfirms() throws Exception {
        BookingResponse confirmed = new BookingResponse(
                200L, 100L, 2L, START, END,
                new BigDecimal("450.00"), BookingStatus.CONFIRMED,
                null, LocalDateTime.now(), LocalDateTime.now()
        );
        when(bookingService.updateBookingStatus(eq(200L), any(), eq(1L))).thenReturn(confirmed);

        mockMvc.perform(patch("/api/v1/bookings/200/status")
                        .with(user(owner))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                { "status": "CONFIRMED" }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("CONFIRMED"));
    }

    @Test
    void updateBookingStatus_returns403_whenNotAuthenticated() throws Exception {
        mockMvc.perform(patch("/api/v1/bookings/200/status")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                { "status": "CONFIRMED" }
                                """))
                .andExpect(status().isForbidden());
    }

    @Test
    void updateBookingStatus_returns400_whenStatusIsMissing() throws Exception {
        mockMvc.perform(patch("/api/v1/bookings/200/status")
                        .with(user(owner))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.status").exists());
    }

    // =========================================================
    // GET /api/v1/bookings/unit/{unitId}  (JWT required — owner)
    // =========================================================

    @Test
    void getBookingsByUnit_returns200_whenOwnerRequests() throws Exception {
        when(bookingService.getBookingsByRentalUnit(100L, 1L)).thenReturn(List.of(sampleResponse));

        mockMvc.perform(get("/api/v1/bookings/unit/100")
                        .with(user(owner)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].rentalUnitId").value(100));
    }

    @Test
    void getBookingsByUnit_returns404_whenUnitNotFound() throws Exception {
        when(bookingService.getBookingsByRentalUnit(999L, 1L))
                .thenThrow(new ResourceNotFoundException("Rental unit not found with id: 999"));

        mockMvc.perform(get("/api/v1/bookings/unit/999")
                        .with(user(owner)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").exists());
    }
}
