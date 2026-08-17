package com.back2kasi.integration;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Integration tests for the Business CRUD API.
 *
 * <p>Tests the full ownership enforcement chain across real HTTP calls:</p>
 * <ul>
 *   <li>Creating a business requires a valid JWT</li>
 *   <li>Only the owner can view, update, or delete their business</li>
 *   <li>Another authenticated user receives 403 on someone else's business</li>
 *   <li>Non-existent resource returns 404 with ApiError</li>
 * </ul>
 */
class BusinessIntegrationTest extends BaseIntegrationTest {

    private String ownerToken;
    private String otherToken;
    private long businessId;

    @BeforeEach
    void setUp() throws Exception {
        ownerToken = registerAndLogin("biz.owner@test.co.za", "secret123");
        otherToken = registerAndLogin("biz.other@test.co.za", "secret123");

        // Create a business owned by ownerToken user
        String createBody = """
                {
                    "name":         "Kasi Toilets",
                    "description":  "Portable toilet hire",
                    "address":      "123 Soweto Rd",
                    "phoneNumber":  "+27711234567",
                    "businessType": "TOILET_RENTAL"
                }
                """;
        String response = mockMvc.perform(post("/api/v1/businesses")
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(createBody))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        businessId = objectMapper.readTree(response).get("id").asLong();
    }

    // =========================================================
    // Create
    // =========================================================

    @Test
    void createBusiness_returns201_whenValidRequest() throws Exception {
        mockMvc.perform(post("/api/v1/businesses")
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "name":         "Cold Kings",
                                    "address":      "456 Alex Rd",
                                    "phoneNumber":  "+27722222222",
                                    "businessType": "COLD_ROOM_RENTAL"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.name").value("Cold Kings"))
                .andExpect(jsonPath("$.ownerId").isNumber());
    }

    @Test
    void createBusiness_returns403_whenNoJwt() throws Exception {
        mockMvc.perform(post("/api/v1/businesses")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                { "name": "No Auth", "address": "X", "phoneNumber": "+1",
                                  "businessType": "TOILET_RENTAL" }
                                """))
                .andExpect(status().isForbidden());
    }

    // =========================================================
    // Read
    // =========================================================

    @Test
    void getMyBusinesses_returns200_withOwnerBusinesses() throws Exception {
        mockMvc.perform(get("/api/v1/businesses")
                        .header("Authorization", bearer(ownerToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].name").value("Kasi Toilets"));
    }

    @Test
    void getBusinessById_returns200_whenOwnerRequests() throws Exception {
        mockMvc.perform(get("/api/v1/businesses/" + businessId)
                        .header("Authorization", bearer(ownerToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(businessId))
                .andExpect(jsonPath("$.name").value("Kasi Toilets"));
    }

    @Test
    void getBusinessById_returns403_whenOtherUserRequests() throws Exception {
        mockMvc.perform(get("/api/v1/businesses/" + businessId)
                        .header("Authorization", bearer(otherToken)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.status").value(403))
                .andExpect(jsonPath("$.error").value("Forbidden"))
                .andExpect(jsonPath("$.message").isNotEmpty());
    }

    @Test
    void getBusinessById_returns404_whenNotFound() throws Exception {
        mockMvc.perform(get("/api/v1/businesses/99999")
                        .header("Authorization", bearer(ownerToken)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.status").value(404))
                .andExpect(jsonPath("$.error").value("Not Found"));
    }

    // =========================================================
    // Update
    // =========================================================

    @Test
    void updateBusiness_returns200_whenOwnerUpdates() throws Exception {
        mockMvc.perform(put("/api/v1/businesses/" + businessId)
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "name":         "Kasi Toilets Updated",
                                    "address":      "999 New Rd",
                                    "phoneNumber":  "+27700000001",
                                    "businessType": "TOILET_RENTAL"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Kasi Toilets Updated"));
    }

    @Test
    void updateBusiness_returns403_whenOtherUserAttempts() throws Exception {
        mockMvc.perform(put("/api/v1/businesses/" + businessId)
                        .header("Authorization", bearer(otherToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "name":         "Hack",
                                    "address":      "X",
                                    "phoneNumber":  "+1",
                                    "businessType": "TOILET_RENTAL"
                                }
                                """))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.status").value(403));
    }

    // =========================================================
    // Delete
    // =========================================================

    @Test
    void deleteBusiness_returns204_whenOwnerDeletes() throws Exception {
        // Create a separate business to delete (setUp business is used by other tests)
        String response = mockMvc.perform(post("/api/v1/businesses")
                        .header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "name": "To Delete", "address": "X",
                                    "phoneNumber": "+27700000002",
                                    "businessType": "COLD_ROOM_RENTAL"
                                }
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        long deleteId = objectMapper.readTree(response).get("id").asLong();

        mockMvc.perform(delete("/api/v1/businesses/" + deleteId)
                        .header("Authorization", bearer(ownerToken)))
                .andExpect(status().isNoContent());

        // Confirm it's gone
        mockMvc.perform(get("/api/v1/businesses/" + deleteId)
                        .header("Authorization", bearer(ownerToken)))
                .andExpect(status().isNotFound());
    }

    @Test
    void deleteBusiness_returns403_whenOtherUserAttempts() throws Exception {
        mockMvc.perform(delete("/api/v1/businesses/" + businessId)
                        .header("Authorization", bearer(otherToken)))
                .andExpect(status().isForbidden());
    }
}
