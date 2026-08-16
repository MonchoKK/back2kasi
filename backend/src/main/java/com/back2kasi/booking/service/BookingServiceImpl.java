package com.back2kasi.booking.service;

import com.back2kasi.booking.dto.BookingResponse;
import com.back2kasi.booking.dto.CreateBookingRequest;
import com.back2kasi.booking.dto.UpdateBookingStatusRequest;
import com.back2kasi.booking.entity.Booking;
import com.back2kasi.booking.entity.BookingStatus;
import com.back2kasi.booking.repository.BookingRepository;
import com.back2kasi.common.exception.ResourceNotFoundException;
import com.back2kasi.common.exception.UnauthorizedException;
import com.back2kasi.rentalunit.entity.RentalUnit;
import com.back2kasi.rentalunit.entity.RentalUnitStatus;
import com.back2kasi.rentalunit.repository.RentalUnitRepository;
import com.back2kasi.user.entity.User;
import com.back2kasi.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.temporal.ChronoUnit;
import java.util.List;

/**
 * Implementation of {@link BookingService}.
 *
 * <p>Layer contract:</p>
 * <pre>
 *   BookingController → BookingServiceImpl → BookingRepository → PostgreSQL
 *                                         → RentalUnitRepository (status transitions)
 *                                         → UserRepository (customer lookup)
 * </pre>
 *
 * <h2>Key design decisions</h2>
 *
 * <p><strong>1. Total price locked at creation time</strong><br>
 * {@code totalPrice = pricePerDay × days} is computed once and stored on the
 * {@code Booking} row. Future price changes on the {@code RentalUnit} never
 * retroactively affect existing bookings.</p>
 *
 * <p><strong>2. Overlap check before save</strong><br>
 * Before persisting a new booking we query for any {@code CONFIRMED} booking on
 * the same unit whose date range overlaps the requested range. {@code PENDING} and
 * {@code CANCELLED} bookings are excluded — they do not block new reservations.</p>
 *
 * <p><strong>3. Automated RentalUnit status transitions</strong><br>
 * Status changes on a booking have side effects on the rental unit:
 * {@code CONFIRMED} → unit becomes {@code RENTED};
 * {@code COMPLETED} or {@code CANCELLED} → unit reverts to {@code AVAILABLE}.</p>
 *
 * <p><strong>4. Role-based transition rules</strong><br>
 * The service inspects the caller's relationship to the booking before allowing
 * a status change. Customers can only cancel their own {@code PENDING} bookings;
 * owners have full transition authority.</p>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class BookingServiceImpl implements BookingService {

    private final BookingRepository bookingRepository;
    private final RentalUnitRepository rentalUnitRepository;
    private final UserRepository userRepository;

    // =========================================================
    // Create
    // =========================================================

    /**
     * {@inheritDoc}
     *
     * <p>Steps:</p>
     * <ol>
     *   <li>Fetch the rental unit — 404 if not found.</li>
     *   <li>Validate date ordering ({@code startDate} must not be after {@code endDate}).</li>
     *   <li>Check for overlapping {@code CONFIRMED} bookings — 409 if conflict.</li>
     *   <li>Compute {@code totalPrice}.</li>
     *   <li>Fetch the customer {@code User} entity — 404 if not found.</li>
     *   <li>Persist the booking in {@code PENDING} status and return the DTO.</li>
     * </ol>
     */
    @Override
    @Transactional
    public BookingResponse createBooking(CreateBookingRequest request, Long customerId) {
        log.info("Customer id={} creating booking for rentalUnitId={} [{} to {}]",
                customerId, request.rentalUnitId(), request.startDate(), request.endDate());

        RentalUnit unit = rentalUnitRepository.findById(request.rentalUnitId())
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Rental unit not found with id: " + request.rentalUnitId()
                ));

        validateDateRange(request);
        checkNoOverlap(unit.getId(), request, -1L);

        long days = ChronoUnit.DAYS.between(request.startDate(), request.endDate()) + 1;
        BigDecimal totalPrice = unit.getPricePerDay().multiply(BigDecimal.valueOf(days));

        User customer = userRepository.findById(customerId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "User not found with id: " + customerId
                ));

        Booking booking = Booking.builder()
                .rentalUnit(unit)
                .customer(customer)
                .startDate(request.startDate())
                .endDate(request.endDate())
                .totalPrice(totalPrice)
                .notes(request.notes())
                .build();

        Booking saved = bookingRepository.save(booking);
        log.info("Booking created: id={} status={} totalPrice={}", saved.getId(), saved.getStatus(), saved.getTotalPrice());

        return BookingResponse.from(saved);
    }

    // =========================================================
    // Read
    // =========================================================

    /**
     * {@inheritDoc}
     *
     * <p>Visibility check: the caller must be either the booking's customer
     * or the business owner of the booked rental unit.</p>
     */
    @Override
    @Transactional(readOnly = true)
    public BookingResponse getBookingById(Long id, Long callerId) {
        log.debug("Fetching bookingId={} for callerId={}", id, callerId);

        Booking booking = findOrThrow(id);
        verifyReadAccess(booking, callerId);

        return BookingResponse.from(booking);
    }

    /** {@inheritDoc} */
    @Override
    @Transactional(readOnly = true)
    public List<BookingResponse> getBookingsByCustomer(Long customerId) {
        log.debug("Fetching bookings for customerId={}", customerId);

        return bookingRepository.findByCustomerId(customerId)
                .stream()
                .map(BookingResponse::from)
                .toList();
    }

    /**
     * {@inheritDoc}
     *
     * <p>Ownership check: the caller must own the rental unit's parent business.</p>
     */
    @Override
    @Transactional(readOnly = true)
    public List<BookingResponse> getBookingsByRentalUnit(Long rentalUnitId, Long ownerId) {
        log.debug("Fetching bookings for rentalUnitId={} by ownerId={}", rentalUnitId, ownerId);

        RentalUnit unit = rentalUnitRepository.findById(rentalUnitId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Rental unit not found with id: " + rentalUnitId
                ));

        verifyUnitOwnership(unit, ownerId);

        return bookingRepository.findByRentalUnitId(rentalUnitId)
                .stream()
                .map(BookingResponse::from)
                .toList();
    }

    // =========================================================
    // Update status
    // =========================================================

    /**
     * {@inheritDoc}
     *
     * <p>Transition rules enforced here:</p>
     * <ul>
     *   <li>Only the business owner may set {@code CONFIRMED} or {@code COMPLETED}.</li>
     *   <li>Either the customer (if {@code PENDING}) or the owner may set {@code CANCELLED}.</li>
     *   <li>A {@code COMPLETED} or {@code CANCELLED} booking cannot be transitioned further.</li>
     * </ul>
     */
    @Override
    @Transactional
    public BookingResponse updateBookingStatus(Long id, UpdateBookingStatusRequest request, Long callerId) {
        log.info("Caller id={} updating bookingId={} to status={}", callerId, id, request.status());

        Booking booking = findOrThrow(id);
        BookingStatus newStatus = request.status();

        // Guard: terminal states cannot be changed
        if (booking.getStatus() == BookingStatus.COMPLETED || booking.getStatus() == BookingStatus.CANCELLED) {
            throw new IllegalStateException(
                    "Cannot change status of a " + booking.getStatus() + " booking"
            );
        }

        boolean isOwner = booking.getRentalUnit().getBusiness().getOwner().getId().equals(callerId);
        boolean isCustomer = booking.getCustomer().getId().equals(callerId);

        if (!isOwner && !isCustomer) {
            throw new UnauthorizedException("You do not have permission to update this booking");
        }

        switch (newStatus) {
            case CONFIRMED -> {
                if (!isOwner) {
                    throw new UnauthorizedException("Only the business owner can confirm a booking");
                }
                booking.setStatus(BookingStatus.CONFIRMED);
                booking.getRentalUnit().setStatus(RentalUnitStatus.RENTED);
                log.info("Booking id={} confirmed — rentalUnit id={} set to RENTED",
                        id, booking.getRentalUnit().getId());
            }
            case COMPLETED -> {
                if (!isOwner) {
                    throw new UnauthorizedException("Only the business owner can complete a booking");
                }
                if (booking.getStatus() != BookingStatus.CONFIRMED) {
                    throw new IllegalStateException("Only a CONFIRMED booking can be marked COMPLETED");
                }
                booking.setStatus(BookingStatus.COMPLETED);
                booking.getRentalUnit().setStatus(RentalUnitStatus.AVAILABLE);
                log.info("Booking id={} completed — rentalUnit id={} set to AVAILABLE",
                        id, booking.getRentalUnit().getId());
            }
            case CANCELLED -> {
                if (!isOwner && !isCustomer) {
                    throw new UnauthorizedException("You do not have permission to cancel this booking");
                }
                BookingStatus previousStatus = booking.getStatus();
                if (isCustomer && !isOwner && previousStatus != BookingStatus.PENDING) {
                    throw new IllegalStateException("Customers may only cancel a PENDING booking");
                }
                booking.setStatus(BookingStatus.CANCELLED);
                // Only revert unit status if the booking was previously confirmed
                if (previousStatus == BookingStatus.CONFIRMED) {
                    booking.getRentalUnit().setStatus(RentalUnitStatus.AVAILABLE);
                }
                log.info("Booking id={} cancelled (was {})", id, previousStatus);
            }
            default -> throw new IllegalStateException("Invalid target status: " + newStatus);
        }

        Booking updated = bookingRepository.save(booking);
        rentalUnitRepository.save(updated.getRentalUnit());

        return BookingResponse.from(updated);
    }

    // =========================================================
    // Private helpers
    // =========================================================

    /**
     * Fetch a booking by ID or throw {@link ResourceNotFoundException}.
     */
    private Booking findOrThrow(Long id) {
        return bookingRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Booking not found with id: " + id
                ));
    }

    /**
     * Validate that {@code startDate} is not after {@code endDate}.
     *
     * @throws IllegalStateException if the date range is invalid
     */
    private void validateDateRange(CreateBookingRequest request) {
        if (request.startDate().isAfter(request.endDate())) {
            throw new IllegalStateException("Start date must not be after end date");
        }
    }

    /**
     * Check that no existing {@code CONFIRMED} booking on this unit overlaps the requested range.
     *
     * @param rentalUnitId     the unit to check
     * @param request          the incoming date range
     * @param excludeBookingId booking to exclude (use {@code -1L} for new bookings)
     * @throws IllegalStateException if a conflicting booking exists
     */
    private void checkNoOverlap(Long rentalUnitId, CreateBookingRequest request, Long excludeBookingId) {
        boolean overlap = bookingRepository.existsOverlappingBooking(
                rentalUnitId,
                request.startDate(),
                request.endDate(),
                BookingStatus.CONFIRMED,
                excludeBookingId
        );
        if (overlap) {
            throw new IllegalStateException(
                    "The rental unit is already booked for the requested date range"
            );
        }
    }

    /**
     * Verify the caller may read this booking.
     *
     * <p>Allowed: the booking's customer, or the business owner of the rental unit.</p>
     *
     * @throws UnauthorizedException if the caller is neither
     */
    private void verifyReadAccess(Booking booking, Long callerId) {
        boolean isCustomer = booking.getCustomer().getId().equals(callerId);
        boolean isOwner = booking.getRentalUnit().getBusiness().getOwner().getId().equals(callerId);
        if (!isCustomer && !isOwner) {
            throw new UnauthorizedException("You do not have permission to view this booking");
        }
    }

    /**
     * Verify the rental unit's parent business is owned by the caller.
     *
     * @throws UnauthorizedException if the caller does not own the business
     */
    private void verifyUnitOwnership(RentalUnit unit, Long ownerId) {
        if (!unit.getBusiness().getOwner().getId().equals(ownerId)) {
            throw new UnauthorizedException(
                    "You do not have permission to view bookings for this rental unit"
            );
        }
    }
}
