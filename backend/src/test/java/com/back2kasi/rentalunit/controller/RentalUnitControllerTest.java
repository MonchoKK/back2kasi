package com.back2kasi.rentalunit.controller;

import com.back2kasi.auth.filter.JwtAuthenticationFilter;
import com.back2kasi.auth.service.JwtService;
import com.back2kasi.common.exception.ResourceNotFoundException;
import com.back2kasi.common.exception.UnauthorizedException;
import com.back2kasi.config.SecurityConfig;
import com.back2kasi.rentalunit.dto.RentalUnitResponse;
import com.back2kasi.rentalunit.entity.RentalUnitStatus;
import com.back2kasi.rentalunit.entity.RentalUnitType;
import com.back2kasi.rentalunit.service.RentalUnitService;
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
import java.time.LocalDateTime;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * MVC slice test for {@link RentalUnitController}.
 *
 * <h2>Public vs Protected endpoints</h2>
 * <p>This test class exercises both access models:</p>
 * <ul>
 *   <li><strong>Public GET tests</strong> — sent without {@code .with(user(...))}
 *       to verify that no authentication is required.</li>
 *   <li><strong>Protected write tests</strong> — sent with
 *       {@code .with(user(authenticatedUser))} to inject a valid principal,
 *       matching how {@code JwtAuthenticationFilter} operates at runtime.</li>
 * </ul>
 */
@WebMvcTest(RentalUnitController.class)
@Import({SecurityConfig.class, JwtAuthenticationFilter.class})
class RentalUnitControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private RentalUnitService rentalUnitService;

    @MockBean
    private UserService userService;

    @MockBean
    private JwtService jwtService;

    private User authenticatedUser;
    private RentalUnitResponse sampleResponse;

    @BeforeEach
    void setUp() {
        authenticatedUser = User.builder()
                .id(1L).firstName("Kabelo").lastName("Kekana")
                .email("kabelo@back2kasi.co.za").password("hashed")
                .phoneNumber("+27712345678").role(Role.USER)
                .build();

        sampleResponse = new RentalUnitResponse(
                100L, "Unit A", "Standard toilet",
                new BigDecimal("150.00"), 1,
                RentalUnitType.STANDARD_TOILET, RentalUnitStatus.AVAILABLE,
                10L, LocalDateTime.now(), LocalDateTime.now()
        );
    }

    // =========================================================
    // POST /api/v1/rental-units  (JWT required)
    // =========================================================

    @Test
    void createRentalUnit_returns201_whenValidRequest() throws Exception {
        when(rentalUnitService.createRentalUnit(any(), eq(1L))).thenReturn(sampleResponse);

        mockMvc.perform(post("/api/v1/rental-units")
                        .with(user(authenticatedUser))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "businessId":     10,
                                    "name":           "Unit A",
                                    "description":    "Standard toilet",
                                    "pricePerDay":    150.00,
                                    "capacity":       1,
                                    "rentalUnitType": "STANDARD_TOILET"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(100))
                .andExpect(jsonPath("$.name").value("Unit A"))
                .andExpect(jsonPath("$.status").value("AVAILABLE"))
                .andExpect(jsonPath("$.businessId").value(10));

        verify(rentalUnitService).createRentalUnit(any(), eq(1L));
    }

    @Test
    void createRentalUnit_returns400_whenNameIsMissing() throws Exception {
        mockMvc.perform(post("/api/v1/rental-units")
                        .with(user(authenticatedUser))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "businessId":     10,
                                    "name":           "",
                                    "pricePerDay":    150.00,
                                    "capacity":       1,
                                    "rentalUnitType": "STANDARD_TOILET"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.name").exists());

        verify(rentalUnitService, never()).createRentalUnit(any(), any());
    }

    @Test
    void createRentalUnit_returns400_whenPriceIsZero() throws Exception {
        mockMvc.perform(post("/api/v1/rental-units")
                        .with(user(authenticatedUser))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "businessId":     10,
                                    "name":           "Unit A",
                                    "pricePerDay":    0.00,
                                    "capacity":       1,
                                    "rentalUnitType": "STANDARD_TOILET"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.pricePerDay").exists());
    }

    @Test
    void createRentalUnit_returns403_whenNotAuthenticated() throws Exception {
        // No .with(user(...)) — simulates a request with no JWT
        mockMvc.perform(post("/api/v1/rental-units")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "businessId":     10,
                                    "name":           "Unit A",
                                    "pricePerDay":    150.00,
                                    "capacity":       1,
                                    "rentalUnitType": "STANDARD_TOILET"
                                }
                                """))
                .andExpect(status().isForbidden());
    }

    // =========================================================
    // GET /api/v1/rental-units  (PUBLIC — no JWT needed)
    // =========================================================

    @Test
    void getRentalUnits_returns200_withList_whenBusinessIdProvided() throws Exception {
        when(rentalUnitService.getRentalUnitsByBusiness(10L)).thenReturn(List.of(sampleResponse));

        // No .with(user(...)) — public endpoint
        mockMvc.perform(get("/api/v1/rental-units").param("businessId", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].name").value("Unit A"));
    }

    @Test
    void getRentalUnits_returns200_withEmptyList_whenNoBusinessIdProvided() throws Exception {
        // No businessId param → controller returns empty list without calling service
        mockMvc.perform(get("/api/v1/rental-units"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));

        verify(rentalUnitService, never()).getRentalUnitsByBusiness(any());
    }

    // =========================================================
    // GET /api/v1/rental-units/{id}  (PUBLIC — no JWT needed)
    // =========================================================

    @Test
    void getRentalUnitById_returns200_whenFound() throws Exception {
        when(rentalUnitService.getRentalUnitById(100L)).thenReturn(sampleResponse);

        // No .with(user(...)) — public endpoint
        mockMvc.perform(get("/api/v1/rental-units/100"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(100))
                .andExpect(jsonPath("$.rentalUnitType").value("STANDARD_TOILET"));
    }

    @Test
    void getRentalUnitById_returns404_whenNotFound() throws Exception {
        when(rentalUnitService.getRentalUnitById(999L))
                .thenThrow(new ResourceNotFoundException("Rental unit not found with id: 999"));

        mockMvc.perform(get("/api/v1/rental-units/999"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").exists());
    }

    // =========================================================
    // PUT /api/v1/rental-units/{id}  (JWT required)
    // =========================================================

    @Test
    void updateRentalUnit_returns200_whenOwnerUpdates() throws Exception {
        RentalUnitResponse updated = new RentalUnitResponse(
                100L, "Updated Unit", "New desc",
                new BigDecimal("200.00"), 2,
                RentalUnitType.VIP_TOILET, RentalUnitStatus.UNDER_MAINTENANCE,
                10L, LocalDateTime.now(), LocalDateTime.now()
        );
        when(rentalUnitService.updateRentalUnit(eq(100L), any(), eq(1L))).thenReturn(updated);

        mockMvc.perform(put("/api/v1/rental-units/100")
                        .with(user(authenticatedUser))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "name":           "Updated Unit",
                                    "description":    "New desc",
                                    "pricePerDay":    200.00,
                                    "capacity":       2,
                                    "rentalUnitType": "VIP_TOILET",
                                    "status":         "UNDER_MAINTENANCE"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Updated Unit"))
                .andExpect(jsonPath("$.status").value("UNDER_MAINTENANCE"));
    }

    @Test
    void updateRentalUnit_returns403_whenOwnerMismatch() throws Exception {
        when(rentalUnitService.updateRentalUnit(eq(100L), any(), eq(1L)))
                .thenThrow(new UnauthorizedException("You do not have permission to modify this rental unit"));

        mockMvc.perform(put("/api/v1/rental-units/100")
                        .with(user(authenticatedUser))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "name":           "Hack",
                                    "pricePerDay":    1.00,
                                    "capacity":       1,
                                    "rentalUnitType": "STANDARD_TOILET",
                                    "status":         "AVAILABLE"
                                }
                                """))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error").exists());
    }

    // =========================================================
    // DELETE /api/v1/rental-units/{id}  (JWT required)
    // =========================================================

    @Test
    void deleteRentalUnit_returns204_whenOwnerDeletes() throws Exception {
        doNothing().when(rentalUnitService).deleteRentalUnit(100L, 1L);

        mockMvc.perform(delete("/api/v1/rental-units/100")
                        .with(user(authenticatedUser)))
                .andExpect(status().isNoContent());

        verify(rentalUnitService).deleteRentalUnit(100L, 1L);
    }

    @Test
    void deleteRentalUnit_returns403_whenNotAuthenticated() throws Exception {
        // No .with(user(...)) — unauthenticated DELETE should be rejected
        mockMvc.perform(delete("/api/v1/rental-units/100"))
                .andExpect(status().isForbidden());

        verify(rentalUnitService, never()).deleteRentalUnit(any(), any());
    }
}
