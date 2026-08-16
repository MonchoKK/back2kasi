package com.back2kasi.rentalunit.controller;

import com.back2kasi.rentalunit.dto.CreateRentalUnitRequest;
import com.back2kasi.rentalunit.dto.RentalUnitResponse;
import com.back2kasi.rentalunit.dto.UpdateRentalUnitRequest;
import com.back2kasi.rentalunit.service.RentalUnitService;
import com.back2kasi.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * REST controller for rental unit endpoints.
 *
 * <h2>Public vs Protected endpoints</h2>
 * <p>Unlike the business endpoints (all protected), rental units have a mixed
 * access model:</p>
 * <ul>
 *   <li><strong>Public</strong> ({@code GET}) — customers can browse available units
 *       before registering. No JWT required. Permitted in {@code SecurityConfig}.</li>
 *   <li><strong>Protected</strong> ({@code POST}, {@code PUT}, {@code DELETE}) —
 *       write operations require a valid JWT. The authenticated user is injected
 *       via {@link AuthenticationPrincipal}.</li>
 * </ul>
 *
 * <p>{@code @AuthenticationPrincipal} resolves to {@code null} on public endpoints
 * (no JWT in the request). The service layer does not receive {@code ownerId} for
 * public reads, so this is safe.</p>
 *
 * <p>URL follows {@code DEVELOPMENT_STANDARDS.md}:</p>
 * <ul>
 *   <li>Prefix: {@code /api/v1/}</li>
 *   <li>Kebab-case plural noun: {@code rental-units}</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/v1/rental-units")
@RequiredArgsConstructor
public class RentalUnitController {

    private final RentalUnitService rentalUnitService;

    // =========================================================
    // POST /api/v1/rental-units  (JWT required)
    // =========================================================

    /**
     * Create a new rental unit under a business owned by the authenticated user.
     *
     * @param request     validated creation payload — includes {@code businessId}
     * @param currentUser the authenticated user (from SecurityContext)
     * @return {@code 201 Created} with the new {@link RentalUnitResponse}
     */
    @PostMapping
    public ResponseEntity<RentalUnitResponse> createRentalUnit(
            @Valid @RequestBody CreateRentalUnitRequest request,
            @AuthenticationPrincipal User currentUser) {

        RentalUnitResponse response = rentalUnitService.createRentalUnit(request, currentUser.getId());
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    // =========================================================
    // GET /api/v1/rental-units  (PUBLIC)
    // =========================================================

    /**
     * List rental units, optionally filtered by business.
     *
     * <p>Accepts an optional {@code ?businessId=} query parameter. If omitted,
     * returns an empty list — a global unfiltered listing is not supported in the
     * MVP to avoid unbounded queries on a growing dataset.</p>
     *
     * <p>This endpoint is public — no JWT required.</p>
     *
     * @param businessId optional filter; if null, returns an empty list
     * @return {@code 200 OK} with the list of rental units
     */
    @GetMapping
    public ResponseEntity<List<RentalUnitResponse>> getRentalUnits(
            @RequestParam(required = false) Long businessId) {

        if (businessId == null) {
            return ResponseEntity.ok(List.of());
        }

        return ResponseEntity.ok(rentalUnitService.getRentalUnitsByBusiness(businessId));
    }

    // =========================================================
    // GET /api/v1/rental-units/{id}  (PUBLIC)
    // =========================================================

    /**
     * Retrieve a specific rental unit by its ID.
     *
     * <p>Public — no JWT required. Returns {@code 404 Not Found} if the unit
     * does not exist (handled by {@code GlobalExceptionHandler}).</p>
     *
     * @param id the rental unit primary key
     * @return {@code 200 OK} with the {@link RentalUnitResponse}
     */
    @GetMapping("/{id}")
    public ResponseEntity<RentalUnitResponse> getRentalUnitById(@PathVariable Long id) {
        return ResponseEntity.ok(rentalUnitService.getRentalUnitById(id));
    }

    // =========================================================
    // PUT /api/v1/rental-units/{id}  (JWT required)
    // =========================================================

    /**
     * Update all mutable fields of a rental unit, enforcing ownership.
     *
     * @param id          the primary key of the unit to update
     * @param request     the validated update payload
     * @param currentUser the authenticated user
     * @return {@code 200 OK} with the updated {@link RentalUnitResponse}
     */
    @PutMapping("/{id}")
    public ResponseEntity<RentalUnitResponse> updateRentalUnit(
            @PathVariable Long id,
            @Valid @RequestBody UpdateRentalUnitRequest request,
            @AuthenticationPrincipal User currentUser) {

        RentalUnitResponse response = rentalUnitService.updateRentalUnit(id, request, currentUser.getId());
        return ResponseEntity.ok(response);
    }

    // =========================================================
    // DELETE /api/v1/rental-units/{id}  (JWT required)
    // =========================================================

    /**
     * Permanently delete a rental unit, enforcing ownership.
     *
     * @param id          the primary key of the unit to delete
     * @param currentUser the authenticated user
     * @return {@code 204 No Content}
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteRentalUnit(
            @PathVariable Long id,
            @AuthenticationPrincipal User currentUser) {

        rentalUnitService.deleteRentalUnit(id, currentUser.getId());
        return ResponseEntity.noContent().build();
    }
}
