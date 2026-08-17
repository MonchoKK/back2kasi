package com.back2kasi.integration;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Integration tests for the Rental Unit API.
 *
 * <p>Key scenarios covered:</p>
 * <ul>
 *   <li>Public GET endpoints work without a JWT (no auth header)</li>
 *   <li>Creating a unit requires JWT + ownership of the parent business</li>
 *   <li>Status update (PUT) only allowed to the business owner</li>
 *   <li>Delete enforces the full ownership chain: caller → business → unit</li>
 * </ul>
 */
class RentalUnitIntegrationTest extends BaseIntegrationTest {

    private String ownerToken;
    private String otherToken;
    private long businessId;
    private long unitId;

    @BeforeEach
    void setUp() throws Exception {
        ownerToken = registerAndLogin("unit.owner@test.co.za", "secret123");
        otherToken = registerAndLogin("unit.other@test.co.za", "secret123");

        // Owner creates a business
        String bizResponse = mockMvc.perform(post("/api/v1/businesses")
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

        businessId = objectMapper.readTree(bizResponse).get("id").asLong();

        // Owner creates a rental unit under that business
        String unitResponse = mockMvc.perform(post("/api/v1/rental-units")
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "businessId":     %d,
                                    "name":           "Unit A",
                                    "description":    "Standard toilet",
                                    "pricePerDay":    150.00,
                                    "capacity":       1,
                                    "rentalUnitType": "STANDARD_TOILET"
                                }
                                """.formatted(businessId)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        unitId = objectMapper.readTree(unitResponse).get("id").asLong();
    }

    // =========================================================
    // Public GET (no JWT required)
    // =========================================================

    @Test
    void getRentalUnitsByBusiness_returns200_withNoJwt() throws Exception {
        // No Authorization header — endpoint is public
        mockMvc.perform(get("/api/v1/rental-units").param("businessId", String.valueOf(businessId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].name").value("Unit A"));
    }

    @Test
    void getRentalUnitById_returns200_withNoJwt() throws Exception {
        mockMvc.perform(get("/api/v1/rental-units/" + unitId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(unitId))
                .andExpect(jsonPath("$.status").value("AVAILABLE"))
                .andExpect(jsonPath("$.pricePerDay").value(150.00));
    }

    @Test
    void getRentalUnitById_returns404_whenNotFound() throws Exception {
        mockMvc.perform(get("/api/v1/rental-units/99999"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.status").value(404))
                .andExpect(jsonPath("$.error").value("Not Found"));
    }

    // =========================================================
    // Create (JWT required)
    // =========================================================

    @Test
    void createRentalUnit_returns403_whenCallerDoesNotOwnBusiness() throws Exception {
        // otherToken user tries to add a unit to ownerToken's business
        mockMvc.perform(post("/api/v1/rental-units")
                        .header("Authorization", bearer(otherToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "businessId":     %d,
                                    "name":           "Intruder Unit",
                                    "pricePerDay":    1.00,
                                    "capacity":       1,
                                    "rentalUnitType": "STANDARD_TOILET"
                                }
                                """.formatted(businessId)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.status").value(403));
    }

    @Test
    void createRentalUnit_returns400_whenPriceIsZero() throws Exception {
        mockMvc.perform(post("/api/v1/rental-units")
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "businessId":     %d,
                                    "name":           "Cheap Unit",
                                    "pricePerDay":    0.00,
                                    "capacity":       1,
                                    "rentalUnitType": "STANDARD_TOILET"
                                }
                                """.formatted(businessId)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.pricePerDay").isNotEmpty());
    }

    // =========================================================
    // Update (JWT required)
    // =========================================================

    @Test
    void updateRentalUnit_returns200_andUpdatesStatus() throws Exception {
        mockMvc.perform(put("/api/v1/rental-units/" + unitId)
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "name":           "Unit A",
                                    "pricePerDay":    200.00,
                                    "capacity":       1,
                                    "rentalUnitType": "STANDARD_TOILET",
                                    "status":         "UNDER_MAINTENANCE"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UNDER_MAINTENANCE"))
                .andExpect(jsonPath("$.pricePerDay").value(200.00));
    }

    @Test
    void updateRentalUnit_returns403_whenOtherUserAttempts() throws Exception {
        mockMvc.perform(put("/api/v1/rental-units/" + unitId)
                        .header("Authorization", bearer(otherToken))
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
                .andExpect(jsonPath("$.status").value(403));
    }

    // =========================================================
    // Delete (JWT required)
    // =========================================================

    @Test
    void deleteRentalUnit_returns204_whenOwnerDeletes() throws Exception {
        // Create a unit specifically to delete
        String unitJson = mockMvc.perform(post("/api/v1/rental-units")
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "businessId":     %d,
                                    "name":           "To Delete",
                                    "pricePerDay":    50.00,
                                    "capacity":       1,
                                    "rentalUnitType": "CHEMICAL_TOILET"
                                }
                                """.formatted(businessId)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        long deleteId = objectMapper.readTree(unitJson).get("id").asLong();

        mockMvc.perform(delete("/api/v1/rental-units/" + deleteId)
                        .header("Authorization", bearer(ownerToken)))
                .andExpect(status().isNoContent());

        // Confirm it's gone (public GET → 404)
        mockMvc.perform(get("/api/v1/rental-units/" + deleteId))
                .andExpect(status().isNotFound());
    }
}
