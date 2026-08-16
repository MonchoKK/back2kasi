package com.back2kasi.booking.service;

import com.back2kasi.booking.dto.BookingResponse;
import com.back2kasi.booking.dto.CreateBookingRequest;
import com.back2kasi.booking.dto.UpdateBookingStatusRequest;

import java.util.List;

/**
 * Contract for all booking operations.
 *
 * <p>All operations require an authenticated caller — there are no public
 * endpoints in the booking module. The {@code callerId} parameter is the
 * primary key of the authenticated user; implementations use it to enforce
 * both ownership and role-based access rules.</p>
 *
 * <p>Role model:</p>
 * <ul>
 *   <li><strong>Customer</strong> — the user who created the booking. May create,
 *       view their own bookings, and cancel a {@code PENDING} booking.</li>
 *   <li><strong>Business owner</strong> — the user who owns the rental unit's
 *       parent business. May view bookings on their units and transition status
 *       to {@code CONFIRMED}, {@code COMPLETED}, or {@code CANCELLED}.</li>
 * </ul>
 */
public interface BookingService {

    /**
     * Create a new booking for a rental unit.
     *
     * <p>The booking is created in {@link com.back2kasi.booking.entity.BookingStatus#PENDING}
     * state. The total price is computed and locked in at creation time.</p>
     *
     * @param request    the validated creation payload (includes {@code rentalUnitId} and date range)
     * @param customerId the ID of the authenticated user making the booking
     * @return the created booking as a response DTO
     * @throws com.back2kasi.common.exception.ResourceNotFoundException if the rental unit does not exist
     * @throws IllegalStateException                                     if the date range is invalid (end before start)
     *                                                                   or overlaps an existing confirmed booking
     */
    BookingResponse createBooking(CreateBookingRequest request, Long customerId);

    /**
     * Retrieve a single booking by its ID.
     *
     * <p>Visibility is restricted: only the customer who made the booking, or the
     * business owner of the rental unit, may view it.</p>
     *
     * @param id       the primary key of the booking
     * @param callerId the ID of the authenticated user requesting the booking
     * @return the booking as a response DTO
     * @throws com.back2kasi.common.exception.ResourceNotFoundException if no booking exists with the given ID
     * @throws com.back2kasi.common.exception.UnauthorizedException     if the caller is neither the customer
     *                                                                   nor the unit's business owner
     */
    BookingResponse getBookingById(Long id, Long callerId);

    /**
     * Retrieve all bookings made by the authenticated customer.
     *
     * @param customerId the ID of the authenticated customer
     * @return list of bookings; empty list if the customer has made none
     */
    List<BookingResponse> getBookingsByCustomer(Long customerId);

    /**
     * Retrieve all bookings for a specific rental unit, enforcing ownership.
     *
     * @param rentalUnitId the primary key of the rental unit
     * @param ownerId      the ID of the authenticated user (must be the business owner)
     * @return list of bookings for the given unit
     * @throws com.back2kasi.common.exception.ResourceNotFoundException if the rental unit does not exist
     * @throws com.back2kasi.common.exception.UnauthorizedException     if the caller does not own the unit's parent business
     */
    List<BookingResponse> getBookingsByRentalUnit(Long rentalUnitId, Long ownerId);

    /**
     * Transition a booking to a new status, enforcing role-based access rules.
     *
     * <p>Permitted transitions:</p>
     * <ul>
     *   <li>Owner → {@code CONFIRMED}: flips the rental unit to {@code RENTED}.</li>
     *   <li>Owner → {@code COMPLETED}: flips the rental unit back to {@code AVAILABLE}.</li>
     *   <li>Owner or Customer → {@code CANCELLED}: flips the rental unit back to
     *       {@code AVAILABLE} (only if not already {@code COMPLETED}).</li>
     * </ul>
     *
     * @param id      the primary key of the booking to update
     * @param request the new status
     * @param callerId the ID of the authenticated user making the request
     * @return the updated booking as a response DTO
     * @throws com.back2kasi.common.exception.ResourceNotFoundException if the booking does not exist
     * @throws com.back2kasi.common.exception.UnauthorizedException     if the caller lacks permission for the requested transition
     * @throws IllegalStateException                                     if the requested transition is not valid
     *                                                                   from the current status
     */
    BookingResponse updateBookingStatus(Long id, UpdateBookingStatusRequest request, Long callerId);
}
