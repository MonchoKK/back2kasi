package com.back2kasi.business.controller;

import com.back2kasi.auth.filter.JwtAuthenticationFilter;
import com.back2kasi.auth.service.JwtService;
import com.back2kasi.business.dto.BusinessResponse;
import com.back2kasi.business.entity.BusinessType;
import com.back2kasi.business.service.BusinessService;
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

import java.time.LocalDateTime;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * MVC slice test for {@link BusinessController}.
 *
 * <p>{@code @WebMvcTest} loads only the Spring MVC layer — no real database,
 * no full application context. The service is replaced with a Mockito mock.
 * This makes tests fast and focused on HTTP concerns: routing, serialisation,
 * validation, and status codes.</p>
 *
 * <h2>Authentication in @WebMvcTest</h2>
 * <p>The real {@link SecurityConfig} is imported so that the full security filter
 * chain runs — exactly as in production. To satisfy {@code anyRequest().authenticated()}
 * without sending a real JWT, each request uses
 * {@code SecurityMockMvcRequestPostProcessors.user(authenticatedUser)}.
 * This request post-processor injects our custom {@link User} entity directly
 * into the {@code SecurityContext} for that single request, bypassing the JWT
 * filter while preserving the real security rules for all other aspects.</p>
 *
 * <p>{@code @AuthenticationPrincipal} in the controller then resolves to our
 * test {@link User} instance, so {@code currentUser.getId()} returns {@code 1L}
 * as expected.</p>
 */
@WebMvcTest(BusinessController.class)
@Import({SecurityConfig.class, JwtAuthenticationFilter.class})
class BusinessControllerTest {

    @Autowired
    private MockMvc mockMvc;

    /** Mock satisfies BusinessController's dependency without real business logic. */
    @MockBean
    private BusinessService businessService;

    /**
     * Required because {@link JwtAuthenticationFilter} depends on {@link UserService}
     * (which implements {@code UserDetailsService}). The filter is in the imported chain
     * and must have all its dependencies satisfied. It does not run for any request in
     * these tests because we use the {@code .with(user(...))} post-processor instead
     * of an {@code Authorization} header.
     */
    @MockBean
    private UserService userService;

    /** Required by {@link JwtAuthenticationFilter} to validate tokens. */
    @MockBean
    private JwtService jwtService;

    /** The authenticated user principal used across all test requests. */
    private User authenticatedUser;

    /** A representative BusinessResponse returned by the mock service. */
    private BusinessResponse sampleResponse;

    @BeforeEach
    void setUp() {
        authenticatedUser = User.builder()
                .id(1L)
                .firstName("Kabelo")
                .lastName("Kekana")
                .email("kabelo@back2kasi.co.za")
                .password("hashed")
                .phoneNumber("+27712345678")
                .role(Role.USER)
                .build();

        sampleResponse = new BusinessResponse(
                10L, "Kasi Toilets", "Portable toilet hire",
                "123 Soweto Rd", "+27711234567",
                BusinessType.TOILET_RENTAL, 1L,
                LocalDateTime.now(), LocalDateTime.now()
        );
    }

    // =========================================================
    // POST /api/v1/businesses
    // =========================================================

    /**
     * A fully valid creation request must return 201 Created with the new
     * business data in the response body.
     */
    @Test
    void createBusiness_returns201_whenRequestIsValid() throws Exception {
        when(businessService.createBusiness(any(), eq(1L))).thenReturn(sampleResponse);

        mockMvc.perform(post("/api/v1/businesses")
                        .with(user(authenticatedUser))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "name":         "Kasi Toilets",
                                    "description":  "Portable toilet hire",
                                    "address":      "123 Soweto Rd",
                                    "phoneNumber":  "+27711234567",
                                    "businessType": "TOILET_RENTAL"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(10))
                .andExpect(jsonPath("$.name").value("Kasi Toilets"))
                .andExpect(jsonPath("$.businessType").value("TOILET_RENTAL"))
                .andExpect(jsonPath("$.ownerId").value(1));

        verify(businessService).createBusiness(any(), eq(1L));
    }

    /**
     * A request with a blank name must fail Bean Validation and return
     * 400 Bad Request — the service is never called.
     */
    @Test
    void createBusiness_returns400_whenNameIsMissing() throws Exception {
        mockMvc.perform(post("/api/v1/businesses")
                        .with(user(authenticatedUser))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "name":         "",
                                    "address":      "123 Soweto Rd",
                                    "phoneNumber":  "+27711234567",
                                    "businessType": "TOILET_RENTAL"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.name").exists());

        verify(businessService, never()).createBusiness(any(), any());
    }

    /**
     * A request without a businessType field must fail {@code @NotNull}
     * validation and return 400 Bad Request.
     */
    @Test
    void createBusiness_returns400_whenBusinessTypeIsNull() throws Exception {
        mockMvc.perform(post("/api/v1/businesses")
                        .with(user(authenticatedUser))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "name":        "Kasi Toilets",
                                    "address":     "123 Soweto Rd",
                                    "phoneNumber": "+27711234567"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.businessType").exists());
    }

    // =========================================================
    // GET /api/v1/businesses
    // =========================================================

    /**
     * An authenticated owner with two businesses must receive a 200 OK
     * with both items in the response array.
     */
    @Test
    void getMyBusinesses_returns200_withListOfBusinesses() throws Exception {
        BusinessResponse second = new BusinessResponse(
                11L, "Cold Kings", null, "456 Alex Rd",
                "+27722222222", BusinessType.COLD_ROOM_RENTAL,
                1L, LocalDateTime.now(), LocalDateTime.now()
        );
        when(businessService.getMyBusinesses(1L)).thenReturn(List.of(sampleResponse, second));

        mockMvc.perform(get("/api/v1/businesses")
                        .with(user(authenticatedUser)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].name").value("Kasi Toilets"))
                .andExpect(jsonPath("$[1].name").value("Cold Kings"));
    }

    /**
     * An owner with no businesses must receive 200 OK with an empty JSON array.
     */
    @Test
    void getMyBusinesses_returns200_withEmptyList_whenOwnerHasNone() throws Exception {
        when(businessService.getMyBusinesses(1L)).thenReturn(List.of());

        mockMvc.perform(get("/api/v1/businesses")
                        .with(user(authenticatedUser)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }

    // =========================================================
    // GET /api/v1/businesses/{id}
    // =========================================================

    /**
     * Fetching an owned business by its ID must return 200 OK with its data.
     */
    @Test
    void getBusinessById_returns200_whenFound() throws Exception {
        when(businessService.getBusinessById(10L, 1L)).thenReturn(sampleResponse);

        mockMvc.perform(get("/api/v1/businesses/10")
                        .with(user(authenticatedUser)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(10))
                .andExpect(jsonPath("$.name").value("Kasi Toilets"));
    }

    /**
     * Fetching a non-existent business must return 404 Not Found with an
     * error message in the response body.
     */
    @Test
    void getBusinessById_returns404_whenNotFound() throws Exception {
        when(businessService.getBusinessById(999L, 1L))
                .thenThrow(new ResourceNotFoundException("Business not found with id: 999"));

        mockMvc.perform(get("/api/v1/businesses/999")
                        .with(user(authenticatedUser)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").exists());
    }

    /**
     * Fetching a business owned by a different user must return 403 Forbidden.
     */
    @Test
    void getBusinessById_returns403_whenOwnerMismatch() throws Exception {
        when(businessService.getBusinessById(10L, 1L))
                .thenThrow(new UnauthorizedException("You do not have permission to access this business"));

        mockMvc.perform(get("/api/v1/businesses/10")
                        .with(user(authenticatedUser)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error").exists());
    }

    // =========================================================
    // PUT /api/v1/businesses/{id}
    // =========================================================

    /**
     * A valid update request from the owner must return 200 OK with the
     * updated business data.
     */
    @Test
    void updateBusiness_returns200_whenOwnerUpdates() throws Exception {
        BusinessResponse updated = new BusinessResponse(
                10L, "Updated Name", "New desc", "999 New St",
                "+27700000001", BusinessType.COLD_ROOM_RENTAL,
                1L, LocalDateTime.now(), LocalDateTime.now()
        );
        when(businessService.updateBusiness(eq(10L), any(), eq(1L))).thenReturn(updated);

        mockMvc.perform(put("/api/v1/businesses/10")
                        .with(user(authenticatedUser))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "name":         "Updated Name",
                                    "description":  "New desc",
                                    "address":      "999 New St",
                                    "phoneNumber":  "+27700000001",
                                    "businessType": "COLD_ROOM_RENTAL"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Updated Name"))
                .andExpect(jsonPath("$.businessType").value("COLD_ROOM_RENTAL"));
    }

    // =========================================================
    // DELETE /api/v1/businesses/{id}
    // =========================================================

    /**
     * Deleting an owned business must return 204 No Content and call the
     * service exactly once.
     */
    @Test
    void deleteBusiness_returns204_whenOwnerDeletes() throws Exception {
        doNothing().when(businessService).deleteBusiness(10L, 1L);

        mockMvc.perform(delete("/api/v1/businesses/10")
                        .with(user(authenticatedUser)))
                .andExpect(status().isNoContent());

        verify(businessService).deleteBusiness(10L, 1L);
    }

    /**
     * Attempting to delete a business belonging to a different user must
     * return 403 Forbidden with an error message.
     */
    @Test
    void deleteBusiness_returns403_whenOwnerMismatch() throws Exception {
        doThrow(new UnauthorizedException("You do not have permission to access this business"))
                .when(businessService).deleteBusiness(10L, 1L);

        mockMvc.perform(delete("/api/v1/businesses/10")
                        .with(user(authenticatedUser)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error").exists());
    }
}
