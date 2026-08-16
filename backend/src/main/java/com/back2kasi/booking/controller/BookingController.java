package com.back2kasi.booking.controller;

import com.back2kasi.booking.dto.BookingResponse;
import com.back2kasi.booking.dto.CreateBookingRequest;
import com.back2kasi.booking.dto.UpdateBookingStatusRequest;
import com.back2kasi.booking.service.BookingService;
import com.back2kasi.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * REST controller for booking endpoints.
 *
 * <h2>Access model</h2>
 * <p>All booking endpoints require a valid JWT — there are no public
 * endpoints in this module. The authenticated user is injected via
 * {@link AuthenticationPrincipal} on every handler.</p>
 *
 * <p>Role-based business rules (who can confirm, cancel, etc.) are enforced
 * in the service layer — the controller only delegates after extracting the
 * caller's primary key from the security context.</p>
 *
 * <p>URL follows {@code DEVELOPMENT_STANDARDS.md}:</p>
 * <ul>
 *   <li>Prefix: {@code /api/v1/}</li>
 *   <li>Kebab-case plural noun: {@code bookings}</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/v1/bookings")
@RequiredArgsConstructor
public class BookingController {

    private final BookingService bookingService;

    // =========================================================
    // POST /api/v1/bookings  (JWT required — any authenticated user)
    // =========================================================

    /**
     * Create a new booking for a rental unit.
     *
     * <p>The authenticated user becomes the customer of the booking.
     * The booking is created in {@code PENDING} state.</p>
     *
     * @param request     validated creation payload
     * @param currentUser the authenticated user (from SecurityContext)
     * @return {@code 201 Created} with the new {@link BookingResponse}
     */
    @PostMapping
    public ResponseEntity<BookingResponse> createBooking(
            @Valid @RequestBody CreateBookingRequest request,
            @AuthenticationPrincipal User currentUser) {

        BookingResponse response = bookingService.createBooking(request, currentUser.getId());
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    // =========================================================
    // GET /api/v1/bookings/{id}  (JWT required — customer or owner)
    // =========================================================

    /**
     * Retrieve a specific booking by its ID.
     *
     * <p>Only the customer who made the booking, or the business owner of the
     * rental unit, may view it. Returns {@code 403 Forbidden} for any other
     * authenticated user.</p>
     *
     * @param id          the booking primary key
     * @param currentUser the authenticated user
     * @return {@code 200 OK} with the {@link BookingResponse}
     */
    @GetMapping("/{id}")
    public ResponseEntity<BookingResponse> getBookingById(
            @PathVariable Long id,
            @AuthenticationPrincipal User currentUser) {

        return ResponseEntity.ok(bookingService.getBookingById(id, currentUser.getId()));
    }

    // =========================================================
    // GET /api/v1/bookings/my  (JWT required — customer)
    // =========================================================

    /**
     * Retrieve all bookings made by the currently authenticated user.
     *
     * <p>Returns an empty list if the user has made no bookings. No ownership
     * check needed — the caller can only see their own bookings.</p>
     *
     * @param currentUser the authenticated user
     * @return {@code 200 OK} with the list of {@link BookingResponse}
     */
    @GetMapping("/my")
    public ResponseEntity<List<BookingResponse>> getMyBookings(
            @AuthenticationPrincipal User currentUser) {

        return ResponseEntity.ok(bookingService.getBookingsByCustomer(currentUser.getId()));
    }

    // =========================================================
    // GET /api/v1/bookings/unit/{unitId}  (JWT required — owner)
    // =========================================================

    /**
     * Retrieve all bookings for a specific rental unit.
     *
     * <p>The authenticated user must be the business owner of the rental unit.
     * Returns {@code 403 Forbidden} if they are not.</p>
     *
     * @param unitId      the primary key of the rental unit
     * @param currentUser the authenticated user (must be the business owner)
     * @return {@code 200 OK} with the list of {@link BookingResponse}
     */
    @GetMapping("/unit/{unitId}")
    public ResponseEntity<List<BookingResponse>> getBookingsByUnit(
            @PathVariable Long unitId,
            @AuthenticationPrincipal User currentUser) {

        return ResponseEntity.ok(bookingService.getBookingsByRentalUnit(unitId, currentUser.getId()));
    }

    // =========================================================
    // PATCH /api/v1/bookings/{id}/status  (JWT required — owner or customer)
    // =========================================================

    /**
     * Update the lifecycle status of a booking.
     *
     * <p>Permitted transitions depend on the caller's role (enforced in the
     * service layer). See {@link BookingService#updateBookingStatus} for the
     * full transition table.</p>
     *
     * @param id          the primary key of the booking to update
     * @param request     the new status
     * @param currentUser the authenticated user
     * @return {@code 200 OK} with the updated {@link BookingResponse}
     */
    @PatchMapping("/{id}/status")
    public ResponseEntity<BookingResponse> updateBookingStatus(
            @PathVariable Long id,
            @Valid @RequestBody UpdateBookingStatusRequest request,
            @AuthenticationPrincipal User currentUser) {

        return ResponseEntity.ok(bookingService.updateBookingStatus(id, request, currentUser.getId()));
    }
}
