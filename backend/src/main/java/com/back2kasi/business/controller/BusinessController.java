package com.back2kasi.business.controller;

import com.back2kasi.business.dto.BusinessResponse;
import com.back2kasi.business.dto.CreateBusinessRequest;
import com.back2kasi.business.dto.UpdateBusinessRequest;
import com.back2kasi.business.service.BusinessService;
import com.back2kasi.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * REST controller for all business-related endpoints.
 *
 * <p>All routes under {@code /api/v1/businesses} require a valid JWT — this is
 * enforced globally by the {@code SecurityFilterChain} in {@code SecurityConfig}
 * ({@code anyRequest().authenticated()}) without any extra annotation here.</p>
 *
 * <p>The currently authenticated user is injected by Spring Security via
 * {@link AuthenticationPrincipal}. Because {@link User} implements
 * {@code UserDetails} and is stored directly in the {@code SecurityContext}
 * by {@code JwtAuthenticationFilter}, we can cast it here safely and extract
 * the owner's {@code id} to pass to the service layer.</p>
 *
 * <p>URL design follows the REST standards in {@code DEVELOPMENT_STANDARDS.md}:</p>
 * <ul>
 *   <li>Prefix: {@code /api/v1/}</li>
 *   <li>Plural noun: {@code businesses}</li>
 *   <li>Kebab-case for multi-word resources (single word here)</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/v1/businesses")
@RequiredArgsConstructor
public class BusinessController {

    private final BusinessService businessService;

    // =========================================================
    // POST /api/v1/businesses
    // =========================================================

    /**
     * Register a new business owned by the currently authenticated user.
     *
     * <p>{@code @Valid} triggers Bean Validation on {@link CreateBusinessRequest}
     * before this method body runs. If validation fails, the
     * {@code GlobalExceptionHandler} returns a {@code 400 Bad Request}
     * with field-level error messages.</p>
     *
     * @param request       the validated creation payload from the request body
     * @param currentUser   the authenticated user (injected from the SecurityContext)
     * @return {@code 201 Created} with the newly created {@link BusinessResponse}
     */
    @PostMapping
    public ResponseEntity<BusinessResponse> createBusiness(
            @Valid @RequestBody CreateBusinessRequest request,
            @AuthenticationPrincipal User currentUser) {

        BusinessResponse response = businessService.createBusiness(request, currentUser.getId());
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    // =========================================================
    // GET /api/v1/businesses
    // =========================================================

    /**
     * Retrieve all businesses owned by the currently authenticated user.
     *
     * <p>This endpoint is scoped to the caller — it never returns businesses
     * belonging to other users.</p>
     *
     * @param currentUser the authenticated user
     * @return {@code 200 OK} with the list of the caller's businesses (may be empty)
     */
    @GetMapping
    public ResponseEntity<List<BusinessResponse>> getMyBusinesses(
            @AuthenticationPrincipal User currentUser) {

        List<BusinessResponse> businesses = businessService.getMyBusinesses(currentUser.getId());
        return ResponseEntity.ok(businesses);
    }

    // =========================================================
    // GET /api/v1/businesses/{id}
    // =========================================================

    /**
     * Retrieve a specific business by ID, enforcing ownership.
     *
     * <p>Returns {@code 404 Not Found} if the business does not exist, or
     * {@code 403 Forbidden} if it belongs to a different user.</p>
     *
     * @param id          the business primary key from the URL path
     * @param currentUser the authenticated user
     * @return {@code 200 OK} with the {@link BusinessResponse}
     */
    @GetMapping("/{id}")
    public ResponseEntity<BusinessResponse> getBusinessById(
            @PathVariable Long id,
            @AuthenticationPrincipal User currentUser) {

        BusinessResponse response = businessService.getBusinessById(id, currentUser.getId());
        return ResponseEntity.ok(response);
    }

    // =========================================================
    // PUT /api/v1/businesses/{id}
    // =========================================================

    /**
     * Update all mutable fields of an existing business, enforcing ownership.
     *
     * <p>Returns {@code 404 Not Found} if the business does not exist, or
     * {@code 403 Forbidden} if it belongs to a different user.</p>
     *
     * @param id          the primary key of the business to update
     * @param request     the validated update payload
     * @param currentUser the authenticated user
     * @return {@code 200 OK} with the updated {@link BusinessResponse}
     */
    @PutMapping("/{id}")
    public ResponseEntity<BusinessResponse> updateBusiness(
            @PathVariable Long id,
            @Valid @RequestBody UpdateBusinessRequest request,
            @AuthenticationPrincipal User currentUser) {

        BusinessResponse response = businessService.updateBusiness(id, request, currentUser.getId());
        return ResponseEntity.ok(response);
    }

    // =========================================================
    // DELETE /api/v1/businesses/{id}
    // =========================================================

    /**
     * Permanently delete a business, enforcing ownership.
     *
     * <p>Returns {@code 404 Not Found} if the business does not exist, or
     * {@code 403 Forbidden} if it belongs to a different user.</p>
     *
     * @param id          the primary key of the business to delete
     * @param currentUser the authenticated user
     * @return {@code 204 No Content} — the resource no longer exists
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteBusiness(
            @PathVariable Long id,
            @AuthenticationPrincipal User currentUser) {

        businessService.deleteBusiness(id, currentUser.getId());
        return ResponseEntity.noContent().build();
    }
}
